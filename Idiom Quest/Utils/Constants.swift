//
//  Constants.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import Foundation

struct AppConstants {
    // App Information
    static let appVersion = "1.0.0"
    static let idiomCount = "30,000+"
    
    // UserDefaults Keys
    struct UserDefaults {
        static let preferredLanguage = "preferredLanguage"
        static let dailyIdiomPrefix = "dailyIdiom_"
    }
    
    // Core Data
    struct CoreData {
        static let modelName = "Idiom_Quest"
        static let entityChengyu = "Chengyu"
        static let entityUserData = "UserData"
    }
    
    // Language Settings
    struct Language {
        static let traditionalChineseName = "繁體中文"
        static let simplifiedChineseName = "简体中文"
        static let traditionalChineseCode = "zh-Hant"
        static let simplifiedChineseCode = "zh-Hans"
    }
}

