//
//  Locale+Extension.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//
import Foundation

extension Locale {
    static var isTraditionalChinese: Bool {
        guard let preferredLanguage = preferredLanguages.first else { return false }
        return preferredLanguage.hasPrefix("zh-Hant")
    }
}
