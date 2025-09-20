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
    @State private var showSearch = false
    @State private var reviewWords: [NSManagedObject] = []
    @State private var animateCard = false
    @State private var showConfetti = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header with gradient
                    headerSection
                    
                    // Daily idiom card
                    dailyIdiomCard
                    
                    // Action buttons
                    actionButtons
                    
                    // Daily review section
                    dailyReviewSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onAppear {
                loadDailyIdiom()
                loadReviewWords()
                debugUserData() // Add debugging
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateCard = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data when app comes to foreground
                loadDailyIdiom()
                loadReviewWords()
            }
            .sheet(isPresented: $showReview) {
                ReviewView()
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                LocalizedText("每日一詞".toPreferredChinese())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                Button(action: { showSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            LocalizedText("學習新成語，豐富你的詞彙！".toPreferredChinese())
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 50)
    }
    
    private var dailyIdiomCard: some View {
        VStack {
            if let idiom = dailyIdiom, let todaysWord = idiom.value(forKey: "word") as? String {
                VStack(spacing: 20) {
                    // Word and pinyin
                    VStack(spacing: 8) {
                        LocalizedText(todaysWord)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.primary, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(idiom.value(forKey: "pinyin") as? String ?? "")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            LocalizedText((idiom.value(forKey: "explanation") as? String ?? ""))
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        } icon: {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        if let example = idiom.value(forKey: "example") as? String, !example.isEmpty {
                            Label {
                                LocalizedText(example.replacingOccurrences(of: "～", with: todaysWord))
                                    .font(.subheadline)
                                    .italic()
                            } icon: {
                                Image(systemName: "quote.bubble.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if let derivation = idiom.value(forKey: "derivation") as? String, !derivation.isEmpty {
                            Label {
                                LocalizedText(derivation)
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Learn button
                    Button(action: {
                        withAnimation(.spring()) {
                            toggleLearned()
                            if isLearned {
                                showConfetti = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showConfetti = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: isLearned ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.title2)
                            
                            LocalizedText(isLearned ? "已學會" : "標記為已學會")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: isLearned ? [.green, .mint] : [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .scaleEffect(animateCard ? 1.0 : 0.8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(25)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .scaleEffect(animateCard ? 1.0 : 0.9)
                .opacity(animateCard ? 1.0 : 0.8)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text(LocalizationKeys.Learning.loadingDailyIdiom)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .overlay(
            showConfetti ? ConfettiView(sourcePosition: nil) : nil
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("復習已學成語".toPreferredChinese()) {
                showReview = true
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .pink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
    
    private var dailyReviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "clock.badge.checkmark.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                LocalizedText("今日複習".toPreferredChinese())
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !reviewWords.isEmpty {
                    LocalizedText("\(reviewWords.count) 個成語")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if reviewWords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    LocalizedText("太棒了！今天沒有需要複習的成語")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    LocalizedText("繼續學習新的成語吧！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(reviewWords.prefix(6), id: \.objectID) { word in
                        reviewWordCard(word: word)
                    }
                }
                
                if reviewWords.count > 6 {
                    Button("查看更多 (\(reviewWords.count - 6))") {
                        showReview = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
    
    private func reviewWordCard(word: NSManagedObject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text((word.value(forKey: "word") as? String ?? "").toPreferredChinese())
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(word.value(forKey: "pinyin") as? String ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                LocalizedText("待複習")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            // Handle review word tap - could navigate to detailed view
        }
    }
    
    
    private func loadDailyIdiom() {
        let context = CoreDataManager.shared.context
        
        // Refresh the context to ensure we have the latest data
        context.refreshAllObjects()
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
        request.fetchLimit = 1
        
        do {
            let totalCount = try context.count(for: request)
            if totalCount > 0 {
                // Use consistent day-based offset (your original approach, fixed)
                let dayOffset = Calendar.current.component(.day, from: Date()) % totalCount
                request.fetchOffset = dayOffset
                
                dailyIdiom = try context.fetch(request).first
            }
            
            // Update learned status
            if let word = dailyIdiom?.value(forKey: "word") as? String {
                isLearned = getLearnedStatus(for: word)
                print("Daily idiom '\(word)' loaded with learned status: \(isLearned)")
            }
        } catch {
            print("Failed to load daily idiom: \(error)")
        }
    }
    
    private func loadReviewWords() {
        let context = CoreDataManager.shared.context
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch UserData entries that are learned and due for review
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "isLearned == %@ AND (nextReviewDate == nil OR nextReviewDate <= %@)", 
                                               NSNumber(value: true), today as NSDate)
        
        do {
            let userDataResults = try context.fetch(userDataRequest)
            let words = userDataResults.compactMap { $0.value(forKey: "word") as? String }
            
            if !words.isEmpty {
                // Fetch corresponding Chengyu entities
                let chengyuRequest = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
                chengyuRequest.predicate = NSPredicate(format: "word IN %@", words)
                chengyuRequest.fetchLimit = 10 // Limit to 10 words for daily review
                
                reviewWords = try context.fetch(chengyuRequest)
            } else {
                reviewWords = []
            }
        } catch {
            print("Failed to load review words: \(error)")
            reviewWords = []
        }
    }
    
    private func getReviewInterval(for reviewCount: Int) -> TimeInterval {
        // Spaced repetition intervals (in days)
        let intervals: [TimeInterval] = [1, 3, 7, 14, 30, 90] // days
        let dayIndex = min(reviewCount, intervals.count - 1)
        return intervals[dayIndex] * 24 * 60 * 60 // convert to seconds
    }

    private func getLearnedWords() -> [String] {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "isLearned == %@", NSNumber(value: true))
        
        do {
            let results = try context.fetch(userDataRequest)
            return results.compactMap { $0.value(forKey: "word") as? String }
        } catch {
            print("Failed to get learned words: \(error)")
            return []
        }
    }

    private func toggleLearned() {
        guard let word = dailyIdiom?.value(forKey: "word") as? String else { return }
        
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            let now = Date()
            
            if let userData = try context.fetch(userDataRequest).first {
                let wasLearned = userData.value(forKey: "isLearned") as? Bool ?? false
                userData.setValue(!wasLearned, forKey: "isLearned")
                print("Toggling learned status for '\(word)': \(wasLearned) -> \(!wasLearned)")
                
                if !wasLearned {
                    // First time learning - set initial review date
                    userData.setValue(now, forKey: "lastReviewDate")
                    let reviewCount = userData.value(forKey: "reviewCount") as? Int32 ?? 0
                    let nextReviewInterval = getReviewInterval(for: Int(reviewCount))
                    userData.setValue(now.addingTimeInterval(nextReviewInterval), forKey: "nextReviewDate")
                    userData.setValue(reviewCount + 1, forKey: "reviewCount")
                    print("Set initial review data for '\(word)'")
                } else {
                    // Unlearning - reset review data
                    userData.setValue(nil, forKey: "lastReviewDate")
                    userData.setValue(nil, forKey: "nextReviewDate")
                    userData.setValue(0, forKey: "reviewCount")
                    print("Reset review data for '\(word)'")
                }
            } else {
                // Create new UserData entry
                let userData = NSEntityDescription.insertNewObject(forEntityName: "UserData", into: context)
                userData.setValue(word, forKey: "word")
                userData.setValue(true, forKey: "isLearned")
                userData.setValue(now, forKey: "lastReviewDate")
                userData.setValue(now.addingTimeInterval(getReviewInterval(for: 0)), forKey: "nextReviewDate")
                userData.setValue(1, forKey: "reviewCount")
                print("Created new UserData entry for '\(word)' with learned=true")
            }
            
            CoreDataManager.shared.saveContext()
            print("Core Data context saved for word: '\(word)'")
            
            // Verify the save worked
            let verifyRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
            verifyRequest.predicate = NSPredicate(format: "word == %@", word)
            if let verifyData = try context.fetch(verifyRequest).first {
                let savedStatus = verifyData.value(forKey: "isLearned") as? Bool ?? false
                print("Verified saved status for '\(word)': \(savedStatus)")
            }
            
            isLearned.toggle()
            loadReviewWords() // Refresh review words
        } catch {
            print("Failed to toggle learned: \(error)")
        }
    }
    
    private func getLearnedStatus(for word: String) -> Bool {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            let results = try context.fetch(userDataRequest)
            print("Found \(results.count) UserData entries for word: \(word)")
            
            if let userData = results.first {
                let learned = userData.value(forKey: "isLearned") as? Bool ?? false
                print("Word '\(word)' learned status: \(learned)")
                return learned
            } else {
                print("No UserData found for word: \(word)")
            }
        } catch {
            print("Failed to get learned status for word '\(word)': \(error)")
        }
        return false
    }
    
    private func debugUserData() {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        
        do {
            let allUserData = try context.fetch(userDataRequest)
            print("=== DEBUG: Total UserData entries: \(allUserData.count) ===")
            
            for userData in allUserData {
                let word = userData.value(forKey: "word") as? String ?? "Unknown"
                let learned = userData.value(forKey: "isLearned") as? Bool ?? false
                print("UserData: '\(word)' - learned: \(learned)")
            }
            
            // Check if any entries are marked as learned
            let learnedRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
            learnedRequest.predicate = NSPredicate(format: "isLearned == %@", NSNumber(value: true))
            let learnedEntries = try context.fetch(learnedRequest)
            print("=== Learned entries count: \(learnedEntries.count) ===")
            
        } catch {
            print("Failed to debug UserData: \(error)")
        }
    }
}
