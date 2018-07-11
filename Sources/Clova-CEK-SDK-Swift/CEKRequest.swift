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

/// A simple data object that represents a request from the Clova platform.
public struct CEKRequest: Decodable {
    public struct User: Decodable {
        public var userId: String
        public var accessToken: String?
    }

    public struct Session: Decodable {
        public var new: Bool
        public var sessionAttributes: [String : String]? = nil
        public var sessionId: String
        public var user: User
    }

    public struct Display: Decodable {
        public struct ContentLayer: Decodable {
            public var width: Int
            public var height: Int
        }

        public var size: String
        public var orientation: String?
        public var dpi: Int?
        public var contentLayer: ContentLayer
    }

    public struct Context: Decodable {
        public struct System: Decodable {
            public struct Device: Decodable {
                public var deviceId: String = ""
                public var display: Display
            }

            public struct Application: Decodable {
                public var applicationId: String
            }

            public var user: User
            public var device: Device
            public var application: Application? // Optional in v0.1.0, it lacks in Dialog test
        }

        enum CodingKeys: String, CodingKey {
            case system = "System"
        }

        public var system: System

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.system = try container.decode(System.self, forKey: .system)
        }
    }

    public enum Request: Decodable {
        public struct Slot: Decodable {
            public var name: String
            public var value: String
            public var valueType: String?
        }

        case launch
        case intent(name: String, slots: [String : Slot])
        case sessionEnded

        enum RequestCodingKeys: String, CodingKey {
            case type
            case intent
        }

        enum IntentCodingKeys: String, CodingKey {
            case name
            case slots
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: RequestCodingKeys.self)
            let requestType = try container.decode(String.self, forKey: .type)
            switch requestType {
            case "LaunchRequest": self = .launch
            case "IntentRequest":
                do {
                    let intentContainer = try container.nestedContainer(keyedBy: IntentCodingKeys.self, forKey: .intent)
                    let name = try intentContainer.decode(String.self, forKey: .name)
                    let slots = try intentContainer.decode([String : Slot].self, forKey: .slots)
                    self = .intent(name: name, slots: slots)
                } catch {
                    throw DecodingError.keyNotFound(RequestCodingKeys.intent, .init(codingPath: [RequestCodingKeys.intent], debugDescription: "Failed to decode intent."))
                }
            case "SessionEndedRequest": self = .sessionEnded
            default: throw DecodingError.keyNotFound(RequestCodingKeys.type, .init(codingPath: [RequestCodingKeys.type], debugDescription: "Requesttype should be LaunchRequest, IntentRequest or EndRequest."))
            }
        }
    }

    public struct Slot: Decodable {
        public var name: String
        public var value: String
    }

    public var version: String
    public var session: Session
    public var context: Context
    public var request: Request
}

// MARK: - Provides helper methods to create a response object.
extension CEKRequest {
    /// A convenient method to obtain a name of the IntentMessage.
    public func getIntentName() -> String {
        switch self.request {
        case .launch, .sessionEnded: return ""
        case let .intent(name: name, slots: _): return name
        }
    }

    /// A convenient method to obtain a list of a dictionary of (name, value) pair of slots.
    public func getSlots() -> [String : String] {
        switch self.request {
        case .launch, .sessionEnded: return [:]
        case let .intent(name: _, slots: slots): return [String:String].init(uniqueKeysWithValues: slots.map { return ($1.name, $1.value) })
        }
    }

    /// A convenient method to obtain a value of a slot whose name is `name`.
    ///
    /// - Parameter name: a name of a slot whose value you want to obtain.
    /// - Returns: a value of the slot whose name is `name`. `nil` if either it is not an IntentRequest, or slots does not contain a slot with given `name`.
    public func getSlot(name: String) -> String? {
        switch self.request {
        case .launch, .sessionEnded: return nil
        case let .intent(name: _, slots: slots): return slots[name]?.value
        }
    }
}
