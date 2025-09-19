//
//  GameView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import SwiftUI
import CoreData

// MARK: - Game View
struct GameView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // Game State
    @State private var gameState: GameState = .waiting
    @State private var balloons: [Balloon] = []
    @State private var currentIdioms: [NSManagedObject] = []
    @State private var correctIdiom: NSManagedObject?
    @State private var showConfetti = false
    @State private var showSuccessText = false
    @State private var successTextScale: CGFloat = 0.5
    @State private var successTextOpacity: Double = 0.0
    
    // Scoring & Progress
    @State private var score = 0
    @State private var currentRound = 1
    @State private var correctAnswers = 0
    @State private var totalRounds = 0
    
    // Game Duration Options
    @State private var selectedDuration = 60  // Default 1 minute
    let durationOptions = [
        (60, "1 分鐘"),
        (180, "3 分鐘"), 
        (300, "5 分鐘")
    ]
    
    // Computed property for formatted time display
    private var formattedTimeRemaining: String {
        let minutes = gameTimeRemaining / 60
        let seconds = gameTimeRemaining % 60
        if gameTimeRemaining >= 60 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(gameTimeRemaining)秒"
        }
    }
    
    // Timers
    @State private var gameTimer: Timer?
    @State private var roundTimer: Timer?
    @State private var bobbingTimer: Timer?
    @State private var flyAwayTimer: Timer?
    @State private var gameTimeRemaining = 60  // Will be set based on selectedDuration
    @State private var roundTimeRemaining = 15   // 15 seconds per round
    
    // UI State
    @State private var roundActive = false
    @State private var userInteractedThisRound = false
    @State private var screenWidth: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    @State private var animateNewRound = false
    @State private var showWrongAnswerEffect = false
    @State private var wrongAnswerShake = false
    @State private var showBalloonEffect = false
    @State private var balloonStartPosition: CGPoint = .zero
    @State private var balloonEndPosition: CGPoint = .zero
    @State private var balloonFlyProgress: CGFloat = 0.0
    @State private var balloonScale: CGFloat = 1.0
    @State private var balloonOpacity: Double = 0.0
    @State private var isPaused = false
    
    let balloonColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan]
    let balloonsPerRound = 4
    let roundDuration: TimeInterval = 8.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky background with gradient
                backgroundView
                
                // Game content based on state
                switch gameState {
                    case .waiting:
                        startScreenView
                    case .playing:
                        gamePlayView(geometry: geometry)
                    case .gameOver:
                        gameOverView
                }
            }
            .onAppear {
                screenWidth = geometry.size.width
                screenHeight = geometry.size.height
            }
            .onDisappear {
                cleanupTimers()
            }
            .onChange(of: appState.shouldPauseGame) { shouldPause in
                if shouldPause {
                    pauseGame()
                } else {
                    resumeGame()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            skyGradient
            atmosphericOverlay
            backgroundClouds
            foregroundClouds
            floatingParticles
        }
    }
    
    // MARK: - Background Components
    private var skyGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.4, green: 0.7, blue: 1.0), // Bright sky blue
                Color(red: 0.3, green: 0.8, blue: 1.0), // Lighter blue
                Color(red: 0.7, green: 0.9, blue: 1.0), // Very light blue
                Color(red: 0.9, green: 0.95, blue: 1.0) // Almost white
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var atmosphericOverlay: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.clear
            ]),
            center: .topTrailing,
            startRadius: 50,
            endRadius: 300
        )
        .ignoresSafeArea()
    }
    
    private var backgroundClouds: some View {
        ForEach(0..<3) { i in
            cloudShape(size: .large, opacity: 0.25)
                .offset(
                    x: CGFloat(i * 150) - 100,
                    y: 60 + CGFloat(i * 30)
                )
        }
    }
    
    private var foregroundClouds: some View {
        ForEach(0..<4) { i in
            cloudShape(size: .medium, opacity: 0.35)
                .offset(
                    x: CGFloat(i * 100) - 50,
                    y: 120 + CGFloat(i * 40)
                )
        }
    }
    
    // MARK: - Cloud Shape Helper
    private func cloudShape(size: CloudSize, opacity: Double) -> some View {
        ZStack {
            // Main cloud body
            Circle()
                .fill(.white.opacity(opacity))
                .frame(width: size.mainSize, height: size.mainSize)
                .blur(radius: size.mainBlur)
            
            // Left puff
            Circle()
                .fill(.white.opacity(opacity * 0.8))
                .frame(width: size.puffSize, height: size.puffSize)
                .offset(x: -size.offset, y: size.verticalOffset)
                .blur(radius: size.puffBlur)
            
            // Right puff
            Circle()
                .fill(.white.opacity(opacity * 0.8))
                .frame(width: size.puffSize, height: size.puffSize)
                .offset(x: size.offset, y: size.verticalOffset)
                .blur(radius: size.puffBlur)
            
            // Top puff
            Circle()
                .fill(.white.opacity(opacity * 0.9))
                .frame(width: size.topSize, height: size.topSize)
                .offset(x: 0, y: -size.topOffset)
                .blur(radius: size.topBlur)
            
            // Additional volumetric details - small wispy circles
            ForEach(Array(0..<size.wispCount), id: \.self) { i in
                Circle()
                    .fill(.white.opacity(opacity * Double.random(in: 0.2...0.6)))
                    .frame(width: size.wispSize, height: size.wispSize)
                    .offset(
                        x: CGFloat.random(in: -size.wispRange...size.wispRange),
                        y: CGFloat.random(in: -size.wispRange*0.8...size.wispRange*0.8)
                    )
                    .blur(radius: Double.random(in: size.wispBlurMin...size.wispBlurMax))
            }
            
            // Large clouds get extra structural elements
            if case .large = size {
                // Additional side volume puffs for large clouds
                Circle()
                    .fill(.white.opacity(opacity * 0.7))
                    .frame(width: 45, height: 45)
                    .offset(x: -55, y: -10)
                    .blur(radius: 1.8)
                
                Circle()
                    .fill(.white.opacity(opacity * 0.75))
                    .frame(width: 40, height: 40)
                    .offset(x: 60, y: 5)
                    .blur(radius: 1.6)
                
                // Extra top volume for towering effect
                Circle()
                    .fill(.white.opacity(opacity * 0.65))
                    .frame(width: 35, height: 35)
                    .offset(x: -15, y: -40)
                    .blur(radius: 2.0)
                
                Circle()
                    .fill(.white.opacity(opacity * 0.6))
                    .frame(width: 28, height: 28)
                    .offset(x: 20, y: -35)
                    .blur(radius: 1.8)
            }
            
            // Medium detail puffs for more volume
            Circle()
                .fill(.white.opacity(opacity * 0.6))
                .frame(width: size.mediumSize, height: size.mediumSize)
                .offset(x: -size.offset * 0.6, y: -size.verticalOffset * 1.5)
                .blur(radius: size.mediumBlur)
            
            Circle()
                .fill(.white.opacity(opacity * 0.65))
                .frame(width: size.mediumSize * 0.8, height: size.mediumSize * 0.8)
                .offset(x: size.offset * 0.7, y: -size.verticalOffset * 0.5)
                .blur(radius: size.mediumBlur * 1.2)
            
            // Bottom volume puffs
            Circle()
                .fill(.white.opacity(opacity * 0.5))
                .frame(width: size.bottomSize, height: size.bottomSize)
                .offset(x: -size.offset * 0.3, y: size.verticalOffset * 2)
                .blur(radius: size.bottomBlur)
            
            Circle()
                .fill(.white.opacity(opacity * 0.55))
                .frame(width: size.bottomSize * 0.9, height: size.bottomSize * 0.9)
                .offset(x: size.offset * 0.4, y: size.verticalOffset * 1.8)
                .blur(radius: size.bottomBlur * 0.9)
            
            // Small decorative puffs (original ones)
            Circle()
                .fill(.white.opacity(opacity * 0.6))
                .frame(width: size.smallSize, height: size.smallSize)
                .offset(x: size.smallOffset, y: -size.smallVertical)
                .blur(radius: size.smallBlur)
            
            Circle()
                .fill(.white.opacity(opacity * 0.6))
                .frame(width: size.smallSize, height: size.smallSize)
                .offset(x: -size.smallOffset * 0.7, y: size.smallVertical)
                .blur(radius: size.smallBlur)
        }
        // Overall blur scaled to cloud size
        .blur(radius: size.overallBlur)
    }
    
    private var floatingParticles: some View {
        ForEach(0..<6) { i in
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: 4)
                .offset(
                    x: CGFloat(i * 60) - 150,
                    y: CGFloat(200 + i * 50)
                )
        }
    }
    
    // MARK: - Start Screen
    private var startScreenView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("🎈")
                    .font(.system(size: 80))
                    .scaleEffect(animateNewRound ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateNewRound)
                
                LocalizedText("成語氣球遊戲")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2)
                
                LocalizedText("在\(selectedDuration/60)分鐘內答對最多成語！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                // Duration Selection
                VStack(spacing: 10) {
                    LocalizedText("選擇遊戲時間")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                    
                    HStack(spacing: 15) {
                        ForEach(durationOptions, id: \.0) { duration, label in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDuration = duration
                                }
                            }) {
                                Text(label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedDuration == duration ? .black : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedDuration == duration ? 
                                                  LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), 
                                                               startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(gradient: Gradient(colors: [.clear, .clear]), 
                                                               startPoint: .leading, endPoint: .trailing))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                            )
                                    )
                                    .scaleEffect(selectedDuration == duration ? 1.1 : 1.0)
                            }
                        }
                    }
                }
                
                Button(action: startGame) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        LocalizedText("開始遊戲")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .scaleEffect(animateNewRound ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateNewRound = true
            }
        }
    }
    
    
    // MARK: - Game Play View
    private func gamePlayView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Current balloons layer with fade-in animation
            ForEach(balloons) { balloon in
                BalloonView(
                    balloon: balloon,
                    screenHeight: geometry.size.height,
                    onTap: { id, isCorrect in
                        handleTap(id: id, isCorrect: isCorrect)
                    }
                )
                .opacity(roundActive ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.5), value: roundActive)
            }
            
            // UI Overlays
            VStack {
                // Top HUD
                gameHUD
                
                // Additional spacing to prevent balloon overlap
                Spacer()
                    .frame(height: 80)
                
                Spacer()
                
                // Bottom explanation area
                explanationArea
                
                // Quit Game Button
                Button(action: {
                    appState.isGameInProgress = false
                    appState.shouldPauseGame = false
                    gameState = .waiting
                    cleanupTimers()
                    balloons.removeAll()
                    isPaused = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                        LocalizedText("退出遊戲")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.red.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 10)
            }
            
            // Confetti
            if showConfetti {
                ConfettiView(sourcePosition: balloonStartPosition)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            showConfetti = false
                        }
                    }
            }
            
            // Success Text Animation
            if showSuccessText {
                VStack {
                    Spacer()
                    
                    Text("🎉 Correct! 🎉")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        .scaleEffect(successTextScale)
                        .opacity(successTextOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                successTextScale = 1.2
                                successTextOpacity = 1.0
                            }
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.2)) {
                                successTextScale = 1.0
                            }
                            
                            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                                successTextOpacity = 0.0
                                successTextScale = 0.8
                            }
                        }
                    
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
            
            // Flying Balloon Effect
            if showBalloonEffect {
                let currentPosition = CGPoint(
                    x: balloonStartPosition.x + (balloonEndPosition.x - balloonStartPosition.x) * balloonFlyProgress,
                    y: balloonStartPosition.y + (balloonEndPosition.y - balloonStartPosition.y) * balloonFlyProgress
                )
                
                Text("🎈")
                    .font(.system(size: 30))
                    .scaleEffect(balloonScale)
                    .opacity(balloonOpacity)
                    .position(currentPosition)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            balloonOpacity = 1.0
                            balloonScale = 1.2
                        }
                        
                        withAnimation(.easeOut(duration: 0.8)) {
                            balloonFlyProgress = 1.0
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                            balloonScale = 0.8
                        }
                        
                        withAnimation(.easeOut(duration: 0.2).delay(0.8)) {
                            balloonOpacity = 0.0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showBalloonEffect = false
                            balloonFlyProgress = 0.0
                            balloonScale = 1.0
                            balloonOpacity = 0.0
                        }
                    }
            }
            
            // Wrong Answer Effect
            if showWrongAnswerEffect {
                ZStack {
                    // Red flash overlay
                    Rectangle()
                        .fill(.red.opacity(0.3))
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.2), value: showWrongAnswerEffect)
                    
                    // Wrong answer feedback
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 10) {
                                Text("❌")
                                    .font(.system(size: 50))
                                    .scaleEffect(wrongAnswerShake ? 1.2 : 1.0)
                                
                                LocalizedText("答錯了！")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: .red, radius: 3)
                            }
                            .offset(x: wrongAnswerShake ? -10 : 0)
                            .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: wrongAnswerShake)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
                .onAppear {
                    withAnimation {
                        wrongAnswerShake = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showWrongAnswerEffect = false
                        wrongAnswerShake = false
                    }
                }
            }
            
            // Pause Overlay
            if isPaused {
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("⏸️")
                            .font(.system(size: 60))
                        
                        LocalizedText("遊戲暫停")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        LocalizedText("回到遊戲頁面繼續")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Game HUD
    private var gameHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                LocalizedText("第 \(currentRound) 回合")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
                if roundActive {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.yellow)
                        LocalizedText("\(roundTimeRemaining)秒")
                            .font(.headline)
                            .foregroundColor(roundTimeRemaining <= 3 ? .red : .yellow)
                            .fontWeight(.bold)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                HStack {
                    Text("🎈")
                        .font(.title2)
                    LocalizedText("\(correctAnswers)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.5), radius: 2)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    LocalizedText(formattedTimeRemaining)
                        .font(.subheadline)
                        .foregroundColor(gameTimeRemaining <= 10 ? .red : .white)
                        .fontWeight(.medium)
                }
                .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Explanation Area
    private var explanationArea: some View {
        VStack(spacing: 10) {
            if let correctIdiom = correctIdiom {
                LocalizedText("找出這個成語:")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                
                VStack(alignment: .leading, spacing: 8) {
                    LocalizedText((correctIdiom.value(forKey: "explanation") as? String ?? "").localized)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
            } else {
                LocalizedText("載入中...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.black.opacity(0.4))
                .blur(radius: 1)
        )
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("🎈")
                    .font(.system(size: 60))
                
                LocalizedText("遊戲結束!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            VStack(spacing: 15) {
                HStack {
                    VStack {
                        LocalizedText("收集氣球")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Text("\(correctAnswers)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("🎈")
                                .font(.system(size: 30))
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        LocalizedText("答對題數")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(correctAnswers)/\(totalRounds)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                let accuracy = totalRounds > 0 ? (Double(correctAnswers) / Double(totalRounds) * 100) : 0
                LocalizedText("準確率: \(Int(accuracy))%")
                    .font(.title3)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 10)
            )
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: restartGame) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        LocalizedText("再玩一次")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { 
                    appState.isGameInProgress = false // Disable pause system
                    appState.shouldPauseGame = false
                    dismiss() 
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        LocalizedText("返回主頁")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.3))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
    
    
    // MARK: - Game Logic Methods
    
    private func startGame() {
        gameState = .playing
        appState.isGameInProgress = true // Enable pause system
        score = 0
        currentRound = 1
        correctAnswers = 0
        totalRounds = 0
        gameTimeRemaining = selectedDuration  // Use selected duration
        
        // Start main game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if gameTimeRemaining > 0 {
                gameTimeRemaining -= 1
            } else {
                endGame()
            }
        }
        
        loadNewRound()
    }
    
    private func restartGame() {
        cleanupTimers()
        appState.isGameInProgress = false // Disable pause system
        appState.shouldPauseGame = false
        gameState = .waiting
        balloons.removeAll()
        currentIdioms.removeAll()
        correctIdiom = nil
        animateNewRound = false
        isPaused = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.animateNewRound = true
            }
        }
    }
    
    private func endGame() {
        cleanupTimers()
        appState.isGameInProgress = false // Disable pause system
        appState.shouldPauseGame = false
        roundActive = false
        gameState = .gameOver
        isPaused = false
        
        // Save high score if needed
        let currentHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "HighScore")
        }
    }
    
    private func loadNewRound() {
        // Don't stop timers - keep them running for faster transitions
        balloons.removeAll()
        currentIdioms.removeAll()
        correctIdiom = nil
        userInteractedThisRound = false
        roundActive = false  // Start as false for fade-in animation
        roundTimeRemaining = Int(roundDuration)
        totalRounds += 1
        
        // Load 4 random idioms from Core Data
        loadRandomIdioms { idioms in
            guard idioms.count >= 4 else {
                print("Not enough idioms loaded")
                return
            }
            
            DispatchQueue.main.async {
                self.currentIdioms = Array(idioms.prefix(4))
                self.correctIdiom = self.currentIdioms.randomElement()
                self.createBalloonsForRound()
                self.startRoundTimer()
                
                // Enable round and trigger fade-in animation
                withAnimation(.easeIn(duration: 0.5)) {
                    self.roundActive = true
                }
            }
        }
    }
    
    private func loadRandomIdioms(completion: @escaping ([NSManagedObject]) -> Void) {
        let context = CoreDataManager.shared.context
        
        DispatchQueue.global(qos: .userInitiated).async {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
            
            do {
                let totalCount = try context.count(for: request)
                guard totalCount >= 4 else {
                    completion([])
                    return
                }
                
                // Get random idioms
                var randomIdioms: [NSManagedObject] = []
                var attempts = 0
                let maxAttempts = 20
                
                while randomIdioms.count < 4 && attempts < maxAttempts {
                    let randomOffset = Int.random(in: 0..<(totalCount - 4))
                    request.fetchOffset = randomOffset
                    request.fetchLimit = 8 // Fetch more to ensure uniqueness
                    
                    let results = try context.fetch(request)
                    
                    for result in results {
                        if randomIdioms.count < 4 && !randomIdioms.contains(where: { 
                            ($0.value(forKey: "word") as? String) == (result.value(forKey: "word") as? String)
                        }) {
                            randomIdioms.append(result)
                        }
                    }
                    attempts += 1
                }
                
                completion(randomIdioms)
            } catch {
                print("Failed to load random idioms: \(error)")
                completion([])
            }
        }
    }
    
    private func createBalloonsForRound() {
        guard !currentIdioms.isEmpty, let correctIdiom = correctIdiom else { return }
        
        // Create answers from the loaded idioms
        var answers: [Answer] = []
        
        for idiom in currentIdioms {
            let word = idiom.value(forKey: "word") as? String ?? ""
            let isCorrect = (idiom.value(forKey: "word") as? String) == (correctIdiom.value(forKey: "word") as? String)
            answers.append(Answer(text: word, isCorrect: isCorrect))
        }
        
        // Shuffle answers
        answers.shuffle()
        
        // Create balloons in single row with alternating heights
        for i in 0..<balloonsPerRound {
            let randomColor = balloonColors.randomElement()!
            
            // Single row layout with alternating heights (low-high-low-high)
            let isHigh = i % 2 == 1  // Odd indices (1, 3) are high
            
            let xPos = screenWidth * (0.15 + CGFloat(i) * 0.18) + CGFloat.random(in: -15...15)
            let baseY = isHigh ? screenHeight * 0.12 : screenHeight * 0.35  // High vs low positions
            
            let randomPhase = Double.random(in: 0...(.pi * 2))
            let randomSize = CGSize(width: CGFloat.random(in: 60...75), height: CGFloat.random(in: 95...115))
            
            let newBalloon = Balloon(
                answer: answers[i],
                color: randomColor,
                yOffset: baseY,
                xPosition: xPos,
                phase: randomPhase,
                baseYOffset: baseY,
                size: randomSize
            )
            balloons.append(newBalloon)
        }
        
        startBobbingAnimation()
    }
    
    private func startRoundTimer() {
        roundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.roundTimeRemaining > 0 {
                self.roundTimeRemaining -= 1
            } else {
                self.endRoundDueToTimeout()
            }
        }
    }
    
    private func startBobbingAnimation() {
        bobbingTimer?.invalidate()
        // Use 30fps instead of 60fps for better performance while still smooth
        bobbingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            let currentTime = Date().timeIntervalSince1970
            
            // Batch update balloons for better performance
            var indices: [Int] = []
            for index in self.balloons.indices {
                if !self.balloons[index].isTapped {
                    indices.append(index)
                }
            }
            
            // Update positions in batch
            for index in indices {
                self.balloons[index].yOffset = self.balloons[index].baseYOffset + 
                    sin(currentTime * 2 + self.balloons[index].phase) * 10
                self.balloons[index].xOffset = 
                    sin(currentTime * 1.2 + self.balloons[index].phase) * 6
            }
        }
    }
    
    private func handleTap(id: UUID, isCorrect: Bool) {
        guard roundActive else { return }
        
        userInteractedThisRound = true
        roundActive = false
        
        if let index = balloons.firstIndex(where: { $0.id == id }) {
            balloons[index].isTapped = true
            
            if isCorrect {
                score += 10
                correctAnswers += 1
                showConfetti = true
                showSuccessText = true
                
                // Reset success text state for next time
                successTextScale = 0.5
                successTextOpacity = 0.0
                
                // Hide success text after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSuccessText = false
                }
                
                // Trigger balloon flying effect
                balloonStartPosition = CGPoint(x: balloons[index].xPosition, y: balloons[index].yOffset)
                // Calculate HUD balloon position (approximate)
                balloonEndPosition = CGPoint(x: screenWidth - 80, y: 80) 
                showBalloonEffect = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                // Wrong answer effects
                showWrongAnswerEffect = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
                // Additional impact feedback for wrong answers
                let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                impactGenerator.impactOccurred()
            }
            
            cleanupRoundTimers()
            
            // Delay fly-away animation for wrong answers to show effect
            let delay = isCorrect ? 0.0 : 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.flyAwayAllBalloons()
            }
        }
    }
    
    private func flyAwayAllBalloons() {
        // Simple fade out animation for current balloons
        withAnimation(.easeOut(duration: 0.8)) {
            for index in balloons.indices {
                balloons[index].isTapped = true
            }
        }
        
        // Prepare next round after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if self.gameTimeRemaining > 0 {
                self.transitionToNextRound()
            } else {
                self.endGame()
            }
        }
    }
    
    private func transitionToNextRound() {
        // Clear current balloons
        balloons.removeAll()
        
        // Update game state
        currentRound += 1
        roundActive = false  // Start as false for fade-in animation
        roundTimeRemaining = Int(roundDuration)
        userInteractedThisRound = false
        
        // Load new round directly with fade-in animation
        loadNewRound()
    }
    
    private func endRoundDueToTimeout() {
        roundActive = false
        cleanupRoundTimers()
        flyAwayAllBalloons()
    }
    
    private func cleanupRoundTimers() {
        roundTimer?.invalidate()
        bobbingTimer?.invalidate()
    }
    
    private func cleanupTimers() {
        gameTimer?.invalidate()
        roundTimer?.invalidate()
        bobbingTimer?.invalidate()
        flyAwayTimer?.invalidate()
    }
    
    private func pauseGame() {
        guard gameState == .playing else { return }
        
        isPaused = true
        
        // Pause all timers
        gameTimer?.invalidate()
        roundTimer?.invalidate()
        bobbingTimer?.invalidate()
        flyAwayTimer?.invalidate()
    }
    
    private func resumeGame() {
        guard gameState == .playing && isPaused else { return }
        
        isPaused = false
        
        // Resume game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.gameTimeRemaining > 0 {
                self.gameTimeRemaining -= 1
            } else {
                self.endGame()
            }
        }
        
        // Resume round timer if round is active
        if roundActive {
            roundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if self.roundTimeRemaining > 0 {
                    self.roundTimeRemaining -= 1
                } else {
                    self.endRoundDueToTimeout()
                }
            }
        }
        
        // Resume bobbing animation
        startBobbingAnimation()
    }
}
