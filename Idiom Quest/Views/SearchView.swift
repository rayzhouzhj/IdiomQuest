//
//  SearchView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [NSManagedObject] = []
    @State private var searchHistory: [SearchHistoryItem] = []
    @State private var isSearching = false
    @State private var selectedTab: SearchTab = .results
    @State private var showDeleteAlert = false
    @State private var itemToDelete: SearchHistoryItem?
    @FocusState private var isSearchFieldFocused: Bool
    
    enum SearchTab: String, CaseIterable {
        case results = "搜尋結果"
        case history = "搜尋記錄"
        
        var icon: String {
            switch self {
            case .results: return "magnifyingglass"
            case .history: return "clock.fill"
            }
        }
    }
    
    struct SearchHistoryItem: Identifiable {
        let id = UUID()
        let searchQuery: String
        let searchDate: Date
        let results: [NSManagedObject]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search bar
                searchBar
                
                // Tab selector
                tabSelector
                
                // Content
                if selectedTab == .results {
                    searchResultsView
                } else {
                    searchHistoryView
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onAppear {
                loadSearchHistory()
                isSearchFieldFocused = true
            }
            .alert("刪除搜尋記錄", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    if let item = itemToDelete {
                        deleteSearchHistoryItem(item)
                    }
                }
            } message: {
                LocalizedText("確定要刪除這個搜尋記錄嗎？")
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack {
                LocalizedText("搜尋成語".toPreferredChinese())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if selectedTab == .results && !searchResults.isEmpty {
                    LocalizedText("找到 \(searchResults.count) 個結果")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if selectedTab == .history && !searchHistory.isEmpty {
                    LocalizedText("\(searchHistory.count) 個搜尋記錄")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                if selectedTab == .history {
                    clearOldSearchHistory()
                }
            }) {
                Image(systemName: selectedTab == .history ? "trash" : "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜尋成語、拼音或解釋...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFieldFocused)
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { newValue in
                    if newValue.isEmpty {
                        searchResults = []
                        selectedTab = .history
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    selectedTab = .history
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SearchTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    tabButtonContent(for: tab)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
    
    private func tabButtonContent(for tab: SearchTab) -> some View {
        let isSelected = selectedTab == tab
        let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: [.blue, .green]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        return HStack {
            Image(systemName: tab.icon)
                .font(.subheadline)
            
            Text(tab.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? AnyView(backgroundGradient) : AnyView(Color.clear))
        .foregroundColor(isSelected ? .white : .primary)
    }
    
    private var searchResultsView: some View {
        Group {
            if isSearching {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    LocalizedText("搜尋中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                emptySearchResultsView
            } else if searchResults.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(searchResults.enumerated()), id: \.element) { index, idiom in
                            searchResultCard(idiom: idiom)
                                .scaleEffect(1.0)
                                .opacity(1.0)
                                .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: searchResults.count)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var searchHistoryView: some View {
        Group {
            if searchHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        LocalizedText("還沒有搜尋記錄")
                            .font(.headline)
                        
                        LocalizedText("開始搜尋你感興趣的成語吧！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchHistory) { historyItem in
                            searchHistoryCard(historyItem: historyItem)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                LocalizedText("找不到相關成語")
                    .font(.headline)
                
                LocalizedText("嘗試其他關鍵字或檢查拼寫")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.7))
            
            VStack(spacing: 8) {
                LocalizedText("開始搜尋成語")
                    .font(.headline)
                
                LocalizedText("在上方輸入關鍵字來搜尋成語")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private func searchResultCard(idiom: NSManagedObject) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with word and learn button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text((idiom.value(forKey: "word") as? String ?? "").toPreferredChinese())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.primary, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(idiom.value(forKey: "pinyin") as? String ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
                
                learnButton(for: idiom)
            }
            
            // Explanation
            Text((idiom.value(forKey: "explanation") as? String ?? "").toPreferredChinese())
                .font(.body)
                .lineLimit(4)
            
            // Additional content
            VStack(alignment: .leading, spacing: 8) {
                if let example = idiom.value(forKey: "example") as? String, !example.isEmpty {
                    Label {
                        Text(example.toPreferredChinese())
                            .font(.caption)
                            .lineLimit(2)
                    } icon: {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if let derivation = idiom.value(forKey: "derivation") as? String, !derivation.isEmpty {
                    Label {
                        Text(derivation.toPreferredChinese())
                            .font(.caption)
                            .lineLimit(2)
                    } icon: {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func learnButton(for idiom: NSManagedObject) -> some View {
        let word = idiom.value(forKey: "word") as? String ?? ""
        let isLearned = getLearnedStatus(for: word)
        
        return Button(action: {
            toggleLearned(for: idiom)
        }) {
            HStack(spacing: 6) {
                Image(systemName: isLearned ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.subheadline)
                
                Text(isLearned ? "已學會" : "學習")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isLearned ? [.green, .mint] : [.blue, .cyan]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func searchHistoryCard(historyItem: SearchHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText("「\(historyItem.searchQuery)」")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatDate(historyItem.searchDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        searchText = historyItem.searchQuery
                        searchResults = historyItem.results
                        selectedTab = .results
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        itemToDelete = historyItem
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
            
            LocalizedText("找到 \(historyItem.results.count) 個結果")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Preview of first few results
            if !historyItem.results.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(historyItem.results.prefix(3), id: \.objectID) { result in
                            Text((result.value(forKey: "word") as? String ?? "").toPreferredChinese())
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if historyItem.results.count > 3 {
                            LocalizedText("...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        selectedTab = .results
        
        DispatchQueue.global(qos: .userInitiated).async {
            let context = CoreDataManager.shared.context
            let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
            
            // Create compound predicate for searching multiple fields
            let wordPredicate = NSPredicate(format: "word CONTAINS[cd] %@", searchText)
            let pinyinPredicate = NSPredicate(format: "pinyin CONTAINS[cd] %@", searchText)
            let explanationPredicate = NSPredicate(format: "explanation CONTAINS[cd] %@", searchText)
            let derivationPredicate = NSPredicate(format: "derivation CONTAINS[cd] %@", searchText)
            let examplePredicate = NSPredicate(format: "example CONTAINS[cd] %@", searchText)
            
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                wordPredicate, pinyinPredicate, explanationPredicate, derivationPredicate, examplePredicate
            ])
            
            request.fetchLimit = 50 // Limit results to prevent performance issues
            
            do {
                let results = try context.fetch(request)
                
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isSearching = false
                    
                    // Save to search history
                    self.saveSearchToHistory(query: self.searchText, results: results)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Search failed: \(error)")
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
    
    private func saveSearchToHistory(query: String, results: [NSManagedObject]) {
        let context = CoreDataManager.shared.context
        
        // Remove duplicate searches for the same query
        let deleteRequest = NSFetchRequest<NSManagedObject>(entityName: "SearchHistory")
        deleteRequest.predicate = NSPredicate(format: "searchQuery == %@", query)
        
        do {
            let existingSearches = try context.fetch(deleteRequest)
            existingSearches.forEach { context.delete($0) }
        } catch {
            print("Failed to remove duplicate searches: \(error)")
        }
        
        // Save new search history entries
        for result in results {
            let searchHistory = NSEntityDescription.insertNewObject(forEntityName: "SearchHistory", into: context)
            searchHistory.setValue(query, forKey: "searchQuery")
            searchHistory.setValue(Date(), forKey: "searchDate")
            searchHistory.setValue(result.value(forKey: "word"), forKey: "word")
        }
        
        CoreDataManager.shared.saveContext()
        loadSearchHistory()
    }
    
    private func loadSearchHistory() {
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "SearchHistory")
        
        // Only load searches from the last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "searchDate >= %@", sevenDaysAgo as NSDate)
        
        let sortDescriptor = NSSortDescriptor(key: "searchDate", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let historyData = try context.fetch(request)
            
            // Group by search query only
            let groupedByQuery = Dictionary(grouping: historyData) { history in
                history.value(forKey: "searchQuery") as? String ?? ""
            }
            
            var historyItems: [SearchHistoryItem] = []
            
            for (query, histories) in groupedByQuery {
                // Get the most recent date for this query
                let dates = histories.compactMap { $0.value(forKey: "searchDate") as? Date }
                guard let mostRecentDate = dates.max() else { continue }
                
                let words = histories.compactMap { $0.value(forKey: "word") as? String }
                
                // Fetch corresponding Chengyu objects
                if !words.isEmpty {
                    let chengyuRequest = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
                    chengyuRequest.predicate = NSPredicate(format: "word IN %@", words)
                    
                    do {
                        let results = try context.fetch(chengyuRequest)
                        let historyItem = SearchHistoryItem(
                            searchQuery: query,
                            searchDate: mostRecentDate,
                            results: results
                        )
                        historyItems.append(historyItem)
                    } catch {
                        print("Failed to fetch Chengyu for history: \(error)")
                    }
                }
            }
            
            // Sort by date descending and keep only recent searches
            let sortedHistory = historyItems.sorted { $0.searchDate > $1.searchDate }
            searchHistory = Array(sortedHistory.prefix(10)) // Keep only recent 10 searches
            
        } catch {
            print("Failed to load search history: \(error)")
            searchHistory = []
        }
    }
    
    private func deleteSearchHistoryItem(_ item: SearchHistoryItem) {
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "SearchHistory")
        request.predicate = NSPredicate(format: "searchQuery == %@", item.searchQuery)
        
        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            CoreDataManager.shared.saveContext()
            loadSearchHistory()
        } catch {
            print("Failed to delete search history: \(error)")
        }
    }
    
    private func clearOldSearchHistory() {
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "SearchHistory")
        
        // Delete searches older than 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "searchDate < %@", sevenDaysAgo as NSDate)
        
        do {
            let oldSearches = try context.fetch(request)
            oldSearches.forEach { context.delete($0) }
            CoreDataManager.shared.saveContext()
            loadSearchHistory()
        } catch {
            print("Failed to clear old search history: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "今天 \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "昨天 \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
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
    
    private func toggleLearned(for idiom: NSManagedObject) {
        guard let word = idiom.value(forKey: "word") as? String else { return }
        
        let context = CoreDataManager.shared.context
        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
        
        do {
            let now = Date()
            let isCurrentlyLearned = getLearnedStatus(for: word)
            
            if let userData = try context.fetch(userDataRequest).first {
                userData.setValue(!isCurrentlyLearned, forKey: "isLearned")
                
                if !isCurrentlyLearned {
                    // First time learning - set initial review date
                    userData.setValue(now, forKey: "lastReviewDate")
                    let reviewCount = userData.value(forKey: "reviewCount") as? Int32 ?? 0
                    let nextReviewInterval = getReviewInterval(for: Int(reviewCount))
                    userData.setValue(now.addingTimeInterval(nextReviewInterval), forKey: "nextReviewDate")
                    userData.setValue(reviewCount + 1, forKey: "reviewCount")
                } else {
                    // Unlearning - reset review data
                    userData.setValue(nil, forKey: "lastReviewDate")
                    userData.setValue(nil, forKey: "nextReviewDate")
                    userData.setValue(0, forKey: "reviewCount")
                }
            } else {
                // Create new UserData entry
                let userData = NSEntityDescription.insertNewObject(forEntityName: "UserData", into: context)
                userData.setValue(word, forKey: "word")
                userData.setValue(true, forKey: "isLearned")
                userData.setValue(now, forKey: "lastReviewDate")
                userData.setValue(now.addingTimeInterval(getReviewInterval(for: 0)), forKey: "nextReviewDate")
                userData.setValue(1, forKey: "reviewCount")
            }
            
            CoreDataManager.shared.saveContext()
        } catch {
            print("Failed to toggle learned: \(error)")
        }
    }
    
    private func getReviewInterval(for reviewCount: Int) -> TimeInterval {
        // Spaced repetition intervals (in days)
        let intervals: [TimeInterval] = [1, 3, 7, 14, 30, 90] // days
        let dayIndex = min(reviewCount, intervals.count - 1)
        return intervals[dayIndex] * 24 * 60 * 60 // convert to seconds
    }
}

// MARK: - SearchHistoryItem Equatable & Hashable

extension SearchView.SearchHistoryItem: Equatable, Hashable {
    static func == (lhs: SearchView.SearchHistoryItem, rhs: SearchView.SearchHistoryItem) -> Bool {
        lhs.searchQuery == rhs.searchQuery && 
        Int(lhs.searchDate.timeIntervalSince1970) == Int(rhs.searchDate.timeIntervalSince1970)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(searchQuery)
        hasher.combine(Int(searchDate.timeIntervalSince1970))
    }
}