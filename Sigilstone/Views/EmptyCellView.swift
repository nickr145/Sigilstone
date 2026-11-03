//
//  EmptyCellView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import SwiftUI

struct EmptyCellView: View {
    var index: Int
    /// The cell's elemental square, if it has one.
    var element: Element? = nil
    var onTap: () -> Void

    private enum Constants {
        static let rectangleForegroundColorOpacity = 0.2
        static let elementTintOpacity = 0.35
        static let rectangleHeight = 100
    }

    var rectangleView: some View {
        Rectangle()
            .foregroundColor((element?.color ?? .gray).opacity(element == nil ? Constants.rectangleForegroundColorOpacity : Constants.elementTintOpacity))
            .frame(height: CGFloat(Constants.rectangleHeight))
            .overlay {
                if let element {
                    Image(systemName: element.symbolName)
                        .font(.title)
                        .foregroundColor(element.color)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(element.map { "Empty board cell \(index + 1), \($0.displayName) square" } ?? "Empty board cell \(index + 1)")
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

#Preview("Fire Square", traits: .sizeThatFitsLayout) {
    EmptyCellView(index: 2, element: .fire, onTap: { print("Tapped on fire square") })
        .padding()
}

#Preview("Empty Cell 1", traits: .sizeThatFitsLayout) {
    EmptyCellView(index: 1, onTap: { print("Tapped on empty cell 1") })
        .padding()
}
