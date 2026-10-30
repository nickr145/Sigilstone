//
//  DifficultySelectionView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-10-16.
//

import SwiftUI

class DifficultySelectionViewModel: ObservableObject {
    @Published var selectedDifficulty: Int = 1
    @Published var showGameView = false
}

struct DifficultySelectionView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @StateObject var viewModel = GameViewModel()
    @StateObject var difficultySelectionViewModel = DifficultySelectionViewModel()
    
    @Environment(\.dismiss) var dismiss
    @Binding var showPVCView: Bool
    
    private enum Constants {
        static let backButtonString = "Back"
        static let selectDifficultyString = "Select Difficulty"
        static let difficultyPickerString = "Difficulty"
        static let startGameString = "Start Game"
        static let difficultySelectionMusicString = GameStringConstants.difficultySelectionMusicString
        static let difficultyLessThan3 = 3
        static let difficultyLessThan5 = 5
        static let padding10 = 10.0
        static let difficultySymbolSize: CGFloat = 80
    }
    
    var blackBackground: some View {
        Color.black
            .ignoresSafeArea()
    }
    
    var backButtonView: some View {
        Button(action: {
            dismiss()
        }) {
            Text(Constants.backButtonString)
                .font(.headline)
                .padding()
                .foregroundStyle(.green)
                .border(Color.green)
        }
    }
    
    var selectDifficultyTextView: some View {
        Text(Constants.selectDifficultyString)
            .font(.largeTitle)
            .padding()
            .foregroundStyle(.red)
            .border(Color.red)
    }
    
    var pickerView: some View {
        Picker(Constants.difficultyPickerString, selection: $difficultySelectionViewModel.selectedDifficulty) {
            ForEach(1..<7, id: \.self) { level in
                Text("Level \(level)")
                    .foregroundColor(.white)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .padding()
    }
    
    var dynamicDifficultyLevelTextView: some View {
        Text("\(viewModel.difficultyLevelNameStrings[difficultySelectionViewModel.selectedDifficulty-1])")
            .foregroundStyle((difficultySelectionViewModel.selectedDifficulty < Constants.difficultyLessThan3 ? .green : (difficultySelectionViewModel.selectedDifficulty < Constants.difficultyLessThan5 ? .yellow : .red)))
    }
    
    var dynamicDifficultyImageView: some View {
        Image(systemName: viewModel.difficultyImageStrings[difficultySelectionViewModel.selectedDifficulty-1])
            .font(.system(size: Constants.difficultySymbolSize))
            .foregroundStyle(.white)
            .padding(Constants.padding10)
    }
    
    var spacerView: some View {
        Spacer()
    }
    
    var startGameButtonView: some View {
        Button(action: {
            let chosenLevel = difficultySelectionViewModel.selectedDifficulty
            viewModel.recordDifficultySelection(chosenLevel)
            difficultySelectionViewModel.showGameView = true
            audioManager.stopAudio()
        }) {
            Text(Constants.startGameString)
                .font(.title)
                .padding()
                .foregroundStyle(.blue)
                .border(Color.blue)
        }
    }
    
    var diffSelectionVStack: some View {
        VStack {
            HStack {
                backButtonView
                selectDifficultyTextView
            }
            pickerView
            dynamicDifficultyLevelTextView
            dynamicDifficultyImageView
            spacerView
            
            startGameButtonView
        }
    }
    
    var pvcView: some View {
        PVCView(difficulty: difficultySelectionViewModel.selectedDifficulty, showPVCView: $showPVCView)
    }
    
    var body: some View {
        ZStack {
            blackBackground
            diffSelectionVStack
            .fullScreenCover(isPresented: $difficultySelectionViewModel.showGameView) {
                pvcView
            }
        }
        .onAppear {
            audioManager.playAudio(named: Constants.difficultySelectionMusicString)
        }
    }
}

struct DifficultySelectionView_Previews: PreviewProvider {
    @State static var showPVCView = false
    
    static var previews: some View {
        DifficultySelectionView(showPVCView: $showPVCView)
            .environmentObject(AudioPlayerManager())
    }
}

