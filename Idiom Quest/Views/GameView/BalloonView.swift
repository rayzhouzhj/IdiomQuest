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
    @State private var shineOffset: CGFloat = -15  // For dynamic shine animation
    @State private var tiltAngle: Double = 0  // For subtle wobble

    var body: some View {
        ZStack {
            // Dynamic shine (pulsing effect)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.2), .clear],
                        center: UnitPoint(x: 0.3, y: 0.2),
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: balloon.size.width * 0.7, height: balloon.size.height * 0.7)
                .blendMode(.softLight)
                .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + shineOffset)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: shineOffset
                )
                .onAppear {
                    shineOffset = -10  // Slight shift for pulsing
                }
            
            // Balloon body with realistic gradient and texture
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                balloon.color.opacity(0.95),
                                balloon.color.opacity(0.8),
                                balloon.color.opacity(0.6),
                                balloon.color.opacity(0.3)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.3),
                            startRadius: 10,
                            endRadius: balloon.size.width * 0.8
                        )
                    )
                    .frame(width: balloon.size.width, height: balloon.size.height)
                    .overlay(
                        // Organic latex texture (curved lines)
                        ZStack {
                            Path { path in
                                path.move(to: CGPoint(x: balloon.size.width * 0.3, y: 0))
                                path.addQuadCurve(
                                    to: CGPoint(x: balloon.size.width * 0.7, y: balloon.size.height),
                                    control: CGPoint(x: balloon.size.width * 0.5, y: balloon.size.height * 0.5)
                                )
                                path.move(to: CGPoint(x: balloon.size.width * 0.2, y: balloon.size.height * 0.2))
                                path.addQuadCurve(
                                    to: CGPoint(x: balloon.size.width * 0.8, y: balloon.size.height * 0.8),
                                    control: CGPoint(x: balloon.size.width * 0.5, y: balloon.size.height * 0.6)
                                )
                            }
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                        }
                        .frame(width: balloon.size.width * 0.8, height: balloon.size.height * 0.8)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(tiltAngle))  // Subtle wobble
                    .shadow(color: balloon.color.opacity(0.2), radius: 10, x: balloon.xOffset * 0.5, y: 5)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: balloon.xOffset * 0.3, y: 3)
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: tiltAngle
                    )
                    .onAppear {
                        tiltAngle = Double.random(in: -5...5)  // Random initial tilt
                    }
                
                // Answer text
                Text(balloon.answer.text)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .frame(width: balloon.size.width * 0.7, alignment: .center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.black.opacity(0.3))
                            .blur(radius: 1)
                    )
                    .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset - 5)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(tiltAngle))
            }
            
            // Curved string (improved with twist)
            StringPathView(
                startPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2),
                endPoint: CGPoint(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 80),
                phase: balloon.phase,
                time: Date().timeIntervalSince1970
            )
            
            // Knot with realistic detail
            ZStack {
                Ellipse()
                    .fill(Color.brown.opacity(0.9))
                    .frame(width: 8, height: 6)
                    .rotationEffect(.degrees(45))
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 2.5, height: 2.5)
            }
            .position(x: balloon.xPosition + balloon.xOffset, y: balloon.yOffset + balloon.size.height / 2 + 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            print("Balloon at x: \(balloon.xPosition), y: \(balloon.yOffset)")
        }
    }
    
    private func handleTap() {
        let isCorrect = balloon.answer.isCorrect
        onTap(balloon.id, isCorrect)
        
        if isCorrect {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                scale = 1.4
                rotation = .degrees(720)
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                opacity = 0
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                scale = 0.7
                rotation = .degrees(20)
            }
            withAnimation(.easeInOut(duration: 0.2).delay(0.1)) {
                rotation = .degrees(-20)
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                scale = 0.3
                opacity = 0
            }
        }
    }
}

// MARK: - Curved String Path View
struct StringPathView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let phase: Double
    let time: TimeInterval
    
    var body: some View {
        ZStack {
            // Main string
            Path { path in
                let midX = (startPoint.x + endPoint.x) / 2
                let control1 = CGPoint(x: midX - 15 * sin(time * 2 + phase), y: startPoint.y + 20)
                let control2 = CGPoint(x: midX + 15 * cos(time * 1.5 + phase), y: endPoint.y - 20)
                
                path.move(to: startPoint)
                path.addCurve(to: endPoint, control1: control1, control2: control2)
            }
            .stroke(
                LinearGradient(
                    colors: [.gray.opacity(0.7), .black.opacity(0.6), .gray.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: time)
            
            // Subtle twist effect
            Path { path in
                let midX = (startPoint.x + endPoint.x) / 2
                let control1 = CGPoint(x: midX - 10 * sin(time * 2.2 + phase), y: startPoint.y + 15)
                let control2 = CGPoint(x: midX + 10 * cos(time * 1.7 + phase), y: endPoint.y - 15)
                
                path.move(to: startPoint)
                path.addCurve(to: endPoint, control1: control1, control2: control2)
            }
            .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: time)
        }
        .onAppear {
            print("String from x: \(startPoint.x), y: \(startPoint.y) to x: \(endPoint.x), y: \(endPoint.y)")
        }
    }
}
