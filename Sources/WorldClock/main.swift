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
import Clova_CEK_SDK_Swift
import LoggerAPI

// Make sure port number is defined
guard let envPort = ProcessInfo.processInfo.environment["PORT"], let port = Int(envPort) else {
        print("Failed to get $PORT. Please define it in ENV.")
        exit(-1)
}

// Setup logging level
if let envLogTypes = ProcessInfo.processInfo.environment["LOG_TYPES"] {
    // LoggerMessageType(rawStringValue:) accepts following description values of LoggerMessageType.
    // "ENTRY", "EXIT", "DEBUG", "VERBOSE", "INFO", "WARNING", "ERROR"
    let logTypes = envLogTypes.components(separatedBy: ",")
        .map{$0.trimmingCharacters(in: .whitespaces)}
        .compactMap(LoggerMessageType.init(rawStringValue:))
    Log.logger = SimpleLogger(logTypes: logTypes)
}

// Prepare paths to route.
var paths = [ApiPath]()

// https://<your hostname>/api (it tries to verify the message)
// Define APPLICATION_ID in env var to check the request is sent for your application
if let applicationId = ProcessInfo.processInfo.environment["APPLICATION_ID"] {
    paths.append(.withVerification(path: "/api", applicationId: applicationId))
}

// https://<your hostname>/<PATH_FOR_DEBUG> (if PATH_FOR_DEBUG is set. Ignores message digest verification)
if let envDebugPath = ProcessInfo.processInfo.environment["PATH_FOR_DEBUG"] {
    paths.append(.forDebug(path: envDebugPath))
}

// (Optional) For API Request for geocoding. Used by Geocoder.swift
let envGoogleApiKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"]

// Create your service handler. Do not forget to call next() with or without an argument.
struct RequestHandler: ExtensionRequestHandler {
    func launchHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) {
        next(.simpleSpeech("どの都市の時間を知りたいかおっしゃってください", shouldEndSession: false))
    }

    func intentHandler(request: CEKRequest, next: @escaping (CEKResponse) -> ()) {
        let name = request.getIntentName()
        let slots = request.getSlots()
        switch name {
        case "CityTimeIntent": // Invoke Google Geocoding API
            if let cityNameSlot = slots["city_name"] {
                Geocoder.getTime(envGoogleApiKey, cityNameSlot.value) { (result) in
                    Log.debug("Request: \(cityNameSlot.value), response: \(result ?? "nil")")
                    if let message = result {
                        next(.simpleSpeech(message, shouldEndSession: true))
                    } else {
                        next(.simpleSpeech("\(cityNameSlot.value)の時間が取得できませんでした。もう一度言い直してみてください", shouldEndSession: false))
                    }
                }
            } else {
                next(.simpleSpeech("都市の名前をおっしゃってください", shouldEndSession: false))
            }
        default: next(.simpleSpeech("よくわかりませんでした", shouldEndSession: true))
        }
    }
}

// Start the server
startServer(port: port, paths: paths, handler: RequestHandler())
