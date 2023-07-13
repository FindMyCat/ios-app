//
//  CookieHandler.swift
//  Find My Cat
//
//  Created by Sahas Chitlange on 6/22/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

class CookieHandlerUtil {

    static let shared: CookieHandlerUtil = CookieHandlerUtil()

    let defaults = UserDefaults.standard
    let cookieStorage = HTTPCookieStorage.shared

    func getCookie(forURL url: String) -> [HTTPCookie] {
        let computedUrl = URL(string: url)
        let cookies = cookieStorage.cookies(for: computedUrl!) ?? []

        return cookies
    }

    func backupCookies(forURL url: String) {
        var cookieDict = [String: AnyObject]()

        for cookie in self.getCookie(forURL: url) {
            cookieDict[cookie.name] = cookie.properties as AnyObject?
        }

        defaults.set(cookieDict, forKey: "savedCookies")
    }

    func restoreCookies() {
        if let cookieDictionary = defaults.dictionary(forKey: "savedCookies") {

            for (_, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey: Any] ) {
                    cookieStorage.setCookie(cookie)
                }
            }
        }
    }
}
