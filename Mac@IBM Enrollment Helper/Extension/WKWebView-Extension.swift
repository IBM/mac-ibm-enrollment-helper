//
//  WKWebView-Extension.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Simone Martorelli on 13/05/2021.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import WebKit

extension WKWebView {
    /// Clean up webview cookies
    func cleanAllCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    func refreshCookies() {
        self.configuration.processPool = WKProcessPool()
    }
}
