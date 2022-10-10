//
//  DeviceManagementState.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 23/09/22.
//  Copyright © 2022 IBM. All rights reserved.
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa

enum DeviceManagementState {
    case unmanaged
    case managedByOther
    case managedByCompany
    
    // The current enrollment state for the device
    static var current: DeviceManagementState {
        guard Utils.isGenericMDMProfileInstalled() else {
            return .unmanaged
        }
        guard Utils.isCompanyMDMProfileInstalled() else {
            return .managedByOther
        }
        return .managedByCompany
    }
    
    class Enums { }
}

extension DeviceManagementState {
    var alertTitle: String {
        switch self {
        case .unmanaged:
            return ""
        case .managedByOther:
            return "management_check_alert_title".localized
        case .managedByCompany:
            return "management_check_alert_title".localized
        }
    }
    
    var alertMessage: String {
        switch self {
        case .unmanaged:
            return ""
        case .managedByOther:
            return "management_check_alert_message_managed_generic".localized
        case .managedByCompany:
            return "management_check_alert_message_managed_company".localized
        }
    }
    
    var mainAlertButtonLabel: String {
        switch self {
        case .unmanaged:
            return ""
        case .managedByOther:
            return "management_check_alert_main_button_managed".localized
        case .managedByCompany:
            return "management_check_alert_main_button_managed".localized
        }
    }
    var secondaryButtonLabel: String? {
        switch self {
        case .unmanaged:
            return nil
        case .managedByOther:
            return nil
        case .managedByCompany:
            return nil
        }
    }
    
    var mainAlertButtonAction: () -> Void {
        switch self {
        case .unmanaged:
            return {}
        case .managedByOther:
            return {
                exit(0)
            }
        case .managedByCompany:
            return {
                exit(0)
            }
        }
    }
    
    var secondaryAlertbuttonAction: () -> Void {
        switch self {
        case .unmanaged:
            return {}
        case .managedByOther:
            return {}
        case .managedByCompany:
            return {}
        }
    }
}
