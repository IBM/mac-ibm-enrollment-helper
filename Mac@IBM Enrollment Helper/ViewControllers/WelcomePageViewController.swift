//
//  WelcomePageViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa
import os.log

final class WelcomePageViewController: NSViewController {

    // MARK: - Enums
    
    enum AlertType {
        case error
        case warning
    }
    
    // MARK: - Constants
    
    static let storyboardID: String = "WelcomePageViewController"
    
    // MARK: - Variables
    
    var isRosettaInstalled: Bool {
        return FileManager.default.fileExists(atPath: "/Library/Apple/usr/share/rosetta/rosetta")
    }

    // MARK: - Outlets

    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageBody: NSTextField!
    @IBOutlet weak var bottomRightButton: NSButton!
    @IBOutlet weak var centerImageView: NSImageView!
    var indicator: NSProgressIndicator!

    // MARK: - Instance methods
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupLayout()
        if Environment.current.isAppVersionCheckEnabled {
            self.checkAppVersion()
        }
    }
    
    // MARK: - Private methods
    
    /// Setup the layou of the page.
    private func setupLayout() {
        self.pageTitle.stringValue = "welcome_page_title".localized
        self.pageBody.stringValue = "welcome_page_body".localized
        self.centerImageView.image = NSImage(named: "mac")!
    }
    
    /// This method get the current app version and compare it with the supported one it gets from the backend
    /// in order to redirect the user to the download page if the running app is not supported anymore.
    private func checkAppVersion() {
        bottomRightButton.isHidden = true
        indicator = NSProgressIndicator(frame: bottomRightButton.frame)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.style = .spinning
        self.view.addSubview(indicator)
        indicator.topAnchor.constraint(equalTo: bottomRightButton.topAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: bottomRightButton.bottomAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: bottomRightButton.leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: bottomRightButton.trailingAnchor).isActive = true
        DispatchQueue.main.async {
            self.indicator.startAnimation(nil)
        }
        RestClient.shared.getRemoteVersionInfo { response in
            guard let supportedVersionString = response.properties.minAllowedBuildNr.first,
                    let supportedVersion = Int(supportedVersionString) else {
                self.handleError(.apiError(type: .noData))
                return
            }
            guard Environment.current.currentAppBuild >= supportedVersion else {
                self.handleError(.generic(type: .oldVersion))
                return
            }
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.bottomRightButton.isHidden = false
            }
        } errorHandler: { error in
            self.handleError(error)
        }
    }
    
    /// This method handle errors of type HelperError.
    /// - Parameter error: the error than needs to be handled.
    private func handleError(_ error: HelperError) {
        os_log(.error, "Error: %@", error.localizedDescription)
        func showAlert(for type: AlertType) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                var action: (NSApplication.ModalResponse) -> Void = { _ in }
                switch type {
                case .error:
                    alert.messageText = "old_app_warning_alert_title".localized
                    alert.informativeText = "old_app_warning_alert_informative_text".localized
                    alert.addButton(withTitle: "old_app_warning_alert_button".localized)
                    action = { _ in
                        NSWorkspace.shared.open(URL(string: Environment.current.versionCheckFailedRedirectURLString)!)
                        exit(0)
                    }
                case .warning:
                    alert.messageText = "failed_check_warning_alert_title".localized
                    alert.informativeText = "failed_check_warning_alert_informative_text".localized
                    alert.addButton(withTitle: "failed_check_warning_alert_button_check".localized)
                    alert.addButton(withTitle: "failed_check_warning_alert_button_continue".localized)
                    action = { response in
                        switch response {
                        case .alertFirstButtonReturn:
                            NSWorkspace.shared.open(URL(string: Environment.current.versionCheckFailedRedirectURLString)!)
                            exit(0)
                        default:
                            DispatchQueue.main.async {
                                self.indicator.isHidden = true
                                self.bottomRightButton.isHidden = false
                            }
                        }
 
                    }
                }
                alert.alertStyle = .warning
                alert.beginSheetModal(for: self.view.window!, completionHandler: action)
            }
        }
        switch error {
        case .apiError(_), .profileError(_):
            showAlert(for: .warning)
        case .generic(_):
            showAlert(for: .error)
        }
    }

    // MARK: - Actions
    
    /// This action is triggered by the bottom right button.
    /// It redirects the user to the Install Rosetta 2 page if detect that the app
    /// is running on an M1 device that doesn't already have it installed.
    /// - Parameter sender: NSButton.
    @IBAction func didPressBottomRightButton(_ sender: NSButton) {
        #if DEBUG
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("goToRosettaPage"), sender: nil)
        #else
        if #available(OSX 11.0, *) {
            if NSRunningApplication.current.executableArchitecture == NSBundleExecutableArchitectureARM64 {
                guard isRosettaInstalled || Environment.current.ignoreRosettaInstallation else {
                    self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("goToRosettaPage"), sender: nil)
                    return
                }
            }
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("jumpToSetupmymacPage"), sender: nil)
        } else {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("jumpToSetupmymacPage"), sender: nil)
        }
        #endif
    }
}
