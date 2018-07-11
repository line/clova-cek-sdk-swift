/**
 * Copyright 2018 LINE Corporation
 *
 * LINE Corporation licenses this file to you under the Apache License,
 * version 2.0 (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at:
 *
 *   https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 **/

import Foundation
import Kitura
import KituraNet
import KituraContracts
import LoggerAPI


/// A dictionary that stores Certificates in memory per URL
//private var signatureCEKCertChain = [String : String]()

/// A data object to hold a path for routing and a secret for validation if necessary
///
/// For example, if its path string is "debug", it handles a request for `https://<yourhost>/debug`
/// - Note: There is currently no way to distinguish the path in the handler.
///
/// - withVerification: Each endpoint tries to verify the request with an URL for a public key in the request header
/// - forDebug: A path for debug which does not need a validation
public enum ApiPath {
    case withVerification(path: String, applicationId: String)
    case forDebug(path: String)

    /// Internal function to only return the path string to be used for routing.
    ///
    /// - Returns: Path string to be used for routing.
    func getPath() -> String {
        switch self {
        case .withVerification(path: let path, applicationId: _): return path
        case .forDebug(path: let path): return path
        }
    }

    /// Return whether current path expects to verify the signature or not
    ///
    /// - Returns: true if it is expected to verify the signature.
    func needVerification() -> Bool {
        switch self {
        case .withVerification: return true
        case .forDebug: return false
        }
    }

    /// Check if the applicationId matches for current path
    ///
    /// - Parameter applicationId: An applicationId included in a CEK request
    /// - Returns: true when it matches as expected one, or current path is for debug purpose.
    func check(applicationId: String) -> Bool {
        switch self {
        case .withVerification(path: _, applicationId: applicationId): return true
        case .withVerification(path: _, applicationId: _): return false
        case .forDebug: return true
        }
    }
}

/// A type that implements business logis for each CEK request types
public protocol ExtensionRequestHandler {

    /// Provide a business logic to handle a request of `Launch` type
    ///
    /// - Parameters:
    ///   - request: A decoded struct of the request message
    ///   - next: A function to finalize its response. *It must be called once.*
    func launchHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) -> ()

    /// Provide a business logic to handle a request of `Intent` type
    ///
    /// - Parameters:
    ///   - request: A decoded struct of the request message
    ///   - next: A function to finalize its response. *It must be called once.*
    func intentHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) -> ()

    /// Provide a business logic to handle a request of `SessionEnded` type
    ///
    /// - Parameter request: A decoded struct of the request message
    func sessionEndedHandler(request: CEKRequest) -> ()
}

// MARK: - Provides default implementation of sessionEndedHandler(request:)
public extension ExtensionRequestHandler {
    func sessionEndedHandler(request: CEKRequest) {
    }

    internal func decodeBody(body: String) throws -> CEKRequest {
        return try JSONDecoder().decode(CEKRequest.self, from: body.data(using: .utf8)!)
    }

    // A function to parse body and invoke each handler
    internal func handle(cekRequest: CEKRequest, request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        let responseHandler: (CEKResponse) -> () = { cekResponse in
            try! response.send(data: JSONEncoder().encode(cekResponse))
            next()
        }

        switch cekRequest.request {
        case .launch:
            self.launchHandler(request: cekRequest, next: responseHandler)
        case .intent:
            self.intentHandler(request: cekRequest, next: responseHandler)
        case .sessionEnded:
            self.sessionEndedHandler(request: cekRequest)
            response.status(.OK)
            next()
        }
    }
}

/// A simple struct that conforms to Error
private struct ParseError: Swift.Error {}

/// Start a webhook server for the `Clova Extension Kit (CEK)`
///
/// - Parameters:
///   - port: Port to listen to
///   - paths: API path. It would respond to https://example.com/<path>
///   - handler: Handler for Business logic
public func startServer(port: Int, paths: [ApiPath], handler: ExtensionRequestHandler) {
    let router: Router = Router()

    // Routing
    for path in (paths.filter{$0.getPath().isEmpty == false}) {
        router.post(path.getPath()) { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
            guard let rawBody = try? request.readString(), let body = rawBody else {
                response.status(.badRequest)
                return
            }

            let cekRequest: CEKRequest

            if path.needVerification() {
                do {
                    try SignatureVerifier.verifyRequest(body: body, headers: request.headers)
                    cekRequest = try handler.decodeBody(body: body)
                    guard let applicationId = cekRequest.context.system.application?.applicationId,
                        path.check(applicationId: applicationId) else {
                            throw VerificationError()
                    }
                } catch {
                    response.status(.unauthorized)
                    return
                }
            } else {
                cekRequest = try handler.decodeBody(body: body)
            }

            do {
                try handler.handle(cekRequest: cekRequest, request: request, response: response, next: next)
            } catch {
                response.status(.badRequest)
                return
            }
        }
    }

    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
