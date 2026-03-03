
//
//  AssessmentOnboardingScreen.swift
//  IsItBroken?
//
//  Created by user@33 on 19/02/26.
//

import SwiftUI

struct AssessmentOnboardingScreen: View {
    
    @State private var navigateToDisclaimer = false
    @State private var showOttawaRules = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    HStack(spacing: 6) {
                        Image(systemName: "cross.circle.fill")
                            .foregroundColor(Color(red: 0.12, green: 0.6, blue: 0.6))
                        Text("IsItBroken?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.25))
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    LottieView(filename: "lottie1")
                        .frame(width: 300, height: 300)
                        .padding(.vertical, 20)
                    
                    VStack(spacing: 16) {
                        Text("Can you walk without pain?")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.25))
                            .multilineTextAlignment(.center)
                        
                        Text("We’ll help you assess your ankle using the Ottawa Ankle Rules.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 30)
                            .lineSpacing(4)
                            .lineLimit(2)
                    }
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            navigateToDisclaimer = true
                        }) {
                            Text("Begin Assessment")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 0.12, green: 0.6, blue: 0.6))
                                )
                                .shadow(color: Color(red: 0.12, green: 0.6, blue: 0.6).opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            showOttawaRules = true
                        }) {
                            Text("What are the Ottawa Rules?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.12, green: 0.6, blue: 0.6))
                                .underline()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToDisclaimer) {
                DisclaimerScreen()
                    .navigationBarBackButtonHidden()
            }
            .sheet(isPresented: $showOttawaRules) {
                OttawaRulesInfoView()
            }
        }
    }
}

// MARK: - Ottawa Rules Info Sheet
struct OttawaRulesInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    let teal = Color(red: 0.12, green: 0.6, blue: 0.6)
    let slate = Color(red: 0.15, green: 0.18, blue: 0.25)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 50))
                        .foregroundColor(teal)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                    
                    Text("About the Ottawa Ankle Rules")
                        .font(.title2.bold())
                        .foregroundColor(slate)

                    
                    
                    Text("The Ottawa Ankle Rules are a set of clinical guidelines used by medical professionals to decide if a patient with a foot or ankle injury needs an X-ray to diagnose a possible bone fracture.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    Divider()
                    
                    Text("Why are they used?")
                        .font(.headline)
                        .foregroundColor(slate)
                    
                    Text("Before these rules were developed, most patients with ankle injuries were given X-rays, but only about 15% actually had fractures. These rules help reduce unnecessary radiation exposure, medical costs, and waiting times in emergency rooms.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(teal)
                        VStack(alignment: .leading) {
                            Text("High Sensitivity (~98%)")
                                .font(.headline)
                                .foregroundColor(slate)
                            Text("This means if the test says 'No X-ray needed', it is extremely likely there is no fracture.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(teal.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(24)
            }
            .navigationTitle("Clinical Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(teal)
                }
            }
        }
    }
}

#Preview {
    AssessmentOnboardingScreen()
}
