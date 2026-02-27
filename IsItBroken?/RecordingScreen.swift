import SwiftUI

struct RecordingScreen: View {
    
    var body: some View {
        ZStack {
            
            // Background
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                Spacer()
                
                // 🎞 Lottie Animation with circle border
                ZStack {
                    
                    Circle()
                        .stroke(Color.orange.opacity(0.6), lineWidth: 3)
                        .frame(width: 200, height: 200)
                    
                    LottieView(filename: "your_animation_file")
                        .frame(width: 150, height: 150)
                }
                
                Spacer()
                
                // Title
                VStack(spacing: 16) {
                    
                    Text("Recording")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.22, blue: 0.4))
                    
                    Text("Outgoing Calls")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.22, blue: 0.4))
                    
                    Text("Unlike other call recorder apps, this app sets up a direct connection and doesn’t require you to create a conference / 3-way call when recording outgoing calls")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Button
                Button(action: {
                    print("See how it works tapped")
                }) {
                    Text("See How it Works")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.35, green: 0.38, blue: 0.75))
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}
