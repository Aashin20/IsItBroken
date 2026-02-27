//
//  StepTestScreen.swift
//  IsItBroken?
//
//  Created for Swift Student Challenge
//

import SwiftUI
import CoreHaptics

struct StepTestScreen: View {

    @State private var stepCount: Int = 0
    @State private var isTesting: Bool = false
    @State private var navigateToPalpation: Bool = false
    @State private var canBearWeight: Bool = false
    
    @State private var showInfoAlert: Bool = false
    @State private var isPulsing: Bool = false // Controls the active button heartbeat

    let deepSlate   = Color(red: 0.15, green: 0.18, blue: 0.25)
    let calmingTeal = Color(red: 0.08, green: 0.62, blue: 0.62)
    let activeTeal  = Color(red: 0.45, green: 0.75, blue: 0.75)
    
    // 1. Even lighter, softer yellow for the shrunken warning badge
    let ultraLightYellow = Color(red: 1.0, green: 0.98, blue: 0.88)
    let darkAmber        = Color(red: 0.6, green: 0.4, blue: 0.0)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).opacity(0.6).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    AssessmentProgressBar(currentStep: 0)

                    Spacer().frame(height: 30)

                    // PRIMARY INSTRUCTION CARD
                    VStack(spacing: 12) {
                        Text("4-STEP WALKING TEST")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(calmingTeal)
                            .tracking(1.2)
                        
                        HStack(alignment: .center, spacing: 10) {
                            Text("Place your phone in your pocket and take 4 natural steps.")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(deepSlate)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                showInfoAlert = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(calmingTeal.opacity(0.8))
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 24)

                    // 2. INCREASED SPACING (+12 pts)
                    Spacer(minLength: 42)
                    
                    stepCounterView
                    
                    // 2. INCREASED SPACING (+12 pts)
                    Spacer(minLength: 32)
                    
                    // 3. SHRUNKEN ANIMATED WARNING
                    ZStack {
                        if isTesting {
                            warningBadgeView
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .frame(height: 32) // Reduced height boundary
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isTesting)

                    Spacer(minLength: 32) // The final breather gap

                    actionButtons
                }
            }
            .alert("Walking Guidelines", isPresented: $showInfoAlert) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("Limping counts, but you must be able to put weight on the injured foot to pass this step.")
            }
            .navigationDestination(isPresented: $navigateToPalpation) {
                PalpationTestScreen(canBearWeight: canBearWeight)
                    .navigationBarBackButtonHidden()
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: "cross.circle.fill")
                .foregroundColor(calmingTeal)
            Text("IsItBroken?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(deepSlate)
            Spacer()
        }
        .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 14)
    }

    private var stepCounterView: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 24, lineCap: .round))
            
            Circle()
                .trim(from: 0.0, to: CGFloat(stepCount) / 4.0)
                .stroke(calmingTeal, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: stepCount)
            
            VStack(spacing: 4) {
                Text("\(stepCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(deepSlate)
                    .contentTransition(.numericText())
                Text("/ 4 steps")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
            }
        }
        .frame(width: 240, height: 240)
    }
    
    // 3. THE REFINED, SHRUNKEN WARNING BADGE
    private var warningBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12)) // Shrunk icon
            Text("Stop immediately on severe pain")
                .font(.system(size: 13)) // Shrunk text
        }
        .foregroundColor(darkAmber)
        .padding(.horizontal, 14) // Reduced padding
        .padding(.vertical, 8)    // Reduced padding
        .background(ultraLightYellow) // Paler yellow
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2) // Softer shadow
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // 4. THE BREATHING / PULSING ACTIVE BUTTON
            Button(action: handlePrimaryButton) {
                Text(isTesting ? "Counting Steps..." : "Start Test")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTesting ? activeTeal : calmingTeal)
                    )
                    .shadow(color: (isTesting ? activeTeal : calmingTeal).opacity(isTesting && isPulsing ? 0.6 : 0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            // Drops opacity to 80% dynamically giving it a heartbeat effect
            .opacity(isTesting ? (isPulsing ? 0.8 : 1.0) : 1.0)
            .animation(isTesting ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)

            // 5. TEXT-ONLY DESTRUCTIVE BUTTON WITH ARROW
            Button(action: failTest) {
                HStack(spacing: 6) {
                    Text("I Can’t Put Weight on My Foot")
                        .font(.system(size: 14))
                }
                .font(.body.weight(.semibold)) // Using semantic iOS text weights
                .foregroundColor(.red)
                .padding(.vertical, 8)
            }
            .opacity(isTesting ? 1.0 : 0.0)
            .disabled(!isTesting)
        }
        .padding(.horizontal, 30).padding(.bottom, 30)
    }

    // MARK: - Logic

    private func handlePrimaryButton() {
        if isTesting { simulateStep() } else { startTest() }
    }

    private func startTest() {
        withAnimation {
            isTesting = true
            stepCount = 0
        }
        // Starts the heartbeat animation immediately
        isPulsing = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func failTest() {
        // Stop the heartbeat
        isPulsing = false
        canBearWeight = false
        navigateToPalpation = true
    }

    private func simulateStep() {
        guard stepCount < 4 else { return }
        stepCount += 1
        triggerStepHaptic()
        if stepCount == 4 {
            // Test success
            isPulsing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isTesting = false
                canBearWeight = true
                navigateToPalpation = true
            }
        }
    }

    private func triggerStepHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }
}
