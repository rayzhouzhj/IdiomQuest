//
//  LocalizedText.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

/// A custom Text view that automatically applies preferred Chinese localization
struct LocalizedText: View {
    private let originalContent: String
    @ObservedObject private var languageSettings = LanguageSettings.shared
    
    init(_ content: String) {
        self.originalContent = content
    }
    
    init<S>(_ content: S) where S : StringProtocol {
        self.originalContent = String(content)
    }
    
    private var localizedContent: String {
        // This will update reactively when languageSettings.preferredLanguage changes
        switch languageSettings.preferredLanguage {
        case .traditionalChinese:
            return originalContent.toTraditionalChinese()
        case .simplifiedChinese:
            return originalContent.toSimplifiedChinese()
        }
    }
    
    var body: some View {
        Text(localizedContent)
    }
}

// MARK: - Text Modifiers Support
extension LocalizedText {
    func font(_ font: Font?) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).font(font)
        }
    }
    
    func fontWeight(_ weight: Font.Weight?) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).fontWeight(weight)
        }
    }
    
    func foregroundColor(_ color: Color?) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).foregroundColor(color)
        }
    }
    
    func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).foregroundStyle(style)
        }
    }
    
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).multilineTextAlignment(alignment)
        }
    }
    
    func lineLimit(_ number: Int?) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).lineLimit(number)
        }
    }
    
    func italic() -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).italic()
        }
    }
    
    func bold() -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).bold()
        }
    }
    
    func underline(_ active: Bool = true, color: Color? = nil) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).underline(active, color: color)
        }
    }
    
    func strikethrough(_ active: Bool = true, color: Color? = nil) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).strikethrough(active, color: color)
        }
    }
    
    func textCase(_ textCase: Text.Case?) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).textCase(textCase)
        }
    }
    
    func kerning(_ kerning: CGFloat) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).kerning(kerning)
        }
    }
    
    func tracking(_ tracking: CGFloat) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).tracking(tracking)
        }
    }
    
    func baselineOffset(_ baselineOffset: CGFloat) -> some View {
        LocalizedTextModified(originalContent: originalContent) { content in
            Text(content).baselineOffset(baselineOffset)
        }
    }
}

// MARK: - Helper for Modified Text
private struct LocalizedTextModified<Content: View>: View {
    let originalContent: String
    let modifier: (String) -> Content
    @ObservedObject private var languageSettings = LanguageSettings.shared
    
    private var localizedContent: String {
        switch languageSettings.preferredLanguage {
        case .traditionalChinese:
            return originalContent.toTraditionalChinese()
        case .simplifiedChinese:
            return originalContent.toSimplifiedChinese()
        }
    }
    
    var body: some View {
        modifier(localizedContent)
    }
}