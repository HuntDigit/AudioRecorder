//
//  DependenciesManager.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 20.09.2025.
//

import Foundation

final class DependenciesManager {
    var systemAudioRecorder: SystemAudioRecorder {
        get {
            if let recorder = _systemAudioRecorder {
                return recorder
            } else {
                let recorder = makeSystemAudioRecorder()
                _systemAudioRecorder = recorder
                return recorder
            }
        }
    }
    
    var audioFileManager: AudioFileManager {
        get {
            if let manager = _audioFileManager {
                return manager
            } else {
                let manager = makeAudioFileManager()
                _audioFileManager = manager
                return manager
            }
        }
    }
    
    private var _systemAudioRecorder: SystemAudioRecorder?
    private var _audioFileManager: AudioFileManager?

}

private extension DependenciesManager {
    
    func makeAudioFileManager() -> AudioFileManager {
        AudioFileManager()
    }
    
    func makeSystemAudioRecorder() -> SystemAudioRecorder {
        let writer = makeSegmentedAudioWriter(config: .defaultConfig, audioFileManager: audioFileManager)
        return SystemAudioRecorder(audioWriter: writer)
    }
    
    func makeSegmentedAudioWriter(config: AudioSettingsConfig,
                                          audioFileManager: AudioFileManager) -> SegmentedAudioWriter {
        return SegmentedAudioWriter(configuration: .defaultConfig,
                                    audioFileManager: audioFileManager)
    }
}
