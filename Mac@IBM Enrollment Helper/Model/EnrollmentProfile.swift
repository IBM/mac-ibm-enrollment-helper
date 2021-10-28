//
//  EnrollmentProfile.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Jan Valentik on 09/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable nesting

import Foundation

protocol ConfProfile {
    var challenge: String { get }
}

/// This object describe a portion of the downloaded .mobileconfig file needed to start the device enrollment.
struct EnrollmentProfile: ConfProfile, Decodable {
    struct PayloadContent: Decodable {
        let challenge: String

        private enum CodingKeys: String, CodingKey {
            case challenge = "Challenge"
        }
    }

    let payloadContent: PayloadContent
    var challenge: String {
        return payloadContent.challenge
    }

    private enum CodingKeys: String, CodingKey {
        case payloadContent = "PayloadContent"
    }
}

/// This class also describe a portion of the downloaded .mobileconfig file but with a different structure we found in the 10.30 beta.
class NewEnrollmentProfile: ConfProfile, Decodable {
    struct PayloadContent: Decodable {
        let challenge: String?
        
        private enum CodingKeys: String, CodingKey {
            case challenge = "Challenge"
        }
    }
    struct FirstLevelPayloadContent: Decodable {
        let payloadContent: PayloadContent
        
        private enum CodingKeys: String, CodingKey {
            case payloadContent = "PayloadContent"
        }
    }
    
    let payloadContent: [FirstLevelPayloadContent]
    var challenge: String {
        return payloadContent[1].payloadContent.challenge ?? ""
    }
    
    private enum CodingKeys: String, CodingKey {
        case payloadContent = "PayloadContent"
    }
}
