//
//  String+Extension.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import Foundation
import CoreFoundation

// MARK: - Localization Configuration
struct LocalizationConfig {
    static var autoLocalizeEnabled: Bool = true
    static var preferredVariant: ChineseVariant = .auto
    
    enum ChineseVariant {
        case auto
        case traditional
        case simplified
    }
}

extension String {
    func toTraditionalChinese() -> String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        let success = CFStringTransform(mutableString, nil, "Hans-Hant" as CFString, false)
        return success ? mutableString as String : self
    }
    
    func toSimplifiedChinese() -> String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        let success = CFStringTransform(mutableString, nil, "Hant-Hans" as CFString, false)
        return success ? mutableString as String : self
    }
    
    func toPreferredChinese() -> String {
        guard LocalizationConfig.autoLocalizeEnabled else { return self }
        
        switch LocalizationConfig.preferredVariant {
        case .traditional:
            return self.toTraditionalChinese()
        case .simplified:
            return self.toSimplifiedChinese()
        case .auto:
            let preferredLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
            let traditionalLocales = ["zh-Hant", "zh-TW", "zh-HK", "zh-MO", "yue-Hant-HK", "yue-Hant-MO"]
            if traditionalLocales.contains(where: preferredLanguage.contains) {
                return self.toTraditionalChinese()
            }
            return self
        }
    }
    
    /// Convenience property for automatic localization
    var localized: String {
        return self.toPreferredChinese()
    }
}
