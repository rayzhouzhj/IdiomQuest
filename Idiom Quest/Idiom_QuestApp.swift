//
//  Idiom_QuestApp.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//

import SwiftUI

@main
struct Idiom_QuestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
