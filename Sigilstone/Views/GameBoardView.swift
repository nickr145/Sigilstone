//
//  GameBoardView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var showComputerPieces: Bool
    
    private enum Constants {
        static let player1String = "Player 1"
        static let player2String = "Player 2"
    }
    
    var player1WithScore: some View {
        VStack {
            Text(Constants.player1String)
                .font(.headline)
                .foregroundColor(.blue)
            Text("\(viewModel.player1Score)")
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
    }
    
    var player2WithScore: some View {
        VStack {
            Text(Constants.player2String)
                .font(.headline)
                .foregroundColor(.red)
            Text("\(viewModel.player2Score)")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
    }
    
    var playerAndScoreTile: some View {
        HStack {
            player1WithScore
            Spacer()
            player2WithScore
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
    
    var boardGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.board.indices, id: \.self) { index in
                Group {
                    if let stone = viewModel.board[index] {
                        StoneView(stone: stone)
                    } else {
                        EmptyCellView(index: index, onTap: {
                            guard !viewModel.isAITurnPending, viewModel.selectedPiece != nil else { return }
                            viewModel.placeSelectedPiece(at: index)
                        })
                    }
                }
            }
        }
        .padding()
        .alert("Game Over", isPresented: $viewModel.isGameOver) {
            Button("OK") { viewModel.resetGame() }
        } message: {
            Text(viewModel.winner.map { "Player \($0) Wins!" } ?? "It's a Tie!")
        }
    }
    
    var pieceselect: some View {
        PieceSelectionView(viewModel: viewModel, showComputerPieces: showComputerPieces)
    }

    var body: some View {
        VStack {
            playerAndScoreTile
            boardGrid
            pieceselect
        }
    }
}


#Preview {
    let sampleStones = [
        Stone(top: 2, right: 3, bottom: 1, left: 4, owner: 1),
        nil,
        Stone(top: 1, right: 2, bottom: 3, left: 4, owner: 2),
        nil, nil, nil, nil, nil, nil
    ]
    
    let viewModel = GameViewModel()
    viewModel.board = sampleStones
    
    return GameBoardView(viewModel: viewModel, showComputerPieces: false)
}

