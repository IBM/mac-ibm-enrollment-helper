//
//  String-Extension.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

extension String {
    /// Return the string localized using self as key and the current locale.
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
