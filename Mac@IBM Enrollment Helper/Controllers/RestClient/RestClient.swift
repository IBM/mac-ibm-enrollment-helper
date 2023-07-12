//
//  RestClient.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 04/10/2021.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable line_length

import Foundation

/// This class handle the interaction with the backend.
class RestClient {
    
    // MARK: - Static variables
    
    static let shared: RestClient = RestClient()
    
    // MARK: - Constants
    
    let environment: Environment

    // MARK: - Initializers
    
    init() {
        self.environment = Environment.current
    }
    
    /// This method send an url request to the artifactory to get the latest hosted version properties.
    /// - Parameters:
    ///   - completion: completion with latest version properties object.
    ///   - errorHandler: completion with error.
    func getRemoteVersionInfo(_ completion: @escaping (ArtifactoryResponse) -> Void,
                              errorHandler: @escaping (HelperError) -> Void) {
        let endpoint = Endpoint.properties
        let request = endpoint.urlRequest(headers: ["X-JFrog-Art-Api": Environment.current.artifactoryAPIKey], httpMethod: .GET)
        URLSession.shared.make(request: request, returning: ArtifactoryResponse.self) {
            errorHandler(HelperError.apiError(type: .badResponse(responseCode: 401)))
        } completion: { response in
            completion(response)
        } errorHandler: { error in
            errorHandler(error)
        }

    }
}
