//
//  BlockView.swift
//  Sigilstone
//

import SwiftUI

/// A broken stone: a cell that can't be played on, owned or scored.
struct BlockView: View {
    var index: Int

    var body: some View {
        Rectangle()
            .foregroundColor(Color(white: 0.12))
            .frame(height: 100)
            .overlay(
                Image(systemName: "xmark.octagon.fill")
                    .font(.title)
                    .foregroundColor(.gray)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Blocked cell \(index + 1)")
    }
}

#Preview("Block", traits: .sizeThatFitsLayout) {
    BlockView(index: 4)
        .padding()
}
