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

import LoggerAPI

/// Simple Logger that applies to `Logger` protocol and prints to console
public class SimpleLogger: Logger {
    public func log(_ type: LoggerMessageType, msg: String, functionName: String, lineNum: Int, fileName: String) {
        print("[\(type)]", msg)
    }

    public func isLogging(_ level: LoggerMessageType) -> Bool {
        return self.logTypes.contains(level)
    }

    let logTypes: Set<LoggerMessageType>

    public init(logTypes: [LoggerMessageType]) {
        self.logTypes = Set<LoggerMessageType>(logTypes)
    }
}

extension LoggerMessageType {
    /// init with a raw value such as `DEBUG`, `VERBOSE` and so on.
    ///
    /// - Parameter rawStringValue: A String which should be one of description. See LoggerMessageType.description.
    public init?(rawStringValue: String) {
        for rawIntValue in 1...7 {
            if let enumValue = LoggerMessageType(rawValue: rawIntValue),
                rawStringValue == enumValue.description {
                self = enumValue
                return
            }
        }
        return nil
    }
}
