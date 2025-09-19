//
//  Idiom_QuestApp.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//

import SwiftUI

// Shared state for app-wide game control
class AppState: ObservableObject {
    @Published var isGameInProgress = false
    @Published var shouldPauseGame = false
}

@main
struct IdiomQuestApp: App {
    let coreDataManager = CoreDataManager.shared
    @StateObject private var appState = AppState()
    @State private var selectedTab = 1 // Game tab (0: Learning, 1: Game, 2: Review)
    
    init() {
        coreDataManager.initializeUserData()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                LearningView()
                    .tabItem {
                        Label("Learning", systemImage: "book.closed")
                    }
                    .tag(0)
                
                GameView()
                    .tabItem {
                        Label("Game", systemImage: "gamecontroller")
                    }
                    .tag(1)
                
                ReviewView()
                    .tabItem {
                        Label("Review", systemImage: "checkmark.circle")
                    }
                    .tag(2)
            }
            .environmentObject(appState)
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
