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
import LoggerAPI

class Clova_CEK_SDK_SwiftTests: XCTestCase {
    private struct EmptyHandlers: ExtensionRequestHandler {
        func launchHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) {}
        func intentHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) {}
    }

    private let rawRequest = """
{
    "version": "0.1.0",
    "session": {
        "sessionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "user": {
            "userId": "xxxxxxxxxxxxxxxxxxxxxx",
            "accessToken": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        },
        "new": true
    },
    "context": {
        "System": {
            "user": {
                "userId": "xxxxxxxxxxxxxxxxxxxxxx",
                "accessToken": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            },
            "device": {
                "deviceId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                "display": {
                    "size": "l100",
                    "orientation": "landscape",
                    "dpi": 96,
                    "contentLayer": {
                        "width": 640,
                        "height": 360
                    }
                }
            }
        }
    },
    "request": {
        "type": "IntentRequest",
        "intent": {
            "name": "CitiesIntent",
            "slots": {
                "city_first": {
                    "name": "city_first",
                    "value": "東京"
                },
                "city_second": {
                    "name": "city_second",
                    "value": "京都"
                }
            }
        }
    }
}
"""

    func testDecodeIntentRequest() {
        let request:CEKRequest? = try? JSONDecoder().decode(CEKRequest.self, from: rawRequest.data(using: .utf8)!)
        if case let .intent(name: name, slots: slots)? = request?.request {
            XCTAssertEqual(name == "CitiesIntent", true)
            if let slot_second = slots["city_second"] {
                XCTAssertEqual(slot_second.value, "京都")
            } else {
                XCTFail()
            }

            XCTAssertEqual(request?.getSlot(name: "city_first"), "東京")
        } else {
            XCTFail()
        }
    }

    func testSimpleSentence() {
        let response = CEKResponse.simpleSpeech("行き先はどちらですか", shouldEndSession: true)
        if let encodedData = try? JSONEncoder().encode(response),
            let text = String.init(data: encodedData, encoding: .utf8) {
            XCTAssert(text.contains("\"shouldEndSession\":true"))
            XCTAssert(text.contains("\"sessionAttributes\":{}"))
            XCTAssert(text.contains("\"type\":\"PlainText\""))
            XCTAssert(text.contains("\"value\":\"行き先はどちらですか\""))
        } else {
            XCTFail()
        }
    }

    func testLoggerMessageType() {
        guard let type = LoggerMessageType.init(rawStringValue: "DEBUG"), case LoggerMessageType.debug = type else {
            XCTFail()
            return
        }
    }

    func testApiPath() {
        let debugPath = ApiPath.forDebug(path: "debugPath")
        let verificationPath = ApiPath.withVerification(path: "verificationPath", applicationId:"com.keno42.worldClock")

        XCTAssert(debugPath.getPath() == "debugPath")
        XCTAssert(verificationPath.getPath() == "verificationPath")
        XCTAssert(debugPath.needVerification() == false)
        XCTAssert(verificationPath.needVerification() == true)
    }

    func testDefaultHandler() {
        let request:CEKRequest = try! JSONDecoder().decode(CEKRequest.self, from: rawRequest.data(using: .utf8)!)
        EmptyHandlers().sessionEndedHandler(request: request)
    }

    static var allTests = [
        ("testDecodeIntentRequest", testDecodeIntentRequest),
        ("testSimpleSentence", testSimpleSentence),
        ("testLoggerMessageType", testLoggerMessageType),
        ("testApiPath", testApiPath),
        ("testDefaultHandler", testDefaultHandler),
        ]

}
