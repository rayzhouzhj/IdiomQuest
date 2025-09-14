//
//  LearningView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import SwiftUI
import CoreData

struct LearningView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var dailyIdiom: NSManagedObject?
    @State private var isLearned: Bool = false
    @State private var showReview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let idiom = dailyIdiom {
                    VStack(spacing: 10) {
                        Text(idiom.value(forKey: "word") as? String ?? "No Word")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(idiom.value(forKey: "pinyin") as? String ?? "No Pinyin")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(idiom.value(forKey: "explanation") as? String ?? "No Explanation")
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        if let example = idiom.value(forKey: "example") as? String, !example.isEmpty {
                            Text("Example: \(example)")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.blue)
                        }
                        
                        if let derivation = idiom.value(forKey: "derivation") as? String, !derivation.isEmpty {
                            Text("Derivation: \(derivation)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    
                    Button(action: toggleLearned) {
                        Image(systemName: isLearned ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                            .foregroundColor(isLearned ? .green : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("Loading daily idiom...")
                }
                
                Button("Review Learned") {
                    showReview = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .navigationTitle("Daily Idiom")
            .onAppear(perform: loadDailyIdiom)
            .sheet(isPresented: $showReview) {
                ReviewView()
            }
        }
    }
    
    private func loadDailyIdiom() {
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
        request.fetchLimit = 1
        
        // Daily offset
        let totalCount = UserDefaults.standard.integer(forKey: "totalChengyuCount") // Set this once after loading
        let dayOffset = Calendar.current.component(.day, from: Date()) % totalCount
        request.fetchOffset = dayOffset
        
        do {
            dailyIdiom = try context.fetch(request).first
            if let word = dailyIdiom?.value(forKey: "word") as? String {
                isLearned = getLearnedStatus(for: word)
            }
        } catch {
            print("Failed to load daily idiom: \(error)")
        }
    }
    
    private func toggleLearned() {
        guard let word = dailyIdiom?.value(forKey: "word") as? String else { return }
        
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            if let userData = try context.fetch(userDataRequest).first {
                userData.setValue(!isLearned, forKey: "isLearned")
            } else {
                let userData = NSEntityDescription.insertNewObject(forEntityName: "UserData", into: context)
                userData.setValue(word, forKey: "word")
                userData.setValue(true, forKey: "isLearned")
            }
            CoreDataManager.shared.saveContext()
            isLearned.toggle()
        } catch {
            print("Failed to toggle learned: \(error)")
        }
    }
    
    private func getLearnedStatus(for word: String) -> Bool {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            if let userData = try context.fetch(userDataRequest).first {
                return userData.value(forKey: "isLearned") as? Bool ?? false
            }
        } catch {
            print("Failed to get learned status: \(error)")
        }
        return false
    }
}
