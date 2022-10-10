//
//  RosettaViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable line_length

import Cocoa

/// This class handle the Rosetta 2 installation page.
final class RosettaViewController: NSViewController {

    // MARK: - Static constants

    static private let appleLegalURL: String = "https://www.apple.com/legal/sla/"
    static private let softwareupdateBaseURL: String = "/usr/sbin/softwareupdate"
    static private let rosettaInstallationArguments: [String] = ["--install-rosetta", "--agree-to-license"]

    // MARK: - Outlets

    @IBOutlet weak var pageTitle: NSTextField!
    @IBOutlet weak var pageBody: NSTextField!
    @IBOutlet weak var rosettaDisclaimer: NSTextView!
    @IBOutlet weak var installRosettaButton: NSButton!
    @IBOutlet weak var bottomRightButton: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var centerImageView: NSImageView!

    // MARK: - Variables

    var disclaimerAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor: NSColor.labelColor,
                NSAttributedString.Key.paragraphStyle: paragraph]
    }
    var disclaimerButtonAttributes: [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor: NSColor.blue,
                NSAttributedString.Key.link: Self.appleLegalURL]
    }

    // MARK: - Instance methods

    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupLayout()
    }

    // MARK: - Private methods
    
    /// Setup the layou of the page.
    private func setupLayout() {
        self.centerImageView.image = NSImage(named: "rosetta_icon")!
        self.pageTitle.stringValue = "rosetta_page_title".localized
        self.pageBody.stringValue = "rosetta_page_body".localized
        let termsButtonAttributedString = NSMutableAttributedString(string: "rosetta_page_terms_disclaimer_button".localized)
        termsButtonAttributedString.addAttributes(disclaimerButtonAttributes,
                                       range: NSRange(location: 0,
                                                      length: termsButtonAttributedString.string.utf16.count))
        let termsAttributedString = NSMutableAttributedString(string: "rosetta_page_terms_disclaimer_body".localized, attributes: disclaimerAttributes)
        termsAttributedString.append(termsButtonAttributedString)
        self.rosettaDisclaimer.textStorage?.setAttributedString(termsAttributedString)
        self.rosettaDisclaimer.isSelectable = true
        self.rosettaDisclaimer.isEditable = false
        self.rosettaDisclaimer.drawsBackground = false
        self.installRosettaButton.title = "rosetta_page_install_button".localized
        self.bottomRightButton.isHidden = true
        self.activityIndicator.startAnimation(nil)
        self.activityIndicator.isHidden = true
    }

    /// This method trigger a shell command that will install Rosetta 2
    /// - Parameter completion: 0 if the installation was succeed, 1 if not.
    private func installRosetta(_ completion: (Int32) -> Void) {
        // When in debug mode it only mock the Rosetta 2 installation.
        #if DEBUG
        completion(0)
        #else
        let task = Process()
        task.launchPath = Self.softwareupdateBaseURL
        task.arguments = Self.rosettaInstallationArguments
        task.launch()
        task.waitUntilExit()
        completion(task.terminationStatus)
        #endif
    }

    // MARK: - Actions
    
    /// Action triggered by the "Install Rosetta 2" button.
    /// - Parameter sender: NSButton.
    @IBAction func didPressInstallRosettaButton(_ sender: NSButton) {
        self.installRosettaButton.isEnabled = false
        self.activityIndicator.isHidden = false
        self.rosettaDisclaimer.textStorage?.setAttributedString(NSAttributedString(string: "rosetta_page_install_status_progress".localized, attributes: disclaimerAttributes))
        self.installRosetta { (result) in
            switch result {
            case 0:
                self.rosettaDisclaimer.textStorage?.setAttributedString(NSAttributedString(string: "rosetta_page_install_status_success".localized, attributes: self.disclaimerAttributes))
                self.installRosettaButton.isEnabled = false
                self.activityIndicator.isHidden = true
                self.bottomRightButton.isHidden = false
            default:
                self.rosettaDisclaimer.textStorage?.setAttributedString(NSAttributedString(string: "rosetta_page_install_status_fail".localized, attributes: self.disclaimerAttributes))
                self.installRosettaButton.isEnabled = true
                self.activityIndicator.isHidden = true
            }
        }
    }
    
    /// Action triggered by the click on the bottom right button.
    /// - Parameter sender: NSButton.
    @IBAction func didPressBottomRightButton(_ sender: NSButton) {
        self.activityIndicator.stopAnimation(nil)
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("goToSetupmymacPage"), sender: nil)
    }
}
