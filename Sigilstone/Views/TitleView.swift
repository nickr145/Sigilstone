//
//  TitleView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-22.
//

import SwiftUI

class TitleViewModel: ObservableObject {
    @Published var showPVPView = false
    @Published var showDifficultySelection = false
    @Published var showInstructionsView = false
}

struct TitleView: View {
    
    private enum Constants {
        static let titleString: String = "Sigilstone"
        static let titleFontSize: CGFloat = 56
        static let titleMusicString = GameStringConstants.titleMusicString
        static let pvpButtonTitle: String = "PVP (Player vs Player)"
        static let pvcButtonTitle: String = "PVC (Player vs Computer)"
        static let instructionButtonTitle: String = "Instructions"
        static let cornerRadius: CGFloat = 10
    }
    
    @EnvironmentObject var audioManager: AudioPlayerManager
    @StateObject var viewModel = TitleViewModel()
    
    var background: some View {
        Color.black
    }
    
    var centeredGraphic: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Text(Constants.titleString)
                    .font(.system(size: Constants.titleFontSize, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(color: .blue, radius: 12)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .ignoresSafeArea()
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    var buttonToPVP: some View {
        Button(action: {
            audioManager.stopAudio()
            viewModel.showPVPView = true
        }) {
            Text(Constants.pvpButtonTitle)
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(Constants.cornerRadius)
        }
    }
    
    var buttonToPVC: some View {
        Button(action: {
            audioManager.stopAudio()
            viewModel.showDifficultySelection = true
        }) {
            Text(Constants.pvcButtonTitle)
                .font(.title2)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(Constants.cornerRadius)
        }
    }
    
    var buttonToInstructions: some View {
        Button(action: {
            audioManager.stopAudio()
            viewModel.showInstructionsView = true
        }) {
            Text(Constants.instructionButtonTitle)
                .font(.title2)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(Constants.cornerRadius)
        }
    }
    
    var emptyTextView: some View {
        Text("")
    }
    
    var buttonVstack: some View {
        VStack(spacing: 50) {
            emptyTextView
            emptyTextView
            emptyTextView
            emptyTextView
            emptyTextView
            emptyTextView

            buttonToPVP
            buttonToPVC
            buttonToInstructions
            
        }
        .padding()
        .fullScreenCover(isPresented: $viewModel.showPVPView, onDismiss: {
            audioManager.playAudio(named: Constants.titleMusicString) // Restart music when returning to TitleView
        }) {
            PVPView()
        }
        .fullScreenCover(isPresented: $viewModel.showDifficultySelection, onDismiss: {
            audioManager.playAudio(named: Constants.titleMusicString) // Restart music when returning to TitleView
        }) {
            DifficultySelectionView(showPVCView: $viewModel.showDifficultySelection)
        }
        .fullScreenCover(isPresented: $viewModel.showInstructionsView, onDismiss: {
            audioManager.playAudio(named: Constants.titleMusicString) // Restart music when returning to TitleView
        }) {
            InstructionsView()
        }
    }

    var body: some View {
        ZStack {
            background
            centeredGraphic
            buttonVstack
        }
        .onAppear {
            audioManager.playAudio(named: Constants.titleMusicString)
        }
        .onDisappear {
            audioManager.stopAudio()
        }
        .ignoresSafeArea()
    }
}


#Preview {
    TitleView()
        .environmentObject(AudioPlayerManager())
}
