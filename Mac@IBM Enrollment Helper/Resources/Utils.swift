//
//  Utils.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 28/07/22.
//  Copyright © 2022 IBM. All rights reserved.
//  SPDX-License-Identifier: Apache2.0
//

import Foundation

struct Utils {
    
    // MARK: - Enums
    
    enum InterfaceStyle: String {
        case dark = "Dark"
        case light = "Light"

        init() {
            let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
            self = InterfaceStyle(rawValue: type)!
        }
    }
    
    // MARK: - Static Variables
    
    static var currentInterfaceStyle: InterfaceStyle {
        return InterfaceStyle()
    }
    
    /// Checks if the given profile is already installed on device.
    /// - Returns: true/false
    static func isProfileInstalled(_ profileName: String) -> Bool {
        let command = "system_profiler SPConfigurationProfileDataType | grep -E \".*\(profileName).*?:\" | awk -F \":\" '{sub(/^[\t ]*/, \"\"); print $1}'"
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output.contains(profileName)
    }
    
    /// Checks if any MDM profile is already installed on device.
    /// - Returns: true/false
    static func isGenericMDMProfileInstalled() -> Bool {
        return isProfileInstalled("com.apple.mdm")
    }
    
    /// Checks specifically if the MDM profile installed on device is the company one.
    /// - Returns: true/false
    static func isCompanyMDMProfileInstalled() -> Bool {
        return isProfileInstalled(Environment.current.managementProfileName)
    }
    
    /// Return the date of installation of the detected MDM Profile.
    /// - Returns: true/false
    static func MDMProfileInstallationDate() -> Date? {
        let command = "system_profiler SPConfigurationProfileDataType | grep -A4 \"MDM Profile\" | grep -E \"Installation Date\" | awk -vRS=\")\" -vFS=\"(\" '{print $2}'"
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return dateFormatter.date(from: output)
    }
    
    /// Checks if the jamf binary is already available on device.
    /// - Returns: true/false
    static func isJamfBinaryInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: "/usr/local/jamf/bin/jamf")
    }
}
