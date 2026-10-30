//
//  AudioPlayerManagerTests.swift
//  SigilstoneTests
//

import XCTest
@testable import Sigilstone

final class AudioPlayerManagerTests: XCTestCase {
    func testPlayAudio_withNoTrackName_isSilent() {
        let manager = AudioPlayerManager()
        manager.playAudio(named: nil)
        XCTAssertNil(manager.audioPlayer)
    }

    func testPlayAudio_withMissingFile_isSilent() {
        let manager = AudioPlayerManager()
        manager.playAudio(named: "NoSuchTrack")
        XCTAssertNil(manager.audioPlayer)
        manager.stopAudio()
    }

    func testMusicDifficultyStrings_areEmptyUntilAudioIsAdded() {
        XCTAssertTrue(GameStringConstants.musicDifficultyStrings.isEmpty)
    }
}
