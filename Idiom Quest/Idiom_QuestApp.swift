//
//  Idiom_QuestApp.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//

import SwiftUI

@main
struct IdiomQuestApp: App {
    let coreDataManager = CoreDataManager.shared
    
    init() {
        coreDataManager.initializeUserData()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                LearningView()
                    .tabItem {
                        Label("Learning", systemImage: "book.closed")
                    }
                
                GameView()
                    .tabItem {
                        Label("Game", systemImage: "gamecontroller")
                    }
                
                ReviewView()
                    .tabItem {
                        Label("Review", systemImage: "checkmark.circle")
                    }
            }
        }
    }
}
