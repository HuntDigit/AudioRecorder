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
    private var items: [AVPlayerItem] = []

    @Published var isPlaying: Bool = false
    
    init(audioFiles: [URL] = []) {
        loadAudioFiles(audioFiles)
    }

    func updateAudioFiles(_ newAudioFiles: [URL]) {
        loadAudioFiles(newAudioFiles)
    }
    
    func play() {
        isPlaying = true
        guard !items.isEmpty else {
            print("No audio")
            return
        }
        player?.pause()
        player?.removeAllItems()
        if player == nil {
            player = AVQueuePlayer()
        }
        for item in items {
            player?.insert(item, after: nil)
        }
        player?.play()
    }

    func stop() {
        isPlaying = false
        player?.pause()
        player?.removeAllItems()
    }
}

private extension AudioPlayer {
    private func loadAudioFiles(_ audioFiles: [URL]) {
        items = audioFiles.map { AVPlayerItem(url: $0) }
    }
}
