//
//  AudioPlayer.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 21.09.2025.
//

import Foundation
import AVFoundation

final class AudioPlayer: ObservableObject {
    private var player: AVQueuePlayer?
    private var urls: [URL] = []

    @Published var isPlaying: Bool = false
    
    init(audioFiles: [URL] = []) {
        urls = audioFiles
    }

    func updateAudioFiles(_ newAudioFiles: [URL]) {
        urls = newAudioFiles
    }
    
    func play() {
        if urls.isEmpty { print("No audio"); return }
        if player == nil {
            player = AVQueuePlayer()
        }
 
        // Recreate the list to reset the cache and start playback from the beginning.
        urls.forEach { player?.insert(.init(url: $0), after: nil) }
 
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player?.removeAllItems()
        isPlaying = false
    }
}
