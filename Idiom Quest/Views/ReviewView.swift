//
//  ReviewView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import SwiftUI
import CoreData

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var learnedIdioms: [NSManagedObject] = []
    
    var body: some View {
        NavigationView {
            List(learnedIdioms, id: \.self) { idiom in
                VStack(alignment: .leading, spacing: 5) {
                    Text((idiom.value(forKey: "word") as? String ?? "No Word").toPreferredChinese())
                        .font(.headline)
                    
                    Text(idiom.value(forKey: "pinyin") as? String ?? "No Pinyin")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text((idiom.value(forKey: "explanation") as? String ?? "No Explanation").toPreferredChinese())
                        .font(.body)
                }
            }
            .navigationTitle("Learned Idioms")
            .onAppear(perform: loadLearnedIdioms)
        }
    }
    
    private func loadLearnedIdioms() {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "isLearned == %@", NSNumber(value: true))
        
        do {
            let userData = try context.fetch(userDataRequest)
            learnedIdioms = userData.compactMap { ud in
                let word = ud.value(forKey: "word") as? String ?? ""
                let chengyuRequest = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
                chengyuRequest.predicate = NSPredicate(format: "word == %@", word)
                return try? context.fetch(chengyuRequest).first
            }
        } catch {
            print("Failed to load learned idioms: \(error)")
        }
    }
}
