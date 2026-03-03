
//
//  AssessmentProgressBar.swift
//  IsItBroken
//
//  Created by user@33 on 26/02/26.
//


import SwiftUI

struct AssessmentProgressBar: View {
    let currentStep: Int

    private let totalSegments = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSegments, id: \.self) { i in
                ProgressSegment(index: i, current: currentStep)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
    }
}
