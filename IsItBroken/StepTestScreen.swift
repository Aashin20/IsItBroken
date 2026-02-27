//
//  StepTestScreen.swift
//  IsItBroken?
//
//
//

import SwiftUI
import CoreHaptics

struct StepTestScreen: View {

    @State private var stepCount: Int = 0
    @State private var isTesting: Bool = false
    @State private var navigateToPalpation: Bool = false
    @State private var canBearWeight: Bool = false

    let deepSlate   = Color(red: 0.15, green: 0.18, blue: 0.25)
    let calmingTeal = Color(red: 0.08, green: 0.62, blue: 0.62)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    // Segment 0 of 5 active — Step Test
                    AssessmentProgressBar(currentStep: 0)

                    Spacer().frame(height: 30)

                    VStack(spacing: 12) {
                        Text("Step Test")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(deepSlate)

                        Text("Can you walk 4 complete steps without assistance? Limping counts, but you must transfer weight.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                    stepCounterView
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "shoeprints.fill")
                            .font(.system(size: 32))
                            .foregroundColor(calmingTeal.opacity(0.6))

                        Text(isTesting ? "Walking... counting steps." : "Place phone in your pocket and walk.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(deepSlate)
                    }

                    Spacer().frame(height: 30)
                    actionButtons
                }
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
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 24)
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
                Text("/ 4 STEPS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
        }
        .frame(width: 240, height: 240)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: handlePrimaryButton) {
                Text(isTesting ? "Simulate Step (Tap)" : "Start Step Test")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTesting ? Color.orange : calmingTeal)
                    )
                    .shadow(color: (isTesting ? Color.orange : calmingTeal).opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())

            Button(action: failTest) {
                Text("I Cannot Walk 4 Steps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 30).padding(.bottom, 30)
    }

    // MARK: - Logic

    private func handlePrimaryButton() {
        if isTesting { simulateStep() } else { startTest() }
    }

    private func startTest() {
        withAnimation { isTesting = true; stepCount = 0 }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func failTest() {
        canBearWeight = false
        navigateToPalpation = true
    }

    private func simulateStep() {
        guard stepCount < 4 else { return }
        stepCount += 1
        triggerStepHaptic()
        if stepCount == 4 {
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
