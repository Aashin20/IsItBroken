//
//  AssessmentResultsView.swift
//  IsItBroken?
//
//  Created for Swift Student Challenge
//

import SwiftUI

// MARK: - Result Row Styling Enum
enum FailSeverity {
    case none
    case supporting
    case critical
}

struct AssessmentResultsView: View {

    // MARK: - Inputs
    let canBearWeight: Bool
    let palpationResults: [UUID: Bool]
    let zones: [PalpationZone]
    
    @State private var navigateToOnboarding = false

    // MARK: - Computed Logic
    private var painCount: Int { palpationResults.values.filter { $0 }.count }
    private var requiresXRay: Bool { painCount > 0 || !canBearWeight }
    
    private var statusColor: Color { requiresXRay ? .red : .green }

    // MARK: - State & Animation
    @State private var headerVisible = false
    @State private var heroVisible = false
    @State private var contentVisible = false
    @State private var expandedRice: String? = nil
    @State private var iconPulse = false
    @State private var showConfetti = false

    var body: some View {
            ZStack(alignment: .top) {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if !requiresXRay && showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    headerNav
                        .opacity(headerVisible ? 1 : 0)
                        .padding(.horizontal, 22)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .background(Color(UIColor.systemGroupedBackground))
                        .zIndex(1)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            heroCard
                                .opacity(heroVisible ? 1 : 0)
                                .offset(y: heroVisible ? 0 : 20)
                                .scaleEffect(heroVisible ? 1 : 0.95)

                            VStack(spacing: 28) {
                                breakdownSection
                                riceSection
                                
                                disclaimerCard
                            }
                            .opacity(contentVisible ? 1 : 0)
                            .offset(y: contentVisible ? 0 : 20)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    }
                    .safeAreaInset(edge: .bottom) {
                        if requiresXRay {
                            clinicCTAContainer
                        }
                    }
                }

                NavigationLink(
                    destination: AssessmentOnboardingScreen().navigationBarBackButtonHidden(true),
                    isActive: $navigateToOnboarding
                ) { EmptyView() }
            }
            .navigationBarHidden(true)
            .onAppear {
                triggerEntranceAnimations()
                triggerHaptics()
            }
        }

    // MARK: - Sticky CTA Container
        private var clinicCTAContainer: some View {
            VStack {
                clinicCTAButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color(UIColor.systemGroupedBackground).opacity(0), location: 0),
                        .init(color: Color(UIColor.systemGroupedBackground), location: 0.35),
                        .init(color: Color(UIColor.systemGroupedBackground), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 20)
        }

    // MARK: - Header Navigation
    private var headerNav: some View {
        HStack {
            Button { navigateToOnboarding = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    Text("Back").font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(.primary)
            }
            Spacer()
            Text("Result")
                .font(.headline)
                .offset(x: -20)
            Spacer()
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.08))
                    .frame(width: 88, height: 88)
                    .scaleEffect(iconPulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: iconPulse)

                Image(systemName: requiresXRay ? "cross.case.fill" : "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(statusColor)
                    .symbolEffect(.bounce, value: heroVisible)
            }
            .padding(.top, 32)

            VStack(spacing: 8) {
                Text(requiresXRay ? "An X-ray is recommended" : "Likely No Fracture")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                Text(requiresXRay ? "Based on your responses, it would be safest to get an X-ray." : "Your results suggest a low risk, but monitor for changes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(statusColor.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Breakdown Section
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ASSESSMENT BREAKDOWN")
                .font(.caption)
                .kerning(1.2)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 10) {
                ResultRow(
                    iconName: canBearWeight ? "figure.walk" : "exclamationmark.triangle.fill",
                    title: "Weight Bearing",
                    subtitle: canBearWeight ? "Able to walk 4 steps" : "Unable to bear weight",
                    badgeLabel: canBearWeight ? "PASS" : "FAIL",
                    badgeColor: canBearWeight ? .green : .red,
                    severity: canBearWeight ? .none : .critical
                )
                
                ForEach(zones) { zone in
                    let hasPain = palpationResults[zone.id] ?? false
                    ResultRow(
                        iconName: hasPain ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                        title: zone.shortName,
                        subtitle: zone.anatomyNote,
                        badgeLabel: hasPain ? "PAIN" : "CLEAR",
                        badgeColor: hasPain ? .red : .green,
                        severity: hasPain ? .supporting : .none
                    )
                }
            }
        }
    }

    // MARK: - RICE Section
    private var riceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(requiresXRay ? "FIRST AID" : "RECOVERY PROTOCOL")
                    .font(.caption)
                    .kerning(1.2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                
                if requiresXRay {
                    Text("While waiting for care")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            
            VStack(spacing: 10) {
                ForEach(riceSteps, id: \.id) { step in
                    RICEStepCard(
                        step: step,
                        isExpanded: expandedRice == step.id,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                expandedRice = expandedRice == step.id ? nil : step.id
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - CTA Button
    private var clinicCTAButton: some View {
        Button {
            if let url = URL(string: "maps://?q=medical+clinic+near+me") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.headline)
                Text("Find care near you")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.15), radius: 6, y: 3)
        }
    }
    
    // MARK: - Disclaimer
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.secondary)
            Text("This result is based on the Ottawa Ankle Rules. It is not a medical diagnosis. If pain persists, consult a doctor.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Animations & Data
    private func triggerEntranceAnimations() {
        withAnimation(.easeIn(duration: 0.3)) { headerVisible = true }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { heroVisible = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) { contentVisible = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { iconPulse = true }
        if !requiresXRay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showConfetti = true }
        }
    }
    
    private func triggerHaptics() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.notificationOccurred(requiresXRay ? .warning : .success)
        }
    }
    
    private let riceSteps: [(id: String, letter: String, title: String, icon: String, color: Color, subtitle: String, detail: String)] = [
        ("R", "R", "Rest", "moon.zzz.fill", Color.blue, "Avoid putting weight on your foot.", "Stop activity immediately to prevent further damage."),
        ("I", "I", "Ice", "snowflake", Color.cyan, "20 min on, 20 min off", "Apply ice to reduce swelling. Do not apply directly to skin."),
        ("C", "C", "Compression", "bandage.fill", Color.orange, "Wrap snugly", "Use an elastic bandage to decrease swelling."),
        ("E", "E", "Elevation", "arrow.up.heart.fill", Color.green, "Above heart level", "Prop your ankle up on pillows to help fluid drain away.")
    ]
}

// MARK: - Supporting Views

struct ResultRow: View {
    let iconName: String, title: String, subtitle: String, badgeLabel: String, badgeColor: Color
    let severity: FailSeverity
    
    @State private var badgeAppeared = false
    
    private var rowBackgroundColor: Color {
        switch severity {
        case .critical: return Color.red.opacity(0.10)
        case .supporting: return Color.red.opacity(0.02)
        case .none: return Color.white
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(badgeColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            badgeView
                .scaleEffect(badgeAppeared ? 1.0 : 0.8)
                .opacity(badgeAppeared ? 1.0 : 0.0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(rowBackgroundColor)
        .overlay(
            alignment: .leading,
            content: {
                if severity != .none {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: severity == .critical ? 4 : 2)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                badgeAppeared = true
            }
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        let baseText = Text(badgeLabel).font(.system(size: 11, weight: .bold)).padding(.horizontal, 10).padding(.vertical, 5)
        
        switch severity {
        case .critical:
            baseText
                .background(Capsule().fill(badgeColor))
                .foregroundColor(.white)
        case .supporting:
            baseText
                .background(Capsule().stroke(badgeColor, lineWidth: 1.5))
                .foregroundColor(badgeColor)
        case .none:
            baseText
                .background(Capsule().fill(badgeColor.opacity(0.15)))
                .foregroundColor(badgeColor)
        }
    }
}

struct RICEStepCard: View {
    let step: (id: String, letter: String, title: String, icon: String, color: Color, subtitle: String, detail: String)
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(step.color.opacity(0.10))
                            .frame(width: 40, height: 40)
                        Text(step.letter)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(step.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: step.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(step.color)
                            Text(step.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Text(step.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(step.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                    .padding(.trailing, 16)
                    .padding(.leading, 70)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

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
    @State private var animate = false

    private let xPos: CGFloat
    private let yStart: CGFloat
    private let particleColor: Color
    private let size: CGFloat
    private let duration: Double
    private let delay: Double

    init(index: Int) {
        self.index = index
        xPos      = CGFloat.random(in: -180 ... 180)
        yStart    = CGFloat.random(in: -50 ... 100)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: duration)) {
                        animate = true
                    }
                }
            }
    }
}
