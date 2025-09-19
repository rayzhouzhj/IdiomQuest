//
//  BalloonView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - Balloon View
struct BalloonView: View {
    let balloon: Balloon
    let screenHeight: CGFloat
    let onTap: (UUID, Bool) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Angle = .degrees(0)
    @State private var animationOffset: CGFloat = 0  // Simplified animation state
    @State private var tiltAngle: Double = 0
    @State private var showExplosion: Bool = false
    @State private var explosionParticles: [ExplosionParticle] = []
    @State private var showPopText: Bool = false
    
    // Explosion Particle for BalloonView
    private struct ExplosionParticle: Identifiable {
        let id = UUID()
        let color: Color
        let startPosition: CGPoint
        let velocity: CGPoint
        let size: CGFloat
    }

    var body: some View {
        ZStack {
            // Simplified balloon body with better performance
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                balloon.color.opacity(0.9),
                                balloon.color.opacity(0.7),
                                balloon.color.opacity(0.5)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.3),
                            startRadius: 10,
                            endRadius: balloon.size.width * 0.6
                        )
                    )
                    .frame(width: balloon.size.width, height: balloon.size.height)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(tiltAngle))
                    .shadow(color: balloon.color.opacity(0.3), radius: 8, x: 2, y: 4)
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset)
                    .onAppear {
                        tiltAngle = Double.random(in: -3...3)  // Reduced range for smoother animation
                    }
                
                // Simplified shine effect
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: balloon.size.width * 0.3, height: balloon.size.height * 0.3)
                    .position(
                        x: balloon.xPosition + balloon.xOffset - balloon.size.width * 0.15,
                        y: balloon.yOffset - balloon.size.height * 0.15
                    )
                    .opacity(opacity)
                    .scaleEffect(scale)
            }
            
            // Simplified string
            SimplifiedStringView(
                startPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2),
                endPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 80),
                animationOffset: animationOffset
            )
            
            // Simplified knot
            Circle()
                .fill(Color.brown.opacity(0.8))
                .frame(width: 6, height: 6)
                .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 80)
                .opacity(opacity)
                .scaleEffect(scale)
            
            // Word display under the string (optimized)
            Text(balloon.answer.text.localized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 60, alignment: .center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 110)
                .opacity(opacity)
                .scaleEffect(scale)
            
            // Balloon rubber fragments
            ForEach(explosionParticles) { particle in
                // Create irregular balloon fragment shapes
                ZStack {
                    // Main fragment piece
                    Ellipse()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 0.6)
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                    
                    // Smaller attached piece for irregular shape
                    if particle.size > 4 { // Only for larger fragments
                        Circle()
                            .fill(particle.color.opacity(0.8))
                            .frame(width: particle.size * 0.4, height: particle.size * 0.4)
                            .offset(x: particle.size * 0.3, y: particle.size * 0.2)
                    }
                }
                .position(particle.startPosition)
                .opacity(showExplosion ? 0 : 1)
                .offset(
                    x: showExplosion ? particle.velocity.x * 100 : 0,
                    y: showExplosion ? particle.velocity.y * 100 + (showExplosion ? 30 : 0) : 0 // Add gravity effect
                )
                .rotationEffect(.degrees(showExplosion ? Double.random(in: 180...720) : 0)) // Tumbling motion
                .scaleEffect(showExplosion ? 0.2 : 1.0)
                .animation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.1)), value: showExplosion)
            }
            
            // "POP!" text effect
            if showPopText {
                Text("POP!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.red)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset)
                    .scaleEffect(showPopText ? 1.5 : 0.1)
                    .opacity(showPopText ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showPopText)
            }
        }
        .onTapGesture {
            handleTap()
        }
        .onChange(of: balloon.isExploding) { isExploding in
            if isExploding && !showExplosion {
                triggerExplosion()
            }
        }
    }
    
    private func handleTap() {
        let isCorrect = balloon.answer.isCorrect
        onTap(balloon.id, isCorrect)
        
        if isCorrect {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.3
                rotation = .degrees(360)
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                opacity = 0
            }
        } else {
            // For wrong answers, trigger explosion immediately
            triggerExplosion()
        }
    }
    
    private func triggerExplosion() {
        // Create realistic balloon pop fragments
        let balloonCenter = CGPoint(
            x: balloon.xPosition + balloon.xOffset,
            y: balloon.yOffset
        )
        
        explosionParticles = []
        
        // Create 8-10 balloon rubber fragments (like real balloon pieces)
        for i in 0..<Int.random(in: 8...10) {
            let angle = Double(i) * (.pi * 2 / 8) + Double.random(in: -0.3...0.3) // Some randomness
            let velocity = CGPoint(
                x: cos(angle) * Double.random(in: 1.5...3.0), // Very fast initial burst
                y: sin(angle) * Double.random(in: 1.5...3.0)
            )
            
            let particle = ExplosionParticle(
                color: balloon.color.opacity(0.9), // Use actual balloon color, slightly transparent
                startPosition: balloonCenter,
                velocity: velocity,
                size: CGFloat.random(in: 6...12) // Various fragment sizes
            )
            
            explosionParticles.append(particle)
        }
        
        // Add some smaller debris
        for _ in 0..<5 {
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = CGPoint(
                x: cos(angle) * Double.random(in: 0.8...1.5),
                y: sin(angle) * Double.random(in: 0.8...1.5)
            )
            
            let particle = ExplosionParticle(
                color: balloon.color.opacity(0.6),
                startPosition: balloonCenter,
                velocity: velocity,
                size: CGFloat.random(in: 2...4) // Tiny pieces
            )
            
            explosionParticles.append(particle)
        }
        
        // Instant balloon pop animation - like a real balloon bursting
        withAnimation(.linear(duration: 0.02)) {
            scale = 1.3 // Quick expand
        }
        
        withAnimation(.linear(duration: 0.02).delay(0.02)) {
            scale = 0.0 // Instant disappear - POP!
            opacity = 0
            showExplosion = true
            showPopText = true
        }
        
        // Hide POP text after brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPopText = false
        }
        
        // Haptic feedback to simulate "POP"
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
}

// MARK: - Simplified String Path View (Better Performance)
struct SimplifiedStringView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let animationOffset: CGFloat
    
    var body: some View {
        Path { path in
            let midY = (startPoint.y + endPoint.y) / 2
            let control1 = CGPoint(x: startPoint.x + animationOffset * 5, y: midY - 10)
            let control2 = CGPoint(x: endPoint.x - animationOffset * 5, y: midY + 10)
            
            path.move(to: startPoint)
            path.addCurve(to: endPoint, control1: control1, control2: control2)
        }
        .stroke(
            LinearGradient(
                colors: [.gray.opacity(0.6), .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
}

// MARK: - Alternative: Emoji Balloon View (Ultra Performance)
struct EmojiBalloonView: View {
    let balloon: Balloon
    let screenHeight: CGFloat
    let onTap: (UUID, Bool) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Emoji balloon with color tint
                Text("🎈")
                    .font(.system(size: balloon.size.width * 0.8))
                    .colorMultiply(balloon.color)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(rotation)
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset)
                
                // Simple string line
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 2, height: 80)
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 40)
                    .opacity(opacity)
                
                // Word display
                Text(balloon.answer.text.localized)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minWidth: 60, alignment: .center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    )
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 110)
                    .opacity(opacity)
                    .scaleEffect(scale)
            }
        }
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        let isCorrect = balloon.answer.isCorrect
        onTap(balloon.id, isCorrect)
        
        if isCorrect {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.3
                rotation = .degrees(360)
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                opacity = 0
            }
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                scale = 0.8
                rotation = .degrees(15)
            }
            withAnimation(.easeInOut(duration: 0.15).delay(0.1)) {
                rotation = .degrees(-15)
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                scale = 0.4
                opacity = 0
            }
        }
    }
}
