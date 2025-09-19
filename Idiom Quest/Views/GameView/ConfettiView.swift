//
//  ConfettiView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var isAnimating = false
    private let particleCount = 60
    private let colors: [Color] = [.yellow, .red, .green, .blue, .purple, .orange, .pink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    Rectangle()
                        .fill(colors[index % colors.count])
                        .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: isAnimating ? CGFloat.random(in: -50...geometry.size.height + 50) : -50
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.0)
                        .animation(
                            Animation.linear(duration: Double.random(in: 2.5...4.0))
                                .repeatForever(autoreverses: false)
                                .delay(Double.random(in: 0...0.5)),
                            value: isAnimating
                        )
                        .onAppear {
                            if !isAnimating {
                                isAnimating = true
                            }
                        }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let skyblue = Color(red: 0.529, green: 0.808, blue: 0.922)
}
