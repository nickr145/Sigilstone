//
//  StoneView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import SwiftUI

struct StoneView: View {
    var stone: Stone
    
    private enum Constants {
        static let player1Owner = 1
        static let blueOpacity = 0.7
        static let redOpacity = 0.7
        static let tileCornerRadius = 10
    }
    
    var top: some View {
        Text("\(stone.top)").font(.headline)
            .bold()
    }
    
    var left: some View {
        Text("\(stone.left)").font(.headline)
            .bold()
    }
    
    var right: some View {
        Text("\(stone.right)").font(.headline)
            .bold()
    }
    
    var bottom: some View {
        Text("\(stone.bottom)").font(.headline)
            .bold()
    }
    
    var body: some View {
        VStack {
            Text("\(stone.top)").font(.headline)
                .bold()
            HStack {
                Text("\(stone.left)").font(.headline)
                    .bold()
                Spacer()
                Text("\(stone.right)").font(.headline)
                    .bold()
            }
            Text("\(stone.bottom)").font(.headline)
                .bold()
        }
        .padding()
        // Blue for Player 1, Red for Player 2
        .background(stone.owner == Constants.player1Owner ?
                    Color.blue.opacity(Constants.blueOpacity) :
                        Color.red.opacity(Constants.redOpacity))
        .cornerRadius(CGFloat(Constants.tileCornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Piece with top \(stone.top), right \(stone.right), bottom \(stone.bottom), left \(stone.left)")

    }
}



#Preview("Player 1 Stone", traits: .sizeThatFitsLayout) {
    StoneView(stone: Stone(top: 2, right: 3, bottom: 1, left: 4, owner: 1))
        .padding()
}

#Preview("Player 2 Stone", traits: .sizeThatFitsLayout) {
    StoneView(stone: Stone(top: 3, right: 2, bottom: 4, left: 1, owner: 2))
        .padding()
}
