//
//  Idiom_QuestApp.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

// Shared state for app-wide game control
class AppState: ObservableObject {
    @Published var isGameInProgress = false
    @Published var shouldPauseGame = false
}

@main
struct IdiomQuestApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let coreDataManager = CoreDataManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var languageSettings = LanguageSettings.shared
    @State private var selectedTab = 0 // Tabs: 0: Learning, 1: Game, 2: Review, 3: Settings
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                LearningView()
                    .tabItem {
                        Label(languageSettings.isTraditionalChinese ? "學習" : "学习", systemImage: "book.closed")
                    }
                    .tag(0)
                
                GameView()
                    .tabItem {
                        Label(languageSettings.isTraditionalChinese ? "遊戲" : "游戏" , systemImage: "gamecontroller")
                    }
                    .tag(1)
                
                ReviewView()
                    .tabItem {
                        Label(languageSettings.isTraditionalChinese ? "複習" : "复习", systemImage: "checkmark.circle")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label(languageSettings.isTraditionalChinese ?  "設定" : "设置", systemImage: "gear")
                    }
                    .tag(3)
            }
            .environmentObject(appState)
            .environmentObject(languageSettings)
            .onChange(of: selectedTab) { newTab in
                // Pause game when switching away from game tab
                if appState.isGameInProgress && newTab != 1 {
                    appState.shouldPauseGame = true
                } else if newTab == 1 {
                    appState.shouldPauseGame = false
                }
            }
        }
    }
}
