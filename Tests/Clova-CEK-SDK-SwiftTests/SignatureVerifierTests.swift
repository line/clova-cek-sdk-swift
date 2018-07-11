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

import XCTest
@testable import Clova_CEK_SDK_Swift
@testable import Kitura
import KituraNet

class SignatureVerifierTests: XCTestCase {

    func testVerifyRequest() {
        let body = """
{"version":"1.0","session":{"new":true,"sessionAttributes":{},"sessionId":"88ac0e66-c53e-485a-873f-542e36a34825","user":{"userId":"Ud01b1625e62790a0e6502b91adbb4b26"}},"context":{"System":{"application":{"applicationId":"com.keno42.worldClock"},"device":{"deviceId":"5d0fb2c9ea716c153c7d2bc489c03de0cbf93af8d737ab700fd435be8a575af6","display":{"size":"none","contentLayer":{"width":0,"height":0}}},"user":{"userId":"Ud01b1625e62790a0e6502b91adbb4b26"}}},"request":{"type":"LaunchRequest","requestId":"2d1f5706-1183-4419-8489-68567f1c6cc6","timestamp":"2018-07-02T10:11:30Z","locale":"ja-JP","extensionId":"com.keno42.worldClock","intent":{"intent":"","name":"","slots":null},"event":{"namespace":"","name":"","payload":null}}}
"""

        let signatureCEK = "iEW0Y9f/4HwCdHI7trS8qLY7XEiTc+lFurZHwCLKspJB0P7MMvcLpckUEIdSvRI9/GP2JfaI5J007dqKZqdmLQo+rSV9rkPnXDN8b1m2G5olQySi0WnOcOk3Dhded5Ts2zzrKINYd7VEIFnE1srN4O1UTfDOHzKcK9yV7anHuxw3X7MUU/KWdR4k3dVJz+kfQxnL2zhafUkC9X2luYah3ja0au3oLw81weizAA1+Y0FEXsx1/mhMLtZA+WLuGEKzuz3UM5V2UtfRBHKVRGnTSsUisR9U9WxUxBFo4RQJ4pK1r0uAeyszzJC4aMsLR9Ca4ysrpxb8rtLgfcurpcb3RQ=="

        let headersContainer = HeadersContainer()
        headersContainer.append("signaturecek", value: signatureCEK)
        headersContainer.append("SignatureCEKCertChainUrl", value: "https://clova-cek-requests.line.me/cek/request-cert.crt")
        let headers = Headers(headers: headersContainer)
        do {
            try SignatureVerifier.verifyRequest(body: body, headers: headers)
        } catch {
            XCTFail()
        }
    }

    func testApplicationIdCheck() {
        let expectedId = "com.example.myApp"
        let path1 = ApiPath.withVerification(path: "", applicationId: expectedId)
        let path2 = ApiPath.withVerification(path: "", applicationId: "") // empty
        let path3 = ApiPath.withVerification(path: "", applicationId: expectedId + "_")

        XCTAssert(path1.check(applicationId: expectedId) == true)
        XCTAssert(path2.check(applicationId: expectedId) == false)
        XCTAssert(path3.check(applicationId: expectedId) == false)
    }

    static var allTests = [
        ("testVerifyRequest", testVerifyRequest),
        ("testApplicationIdCheck", testApplicationIdCheck)
    ]

}
