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
import Clova_CEK_SDK_Swift


// MARK: - Provides default implementation of sessionEndedHandler(request:)
public extension ExtensionRequestHandler {
    func sessionEndedHandler(request: CEKRequest) {
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

            do {
                cekRequest = try verifyRequest(for: path, body: body, signatureCek: request.headers["SignatureCEK"])
            } catch {
                response.status(.unauthorized)
                return
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
