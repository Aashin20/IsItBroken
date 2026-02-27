
//
//  DisclaimerScreen.swift
//  IsItBroken?
//

import SwiftUI

struct DisclaimerScreen: View {
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Subtle ambient background
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.6, blue: 0.6).opacity(0.06),
                    Color.white
                ]),
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "cross.circle.fill")
                        .foregroundColor(Color(red: 0.12, green: 0.6, blue: 0.6))
                    Text("IsItBroken?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.25))
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Lottie with glow
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    LottieView(filename: "Alert")
                        .frame(width: 130, height: 130)
                }
                .padding(.bottom, 24)
                
                // Title — authority, not alarm
                Text("Important Disclaimer")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.25))
                    .padding(.bottom, 20)
                
                // Info cards
                VStack(spacing: 12) {
                    DisclaimerCard(
                        icon: "stethoscope",
                        iconColor: Color(red: 0.12, green: 0.6, blue: 0.6),
                        text: "This app uses the Ottawa Ankle Rules to help estimate the need for an X-ray. It is **NOT** a substitute for professional medical advice, diagnosis, or treatment."
                    )
                    
                    DisclaimerCard(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        text: "If you are experiencing severe pain, significant deformity, or bleeding, seek **emergency medical care immediately**."
                    )
                }
                .padding(.horizontal, 24)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 12)
                
                Spacer()
                
                // CTA
                Button(action: { /* navigate */ }) {
                    Text("I Understand")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.12, green: 0.6, blue: 0.6))
                        )
                        .shadow(color: Color(red: 0.12, green: 0.6, blue: 0.6).opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .buttonStyle(SpringButtonStyle())
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateIn = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Card component
struct DisclaimerCard: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 28)
            
            Text(LocalizedStringKey(text))
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(red: 0.25, green: 0.28, blue: 0.35))
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Springy press feedback
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
#Preview {
    DisclaimerScreen()
}
