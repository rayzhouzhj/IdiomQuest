//
//  GameView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 14/9/2025.
//

import SwiftUI
import CoreData

struct GameView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var explanation = ""
    @State private var correctWord = ""
    @State private var balloonWords: [String] = []
    @State private var score = 0
    @State private var timeLeft = 60
    @State private var timer: Timer? = nil
    @State private var gameActive = false
    @State private var highScore = UserDefaults.standard.integer(forKey: "highScore")
    @State private var showGameOver = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Score: \(score)")
                .font(.title)
            
            Text("Time: \(timeLeft)")
                .font(.title)
                .foregroundColor(timeLeft <= 10 ? .red : .primary)
            
            Text(explanation)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                ForEach(Array(balloonWords.enumerated()), id: \.offset) { index, word in
                    BalloonView(word: word, isCorrect: word == correctWord, onTap: {
                        tapBalloon(word)
                    })
                }
            }
            
            Button(gameActive ? "Stop Game" : "Start Game") {
                if gameActive {
                    stopGame()
                } else {
                    startGame()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .navigationTitle("Balloon Game")
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if gameActive && timeLeft > 0 {
                timeLeft -= 1
                if timeLeft <= 0 {
                    stopGame()
                }
            }
        }
        .alert("Game Over", isPresented: $showGameOver) {
            Button("Play Again") {
                startGame()
            }
        } message: {
            Text("Final Score: \(score)\nHigh Score: \(highScore)")
        }
    }
    
    private func startGame() {
        gameActive = true
        score = 0
        timeLeft = 60
        loadNextRound()
    }
    
    private func stopGame() {
        gameActive = false
        timer?.invalidate()
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        showGameOver = true
    }
    
    private func loadNextRound() {
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
        request.fetchLimit = 5 // Fetch 5 to choose 4
        do {
            let idioms = try context.fetch(request).shuffled()
            if idioms.count >= 5 {
                correctWord = idioms[0].value(forKey: "word") as? String ?? ""
                explanation = idioms[0].value(forKey: "explanation") as? String ?? ""
                balloonWords = idioms.prefix(4).map { $0.value(forKey: "word") as? String ?? "" }.shuffled()
            }
        } catch {
            print("Failed to load idioms: \(error)")
        }
    }
    
    private func tapBalloon(_ word: String) {
        if word == correctWord {
            score += 10
            loadNextRound()
        }
        // Wrong answer: No points, load next
        loadNextRound()
    }
}

struct BalloonView: View {
    let word: String
    let isCorrect: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(word)
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(isCorrect ? 0.8 : 0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .scaleEffect(isCorrect ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isCorrect)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
