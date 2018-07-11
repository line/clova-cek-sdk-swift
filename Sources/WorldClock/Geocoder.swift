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
import SwiftyRequest

public class Geocoder {
    struct GeocodeResponse: Codable {
        struct Results: Codable {
            struct Geometry: Codable {
                struct Location: Codable {
                    var lat: Double
                    var lng: Double
                }
                var location: Location
            }
            var geometry: Geometry
        }
        var results: [Results]

        func latLng() -> (Double, Double)? {
            guard let lat = self.results.first?.geometry.location.lat,
                let lng = self.results.first?.geometry.location.lng else {
                    return nil
            }

            return (lat, lng)
        }
    }

    struct TimezoneResponse: Codable {
        var timeZoneId: String
    }

    public static func getTime(_ apiKey: String?, _ address: String, _ handler: @escaping (String?) -> ()) {
        guard let apiKey = apiKey else {
            handler(nil)
            return
        }

        requestGeocode(apiKey, address) { (latLng: (Double, Double)?) in
            guard let latLng = latLng else {
                handler(nil)
                return
            }

            requestTimezone(apiKey, latLng.0, latLng.1, { (timeZoneId: String?) in
                guard let timeZoneId = timeZoneId,
                    let timeZone = TimeZone.init(identifier: timeZoneId) else {
                    handler(nil)
                    return
                }

                let time = Date.init()
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = timeZone
                dateFormatter.locale = Locale.init(identifier: "ja")
                dateFormatter.dateFormat = "\(address)は現在、ah時m分です"
                handler(dateFormatter.string(from: time))
            })

        }
    }

    static func requestGeocode(_ apiKey: String, _ address: String, _ handler: @escaping ((Double, Double)?) -> ()) {
        let request = RestRequest(method: .get, url: "https://maps.googleapis.com/maps/api/geocode/json")
        request.responseData(templateParams: nil,
                             queryItems: [URLQueryItem(name: "address", value: address),
                                          URLQueryItem(name: "key", value: apiKey)])
        { response in
            switch response.result {
            case .success(let retval):
                guard let results = try? JSONDecoder().decode(GeocodeResponse.self, from: retval) else {
                    handler(nil)
                    return
                }
                handler(results.latLng())
            case .failure:
                handler(nil)
            }
        }
    }

    static func requestTimezone(_ apiKey: String, _ lat: Double, _ lng: Double, _ handler: @escaping (String?) -> ()) {
        let request = RestRequest(method: .get, url: "https://maps.googleapis.com/maps/api/timezone/json")
        request.responseData(templateParams: nil,
                             queryItems: [URLQueryItem(name: "location", value: "\(lat),\(lng)"),
                                          URLQueryItem(name: "timestamp", value: "\(Date().timeIntervalSince1970)"),
                                          URLQueryItem(name: "key", value: apiKey)])
        { response in
            switch response.result {
            case .success(let retval):
                guard let results = try? JSONDecoder().decode(TimezoneResponse.self, from: retval) else {
                    handler(nil)
                    return
                }
                handler(results.timeZoneId)
            case .failure:
                handler(nil)
            }
        }
    }
}
