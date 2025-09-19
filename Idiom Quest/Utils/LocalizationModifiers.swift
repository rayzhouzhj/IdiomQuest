//
//  LocalizationModifiers.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - View Modifier for automatic localization
struct AutoLocalizedModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.locale, Locale.current)
    }
}

// MARK: - View extension for easy application
extension View {
    /// Applies automatic Chinese localization to all text in this view hierarchy
    func autoLocalized() -> some View {
        modifier(AutoLocalizedModifier())
    }
}

// MARK: - Global Text Override (Advanced Option)
#if DEBUG
// This is a more advanced approach that overrides Text globally
// Only use in debug builds to avoid App Store issues

struct AutoLocalizedText: View {
    private let text: Text
    
    init(_ content: LocalizedStringKey) {
        // For LocalizedStringKey, we need to extract the string
        self.text = Text(content)
    }
    
    init<S>(_ content: S) where S : StringProtocol {
        let localizedContent = String(content).toPreferredChinese()
        self.text = Text(localizedContent)
    }
    
    var body: some View {
        text
    }
}

// Uncomment this to globally replace Text with AutoLocalizedText
// typealias Text = AutoLocalizedText
#endif