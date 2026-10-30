//
//  PVCView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-23.
//

import SwiftUI

struct PVCView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    var difficulty: Int
    @StateObject var viewModel = GameViewModel()
    @Binding var showPVCView: Bool
    
    private enum Constants {
        static let pvcNavTitleString = "PVC (Player vs Computer)"
        static let backButtonString = "Back"
        static let zIndex = 0
        static let backButtonCornerRadius = 100
        static let backButtonPadding = 70
    }
    
    var blackBackground: some View {
        Color.black
            .ignoresSafeArea()
    }
    
    var boardBackground: some View {
        LinearGradient(colors: [Color(red: 0.08, green: 0.09, blue: 0.20), Color(red: 0.02, green: 0.02, blue: 0.06)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    var gameBoardView: some View {
        GameBoardView(viewModel: viewModel, showComputerPieces: false)
            .navigationTitle(Constants.pvcNavTitleString)
            .padding()
            .background(Color.clear)
            .zIndex(CGFloat(Constants.zIndex))
    }
    
    var buttonTextView: some View {
        Text(Constants.backButtonString)
            .font(.footnote)
            .padding()
            .background(Color.green)
            .foregroundColor(.black)
            .cornerRadius(CGFloat(Constants.backButtonCornerRadius))
    }
    
    var buttonView: some View {
        Button(action: {
            showPVCView = false // Dismiss the current view to return to TitleView
        }) {
            buttonTextView
        }
        .padding(.top, CGFloat(Constants.backButtonPadding))
    }
    
    var spacerView: some View {
        Spacer()
    }
    
    var buttonVstack: some View {
        VStack {
            HStack {
                buttonView
            }
            spacerView
        }
    }

    var body: some View {
        ZStack {
            blackBackground
            boardBackground
            gameBoardView
            buttonVstack
        }
        .onAppear {
            viewModel.setupComputerDifficulty(difficulty)
            audioManager.playAudio(named: viewModel.musicDifficultyStrings.indices.contains(difficulty - 1)
                                    ? viewModel.musicDifficultyStrings[difficulty - 1] : nil)
            triggerComputerMoveIfNeeded()
        }
        .onDisappear {
            audioManager.stopAudio()
        }
        .ignoresSafeArea(.all)
        .onChange(of: viewModel.currentPlayer) { oldValue, newValue in
            triggerComputerMoveIfNeeded()
        }
        // resetGame() re-sets currentPlayer to the value it already had when the
        // computer made the last move, so the .onChange above never fires for it.
        .onChange(of: viewModel.isGameOver) { _, isOver in
            if !isOver { triggerComputerMoveIfNeeded() }
        }
    }

    // `.onChange` never fires for the value a @Published property already holds
    // at first render, so the computer's very first move (when it starts the
    // game) has to be triggered from `.onAppear` too, not just `.onChange`.
    private func triggerComputerMoveIfNeeded() {
        guard viewModel.currentPlayer == 2, !viewModel.isGameOver, !viewModel.isAITurnPending else { return }
        viewModel.isAITurnPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewModel.performComputerMove()
            viewModel.isAITurnPending = false
        }
    }
}


struct PVCView_Previews: PreviewProvider {
    @State static var showPVCView = false

    static var previews: some View {
        PVCView(difficulty: 3, showPVCView: $showPVCView)
            .environmentObject(AudioPlayerManager())
    }
}
