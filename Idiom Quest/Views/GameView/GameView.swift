//
//  GameView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import SwiftUI
import CoreData

// MARK: - Game States
enum GameState {
    case waiting
    case playing
    case gameOver
}

// MARK: - Game View
struct GameView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // Game State
    @State private var gameState: GameState = .waiting
    @State private var balloons: [Balloon] = []
    @State private var nextRoundBalloons: [Balloon] = []
    @State private var currentIdioms: [NSManagedObject] = []
    @State private var nextRoundIdioms: [NSManagedObject] = []
    @State private var correctIdiom: NSManagedObject?
    @State private var nextCorrectIdiom: NSManagedObject?
    @State private var showConfetti = false
    @State private var showTransition = false
    
    // Scoring & Progress
    @State private var score = 0
    @State private var currentRound = 1
    @State private var correctAnswers = 0
    @State private var totalRounds = 0
    
    // Timers
    @State private var gameTimer: Timer?
    @State private var roundTimer: Timer?
    @State private var bobbingTimer: Timer?
    @State private var flyAwayTimer: Timer?
    @State private var gameTimeRemaining = 60  // 1 minute game
    @State private var roundTimeRemaining = 8   // 8 seconds per round
    
    // UI State
    @State private var roundActive = false
    @State private var userInteractedThisRound = false
    @State private var screenWidth: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    @State private var animateNewRound = false
    @State private var showWrongAnswerEffect = false
    @State private var wrongAnswerShake = false
    @State private var showCoinEffect = false
    @State private var coinPosition: CGPoint = .zero
    @State private var coinSpin: Double = 0
    @State private var coinScale: CGFloat = 1.0
    @State private var coinOpacity: Double = 0.0
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
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.cyan.opacity(0.6),
                    Color.white.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated clouds
            ForEach(0..<4) { i in
                Ellipse()
                    .fill(.white.opacity(0.3))
                    .frame(
                        width: CGFloat.random(in: 80...150),
                        height: CGFloat.random(in: 30...50)
                    )
                    .offset(
                        x: CGFloat(i * 100) + sin(Date().timeIntervalSince1970 * 0.3 + Double(i)) * 30,
                        y: 80 + CGFloat(i * 40)
                    )
                    .animation(
                        .linear(duration: 25).repeatForever(autoreverses: false),
                        value: Date().timeIntervalSince1970
                    )
            }
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
                
                LocalizedText("在60秒內答對最多成語！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                HStack(spacing: 20) {
                    VStack {
                        Text("⏱️")
                            .font(.title)
                        LocalizedText("60秒")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text("🪙")
                            .font(.title)
                        LocalizedText("答對+10金幣")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text("🎈")
                            .font(.title)
                        LocalizedText("4個選項")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.white.opacity(0.2))
                        .blur(radius: 1)
                )
                
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
            
            Button(action: { 
                appState.isGameInProgress = false // Disable pause system
                appState.shouldPauseGame = false
                dismiss() 
            }) {
                HStack {
                    Image(systemName: "xmark")
                    LocalizedText("返回")
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
            // Current balloons layer
            ForEach(balloons) { balloon in
                BalloonView(
                    balloon: balloon,
                    screenHeight: geometry.size.height,
                    onTap: { id, isCorrect in
                        handleTap(id: id, isCorrect: isCorrect)
                    }
                )
            }
            
            // Next round balloons (flying in from bottom)
            if showTransition {
                ForEach(nextRoundBalloons) { balloon in
                    BalloonView(
                        balloon: balloon,
                        screenHeight: geometry.size.height,
                        onTap: { _, _ in } // No interaction during transition
                    )
                }
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
            }
            
            // Confetti
            if showConfetti {
                ConfettiView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showConfetti = false
                        }
                    }
            }
            
            // Mario Coin Effect
            if showCoinEffect {
                VStack(spacing: 8) {
                    // Spinning coin
                    Text("🪙")
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(coinSpin))
                        .scaleEffect(coinScale)
                        .opacity(coinOpacity)
                        .animation(.easeInOut(duration: 0.6), value: coinSpin)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: coinScale)
                    
                    // +10 Coins text
                    HStack(spacing: 4) {
                        Text("+10")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("🪙")
                            .font(.title3)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .scaleEffect(coinScale)
                    .opacity(coinOpacity)
                }
                .position(coinPosition)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        coinOpacity = 1.0
                        coinScale = 1.3
                    }
                    
                    withAnimation(.linear(duration: 0.6)) {
                        coinSpin = 720 // Two full rotations
                    }
                    
                    withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                        coinScale = 0.8
                    }
                    
                    withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
                        coinOpacity = 0.0
                        coinScale = 1.5
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showCoinEffect = false
                        coinSpin = 0
                        coinScale = 1.0
                        coinOpacity = 0.0
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
                    Text("🪙")
                        .font(.title2)
                    LocalizedText("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.5), radius: 2)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    LocalizedText("\(gameTimeRemaining)秒")
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
                        LocalizedText("最終金幣")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Text("\(score)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("🪙")
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
        gameTimeRemaining = 60
        
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
        nextRoundBalloons.removeAll()
        currentIdioms.removeAll()
        correctIdiom = nil
        animateNewRound = false
        showTransition = false
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
        nextRoundBalloons.removeAll()
        currentIdioms.removeAll()
        correctIdiom = nil
        userInteractedThisRound = false
        roundActive = true
        roundTimeRemaining = Int(roundDuration)
        totalRounds += 1
        showTransition = false
        
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
        
        // Create balloons
        for i in 0..<balloonsPerRound {
            let randomColor = balloonColors.randomElement()!
            let xPos = CGFloat(i) * (screenWidth / CGFloat(balloonsPerRound)) + (screenWidth / CGFloat(balloonsPerRound) / 2)
            let randomPhase = Double.random(in: 0...(.pi * 2))
            let randomSize = CGSize(width: CGFloat.random(in: 60...75), height: CGFloat.random(in: 95...115))
            let baseY = screenHeight * 0.15 + CGFloat.random(in: -20...20)
            
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
                
                // Trigger coin effect at balloon position
                coinPosition = CGPoint(x: balloons[index].xPosition, y: balloons[index].yOffset)
                showCoinEffect = true
                
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
        // Prepare next round balloons if game continues
        if gameTimeRemaining > 0 {
            prepareNextRound()
        }
        
        flyAwayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            var balloonsRemaining = false
            
            // Move current balloons up (fly away)
            for index in self.balloons.indices {
                self.balloons[index].isTapped = true
                self.balloons[index].yOffset -= 12
                
                if self.balloons[index].yOffset > -100 {
                    balloonsRemaining = true
                }
            }
            
            // Move next balloons up (fly in) if transitioning
            if self.showTransition {
                for index in self.nextRoundBalloons.indices {
                    self.nextRoundBalloons[index].yOffset -= 8 // Slower for smooth transition
                    
                    // Stop when they reach target position
                    if self.nextRoundBalloons[index].yOffset <= self.nextRoundBalloons[index].baseYOffset {
                        self.nextRoundBalloons[index].yOffset = self.nextRoundBalloons[index].baseYOffset
                    }
                }
            }
            
            if !balloonsRemaining {
                timer.invalidate()
                
                // Transition to next round
                if self.gameTimeRemaining > 0 {
                    self.transitionToNextRound()
                } else {
                    self.endGame()
                }
            }
        }
    }
    
    private func prepareNextRound() {
        // Load next round data
        loadRandomIdioms { idioms in
            guard idioms.count >= 4 else { return }
            
            DispatchQueue.main.async {
                let nextIdioms = Array(idioms.prefix(4))
                let nextCorrectIdiom = nextIdioms.randomElement()
                
                // Create next round balloons starting from bottom of screen
                self.createNextRoundBalloons(idioms: nextIdioms, correctIdiom: nextCorrectIdiom)
                self.showTransition = true
            }
        }
    }
    
    private func createNextRoundBalloons(idioms: [NSManagedObject], correctIdiom: NSManagedObject?) {
        guard let correctIdiom = correctIdiom else { return }
        
        nextRoundBalloons.removeAll()
        
        // Store next round data for later use
        self.nextRoundIdioms = idioms
        self.nextCorrectIdiom = correctIdiom
        
        // Create answers
        var answers: [Answer] = []
        for idiom in idioms {
            let word = idiom.value(forKey: "word") as? String ?? ""
            let isCorrect = (idiom.value(forKey: "word") as? String) == (correctIdiom.value(forKey: "word") as? String)
            answers.append(Answer(text: word, isCorrect: isCorrect))
        }
        answers.shuffle()
        
        // Create balloons starting from bottom
        for i in 0..<balloonsPerRound {
            let randomColor = balloonColors.randomElement()!
            let xPos = CGFloat(i) * (screenWidth / CGFloat(balloonsPerRound)) + (screenWidth / CGFloat(balloonsPerRound) / 2)
            let randomPhase = Double.random(in: 0...(.pi * 2))
            let randomSize = CGSize(width: CGFloat.random(in: 60...75), height: CGFloat.random(in: 95...115))
            let targetY = screenHeight * 0.15 + CGFloat.random(in: -20...20)
            
            let newBalloon = Balloon(
                answer: answers[i],
                color: randomColor,
                yOffset: screenHeight + 100, // Start below screen
                xPosition: xPos,
                phase: randomPhase,
                baseYOffset: targetY, // Target position
                size: randomSize
            )
            nextRoundBalloons.append(newBalloon)
        }
    }
    
    private func transitionToNextRound() {
        // Replace current balloons with next round balloons
        balloons = nextRoundBalloons
        currentIdioms = nextRoundIdioms
        correctIdiom = nextCorrectIdiom
        nextRoundBalloons.removeAll()
        showTransition = false
        
        // Update game state
        currentRound += 1
        roundActive = true
        roundTimeRemaining = Int(roundDuration)
        userInteractedThisRound = false
        
        // Start new round timer and animations
        startRoundTimer()
        startBobbingAnimation()
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

extension Color {
    static let skyblue = Color(red: 0.5, green: 0.8, blue: 1.0)
}
