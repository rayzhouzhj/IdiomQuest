//
//  LocalizedText.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

/// A custom Text view that automatically applies preferred Chinese localization
struct LocalizedText: View {
    private let content: String
    private let originalText: Text
    
    init(_ content: String) {
        self.content = content.toPreferredChinese()
        self.originalText = Text(self.content)
    }
    
    init<S>(_ content: S) where S : StringProtocol {
        self.content = String(content).toPreferredChinese()
        self.originalText = Text(self.content)
    }
    
    var body: some View {
        originalText
    }
}

// MARK: - Text Modifiers Support
extension LocalizedText {
    func font(_ font: Font?) -> some View {
        originalText.font(font)
    }
    
    func fontWeight(_ weight: Font.Weight?) -> some View {
        originalText.fontWeight(weight)
    }
    
    func foregroundColor(_ color: Color?) -> some View {
        originalText.foregroundColor(color)
    }
    
    func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        originalText.foregroundStyle(style)
    }
    
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View {
        originalText.multilineTextAlignment(alignment)
    }
    
    func lineLimit(_ number: Int?) -> some View {
        originalText.lineLimit(number)
    }
    
    func italic() -> some View {
        originalText.italic()
    }
    
    func bold() -> some View {
        originalText.bold()
    }
    
    func underline(_ active: Bool = true, color: Color? = nil) -> some View {
        originalText.underline(active, color: color)
    }
    
    func strikethrough(_ active: Bool = true, color: Color? = nil) -> some View {
        originalText.strikethrough(active, color: color)
    }
    
    func textCase(_ textCase: Text.Case?) -> some View {
        originalText.textCase(textCase)
    }
    
    func kerning(_ kerning: CGFloat) -> some View {
        originalText.kerning(kerning)
    }
    
    func tracking(_ tracking: CGFloat) -> some View {
        originalText.tracking(tracking)
    }
    
    func baselineOffset(_ baselineOffset: CGFloat) -> some View {
        originalText.baselineOffset(baselineOffset)
    }
}