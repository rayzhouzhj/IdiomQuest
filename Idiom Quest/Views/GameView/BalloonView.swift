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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
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
            }
            withAnimation(.easeInOut(duration: 0.15).delay(0.1)) {
                scale = 1.0
            }
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
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
