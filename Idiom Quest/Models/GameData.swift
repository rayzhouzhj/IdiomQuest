//
//  GameData.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - Models
struct Answer: Identifiable {
    let id = UUID()
    let text: String
    let isCorrect: Bool
}

struct Balloon: Identifiable {
    let id = UUID()
    let answer: Answer
    let color: Color
    var yOffset: CGFloat
    let xPosition: CGFloat
    let phase: Double
    var xOffset: CGFloat = 0
    var baseYOffset: CGFloat
    let size: CGSize
    var isTapped = false
    var isExploding = false
}
