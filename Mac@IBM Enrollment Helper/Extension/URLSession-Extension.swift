//
//  URLSession-Extension.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 05/10/2021.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

extension URLSession {
    /// Execute a data task with the provided URLRequest expecting to receive the related returning type.
    /// - Parameters:
    ///   - request: The URLRequest that needs to be made;
    ///   - returning: The expected returning object type;
    ///   - onUnauthorized: Block of code that needs to be executed on "Unauthorized" server response;
    ///   - completion: Block of code that needs to be executed on the completion with success of the data task;
    ///   - errorHandler: Block of code that needs to be executed on the completion with error of the data task.
    internal func make<T: Decodable>(request: URLRequest,
                                     returning: T.Type,
                                     onUnauthorized: (() -> Void)? = nil,
                                     completion: @escaping (T) -> Void,
                                     errorHandler: @escaping (HelperError) -> Void) {
        self.dataTask(with: request) { (data, response, error) in
            if let error = error {
                errorHandler(HelperError.apiError(type: .networkError(errorString: error.localizedDescription)))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                errorHandler(HelperError.apiError(type: .noResponse))
                return
            }
            do {
                switch response.statusCode {
                case 200, 201, 202:
                    guard let data = data else {
                        errorHandler(HelperError.apiError(type: .noData))
                        return
                    }
                    let response = try JSONDecoder().decode(returning, from: data)
                    completion(response)
                case 401:
                    guard let onUnauthorized = onUnauthorized else {
                        errorHandler(HelperError.apiError(type: .badResponse(responseCode: response.statusCode)))
                        return
                    }
                    onUnauthorized()
                default:
                    errorHandler(HelperError.apiError(type: .badResponse(responseCode: response.statusCode)))
                }
            } catch {
                errorHandler(HelperError.apiError(type: .decoding(decodingError: error.localizedDescription)))
            }
        }.resume()
    }
    
    /// Execute a data task with the provided URLRequest expecting to receive the related returning type.
    /// - Parameters:
    ///   - request: The URLRequest that needs to be made;
    ///   - onUnauthorized: Block of code that needs to be executed on "Unauthorized" server response;
    ///   - completion: Block of code that needs to be executed on the completion with success of the data task;
    ///   - errorHandler: Block of code that needs to be executed on the completion with error of the data task.
    internal func make(request: URLRequest,
                       onUnauthorized: (() -> Void)? = nil,
                       completion: @escaping () -> Void,
                       errorHandler: @escaping (HelperError) -> Void) {
        self.dataTask(with: request) { (_, response, error) in
            if let error = error {
                errorHandler(HelperError.apiError(type: .networkError(errorString: error.localizedDescription)))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                errorHandler(HelperError.apiError(type: .noResponse))
                return
            }
            switch response.statusCode {
            case 200, 201, 202:
                completion()
            case 401:
                guard let onUnauthorized = onUnauthorized else {
                    errorHandler(HelperError.apiError(type: .badResponse(responseCode: response.statusCode)))
                    return
                }
                onUnauthorized()
            default:
                errorHandler(HelperError.apiError(type: .badResponse(responseCode: response.statusCode)))
            }
        }.resume()
    }
}
