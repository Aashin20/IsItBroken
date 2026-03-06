//
//  StepTestScreen.swift
//  IsItBroken?
//
//  Created for Swift Student Challenge
//

import SwiftUI

struct StepTestScreen: View {

    @State private var stepCount: Int = 0
    
    @State private var hasStartedTest: Bool = false
    @State private var isCountingSteps: Bool = false
    
    @State private var navigateToPalpation: Bool = false
    @State private var canBearWeight: Bool = false
    
    @State private var showInfoAlert: Bool = false
    @State private var isPulsing: Bool = false

    let deepSlate   = Color(red: 0.15, green: 0.18, blue: 0.25)
    let calmingTeal = Color(red: 0.08, green: 0.62, blue: 0.62)
    let activeTeal  = Color(red: 0.45, green: 0.75, blue: 0.75)
    
    let ultraLightYellow = Color(red: 1.0, green: 0.98, blue: 0.88)
    let darkAmber        = Color(red: 0.6, green: 0.4, blue: 0.0)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).opacity(0.6).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    Spacer().frame(height: 30)

                    VStack(spacing: 12) {
                        Text("STEP TEST")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(calmingTeal)
                            .tracking(1.2)
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("Place your phone in your pocket and take 4 steps")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(deepSlate)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                showInfoAlert = true
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(calmingTeal.opacity(0.8))
                                    .padding(.bottom, 3)
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

                    Spacer(minLength: 42)
                    
                    stepCounterView
                    
                    Spacer(minLength: 32)
                    
                    ZStack {
                        if hasStartedTest {
                            warningBadgeView
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .frame(height: 32)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: hasStartedTest)

                    Spacer(minLength: 32)

                    actionButtons
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showInfoAlert)
            .sensoryFeedback(.success, trigger: hasStartedTest) { oldValue, newValue in
                return newValue == true
            }
            .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: stepCount)
            
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
    
    private var warningBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text("Stop immediately on severe pain")
                .font(.system(size: 13))
        }
        .foregroundColor(darkAmber)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ultraLightYellow)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                if !hasStartedTest {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        hasStartedTest = true
                    }
                } else if !isCountingSteps {
                    startAutomatedTest()
                }
            }) {
                Text(primaryButtonText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isCountingSteps ? activeTeal : calmingTeal)
                    )
                    .shadow(color: (isCountingSteps ? activeTeal : calmingTeal).opacity(isCountingSteps && isPulsing ? 0.6 : 0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .opacity(isCountingSteps ? (isPulsing ? 0.8 : 1.0) : 1.0)
            .disabled(isCountingSteps)
            .animation(isCountingSteps ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)
            .contentTransition(.opacity)

            if hasStartedTest && !isCountingSteps {
                Button(action: failTest) {
                    Text("I Can’t Put Weight on My Foot")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.systemGray6).opacity(0.8))
                        )
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95))
                ))
            }
        }
        .padding(.horizontal, 30).padding(.bottom, 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: hasStartedTest)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isCountingSteps)
    }
    
    private var primaryButtonText: String {
        if !hasStartedTest { return "Start Test" }
        if isCountingSteps { return "Walking..." }
        return "I Can Walk 4 Steps"
    }
    
    private func startAutomatedTest() {
        withAnimation {
            isCountingSteps = true
            stepCount = 0
        }
        isPulsing = true
        
        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.stepCount < 4 {
                    self.stepCount += 1
                }
                
                if self.stepCount == 4 {
                    timer.invalidate()
                    self.isPulsing = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.isCountingSteps = false
                        self.canBearWeight = true
                        self.navigateToPalpation = true
                    }
                }
            }
        }
    }

    private func failTest() {
        isPulsing = false
        canBearWeight = false
        navigateToPalpation = true
    }
}
