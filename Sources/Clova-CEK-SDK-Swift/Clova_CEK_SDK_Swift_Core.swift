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
    public func getPath() -> String {
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


/// A helper method to decode given message body to `CEKRequest` object.
///
/// - Parameter body: A raw string of the message body
/// - Returns: A `CEKRequest` object which is decoded from the message body
/// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
/// - throws: An error if any value throws an error during decoding.
private func decodeBody(body: String) throws -> CEKRequest {
    return try JSONDecoder().decode(CEKRequest.self, from: body.data(using: .utf8)!)
}

/// Verify given request for given path and return `CEKRequest`.
///
/// - Parameters:
///   - path: `ApiPath` object to specify a path to receive the request and the necessity of verification
///   - body: A raw string of the message body
///   - signatureCek: A signature if given
/// - Returns: A `CEKRequest` object which is decoded from the message body
/// - Throws: A `VerificationError` object
public func verifyRequest(for path: ApiPath, body: String, signatureCek: String?) throws -> CEKRequest {
    let cekRequest: CEKRequest

    if path.needVerification() {
        do {
            try SignatureVerifier.verifyRequest(body: body, signatureCek: signatureCek)
            cekRequest = try decodeBody(body: body)
            guard let applicationId = cekRequest.context.system.application?.applicationId,
                path.check(applicationId: applicationId) else {
                    throw VerificationError()
            }
        } catch {
            throw VerificationError()
        }
    } else {
        cekRequest = try decodeBody(body: body)
    }

    return cekRequest
}
