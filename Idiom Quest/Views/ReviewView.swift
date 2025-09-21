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
    @Environment(\.dismiss) private var dismiss
    @State private var learnedIdioms: [NSManagedObject] = []
    @State private var searchText = ""
    @State private var selectedCategory: ReviewCategory = .all
    @State private var animateCards = false
    
    enum ReviewCategory: String, CaseIterable {
        case all = "全部"
        case recent = "最近學習"
        case needsReview = "需要複習"
        
        var icon: String {
            switch self {
            case .all: return "book.fill"
            case .recent: return "clock.fill"
            case .needsReview: return "arrow.clockwise"
            }
        }
    }
    
    var filteredIdioms: [NSManagedObject] {
        var filtered = learnedIdioms
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { idiom in
                let word = (idiom.value(forKey: "word") as? String ?? "")
                let pinyin = idiom.value(forKey: "pinyin") as? String ?? ""
                let explanation = (idiom.value(forKey: "explanation") as? String ?? "")
                
                return word.localizedCaseInsensitiveContains(searchText) ||
                       pinyin.localizedCaseInsensitiveContains(searchText) ||
                       explanation.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedCategory {
        case .all:
            break
        case .recent:
            // Show idioms learned in the last 7 days
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filtered = filtered.filter { idiom in
                guard let word = idiom.value(forKey: "word") as? String else { return false }
                return getLastReviewDate(for: word) ?? Date.distantPast > sevenDaysAgo
            }
        case .needsReview:
            // Show idioms that need review
            filtered = filtered.filter { idiom in
                guard let word = idiom.value(forKey: "word") as? String else { return false }
                return isWordDueForReview(word: word)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Category filter
                categoryFilter
                
                // Search bar
                searchBar
                
                // Content
                if filteredIdioms.isEmpty {
                    emptyStateView
                } else {
                    idiomsList
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onAppear {
                loadLearnedIdioms()
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateCards = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    LocalizedText("已學成語")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    LocalizedText("\(learnedIdioms.count) 個成語")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: loadLearnedIdioms) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(animateCards ? 360 : 0))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReviewCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            
                            LocalizedText(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category ?
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.2), .gray.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(20)
                        .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜尋成語或拼音...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedCategory == .all ? "book.closed" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                LocalizedText(getEmptyStateTitle())
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                LocalizedText(getEmptyStateSubtitle())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var idiomsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(filteredIdioms.enumerated()), id: \.element) { index, idiom in
                    idiomCard(idiom: idiom)
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: animateCards)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func idiomCard(idiom: NSManagedObject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText((idiom.value(forKey: "word") as? String ?? ""))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.primary, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    LocalizedText(idiom.value(forKey: "pinyin") as? String ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    let word = idiom.value(forKey: "word") as? String ?? ""
                    
                    if isWordDueForReview(word: word) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        LocalizedText("待複習")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        LocalizedText("已掌握")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Explanation
            LocalizedText((idiom.value(forKey: "explanation") as? String ?? ""))
                .font(.body)
                .lineLimit(3)
            
            // Additional info
            if let example = idiom.value(forKey: "example") as? String, !example.isEmpty {
                Label {
                    LocalizedText(example)
                        .font(.caption)
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            // Review info
            let word = idiom.value(forKey: "word") as? String ?? ""
            if let lastReview = getLastReviewDate(for: word) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    LocalizedText("上次複習: \(formatDate(lastReview))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    let reviewCount = getReviewCount(for: word)
                    LocalizedText("複習 \(reviewCount) 次")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            // Could add detailed view navigation here
        }
    }
    
    
    private func getEmptyStateTitle() -> String {
        switch selectedCategory {
        case .all:
            return searchText.isEmpty ? "還沒有學習任何成語" : "找不到匹配的成語"
        case .recent:
            return "最近沒有學習新成語"
        case .needsReview:
            return "沒有需要複習的成語"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedCategory {
        case .all:
            return searchText.isEmpty ? "開始學習你的第一個成語吧！" : "嘗試其他搜尋關鍵字"
        case .recent:
            return "過去7天內沒有學習記錄"
        case .needsReview:
            return "所有成語都已經掌握得很好！"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func getLastReviewDate(for word: String) -> Date? {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            if let userData = try context.fetch(userDataRequest).first {
                return userData.value(forKey: "lastReviewDate") as? Date
            }
        } catch {
            print("Failed to get last review date: \(error)")
        }
        return nil
    }
    
    private func getReviewCount(for word: String) -> Int {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            if let userData = try context.fetch(userDataRequest).first {
                return Int(userData.value(forKey: "reviewCount") as? Int32 ?? 0)
            }
        } catch {
            print("Failed to get review count: \(error)")
        }
        return 0
    }
    
    private func isWordDueForReview(word: String) -> Bool {
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            if let userData = try context.fetch(userDataRequest).first {
                if let nextReviewDate = userData.value(forKey: "nextReviewDate") as? Date {
                    return nextReviewDate <= Date()
                }
            }
        } catch {
            print("Failed to check review status: \(error)")
        }
        return false
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
