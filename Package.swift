// swift-tools-version:4.1

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

import PackageDescription

let package = Package(
    name: "Clova-CEK-SDK-Swift",
    products: [
        .executable(name: "WorldClock",
                    targets: ["WorldClock"]),
        .library(
            name: "Clova-CEK-SDK-Swift",
            targets: ["Clova-CEK-SDK-Swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura", from: "2.4.0"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", .upToNextMinor(from: "1.0.1")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/IBM-Swift/OpenSSL", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "Clova-CEK-SDK-Swift",
            dependencies: ["Kitura", "Cryptor", "OpenSSL"]),
        .target(
            name: "WorldClock",
            dependencies: ["Clova-CEK-SDK-Swift", "SwiftyRequest"]),
        .testTarget(
            name: "Clova-CEK-SDK-SwiftTests",
            dependencies: ["Clova-CEK-SDK-Swift"]),
    ]
)
