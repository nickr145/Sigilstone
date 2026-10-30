//
//  PieceSelectionView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-28.
//

import SwiftUI

struct PieceSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    // Whether player 2's hand should ever be shown for selection — true in PVP
    // (a human plays player 2), false in PVC (player 2 is the computer, which
    // selects its own piece programmatically via performComputerMove()).
    var showComputerPieces: Bool

    // Legality is enforced in GameViewModel.placeSelectedPiece; this view only
    // controls which hand is visible/tappable for the current turn.
    var body: some View {
        VStack {
            if viewModel.currentPlayer == 1 {
                player1PiecesRow
            } else if showComputerPieces {
                player2PiecesRow
            }
            // else: PVC mode, computer's turn — nothing for the human to select.
        }
    }

    var player1PiecesRow: some View {
        HStack {
            ForEach(viewModel.player1Pieces) { piece in
                StoneView(stone: piece)
                    .onTapGesture {
                        viewModel.selectedPiece = piece
                    }
                    .border(viewModel.selectedPiece?.id == piece.id ? Color.red : Color.clear)
            }
        }
        .padding()
    }

    var player2PiecesRow: some View {
        HStack {
            ForEach(viewModel.player2Pieces) { piece in
                StoneView(stone: piece)
                    .onTapGesture {
                        viewModel.selectedPiece = piece
                    }
                    .border(viewModel.selectedPiece?.id == piece.id ? Color.red : Color.clear)
            }
        }
        .padding()
    }
}

#Preview {
    PieceSelectionView(viewModel: GameViewModel(), showComputerPieces: true)
}




