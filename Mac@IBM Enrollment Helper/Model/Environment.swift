//
//  Environment.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 09/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable identifier_name line_length

import Foundation

/// This struct handle all the configurable items for Mac@IBM Enrollment Helper
private struct Configuration {
    
    // MARK: - Rosetta 2 Installation
    
    /// Boolean value that define if to check Rosetta 2 installation on M1 device and so to show the related installation page.
    static let testIgnoreRosettaInstallation: Bool = false
    static let qaIgnoreRosettaInstallation: Bool = false
    static let prodIgnoreRosettaInstallation: Bool = false

    // MARK: - Artifactory configuration for app version check
    
    /// Boolean value that defines whether to run the app version check on the welcome page or not.
    /// If false you can ignore the other 'Artifcatory configuration' parameters.
    static let testAreStartupChecksEnabled: Bool = false
    static let qaAreStartupChecksEnabled: Bool = false
    static let prodAreStartupChecksEnabled: Bool = false
    /// The remote installer file name for version checking (ex. Enrollment Helper.dmg)
    static let testRemoteFileName: String = ""
    static let qaRemoteFileName: String = ""
    static let prodRemoteFileName: String = ""
    /// Artifactory folder URLs
    static let testArtifactoryURLString: String = "https://artifactory.folder.url"
    static let qaArtifactoryURLString: String = "https://artifactory.folder.url"
    static let prodArtifactoryURLString: String = "https://artifactory.folder.url"
    /// Where to redirect the user if the app version check fails.
    static let testVersionCheckFailedRedirectURLString: String = "https://url.where.to.redirect.user"
    static let qaVersionCheckFailedRedirectURLString: String = "https://url.where.to.redirect.user"
    static let prodVersionCheckFailedRedirectURLString: String = "https://url.where.to.redirect.user"

    // MARK: - Jamf configuration for profile download and installation check
    
    /// The Jamf Pro Server base URLs
    static let testEnvURLString: String = "https://jss.url"
    static let qaEnvURLString: String = "https://jss.url"
    static let prodEnvURLString: String = "https://jss.url"
    /// Default enrollment profile file name
    static let testDefaultProfileFileName: String = "enrollmentProfile.mobileconfig"
    static let qaDefaultProfileFileName: String = "enrollmentProfile.mobileconfig"
    static let prodDefaultProfileFileName: String = "enrollmentProfile.mobileconfig"
    /// Default enrollment profile name
    static let testDefaultManagementProfileName: String = "Company Management Profile"
    static let qaDefaultManagementProfileName: String = "Company Management Profile"
    static let prodDefaultManagementProfileName: String = "Company Management Profile"
    /// Self Service app custom path
    static let testAppStorePath: String = "/Applications/Some App Store.app"
    static let qaAppStorePath: String = "/Applications/Some App Store.app"
    static let prodAppStorePath: String = "/Applications/Some App Store.app"
    /// Self Service app standard url scheme
    static let testAppStoreURL: String = "jamfselfservice://"
    static let qaAppStoreURL: String = "jamfselfservice://"
    static let prodAppStoreURL: String = "jamfselfservice://"
    
    // MARK: - Default timeouts
    
    /// Timeout in seconds for the "Profile Installation" check.
    /// This timeout runs in background on the "Open System Preference" page and when expired will trigger an alert that asks the user to install the profile in System Preferences.
    /// It will then reset itself and restart in background.
    static let testDefaultCheckProfileTimeInterval: TimeInterval = 300
    static let qaDefaultCheckProfileTimeInterval: TimeInterval = 300
    static let prodDefaultCheckProfileTimeInterval: TimeInterval = 300
    /// Timeout in seconds for the "Enrollment Started" check.
    /// This timeout runs in background on the last page of the process and when expired the app will check to see if the Jamf binary is available on the user device.
    /// If so it launches the Self Service app and closes the Enrollment Helper.
    static let testDefaultCheckEnrollmentStartedTimeInterval: TimeInterval = 1200
    static let qaDefaultCheckEnrollmentStartedTimeInterval: TimeInterval = 1200
    static let prodDefaultCheckEnrollmentStartedTimeInterval: TimeInterval = 1200
}

/// This struct handle all the constants for Mac@IBM Enrollment Helper
struct Constants {
    /// The UserDefaults (plist) key used to define the environment on which the app should work
    static fileprivate let environmentUDKey: String = "environment"
    /// Jamf binary path
    static let jamfPath: String = "/usr/local/jamf/bin/jamf"
    /// Jamf binary jss connection check argument
    static let jssConnectionCheckArgument: String = "checkJSSConnection"
}

/// This enum handle the constants/variables for the three supported environment
enum Environment: String {
    case test
    case qa
    case prod
    
    /// The current environment
    static var current: Environment {
        if let environmentRawValue = UserDefaults.standard.string(forKey: Constants.environmentUDKey),
           let environment = Environment(rawValue: environmentRawValue) {
            return environment
        } else {
            return prod
        }
    }
    
    // MARK: - Common environments variables
    
    var currentAppBuild: Int {
        return Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
    }
    var enrollmentURL: URL {
        return URL(string: environmentURL)!.appendingPathComponent("/enroll")
    }
    var artifactoryAPIKey: String {
        return Secrets.artifactoryAPIKey
    }
    
    // MARK: - Environment based variables
    
    var ignoreRosettaInstallation: Bool {
        switch self {
        case .test:
            return Configuration.testIgnoreRosettaInstallation
        case .qa:
            return Configuration.qaIgnoreRosettaInstallation
        case .prod:
            return Configuration.prodIgnoreRosettaInstallation
        }
    }
    var areStartupChecksEnabled: Bool {
        guard URL(string: self.artifactoryURLString) != nil &&
                !self.remoteFileName.isEmpty &&
                URL(string: self.versionCheckFailedRedirectURLString) != nil else {
                    return false
                }
        switch self {
        case .test:
            return Configuration.testAreStartupChecksEnabled
        case .qa:
            return Configuration.qaAreStartupChecksEnabled
        case .prod:
            return Configuration.prodAreStartupChecksEnabled
        }
    }
    var remoteFileName: String {
        switch self {
        case .test:
            return Configuration.testRemoteFileName
        case .qa:
            return Configuration.qaRemoteFileName
        case .prod:
            return Configuration.prodRemoteFileName
        }
    }
    var defaultCheckEnrollmentStartedTimeInterval: TimeInterval {
        switch self {
        case .test:
            return Configuration.testDefaultCheckEnrollmentStartedTimeInterval
        case .qa:
            return Configuration.qaDefaultCheckEnrollmentStartedTimeInterval
        case .prod:
            return Configuration.prodDefaultCheckEnrollmentStartedTimeInterval
        }
    }
    var versionCheckFailedRedirectURLString: String {
        switch self {
        case .test:
            return Configuration.testVersionCheckFailedRedirectURLString
        case .qa:
            return Configuration.qaVersionCheckFailedRedirectURLString
        case .prod:
            return Configuration.prodVersionCheckFailedRedirectURLString
        }
    }
    var defaultCheckProfileTimeInterval: TimeInterval {
        switch self {
        case .test:
            return Configuration.testDefaultCheckProfileTimeInterval
        case .qa:
            return Configuration.qaDefaultCheckProfileTimeInterval
        case .prod:
            return Configuration.prodDefaultCheckProfileTimeInterval
        }
    }
    var mobileconfigFileName: String {
        switch self {
        case .test:
            return Configuration.testDefaultProfileFileName
        case .qa:
            return Configuration.qaDefaultProfileFileName
        case .prod:
            return Configuration.prodDefaultProfileFileName
        }
    }
    var managementProfileName: String {
        switch self {
        case .test:
            return Configuration.testDefaultManagementProfileName
        case .qa:
            return Configuration.qaDefaultManagementProfileName
        case .prod:
            return Configuration.prodDefaultManagementProfileName
        }
    }
    var appstorePath: String {
        switch self {
        case .test:
            return Configuration.testAppStorePath
        case .qa:
            return Configuration.qaAppStorePath
        case .prod:
            return Configuration.prodAppStorePath
        }
    }
    var appstoreURL: String {
        switch self {
        case .test:
            return Configuration.testAppStoreURL
        case .qa:
            return Configuration.qaAppStoreURL
        case .prod:
            return Configuration.prodAppStoreURL
        }
    }
    var artifactoryURLString: String {
        switch self {
        case .test:
            return Configuration.testArtifactoryURLString
        case .qa:
            return Configuration.qaArtifactoryURLString
        case .prod:
            return Configuration.prodArtifactoryURLString
        }
    }
    var environmentURL: String {
        switch self {
        case .test:
            return Configuration.testEnvURLString
        case .qa:
            return Configuration.qaEnvURLString
        case .prod:
            return Configuration.prodEnvURLString
        }
    }
}
