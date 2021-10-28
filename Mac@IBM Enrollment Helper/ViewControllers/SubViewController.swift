//
//  SubViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable line_length

import Cocoa

/// Parent view controller for the main window of the application.
final class SubViewController: NSViewController {

    // MARK: - Instance methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    // MARK: - Private methods

    /// Define and present the target VC.
    private func setupLayout() {
        let mainStoryboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        guard let sourceViewController = mainStoryboard.instantiateController(withIdentifier: WelcomePageViewController.storyboardID) as? NSViewController else {
            return
        }
        self.insertChild(sourceViewController, at: 0)
        self.view.addSubview(sourceViewController.view)
        self.view.frame = sourceViewController.view.frame
    }
}
