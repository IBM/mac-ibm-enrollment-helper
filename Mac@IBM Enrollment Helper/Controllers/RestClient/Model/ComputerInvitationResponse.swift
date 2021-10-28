//
//  ComputerInvitationResponse.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Jan Valentik on 10/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

struct ComputerInvitation: Decodable {
    let invitationStatus: String

    private enum CodingKeys: String, CodingKey {
        case invitationStatus = "invitation_status"
    }
}

struct ComputerInvitationResponse: Decodable {
    let computerInvitation: ComputerInvitation

    private enum CodingKeys: String, CodingKey {
        case computerInvitation = "computer_invitation"
    }
}
