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
    @State private var bobbingOffset: CGFloat = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var gentleRotation: Double = 0
    
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
            // Enhanced balloon body with realistic depth
            ZStack {
                // Main balloon body with enhanced gradient
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                balloon.color.opacity(0.95),          // Bright center
                                balloon.color.opacity(0.85),          // Mid tone
                                balloon.color.opacity(0.7),           // Darker edge
                                balloon.color.opacity(0.5)            // Darkest rim
                            ],
                            center: UnitPoint(x: 0.4, y: 0.25),       // Off-center for 3D effect
                            startRadius: 5,
                            endRadius: balloon.size.width * 0.7
                        )
                    )
                    .overlay(
                        // Secondary gradient for depth
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        balloon.color.opacity(0.2),
                                        balloon.color.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .frame(width: balloon.size.width, height: balloon.size.height)
                    .scaleEffect(scale * breathingScale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(tiltAngle + gentleRotation))
                    .shadow(color: balloon.color.opacity(0.4), radius: 12, x: 3, y: 6)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 5, y: 10) // Additional soft shadow
                    .position(
                        x: balloon.xPosition + balloon.xOffset, 
                        y: balloon.yOffset + bobbingOffset
                    )
                    .onAppear {
                        tiltAngle = Double.random(in: -3...3)
                        startIdleAnimations()
                    }
                
                // Realistic balloon mouth/tie at bottom
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                balloon.color.opacity(0.8),
                                balloon.color.opacity(0.6),
                                balloon.color.opacity(0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: balloon.size.width * 0.15, height: balloon.size.height * 0.08)
                    .position(
                        x: balloon.xPosition + balloon.xOffset,
                        y: balloon.yOffset + balloon.size.height / 2 - 2 + bobbingOffset
                    )
                    .scaleEffect(scale * breathingScale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(tiltAngle + gentleRotation))
                
                // Enhanced primary shine effect
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: balloon.size.width * 0.2
                        )
                    )
                    .frame(width: balloon.size.width * 0.25, height: balloon.size.height * 0.35)
                    .position(
                        x: balloon.xPosition + balloon.xOffset - balloon.size.width * 0.12,
                        y: balloon.yOffset - balloon.size.height * 0.18 + bobbingOffset
                    )
                    .opacity(opacity)
                    .scaleEffect(scale * breathingScale)
                    .rotationEffect(.degrees(tiltAngle + gentleRotation))
                
                // Secondary smaller shine
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: balloon.size.width * 0.12, height: balloon.size.height * 0.12)
                    .position(
                        x: balloon.xPosition + balloon.xOffset + balloon.size.width * 0.08,
                        y: balloon.yOffset - balloon.size.height * 0.05 + bobbingOffset
                    )
                    .opacity(opacity)
                    .scaleEffect(scale * breathingScale)
                    .rotationEffect(.degrees(tiltAngle + gentleRotation))
            }
            
            // Enhanced curvy string
            CurvyStringView(
                startPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + bobbingOffset),
                endPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 70 + bobbingOffset),
                animationOffset: animationOffset
            )
            
            // Enhanced knot with realistic 3D design
            ZStack {
                // Knot shadow base
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .offset(x: 1, y: 1)
                
                // Main knot body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brown.opacity(0.95),
                                Color.brown.opacity(0.75),
                                Color.brown.opacity(0.55),
                                Color.brown.opacity(0.35)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 1,
                            endRadius: 5
                        )
                    )
                    .frame(width: 9, height: 9)
                
                // Knot highlight
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 3, height: 3)
                    .offset(x: -1, y: -1)
            }
            .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 70 + bobbingOffset)
            .opacity(opacity)
            .scaleEffect(scale)
            
            // Enhanced word display with premium styling
            LocalizedText(balloon.answer.text.localized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minWidth: 60, alignment: .center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color.gray.opacity(0.05),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.8),
                                            .clear,
                                            Color.gray.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .overlay(
                            // Enhanced connection line to knot
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.7),
                                            Color.gray.opacity(0.4)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 1.5, height: 10)
                                .offset(y: -14)
                        )
                )
                .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 85 + bobbingOffset)
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
                LocalizedText("POP!")
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
    
    private func startIdleAnimations() {
        // Gentle bobbing animation
        withAnimation(
            .easeInOut(duration: Double.random(in: 2.5...4.0))
            .repeatForever(autoreverses: true)
        ) {
            bobbingOffset = CGFloat.random(in: -3...3)
        }
        
        // Subtle breathing scale effect
        withAnimation(
            .easeInOut(duration: Double.random(in: 3.0...5.0))
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = CGFloat.random(in: 0.98...1.02)
        }
        
        // Very gentle rotation
        withAnimation(
            .linear(duration: Double.random(in: 8.0...12.0))
            .repeatForever(autoreverses: false)
        ) {
            gentleRotation = Double.random(in: -2...2)
        }
    }
}

// MARK: - Natural Balloon String View
struct CurvyStringView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let animationOffset: CGFloat
    
    var body: some View {
        Path { path in
            // Simple, natural-looking balloon string with gentle curves
            let stringLength = endPoint.y - startPoint.y
            let midY = startPoint.y + stringLength * 0.5
            
            // Gentle sway based on animation offset (wind effect)
            let swayAmount: CGFloat = 3.0
            let sway = sin(Double(animationOffset) * 0.05) * swayAmount
            
            // Create a gentle S-curve like a real hanging string
            let quarterY = startPoint.y + stringLength * 0.25
            let threeQuarterY = startPoint.y + stringLength * 0.75
            
            path.move(to: startPoint)
            
            // First curve segment (top quarter)
            let control1 = CGPoint(
                x: startPoint.x + sway * 0.5,
                y: quarterY - 5
            )
            let point1 = CGPoint(
                x: startPoint.x + sway,
                y: quarterY
            )
            path.addQuadCurve(to: point1, control: control1)
            
            // Second curve segment (middle)
            let control2 = CGPoint(
                x: startPoint.x + sway * 1.5,
                y: midY
            )
            let point2 = CGPoint(
                x: startPoint.x - sway * 0.5,
                y: threeQuarterY
            )
            path.addQuadCurve(to: point2, control: control2)
            
            // Final segment to end point
            let control3 = CGPoint(
                x: endPoint.x - sway * 0.3,
                y: threeQuarterY + 10
            )
            path.addQuadCurve(to: endPoint, control: control3)
        }
        .stroke(
            Color.gray.opacity(0.7),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: .black.opacity(0.15), radius: 0.5, x: 0.5, y: 0.5)
    }
}
