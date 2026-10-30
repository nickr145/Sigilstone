//
//  EmptyCellView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import SwiftUI

struct EmptyCellView: View {
    var index: Int
    var onTap: () -> Void 
    
    private enum Constants {
        static let rectangleForegroundColorOpacity = 0.2
        static let rectangleHeight = 100
    }
    
    var rectangleView: some View {
        Rectangle()
            .foregroundColor(.gray.opacity(Constants.rectangleForegroundColorOpacity))
            .frame(height: CGFloat(Constants.rectangleHeight))
            .onTapGesture {
                onTap()
            }
            .accessibilityLabel("Empty board cell \(index + 1)")
            .accessibilityAddTraits(.isButton)
    }
    
    var body: some View {
        rectangleView
    }
}




#Preview("Empty Cell 0", traits: .sizeThatFitsLayout) {
    EmptyCellView(index: 0, onTap: { print("Tapped on empty cell 0") })
        .padding()
}

#Preview("Empty Cell 1", traits: .sizeThatFitsLayout) {
    EmptyCellView(index: 1, onTap: { print("Tapped on empty cell 1") })
        .padding()
}
