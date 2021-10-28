//
//  ArtifactoryResponse.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 06/10/2021.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

struct VersionProperties: Decodable {
    let buildNumber: [String]
    let minAllowedBuildNr: [String]
    let version: [String]
    
    private enum CodingKeys: String, CodingKey {
        case buildNumber = "build_nr"
        case minAllowedBuildNr = "min_allowed_build_nr"
        case version = "version"
    }
}

struct ArtifactoryResponse: Decodable {
    let properties: VersionProperties
}
