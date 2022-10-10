//
//  HelperError.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 10/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

/// Enumerates possible errors.
enum HelperError {
    case profileError(type: Enums.ProfileError)
    case apiError(type: Enums.APIError)
    case generic(type: Enums.Generic)

    class Enums { }
}

extension HelperError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .profileError(let type):
            return type.localizedDescription
        case .apiError(type: let type):
            return type.localizedDescription
        case .generic(type: let type):
            return type.localizedDescription
        }
    }
}

extension HelperError.Enums {
    enum ProfileError {
        case decoding(description: String)
        case store(description: String)
        case deviceIsManaged
    }
}

extension HelperError.Enums.ProfileError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .decoding(let description):
            return "Failed to decode the profile: \(description)."
        case .store(let description):
            return "Failed to save configuration profile: \(description)."
        case .deviceIsManaged:
            return ""
        }
    }
}

extension HelperError.Enums {
    enum APIError {
        case noData
        case noResponse
        case decoding(decodingError: String)
        case badResponse(responseCode: Int)
        case networkError(errorString: String)
    }
}

extension HelperError.Enums.APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noData:
            return "Received no data from response."
        case .noResponse:
            return "Received no response from data task."
        case .decoding(let decodingError):
            return "Failed to decode object from json: \(decodingError)."
        case .badResponse(let code):
            return "Received bad response from server. Response code: \(code)."
        case .networkError(let errorString):
            return "Network error: \(errorString)."
        }
    }
}

extension HelperError.Enums {
    enum Generic {
        case timeout
        case oldVersion
    }
}

extension HelperError.Enums.Generic: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Current check timeout."
        case .oldVersion:
            return ""
        }
    }
}
