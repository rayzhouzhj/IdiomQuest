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
    @State private var balloons: [Balloon] = []
    @State private var showConfetti = false
    @State private var score = 0
    @State private var currentRound = 1
    @State private var roundTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var bobbingTimer: Timer?
    @State private var flyAwayTimer: Timer?
    @State private var roundTimeRemaining = 10  // Countdown seconds
    @State private var roundActive = false
    @State private var userInteractedThisRound = false
    @State private var screenWidth: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    let answers: [Answer] = [
        Answer(text: "Correct Answer", isCorrect: true),
        Answer(text: "Wrong 1", isCorrect: false),
        Answer(text: "Wrong 2", isCorrect: false),
        Answer(text: "Wrong 3", isCorrect: false)
    ]
    
    let balloonColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    let balloonsPerRound = 4
    let roundDuration: TimeInterval = 10.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky background with clouds
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.skyblue.opacity(0.9), .white.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ForEach(0..<3) { i in
                        Ellipse()
                            .fill(.white.opacity(0.3))
                            .frame(width: CGFloat.random(in: 80...150), height: 40)
                            .offset(x: CGFloat(i * 120) + sin(Date().timeIntervalSince1970 * 0.5 + Double(i)) * 20, y: 100 + CGFloat(i * 50))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: Date().timeIntervalSince1970)
                    }
                }
                
                // Balloons layer
                ForEach(balloons) { balloon in
                    BalloonView(
                        balloon: balloon,
                        screenHeight: geometry.size.height,
                        onTap: { id, isCorrect in
                            handleTap(id: id, isCorrect: isCorrect)
                        }
                    )
                }
                
                // UI Overlays
                VStack {
                    // Score, Round, and Countdown at top
                    HStack {
                        VStack(alignment: .leading) {
                            LocalizedText("Round: \(currentRound)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                            if roundActive {
                                LocalizedText("Time: \(roundTimeRemaining)s")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            }
                        }
                        Spacer()
                        LocalizedText("Score: \(score)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.3))
                            .blur(radius: 2)
                    )
                    .padding(.horizontal)
                    
                    if roundActive && balloons.count == 0 {
                        LocalizedText("Round Complete! Starting next...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.black.opacity(0.3))
                                    .blur(radius: 2)
                            )
                    }
                    
                    Spacer()
                    
                    // Tips at bottom
                    LocalizedText("Tip: Tap the balloon with the correct answer to score +10! Wrong answers deduct 5 points.")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.black.opacity(0.3))
                                .blur(radius: 2)
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                
                // Confetti
                if showConfetti {
                    ConfettiView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showConfetti = false
                            }
                        }
                }
            }
            .onAppear {
                screenWidth = geometry.size.width
                screenHeight = geometry.size.height
                startNewRound()
            }
            .onDisappear {
                roundTimer?.invalidate()
                countdownTimer?.invalidate()
                bobbingTimer?.invalidate()
                flyAwayTimer?.invalidate()
            }
        }
    }
    
    private func startNewRound() {
        // Invalidate existing timers
        roundTimer?.invalidate()
        countdownTimer?.invalidate()
        bobbingTimer?.invalidate()
        flyAwayTimer?.invalidate()
        
        // Reset state
        balloons.removeAll()
        userInteractedThisRound = false
        roundActive = true
        roundTimeRemaining = 10
        
        // Spawn balloons near top
        let shuffledAnswers = answers.shuffled()
        for i in 0..<balloonsPerRound {
            let randomColor = balloonColors.randomElement()!
            let xPos = CGFloat(i) * (screenWidth / CGFloat(balloonsPerRound)) + (screenWidth / CGFloat(balloonsPerRound) / 2)
            let randomPhase = Double.random(in: 0...(.pi * 2))
            let randomSize = CGSize(width: CGFloat.random(in: 55...70), height: CGFloat.random(in: 90...110))
            let baseY = screenHeight * 0.15  // Start just below score (15% from top)
            
            let newBalloon = Balloon(
                answer: shuffledAnswers[i % shuffledAnswers.count],
                color: randomColor,
                yOffset: baseY,
                xPosition: xPos,
                phase: randomPhase,
                baseYOffset: baseY,
                size: randomSize
            )
            balloons.append(newBalloon)
            print("Spawned balloon \(i) at x: \(xPos), y: \(baseY)")
        }
        
        // Start countdown timer (1-second intervals)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if roundTimeRemaining > 0 {
                roundTimeRemaining -= 1
            } else {
                endRoundDueToTimeout()
            }
        }
        
        // Start 10-second round timer (for precision, but countdown handles display)
        roundTimer = Timer.scheduledTimer(withTimeInterval: roundDuration, repeats: false) { _ in
            endRoundDueToTimeout()
        }
        
        // Start bobbing animation
        startBobbingAnimation()
    }
    
    private func startBobbingAnimation() {
        bobbingTimer?.invalidate()
        bobbingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            let currentTime = Date().timeIntervalSince1970
            
            for index in balloons.indices {
                if !balloons[index].isTapped {
                    balloons[index].yOffset = balloons[index].baseYOffset + sin(currentTime * 2 + balloons[index].phase) * 15  // Smaller amplitude
                    balloons[index].xOffset = sin(currentTime * 1 + balloons[index].phase) * 10
                }
            }
        }
    }
    
    private func handleTap(id: UUID, isCorrect: Bool) {
        userInteractedThisRound = true
        if let index = balloons.firstIndex(where: { $0.id == id }) {
            balloons[index].isTapped = true
            
            if isCorrect {
                score += 10
                showConfetti = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                score -= 5
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            
            // Invalidate timers and fly away all balloons (including tapped one)
            roundTimer?.invalidate()
            countdownTimer?.invalidate()
            bobbingTimer?.invalidate()
            
            // Fly away remaining balloons
            flyAwayAllBalloons()
        }
    }
    
    private func flyAwayAllBalloons() {
        flyAwayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            for index in balloons.indices.reversed() {
                balloons[index].isTapped = true  // Stop bobbing
                balloons[index].yOffset -= 5  // Fly upward
                if balloons[index].yOffset < -100 {
                    balloons.remove(at: index)
                }
            }
            if balloons.isEmpty {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  // Delay before next round
                    currentRound += 1
                    startNewRound()
                }
            }
        }
    }
    
    private func endRoundDueToTimeout() {
        print("Timeout: Flying away balloons")
        roundTimer?.invalidate()
        countdownTimer?.invalidate()
        bobbingTimer?.invalidate()
        
        flyAwayAllBalloons()  // Reuse fly-away logic
    }
}


//struct GameViewOld: View {
//    @Environment(\.managedObjectContext) private var context
//    @State private var explanation = ""
//    @State private var correctWord = ""
//    @State private var balloonWords: [String] = []
//    @State private var score = 0
//    @State private var timeLeft = 60
//    @State private var timer: Timer? = nil
//    @State private var gameActive = false
//    @State private var highScore = UserDefaults.standard.integer(forKey: "highScore")
//    @State private var showGameOver = false
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            LocalizedText("Score: \(score)")
//                .font(.title)
//            
//            LocalizedText("Time: \(timeLeft)")
//                .font(.title)
//                .foregroundColor(timeLeft <= 10 ? .red : .primary)
//            
//            Text(explanation)
//                .font(.body)
//                .multilineTextAlignment(.center)
//                .padding()
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
//                ForEach(Array(balloonWords.enumerated()), id: \.offset) { index, word in
//                    BalloonView(word: word, isCorrect: word == correctWord, onTap: {
//                        tapBalloon(word)
//                    })
//                }
//            }
//            
//            Button(gameActive ? "Stop Game" : "Start Game") {
//                if gameActive {
//                    stopGame()
//                } else {
//                    startGame()
//                }
//            }
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(8)
//        }
//        .navigationTitle("Balloon Game")
//        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
//            if gameActive && timeLeft > 0 {
//                timeLeft -= 1
//                if timeLeft <= 0 {
//                    stopGame()
//                }
//            }
//        }
//        .alert("Game Over", isPresented: $showGameOver) {
//            Button("Play Again") {
//                startGame()
//            }
//        } message: {
//            LocalizedText("Final Score: \(score)\nHigh Score: \(highScore)")
//        }
//    }
//    
//    private func startGame() {
//        gameActive = true
//        score = 0
//        timeLeft = 60
//        loadNextRound()
//    }
//    
//    private func stopGame() {
//        gameActive = false
//        timer?.invalidate()
//        if score > highScore {
//            highScore = score
//            UserDefaults.standard.set(highScore, forKey: "highScore")
//        }
//        showGameOver = true
//    }
//    
//    private func loadNextRound() {
//        let context = CoreDataManager.shared.context
//        let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
//        request.fetchLimit = 5 // Fetch 5 to choose 4
//        do {
//            let idioms = try context.fetch(request).shuffled()
//            if idioms.count >= 5 {
//                correctWord = idioms[0].value(forKey: "word") as? String ?? ""
//                explanation = idioms[0].value(forKey: "explanation") as? String ?? ""
//                balloonWords = idioms.prefix(4).map { $0.value(forKey: "word") as? String ?? "" }.shuffled()
//            }
//        } catch {
//            print("Failed to load idioms: \(error)")
//        }
//    }
//    
//    private func tapBalloon(_ word: String) {
//        if word == correctWord {
//            score += 10
//            loadNextRound()
//        }
//        // Wrong answer: No points, load next
//        loadNextRound()
//    }
//}
