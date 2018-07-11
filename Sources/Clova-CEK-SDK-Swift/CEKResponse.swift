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

let CEKResponseVersion = "0.1.0"

public enum SpeechInfoObject: Encodable {
    case plainText(lang: String, text: String)
    case url(url: String)

    enum CodingKeys: String, CodingKey {
        case type
        case lang
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .plainText(lang: lang, text: text):
            try container.encode("PlainText", forKey: .type)
            try container.encode(lang, forKey: .lang)
            try container.encode(text, forKey: .value)
        case let .url(url: urlString):
            try container.encode("URL", forKey: .type)
            try container.encode("", forKey: .lang)
            try container.encode(urlString, forKey: .value)
        }
    }

    /// Return .url if given string can be converted to URL, otherwise return .plainText
    ///
    /// - Parameters:
    ///   - textOrUrl: a text or an url
    ///   - lang: specifies in what language the string is written in the case of .plainText
    public init(_ textOrUrl: String, lang: String = "ja") {
        if let _ = URL(string: textOrUrl) {
            self = .url(url: textOrUrl)
        } else {
            self = .plainText(lang: lang, text: textOrUrl)
        }
    }
}


public enum SpeechInfo: Encodable {
    case simpleSpeech(speechInfoObject: SpeechInfoObject)
    case speechList(speechInfoObjects: [SpeechInfoObject])

    enum CodingKeys: String, CodingKey {
        case type
        case values
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .simpleSpeech(speechInfoObject: object):
            try container.encode("SimpleSpeech", forKey: .type)
            try container.encode(object, forKey: .values)
            break
        case let .speechList(speechInfoObjects: objects):
            try container.encode("SpeechList", forKey: .type)
            try container.encode(objects, forKey: .values)
            break
        }
    }
}


public enum SpeechType: Encodable {
    case onlySpeechInfo(speechInfo: SpeechInfo)
    case speechSet(brief: SpeechInfoObject, verbose: SpeechInfo)

    enum CodingKeys: String, CodingKey {
        case type
        case values
        case brief
        case verbose
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .onlySpeechInfo(speechInfo: speechInfo):
            try speechInfo.encode(to: encoder)
            break
        case let .speechSet(brief: brief, verbose: verbose):
            try container.encode("SpeechSet", forKey: .type)
            try container.encode(brief, forKey: .brief)
            try container.encode(verbose, forKey: .verbose)
            break
        }
    }

    /// Return .onlySpeechInfo(.simpleSpeech)
    ///
    /// - Parameter speechInfoObject: an object of SpeechInfoObject
    /// - Returns: .onlySpeechInfo(.simpleSpeech)
    public static func simpleSpeech(_ speechInfoObject: SpeechInfoObject) -> SpeechType {
        return .onlySpeechInfo(speechInfo: .simpleSpeech(speechInfoObject: speechInfoObject))
    }

    /// Return .onlySpeechInfo(.speechList)
    ///
    /// - Parameter speechInfoObjects: an array of SpeechInfoObject
    /// - Returns: .onlySpeechInfo(.speechList)
    public static func speechList(_ speechInfoObjects: [SpeechInfoObject]) -> SpeechType {
        return .onlySpeechInfo(speechInfo: .speechList(speechInfoObjects: speechInfoObjects))
    }
}


public struct Reprompt: Encodable {
    public var outputSpeech: SpeechType
}


/// A simple data struct for the `card` key
public struct Card: Encodable {
}


/// A simple data struct for the `header` key
public struct Header: Encodable {
    public var messageId: String = ""
    public var name: String = ""
    public var namespace: String = ""
}


/// A simple data struct for the `directive` key
public struct Directive: Encodable {
    public var header: Header = Header()
    public var payload: String = ""
}


/// A simple data struct for the `response` key
public struct Response: Encodable {
    public var outputSpeech: SpeechType
    public var reprompt: Reprompt?
    public var card: Card = Card()
    public var directives: [Directive] = [Directive]()
    public var shouldEndSession: Bool = false

    public init(outputSpeech: SpeechType, shouldEndSession: Bool, reprompt: SpeechType? = nil) {
        self.outputSpeech = outputSpeech
        self.shouldEndSession = shouldEndSession
        if let reprompt = reprompt {
            self.reprompt = Reprompt.init(outputSpeech: reprompt)
        }
    }
}


/// A simple data struct that represents a response to the Clova platform.
public struct CEKResponse: Encodable {
    public var version: String = CEKResponseVersion
    public var sessionAttributes: [String : String] = [String : String]()
    public var response: Response

    public init(response: Response, sessionAttributes: [String : String]?) {
        self.response = response
        self.sessionAttributes = sessionAttributes ?? [String : String]()
    }
}

// MARK: - Helper methods for creating CEKResponse
extension CEKResponse {
    /// Creates a `SimpleSpeech` response with a plain text or an URL.
    ///
    /// - Parameters:
    ///   - textOrUrl: .plainText or .url. They means a sentence to speech and an URL for an audio file to play, respectively.
    ///   - shouldEndSession: Indicates it keeps conversation or not. Pass `false` if you want to continue the conversation.
    ///   - sessionAttributes: If you pass it
    /// - Returns: A CEKResponse object for `SimpleSpeech`
    public static func simpleSpeech(_ textOrUrl: String, shouldEndSession: Bool, sessionAttributes: [String : String]? = nil, repromptTextOrUrl: String? = nil) -> CEKResponse {
        if let repromptTextOrUrl = repromptTextOrUrl {
            return .init(response: .init(outputSpeech: .simpleSpeech(.init(textOrUrl)), shouldEndSession: shouldEndSession, reprompt: SpeechType.simpleSpeech(.init(repromptTextOrUrl))), sessionAttributes: sessionAttributes)
        } else {
            return .init(response: .init(outputSpeech: .simpleSpeech(.init(textOrUrl)), shouldEndSession: shouldEndSession), sessionAttributes: sessionAttributes)
        }
    }
}
