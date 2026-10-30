//
//  InstructionsView.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-10-12.
//

import SwiftUI

struct InstructionsView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.dismiss) var dismiss  // For dismissing the view
    
    private enum Constants {
        static let HStackSpacing10 = 10.0
        static let HStackSpacing20 = 20.0
        static let VStackSpacing30 = 30.0
        static let shadowRadius = 10.0
        static let padding10 = 10.0
        static let padding5 = 5.0
        static let frameHeight = 100.0
        static let frameWidth = 60.0
        static let backButtonCornerRadius = 100.0
        static let sigilstoneInstructionsString = "Sigilstone Instructions"
        static let targetImageString = "target"
        static let objectiveTitleString = "Objective"
        static let objectiveString = "Capture as many stones as possible by strategically placing your pieces on the board."
        static let gameControllerImageString = "gamecontroller.fill"
        static let howToPlayString = "How to Play"
        static let howToPlayBulletPointsString = """
        - Players take turns placing their stones on the 3x3 board.
        - Each stone has values on all four sides.
        - When placed adjacent to an opponent’s stone, the values of the touching sides are compared.
        - If your stone's side value is higher than the opponent’s, you capture their stone.
        """
        static let trophyImageString = "trophy.fill"
        static let winningTheGameString = "Winning the Game"
        static let gameEndsDescriptionString = "The game ends when the board is full. The player who controls the most stones at the end of the game wins."
        static let listBulletRectangleImageString = "list.bullet.rectangle"
        static let additionalRulesString = "Additional Rules"
        static let additionalBulletPointsString = """
        - If a player cannot place a stone, the turn is skipped.
        - In Player vs Computer mode, the AI will automatically place a stone after Player 1’s turn.
        """
        static let backButtonString = "Back"
        static let audioMusicString = GameStringConstants.instructionsMusicString
        static let navTitleString = "Instructions"
    }
    
    var blackBackground: some View {
        Color.black
            .ignoresSafeArea()
    }
    
    var titleWithStone: some View {
        HStack(spacing: Constants.HStackSpacing20) {
            Text(Constants.sigilstoneInstructionsString)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .shadow(radius: Constants.shadowRadius)
                .multilineTextAlignment(.center)
                .padding(.bottom, Constants.padding10)
            StoneView(stone: Stone(top: 2, right: 3, bottom: 1, left: 4, owner: 1))
                .frame(width: Constants.frameWidth, height: Constants.frameHeight)
                .padding(.leading, Constants.padding10)
        }
        .padding(.horizontal)
    }
    
    var objectiveWithTargetImage: some View {
        HStack(spacing: Constants.HStackSpacing10) {
            Image(systemName: Constants.targetImageString)
                .foregroundColor(.yellow)
                .font(.title2)
            Text(Constants.objectiveTitleString)
                .font(.title2)
                .bold()
                .foregroundColor(.yellow)
        }
    }
    
    var objectiveText: some View {
        Text(Constants.objectiveString)
            .foregroundColor(.white)
            .font(.body)
            .padding(.bottom, Constants.padding5)
            .multilineTextAlignment(.leading)
    }
    
    var howToPlayWithGameController: some View {
        HStack(spacing: Constants.HStackSpacing10) {
            Image(systemName: Constants.gameControllerImageString)
                .foregroundColor(.green)
                .font(.title2)
            Text(Constants.howToPlayString)
                .font(.title2)
                .bold()
                .foregroundColor(.green)
        }
    }
    
    var howToPlayBulletPoints: some View {
        Text(Constants.howToPlayBulletPointsString)
        .foregroundColor(.white)
        .font(.body)
        .padding(.bottom, Constants.padding5)
        .multilineTextAlignment(.leading)
    }
    
    var winningSectionWithIcon: some View {
        HStack(spacing: Constants.HStackSpacing10) {
            Image(systemName: Constants.trophyImageString)
                .foregroundColor(.orange)
                .font(.title2)
            
            Text(Constants.winningTheGameString)
                .font(.title2)
                .bold()
                .foregroundColor(.orange)
        }
    }
    
    var gameEndsDescription: some View {
        Text(Constants.gameEndsDescriptionString)
            .foregroundColor(.white)
            .font(.body)
            .padding(.bottom, Constants.padding5)
            .multilineTextAlignment(.leading)
    }
    
    var additionalRules: some View {
        HStack(spacing: Constants.HStackSpacing10) {
            Image(systemName: Constants.listBulletRectangleImageString)
                .foregroundColor(.red)
                .font(.title2)
            
            Text(Constants.additionalRulesString)
                .font(.title2)
                .bold()
                .foregroundColor(.red)
        }
    }
    
    var additionalBulletPoints: some View {
        Text(Constants.additionalBulletPointsString)
        .foregroundColor(.white)
        .font(.body)
        .multilineTextAlignment(.leading)
    }
    
    var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text(Constants.backButtonString)
                .font(.footnote)
                .padding()
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(Constants.backButtonCornerRadius)
        }
    }
    
    var instructionVStack: some View {
        VStack(alignment: .leading, spacing: Constants.VStackSpacing30) {
            titleWithStone
            objectiveWithTargetImage
            objectiveText
            howToPlayWithGameController
            howToPlayBulletPoints
            winningSectionWithIcon
            gameEndsDescription
            additionalRules
            additionalBulletPoints
        }
        .padding()
    }
    
    var body: some View {
        ZStack {
            blackBackground

            ScrollView {
                instructionVStack
                backButton
            }
            
        }
        .onAppear {
            audioManager.playAudio(named: Constants.audioMusicString)
        }
        .onDisappear {
            audioManager.stopAudio()
        }
        .navigationTitle(Constants.navTitleString)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InstructionsView()
        .environmentObject(AudioPlayerManager())
}
