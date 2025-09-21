//
//  DetailedReviewView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 21/9/2025.
//

import SwiftUI
import CoreData

// MARK: - Detailed Review View
struct DetailedReviewView: View {
    let word: NSManagedObject
    let onReviewed: (NSManagedObject) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    @State private var isExplanationRevealed = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        LocalizedText("複習成語")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("回憶一下這個成語的意思")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Word Card
                    VStack(spacing: 20) {
                        // Word and pinyin
                        VStack(spacing: 8) {
                            if let wordText = word.value(forKey: "word") as? String {
                                LocalizedText(wordText)
                                    .font(.system(size: 36, weight: .bold, design: .serif))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.primary, .orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            
                            Text(word.value(forKey: "pinyin") as? String ?? "")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 15) {
                            // Explanation with blur mask
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    ZStack {
                                        if let wordText = word.value(forKey: "word") as? String,
                                           let explanation = word.value(forKey: "explanation") as? String {
                                            LocalizedText(explanation.replacingOccurrences(of: "～", with: wordText))
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                                .blur(radius: isExplanationRevealed ? 0 : 8)
                                                .animation(.easeInOut(duration: 0.3), value: isExplanationRevealed)
                                        }
                                        
                                        if !isExplanationRevealed {
                                            VStack(spacing: 8) {
                                                Image(systemName: "eye.slash.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.orange)
                                                
                                                Text("輕觸顯示解釋")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.vertical, 20)
                                        }
                                    }
                                } icon: {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isExplanationRevealed = true
                                    }
                                }
                                
                                if !isExplanationRevealed {
                                    Text("先思考一下這個成語的意思，然後點擊查看解釋")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .padding(.leading, 30)
                                }
                            }
                            
                            // Example
                            if let wordText = word.value(forKey: "word") as? String,
                               let example = word.value(forKey: "example") as? String, !example.isEmpty {
                                Label {
                                    LocalizedText(example.replacingOccurrences(of: "～", with: wordText))
                                        .font(.subheadline)
                                        .italic()
                                } icon: {
                                    Image(systemName: "quote.bubble.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // Derivation
                            if let derivation = word.value(forKey: "derivation") as? String, !derivation.isEmpty {
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
                        
                        // Review Button
                        Button(action: {
                            withAnimation(.spring()) {
                                showConfetti = true
                                onReviewed(word)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showConfetti = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                
                                LocalizedText("已複習完成")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(25)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .overlay(
            showConfetti ? ConfettiView(sourcePosition: nil) : nil
        )
    }
}
