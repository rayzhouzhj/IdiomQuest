//
//  SettingsView.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 22/9/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var languageSettings = LanguageSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateGradient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    headerSection
                    
                    // Language Section
                    languageSection
                    
                    // App Info Section
                    appInfoSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(
                ZStack {
                    // Animated gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.15),
                            Color.purple.opacity(0.15),
                            Color.blue.opacity(0.15)
                        ]),
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
                    
                    // Floating particles effect
                    floatingParticles
                }
            )
        }
        .navigationViewStyle(.stack)
        .onAppear {
            withAnimation {
                animateGradient = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // App Icon with enhanced design
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.2), .purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Inner circle with material
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 65, height: 65)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Icon
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title and Tagline - Centered
            VStack(spacing: 8) {
                LocalizedText("成語探險")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.primary, .blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                LocalizedText("探索中華文化的智慧寶藏")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                LocalizedText("語言偏好")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(.horizontal, 5)
            
            // Language Options
            VStack(spacing: 15) {
                ForEach(PreferredLanguage.allCases, id: \.self) { language in
                    languageOption(language)
                }
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                LocalizedText("應用資訊")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(.horizontal, 5)
            
            // Info Cards
            VStack(spacing: 12) {
                infoCard("版本", AppConstants.appVersion, .blue)
                infoCard("成語數量", AppConstants.idiomCount, .orange)
            }
        }
    }
    
    // MARK: - Floating Particles
    private var floatingParticles: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...40), height: CGFloat.random(in: 20...40))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateGradient
                    )
            }
        }
        .opacity(0.6)
    }
    
    private func languageOption(_ language: PreferredLanguage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                languageSettings.preferredLanguage = language
            }
        }) {
            HStack(spacing: 15) {
                // Language Flag/Icon
                Image(systemName: language == .traditionalChinese ? "flag.fill" : "flag.2.crossed.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: language == .traditionalChinese ? [.red, .orange] : [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Selection Indicator
                if languageSettings.preferredLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(1.2)
                        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                languageSettings.preferredLanguage == language ?
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: languageSettings.preferredLanguage == language ? 2 : 1
                            )
                    )
                    .shadow(
                        color: languageSettings.preferredLanguage == language ? .green.opacity(0.2) : .black.opacity(0.05),
                        radius: languageSettings.preferredLanguage == language ? 10 : 5,
                        x: 0,
                        y: languageSettings.preferredLanguage == language ? 5 : 2
                    )
            )
            .scaleEffect(languageSettings.preferredLanguage == language ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func infoCard(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 15) {
            // Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: getIconForTitle(title))
                        .font(.title2)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                LocalizedText(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                LocalizedText(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
    
    private func getIconForTitle(_ title: String) -> String {
        switch title {
        case "版本", "版本 / Version":
            return "info.circle.fill"
        case "成語數量", "成語數量 / Idiom Count":
            return "book.fill"
        case "開發者", "開發者 / Developer":
            return "person.fill"
        default:
            return "info.circle.fill"
        }
    }
}

#Preview {
    SettingsView()
}
