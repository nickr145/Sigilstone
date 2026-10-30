//
//  AudioPlayerManager.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-10-19.
//

import Foundation
import AVFoundation
import AVKit
import SwiftUI

class AudioPlayerManager: ObservableObject {
    var audioPlayer: AVAudioPlayer?

    init() {
        configureAudioSession()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            audioPlayer?.pause()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                audioPlayer?.play()
            }
        @unknown default:
            break
        }
    }

    // No bundled tracks yet: a nil or missing track name is silence, not an error.
    func playAudio(named fileName: String?, fileType: String = "mp3") {
        guard let fileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // indefinite loops
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
    }
}
