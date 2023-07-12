//
//  LoginAndDownloadViewController.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 07/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//
//  swiftlint:disable line_length function_body_length

import Cocoa
import WebKit
import os.log

/// This class handle the login WebView page with the profile download.
class LoginAndDownloadViewController: NSViewController {

    // MARK: - Variables

    var environment = Environment.current
    var profile: ConfProfile!
    var profileLocation: URL!
    
    // MARK: - Outlets

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var forwardButton: NSButton!
    @IBOutlet weak var environmentLabel: NSTextField!

    // MARK: - Instance methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
    }

    override func viewWillAppear() {
        super.viewDidAppear()
        self.setupLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.webView.cleanAllCookies()
        self.webView.refreshCookies()
        self.webView.load(URLRequest(url: Environment.current.enrollmentURL))
    }
    
    /// Prepare the nex view providing some info.
    /// - Parameters:
    ///   - segue: segue to the next view.
    ///   - sender: any sender.
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let profileInstallationViewController = segue.destinationController as? ProfileInstallationViewController,
            let profile = self.profile {
            profileInstallationViewController.profile = profile
            profileInstallationViewController.profileLocation = profileLocation
        }
    }

    // MARK: - Private methods
    
    /// Setup the layou of the page.
    private func setupLayout() {
        self.backButton.isEnabled = false
        self.forwardButton.isEnabled = false
        // If the environment is not prod this make the environment label visible on the bottom right of the web view.
        guard environment == .prod else {
            self.environmentLabel.stringValue = environment.rawValue
            return
        }
    }

    /// This method copy the webview cookies and start the download request for the mobileconfig profile.
    /// - Parameter request: The URLRequest used for the download.
    private func startDownload(with request: URLRequest, completion: @escaping (Bool) -> Void, errorHandler: @escaping (HelperError) -> Void) {
        let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(environment.mobileconfigFileName)
        let urlSessionConf = URLSessionConfiguration.default
        var customRequest = request
        customRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
            urlSessionConf.httpCookieStorage = HTTPCookieStorage.shared
            urlSessionConf.httpCookieStorage?.setCookies(cookies, for: request.url, mainDocumentURL: nil)
            let urlSession = URLSession(configuration: urlSessionConf)
            urlSession.dataTask(with: request) { data, response, err in
                guard let data = data,
                      err == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let suggestedFileName = response?.suggestedFilename,
                      suggestedFileName == self.environment.mobileconfigFileName else {
                    completion(false)
                    return
                }
                os_log("Successufully downloaded profile")
                do {
                    let xml = try CMSDecoder.decoder(data).decrypt()
                    if let enrollmentProfile = try? PropertyListDecoder().decode(EnrollmentProfile.self, from: xml) {
                        self.profile = enrollmentProfile
                    } else if let enrollmentProfile = try? PropertyListDecoder().decode(NewEnrollmentProfile.self, from: xml) {
                        self.profile = enrollmentProfile
                    } else {
                        errorHandler(HelperError.profileError(type: .decoding(description: "Not able to decode configuration profile.")))
                        return
                    }
                    self.profileLocation = localFileURL
                } catch let error {
                    errorHandler(HelperError.profileError(type: .decoding(description: error.localizedDescription)))
                    return
                }
                let writeDataOperation = BlockOperation(block: {
                    do {
                        try data.write(to: localFileURL, options: .atomic)
                    } catch let error {
                        errorHandler(HelperError.profileError(type: .store(description: error.localizedDescription)))
                        return
                    }
                })
                writeDataOperation.completionBlock = {
                    os_log("Profile saved at %{public}@", localFileURL.absoluteString)
                }
                let openFileOperation = BlockOperation(block: {
                    self.open(localFileURL, completion: {
                        completion(true)
                    }, error: {
                        errorHandler(HelperError.profileError(type: .store(description: "Not able to open downloaded profile.")))
                    })
                })
                openFileOperation.addDependency(writeDataOperation)
                let queue = OperationQueue()
                queue.addOperations([writeDataOperation, openFileOperation], waitUntilFinished: true)
            }.resume()
        }
    }
    
    /// Open the given file url.
    /// - Parameters:
    ///   - file: the file url.
    ///   - counter: number of try.
    ///   - completion: completion callback.
    ///   - error: completion with error callback.
    private func open(_ file: URL, counter: Int = 0, completion: @escaping () -> Void, error: @escaping () -> Void) {
            guard NSWorkspace.shared.open(file) else {
                os_log("Failed to open %{public}@ trying again in 500 milliseconds (attempt n: %{public}@)", file.absoluteString, counter+1)
                guard counter < 10 else {
                    error()
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.open(file, counter: counter+1, completion: completion, error: error)
                }
                return
            }
            os_log("Successufully opened %{public}@", file.absoluteString)
            completion()
    }
    
    /// Handle the error of type HelperError
    /// - Parameter error: the error.
    private func handleError(_ error: HelperError) {
        os_log(.error, "Error: %@", error.localizedDescription)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "error_alert_title".localized
            alert.informativeText = "error_alert_informative_text".localized
            alert.addButton(withTitle: "error_alert_button".localized)
            alert.alertStyle = .warning
            alert.beginSheetModal(for: self.view.window!) { _ in
                self.performSegue(withIdentifier: "backToWelcomePage", sender: nil)
            }
        }
    }
    
    /// Check if the request made from the web view is the download of the profile.
    /// - Parameters:
    ///   - request: the request made by the web view
    ///   - decisionHandler: callback with decision to allow or not the request for the web view.
    private func checkRequest(_ request: URLRequest, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let httpBody = request.httpBody,
           let decodedString = String(data: httpBody, encoding: .utf8),
           decodedString.contains("installEnterpriseProfile.jsp") {
            startDownload(with: request, completion: { (success) in
                guard success else {
                    decisionHandler(.allow)
                    return
                }
                decisionHandler(.cancel)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToProfileInstallationPage", sender: nil)
                }
            }, errorHandler: { (error) in
                self.handleError(error)
                decisionHandler(.cancel)
            })
            return
        }
        decisionHandler(.allow)
    }
    
    /// LEGACY - Check if the request made from the web view is the download of the profile.
    /// - Parameters:
    ///   - request: the request made by the web view
    ///   - decisionHandler: callback with decision to allow or not the request for the web view.
    private func checkRequestLegacy(_ request: URLRequest, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = request.url,
           url.absoluteString == (self.environment.enrollmentURL.absoluteString + "/?"),
           request.httpMethod == "POST" {
            var adjustedRequest = request
            adjustedRequest.httpBody = "lastPage=installEnterpriseProfile.jsp&payload=enterprise&device-detect-complete=&invitation=&type=".data(using: .utf8)
            startDownload(with: adjustedRequest, completion: { (success) in
                guard success else {
                    decisionHandler(.allow)
                    return
                }
                decisionHandler(.cancel)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToProfileInstallationPage", sender: nil)
                }
            }, errorHandler: { (error) in
                self.handleError(error)
                decisionHandler(.cancel)
            })
            return
        }
        decisionHandler(.allow)
    }

    // MARK: - Actions
    
    /// Action triggered by the click on the bottom left button.
    /// - Parameter sender: NSButton.
    @IBAction func didPressBackButton(_ sender: NSButton) {
        self.webView.goBack()
    }

    /// Action triggered by the click on the bottom right button.
    /// - Parameter sender: NSButton.
    @IBAction func didPressForwardButton(_ sender: NSButton) {
        self.webView.goForward()
    }
}

// MARK: - WKNavigationDelegate methods

extension LoginAndDownloadViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
        if navigationAction.request.httpBody != nil {
            checkRequest(navigationAction.request, decisionHandler: decisionHandler)
        } else {
            checkRequestLegacy(navigationAction.request, decisionHandler: decisionHandler)
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let suggestedFileName = navigationResponse.response.suggestedFilename,
           suggestedFileName == self.environment.mobileconfigFileName {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
