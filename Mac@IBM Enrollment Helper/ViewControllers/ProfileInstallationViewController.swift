//
//  ProfileInstallationViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable line_length function_body_length

import Cocoa
import os.log

final class ProfileInstallationViewController: NSViewController {

    // MARK: - Enums

    enum AlertType {
        case error
        case warning
        case timeout
    }

    // MARK: - Outlets

    @IBOutlet weak var pageBody: NSTextField!
    @IBOutlet weak var systemPreferencesButton: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var centerImageView: NSImageView!
    @IBOutlet weak var retryButton: NSButton!
    @IBOutlet weak var retryLabel: NSTextField!
    
    var profile: ConfProfile?
    var profileLocation: URL?
    private var request: AnyObject?
    private var jssTimer: Timer?
    private var retryTimer: Timer?
    private var timerExpired: Bool = false

    // MARK: - Instance methods

    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupLayout()
        self.checkForProfileInstallation()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Set the timer to trigger a reminder pop-up for the user to install the profile.
        self.jssTimer = Timer.scheduledTimer(withTimeInterval: Environment.current.defaultCheckProfileTimeInterval,
                                             repeats: false,
                                             block: { [weak self] _ in
                                                self?.timerExpired = true
                                             })
        // Set a timer to show a label and a button on the bottom of the view to help the user to
        // trigger again the profile installation if not present in the system preferences.
        self.retryTimer = Timer.scheduledTimer(withTimeInterval: 10,
                                               repeats: false,
                                               block: { [weak self] _ in
                                                DispatchQueue.main.async {
                                                    self?.retryButton.isHidden = false
                                                    self?.retryLabel.isHidden = false
                                                }
                                               })
    }

    // MARK: - Private methods

    /// Setup the layou of the page.
    private func setupLayout() {
        self.pageBody.stringValue = "profile_installation_page_body".localized
        self.systemPreferencesButton.title = "profile_installation_page_button".localized
        self.retryButton.isHidden = true
        self.retryLabel.isHidden = true
        self.retryLabel.stringValue = "profile_installation_page_retry_label".localized
        self.retryButton.title = "profile_installation_page_retry_button".localized
        self.activityIndicator.startAnimation(nil)
        self.centerImageView.image = NSImage(named: "settings_sample")!
    }
    
    /// Check the profile installation using the invitation ID it got from the profile and Jamf APIs.
    private func checkForProfileInstallation() {
        // If in debug mode it goes directly to the next page.
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.performSegue(withIdentifier: "goToWaitingPage", sender: nil)
        }
        #else
        guard let profile = self.profile else {
            return
        }
        let invitationId = profile.challenge
        RestClient.shared.checkComputerInvitation(invitationId) { response in
            let status = response.computerInvitation.invitationStatus
            guard status == "ENROLLMENT_COMPLETE" else {
                guard !self.timerExpired else {
                    self.handleError(.generic(type: .timeout))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
                    self?.checkForProfileInstallation()
                }
                return
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToWaitingPage", sender: nil)
            }
        } errorHandler: { error in
            self.handleError(error)
        }
        #endif
    }
    
    /// Handle the error of type HelperError
    /// - Parameter error: the error.
    private func handleError(_ error: HelperError) {
        os_log(.error, "Error: %@", error.localizedDescription)
        func showAlert(with message: String, type: AlertType) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                var action: (NSApplication.ModalResponse) -> Void = { _ in }
                switch type {
                case .error:
                    alert.messageText = "error_alert_title".localized
                    alert.addButton(withTitle: "error_alert_button".localized)
                    action = { _ in
                        self.performSegue(withIdentifier: "backToWelcomePage", sender: nil)
                    }
                case .warning:
                    alert.messageText = "warning_alert_title".localized
                    alert.addButton(withTitle: "warning_alert_button".localized)
                    action = { _ in
                        self.checkForProfileInstallation()
                    }
                case .timeout:
                    self.timerExpired = false
                    alert.messageText = "profile_installation_page_alert_title".localized
                    alert.addButton(withTitle: "profile_installation_page_alert_button".localized)
                    action = { _ in
                        self.checkForProfileInstallation()
                        self.jssTimer = Timer.scheduledTimer(withTimeInterval: Environment.current.defaultCheckProfileTimeInterval,
                                                             repeats: false,
                                                             block: { [weak self] _ in
                            self?.timerExpired = true
                        })
                    }
                }
                alert.informativeText = message
                alert.alertStyle = .warning
                alert.beginSheetModal(for: self.view.window!, completionHandler: action)
            }
        }
        switch error {
        case .apiError(let type):
            switch type {
            case .badResponse:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            case .decoding:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            case .networkError:
                showAlert(with: "warning_alert_informative_text".localized, type: .warning)
            case .noData:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            case .noResponse:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            }
        case .profileError(let type):
            switch type {
            case .decoding:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            case .store:
                showAlert(with: "error_alert_informative_text".localized, type: .error)
            }
        case .generic(let type):
            switch type {
            case .timeout, .oldVersion:
                showAlert(with: "profile_installation_page_alert_informative_text".localized, type: .timeout)
            }
        }
    }
    
    /// If needed start over the process from the welcome page.
    private func startOver() {
        self.performSegue(withIdentifier: "backToWelcomePage", sender: nil)
    }
    
    /// Trigger the profile installation.
    private func openProfile() {
        guard let file = profileLocation, NSWorkspace.shared.open(file) else {
            self.handleError(HelperError.profileError(type: .store(description: "Unable to find the configration profile.")))
            return
        }
    }

    // MARK: - Actions
    
    /// Action triggered by the click on the "Open System Preferences" button.
    /// - Parameter sender: NSButton.
    @IBAction func didPressSystemPreferenceButton(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preferences.configurationprofiles")!)
    }
    
    /// Action triggered by the click on the "Retry" button that appears after the give timeout.
    /// - Parameter sender: NSButton.
    @IBAction func didPressRetryButton(_ sender: NSButton) {
        guard retryButton.title == "profile_installation_page_retry_button".localized else {
            startOver()
            return
        }
        let animationView = NSProgressIndicator()
        animationView.style = .spinning
        animationView.controlSize = .small
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerYAnchor.constraint(equalTo: retryLabel.centerYAnchor).isActive = true
        animationView.leadingAnchor.constraint(equalTo: retryLabel.trailingAnchor, constant: 12).isActive = true
        animationView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40).isActive = true
        animationView.startAnimation(nil)
        retryButton.isHidden = true
        openProfile()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
            animationView.isHidden = true
            self?.retryButton.isHidden = false
            self?.retryLabel.stringValue = "profile_installation_page_restart_label".localized
            self?.retryButton.title = "profile_installation_page_restart_button".localized
        })
    }
}
