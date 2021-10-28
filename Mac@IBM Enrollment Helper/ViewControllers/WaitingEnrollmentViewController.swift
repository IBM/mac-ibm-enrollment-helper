//
//  WaitingEnrollmentViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa

/// This class handle the "Waiting for initialized enrollment" page.
final class WaitingEnrollmentViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageBody: NSTextField!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    // MARK: - Variables
    
    var timer: Timer?

    // MARK: - Instance methods

    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.setupTimer()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.timer?.invalidate()
        self.timer = nil
    }

    // MARK: - Private methods

    /// Setup the layou of the page.
    private func setupLayout() {
        self.activityIndicator.startAnimation(nil)
        self.pageTitle.stringValue = "waiting_page_title".localized
        self.pageBody.stringValue = "waiting_page_body".localized
    }
    
    /// Set the timer using the "defaultCheckEnrollmentStartedTimeInterval" defined in the Configuration struct.
    private func setupTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: Environment.current.defaultCheckEnrollmentStartedTimeInterval,
                                                repeats: false,
                                                block: { [weak self] _ in
                                                    self?.timeout()
                                                })
    }
    
    /// On timeout check if jamf binary and jss connection are in place.
    private func timeout() {
        self.timer = nil
        checkJSSConnection({ [weak self] result in
            switch result {
            case 0:
                guard FileManager.default.fileExists(atPath: Environment.current.appstorePath) else {
                    DispatchQueue.main.async {
                        self?.showErrorPopup()
                    }
                    return
                }
                guard let appStoreURL = URL(string: Environment.current.appstoreURL) else {
                    exit(1)
                }
                NSWorkspace.shared.open(appStoreURL)
                exit(0)
            default:
                DispatchQueue.main.async {
                    self?.showErrorPopup()
                }
            }
        })
    }
    
    /// Shows a pop-up with an error and close the app.
    private func showErrorPopup() {
        let alert = NSAlert()
        alert.messageText = "waiting_page_alert_message".localized
        alert.informativeText = "waiting_page_alert_informative_text".localized
        alert.addButton(withTitle: "waiting_page_alert_button".localized)
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) { _ in
            exit(0)
        }
    }
    
    /// Check if the jamf binary is present and the connection to the jss.
    /// - Parameter completion: cli exit code.
    private func checkJSSConnection(_ completion: (Int32) -> Void) {
        let task = Process()
        task.launchPath = Constants.jamfPath
        task.arguments = [Constants.jssConnectionCheckArgument]
        task.launch()
        task.waitUntilExit()
        completion(task.terminationStatus)
    }
}
