//
//  EndPoint.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 01/10/2021.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable trailing_whitespace

import Foundation

internal enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case HEAD
    case DELETE
    case CONNECT
    case OPTIONS
    case TRACE
}

/// Rapresent an endpoint/
internal struct Endpoint: RawRepresentable, Equatable {
    
    // MARK: - Properties
    
    /// The raw value of url.
    let rawValue: URL
    
    /// Url components of the endpoint.
    var urlComponents: URLComponents! {
        return URLComponents(url: rawValue, resolvingAgainstBaseURL: true)
    }
    
    // MARK: - Init
    
    /// Create a new enpoint from url.
    /// - Parameter rawValue: The url that points of the endpoint.
    init(rawValue: URL) {
        self.rawValue = rawValue
    }
    
    /// Create a new endpoint from string and relative endpoint.
    /// - Parameters:
    ///   - string: The string of the path.
    ///   - endpoint: The relative endpoint.
    init(string: StaticString, relativeTo endpoint: Endpoint? = nil) {
        guard let url = URL(string: "\(string)", relativeTo: endpoint?.rawValue) else {
            // Log error locally
            fatalError("Cannot create an url from string '\(string)'")
        }
        self.rawValue = url
    }
    
    init(string: String, relativeTo endpoint: Endpoint? = nil) {
        guard let url = URL(string: string, relativeTo: endpoint?.rawValue) else {
            // Log error locally
            fatalError("Cannot create an url from string '\(string)'")
        }
        self.rawValue = url
    }
    
    /// Create a new url request from the endpoint.
    func urlRequest(withAuthToken token: String? = nil,
                    headers: [String: String]? = nil,
                    httpBody: Data? = nil,
                    httpMethod: HTTPMethod = .GET,
                    basicCred: String? = nil) -> URLRequest {
        var request = URLRequest(url: rawValue)
        request.httpMethod = httpMethod.rawValue
        switch self {
        case .properties:
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        default:
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let headers = headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let basicCred = basicCred {
            request.addValue("Basic \(basicCred)", forHTTPHeaderField: "Authorization")
        }
        if let body = httpBody {
            request.httpBody = body
        }
        return request
    }
}

extension Endpoint: CaseIterable {
    
    // MARK: - Base Endpoints
    
    static private let baseJSSUrl = Endpoint(string: Environment.current.environmentURL)
    static private let baseArtifactoryURL = Endpoint(string: Environment.current.artifactoryURLString)
    
    // MARK: - Artifactory Endpoints
    
    static let properties = Endpoint(string: Environment.current.remoteFileName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "?properties", relativeTo: baseArtifactoryURL)
    
    /// Useful for tests purposes
    static var allCases: [Endpoint] {[
        .properties
    ]}
}
