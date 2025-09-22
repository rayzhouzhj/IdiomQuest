//
//  LanguageSettings.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 22/9/2025.
//

import Foundation

enum PreferredLanguage: String, CaseIterable {
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .traditionalChinese:
            return "繁體中文"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()
    
    @Published var preferredLanguage: PreferredLanguage {
        didSet {
            UserDefaults.standard.set(preferredLanguage.rawValue, forKey: "preferredLanguage")
            print("Language preference changed to: \(preferredLanguage.displayName)")
        }
    }
    
    init() {
        // Load saved preference or default to Traditional Chinese
        let savedLanguage = UserDefaults.standard.string(forKey: "preferredLanguage") ?? PreferredLanguage.traditionalChinese.rawValue
        self.preferredLanguage = PreferredLanguage(rawValue: savedLanguage) ?? .traditionalChinese
    }
    
    var isTraditionalChinese: Bool {
        return preferredLanguage == .traditionalChinese
    }
    
    var isSimplifiedChinese: Bool {
        return preferredLanguage == .simplifiedChinese
    }
}
