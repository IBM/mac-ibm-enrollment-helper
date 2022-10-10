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
import AVKit

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
    @IBOutlet weak var centerImageViewTop: NSLayoutConstraint!
    @IBOutlet weak var centerImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomLine: NSBox!
    
    var profile: ConfProfile?
    var profileLocation: URL?
    private var request: AnyObject?
    private var jssTimer: Timer?
    private var retryTimer: Timer?
    private var timerExpired: Bool = false
    private var videoPlayerView: AVPlayerView!

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
    
    private func createLocalUrl(for filename: String, ofType: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(filename).\(ofType)")
        
        guard fileManager.fileExists(atPath: url.path) else {
            guard let video = NSDataAsset(name: filename)  else { return nil }
            fileManager.createFile(atPath: url.path, contents: video.data, attributes: nil)
            return url
        }
        
        return url
    }

    /// Setup the layou of the page.
    private func setupLayout() {
        self.retryButton.isHidden = true
        self.retryLabel.isHidden = true
        self.retryButton.title = "profile_installation_page_retry_button".localized
        self.activityIndicator.startAnimation(nil)
        let sampleVideoName: String = Utils.currentInterfaceStyle == .light ? "settings_sample_ventura_light" : "settings_sample_ventura_dark"
        if #available(OSX 13, *) {
            self.systemPreferencesButton.title = "profile_installation_page_button_ventura".localized
            self.pageBody.stringValue = "profile_installation_page_body_ventura".localized
            self.retryLabel.stringValue = "profile_installation_page_retry_label_ventura".localized
            self.centerImageView.isHidden = true
            guard let videoURL = createLocalUrl(for: sampleVideoName, ofType: "mov") else { return }
            self.videoPlayerView = AVPlayerView(frame: self.centerImageView.frame)
            let videoPlayer = AVPlayer(playerItem: AVPlayerItem(asset: AVAsset(url: videoURL)))
            self.videoPlayerView.player = videoPlayer
            self.videoPlayerView.controlsStyle = .none
            self.videoPlayerView.showsTimecodes = false
            self.videoPlayerView.showsFrameSteppingButtons = false
            self.videoPlayerView.showsSharingServiceButton = false
            self.videoPlayerView.showsFullScreenToggleButton = false
            self.view.addSubview(self.videoPlayerView)
            self.videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
            self.videoPlayerView.topAnchor.constraint(equalTo: self.pageBody.bottomAnchor, constant: 16).isActive = true
            self.videoPlayerView.bottomAnchor.constraint(equalTo: self.bottomLine.topAnchor, constant: -16).isActive = true
            self.videoPlayerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
            if let videoResolution = resolutionForVideo(at: videoURL) {
                let multiplier = videoResolution.width/videoResolution.height
                self.videoPlayerView.widthAnchor.constraint(equalTo: self.videoPlayerView.heightAnchor, multiplier: multiplier).isActive = true
            } else {
                self.videoPlayerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40).isActive = true
                self.videoPlayerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40).isActive = true
            }
            self.videoPlayerView.player?.playImmediately(atRate: 1.5)
            NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        } else {
            self.systemPreferencesButton.title = "profile_installation_page_button".localized
            self.pageBody.stringValue = "profile_installation_page_body".localized
            self.retryLabel.stringValue = "profile_installation_page_retry_label".localized
            self.centerImageView.image = NSImage(named: "settings_sample")!
        }
    }
    
    /// Get the resolution of the video.
    /// - Parameter url: url of the video.
    /// - Returns: the resolution of the video.
    private func resolutionForVideo(at url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    /// Replay the video in loop
    @objc
    private func itemDidFinishPlaying(_ notification: Notification) {
        self.videoPlayerView.player?.seek(to: .zero)
        self.videoPlayerView.player?.playImmediately(atRate: 1.5)
    }
    
    /// Check the profile installation using the invitation ID it got from the profile and Jamf APIs.
    private func checkForProfileInstallation() {
        // If in debug mode it goes directly to the next page.
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) {
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
            case .deviceIsManaged:
                break
            }
        case .generic(let type):
            switch type {
            case .timeout, .oldVersion:
                if #available(OSX 13, *) {
                    showAlert(with: "profile_installation_page_alert_informative_text_ventura".localized, type: .timeout)
                } else {
                    showAlert(with: "profile_installation_page_alert_informative_text".localized, type: .timeout)
                }
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
