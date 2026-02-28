//
//  AssessmentResultsView.swift
//  IsItBroken?
//
//  Created for Swift Student Challenge
//

import SwiftUI

struct AssessmentResultsView: View {

    // MARK: - Inputs
    let canBearWeight: Bool
    let palpationResults: [UUID: Bool]
    
    // NOTE: This uses a Mock struct for UI building.
    // If you have a real 'PalpationZone' struct in your data model, replace this.
    var palpationZones: [PalpationZoneMock] = [
        .init(name: "Posterior Edge (Fibula)", anatomyNote: "Lateral Malleolus (6cm)"),
        .init(name: "Posterior Edge (Tibia)", anatomyNote: "Medial Malleolus (6cm)"),
        .init(name: "Base of 5th Metatarsal", anatomyNote: "Lateral Foot"),
        .init(name: "Navicular", anatomyNote: "Medial Foot")
    ]

    // FIX 1: Instead of dismiss(), navigate back to onboarding
    @State private var navigateToOnboarding = false

    // MARK: - Computed Logic
    private var painCount: Int { palpationResults.values.filter { $0 }.count }
    private var requiresXRay: Bool { painCount > 0 || !canBearWeight }
    private var statusColor: Color { requiresXRay ? .painRed : .teal }

    // MARK: - State & Animation
    @State private var heroVisible = false
    @State private var contentVisible = false
    @State private var expandedRice: String? = nil
    @State private var iconPulse = false
    @State private var showConfetti = false

    var body: some View {
        // No NavigationStack here — this view lives inside the parent's existing stack.
        // Adding one here would create a nested stack, causing the spurious back button.
        ZStack(alignment: .top) {
                // Background - Neutral Gradient
                LinearGradient(
                    colors: [Color.appBG, Color(red: 0.93, green: 0.95, blue: 0.99)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Confetti Layer (Only if healthy)
                if !requiresXRay && showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Header / Nav ──
                        headerNav
                            .padding(.top, 8)

                        // ── Hero Card ──
                        heroCard
                            .opacity(heroVisible ? 1 : 0)
                            .offset(y: heroVisible ? 0 : 20)
                            .scaleEffect(heroVisible ? 1 : 0.95)

                        // ── Content Stack ──
                        VStack(spacing: 24) {
                            breakdownSection
                            
                            riceSection
                            
                            disclaimerCard
                        }
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 22)
                }

                // Hidden NavigationLink triggered by back button
                NavigationLink(
                    destination: AssessmentOnboardingScreen()
                        .navigationBarBackButtonHidden(true),
                    isActive: $navigateToOnboarding
                ) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                triggerEntranceAnimations()
                triggerHaptics()
            }
    }

    // MARK: - Header Navigation
    private var headerNav: some View {
        HStack {
            // FIX 1: Back button now navigates to AssessmentOnboardingScreen
            Button {
                navigateToOnboarding = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(.ink)
            }

            Spacer()

            Text("Result")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.ink)
                .offset(x: -20)
            
            Spacer()
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: 0) {
            // Icon & Status
            VStack(spacing: 16) {
                ZStack {
                    // Outer Glow
                    Circle()
                        .fill(Color.teal.opacity(0.10))
                        .frame(width: 100, height: 100)
                        .scaleEffect(iconPulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: iconPulse)

                    // Ring
                    Circle()
                        .strokeBorder(Color.teal.opacity(0.3), lineWidth: 3)
                        .frame(width: 88, height: 88)

                    // Icon
                    Image(systemName: requiresXRay ? "waveform.path.ecg" : "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(statusColor)
                        .symbolEffect(.bounce, value: heroVisible)
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text(requiresXRay ? "X-Ray Recommended" : "Low Fracture Risk")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.ink)

//                    Text(requiresXRay
//                         ? "Pain detected in **\(painCount)** zones based on Ottawa Rules."
//                         : "No bony tenderness detected in the assessment zones.")
//                        .font(.system(size: 15, weight: .medium, design: .rounded))
//                        .foregroundColor(.inkSecondary)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color.teal.opacity(0.04))

            // Stats Row
            HStack(spacing: 0) {
                statCell(value: "\(painCount)", label: "Pain Zones", color: painCount > 0 ? .painRed : .clearGreen)
                Divider().frame(height: 30)
                statCell(value: canBearWeight ? "Yes" : "No", label: "Weight Bear", color: canBearWeight ? .clearGreen : .painRed)
                Divider().frame(height: 30)
                statCell(value: requiresXRay ? "Yes" : "No", label: "X-Ray", color: requiresXRay ? .painRed : .clearGreen)
            }
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 20, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.inkSecondary.opacity(0.6))
                .kerning(0.5) // Slight letter spacing for that "pro" look
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.05)) // Subtle tint background
        .cornerRadius(12)
        .padding(.horizontal, 4)
    }

    // MARK: - Breakdown Section
    private var breakdownSection: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Assessment Breakdown", icon: "list.clipboard")

            VStack(spacing: 10) {
                ResultRow(
                    iconName: canBearWeight ? "figure.walk" : "exclamationmark.triangle.fill",
                    title: "Weight Bearing",
                    subtitle: canBearWeight ? "Able to walk 4 steps" : "Unable to bear weight",
                    badgeLabel: canBearWeight ? "PASS" : "FAIL",
                    badgeColor: canBearWeight ? .clearGreen : .painRed
                )
                
                ForEach(palpationZones) { zone in
                    let hasPain = palpationResults[zone.id] ?? false
                    ResultRow(
                        iconName: hasPain ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                        title: zone.name,
                        subtitle: zone.anatomyNote,
                        badgeLabel: hasPain ? "PAIN" : "CLEAR",
                        badgeColor: hasPain ? .painRed : .clearGreen
                    )
                }
            }
        }
    }

    // MARK: - RICE Section
    private var riceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(requiresXRay ? "First Aid (While waiting)" : "Recovery Protocol", icon: "cross.case.fill")

            VStack(spacing: 12) {
                ForEach(riceSteps, id: \.id) { step in
                    RICEStepCard(
                        step: step,
                        isExpanded: expandedRice == step.id,
                        onTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                expandedRice = expandedRice == step.id ? nil : step.id
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Disclaimer
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.inkSecondary)
            Text("This result is based on the Ottawa Ankle Rules. It is not a medical diagnosis. If pain persists, consult a doctor.")
                .font(.caption)
                .foregroundColor(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(Color.inkSecondary.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.teal))
            
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.inkSecondary)
                .kerning(1.0)
            
            Spacer()
        }
        .padding(.leading, 4)
    }

    private func triggerEntranceAnimations() {
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            heroVisible = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
            contentVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            iconPulse = true
        }
        if !requiresXRay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
    
    private func triggerHaptics() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(requiresXRay ? .warning : .success)
        }
    }
    
    private let riceSteps: [(id: String, letter: String, title: String, icon: String, color: Color, subtitle: String, detail: String)] = [
        ("R", "R", "Rest", "moon.zzz.fill", Color.blue, "Avoid weight bearing", "Stop activity immediately."),
        ("I", "I", "Ice", "snowflake", Color.cyan, "20 min on, 20 min off", "Apply ice to reduce swelling."),
        ("C", "C", "Compression", "bandage.fill", Color.orange, "Wrap snugly", "Use an elastic bandage."),
        ("E", "E", "Elevation", "arrow.up.heart.fill", Color.green, "Above heart level", "Prop ankle up on pillows.")
    ]
}

// MARK: - Supporting Views

struct RICEStepCard: View {
    let step: (id: String, letter: String, title: String, icon: String, color: Color, subtitle: String, detail: String)
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(step.color.opacity(0.10))
                            .frame(width: 46, height: 46)
                        Text(step.letter)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(step.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: step.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(step.color)
                            Text(step.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.ink)
                        }
                        Text(step.subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.inkSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                        .animation(.spring(response: 0.35), value: isExpanded)
                }
                .padding(14)

                if isExpanded {
                    Divider().padding(.horizontal, 14)
                    Text(step.detail)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.inkSecondary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(isExpanded ? 0.07 : 0.04),
                            radius: isExpanded ? 10 : 6, y: isExpanded ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isExpanded ? step.color.opacity(0.32) : Color.divider.opacity(0.7),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// FIX 2: Confetti rewritten so each particle manages its own animation state.
// The old approach passed `startAnimation` as a `let` constant from a parent @State,
// but SwiftUI doesn't re-render ConfettiParticle when that Bool flips because the
// particle is initialized before the state change propagates properly.
// Solution: each particle uses its own @State driven by .onAppear.
struct ConfettiView: View {
    var body: some View {
        ZStack {
            ForEach(0..<25, id: \.self) { i in
                ConfettiParticle(index: i)
            }
        }
    }
}

struct ConfettiParticle: View {
    let index: Int

    // FIX 2: Own animation state — triggered in .onAppear after a staggered delay
    @State private var animate = false

    // Stable random properties (computed once at init time)
    private let xPos: CGFloat
    private let yStart: CGFloat
    private let particleColor: Color
    private let size: CGFloat
    private let duration: Double
    private let delay: Double

    init(index: Int) {
        self.index = index
        xPos      = CGFloat.random(in: -180 ... 180)
        yStart    = CGFloat.random(in: -50 ... 100)   // start near top of screen
        particleColor = [Color.red, Color.blue, Color.green, Color.orange, Color.purple, Color.pink].randomElement()!
        size      = CGFloat.random(in: 6 ... 12)
        duration  = Double.random(in: 1.8 ... 3.2)
        delay     = Double(index) * 0.06
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particleColor)
            .frame(width: size, height: size * 1.6)
            .offset(x: xPos, y: animate ? UIScreen.main.bounds.height + 100 : yStart)
            .opacity(animate ? 0 : 1)
            .rotationEffect(.degrees(animate ? Double.random(in: 180 ... 540) : 0))
            .onAppear {
                // FIX 2: Trigger animation from within the particle itself
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: duration)) {
                        animate = true
                    }
                }
            }
    }
}

struct ResultRow: View {
    let iconName: String, title: String, subtitle: String, badgeLabel: String, badgeColor: Color
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(badgeColor)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.ink)
                Text(subtitle).font(.caption).foregroundColor(.inkSecondary)
            }
            Spacer()
            Text(badgeLabel)
                .font(.system(size: 10, weight: .black))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(badgeColor.opacity(0.12))) // Use Capsule
                .foregroundColor(badgeColor)        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
}

// MARK: - Mock Data
struct PalpationZoneMock: Identifiable {
    let id = UUID()
    let name: String
    let anatomyNote: String
}
