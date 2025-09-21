//
//  ConfettiView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - Enhanced Confetti View
struct ConfettiView: View {
    let sourcePosition: CGPoint?
    @State private var isAnimating = false
    @State private var burstAnimating = false
    private let particleCount = 80
    private let burstParticleCount = 20
    private let colors: [Color] = [.yellow, .red, .green, .blue, .purple, .orange, .pink, .cyan, .mint]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main confetti rain (from top)
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiParticle(
                        color: colors[index % colors.count],
                        delay: Double.random(in: 0...0.8),
                        duration: Double.random(in: 3.0...5.0),
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        endY: geometry.size.height + 100,
                        isAnimating: $isAnimating
                    )
                }
                
                // Burst effect from balloon position
                if let sourcePos = sourcePosition {
                    ForEach(0..<burstParticleCount, id: \.self) { index in
                        BurstParticle(
                            color: colors[index % colors.count],
                            sourcePosition: sourcePos,
                            angle: Double(index) * (360.0 / Double(burstParticleCount)),
                            distance: CGFloat.random(in: 100...200),
                            isAnimating: $burstAnimating
                        )
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // Start animations immediately
                withAnimation {
                    isAnimating = true
                    burstAnimating = true
                }
            }
        }
    }
}

// MARK: - Individual Confetti Particle
struct ConfettiParticle: View {
    let color: Color
    let delay: Double
    let duration: Double
    let startX: CGFloat
    let endY: CGFloat
    @Binding var isAnimating: Bool
    
    @State private var yPosition: CGFloat = -50
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: startX, y: yPosition)
            .onAppear {
                // Start animation with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: duration)) {
                        yPosition = endY
                        rotation = Double.random(in: 360...720)
                        scale = 1.0
                    }
                    
                    // Fade out near the end
                    withAnimation(.easeIn(duration: 0.5).delay(duration - 0.5)) {
                        opacity = 0
                    }
                }
            }
    }
}

// MARK: - Burst Particle from Balloon
struct BurstParticle: View {
    let color: Color
    let sourcePosition: CGPoint
    let angle: Double
    let distance: CGFloat
    @Binding var isAnimating: Bool
    
    @State private var currentPosition: CGPoint = .zero
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 10...18), height: CGFloat.random(in: 10...18))
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .position(currentPosition)
            .onAppear {
                currentPosition = sourcePosition
                
                // Calculate end position
                let radians = angle * .pi / 180
                let endX = sourcePosition.x + cos(radians) * distance
                let endY = sourcePosition.y + sin(radians) * distance
                let endPosition = CGPoint(x: endX, y: endY)
                
                // Start burst animation immediately
                withAnimation(.easeOut(duration: 1.2)) {
                    currentPosition = endPosition
                    rotation = Double.random(in: 180...360)
                }
                
                withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                    scale = 0.3
                    opacity = 0
                }
            }
    }
}
