//
//  SegmentAudioWriter.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 19.09.2025.
//

import AVFoundation
import Combine

enum SegmentAudioWriterError: Error {
    case failedToCreateAssetWriter
    case failedToCreateAssetWriterInput
    case failedToAddAssetWriterInput
    
    case writerIsNotReady
}

class SegmentedAudioWriter {
    
    typealias SWError = SegmentAudioWriterError
    
    let currentSegmentindex = PassthroughSubject<Int, Never>()

    private var audioFileManager: AudioFileManager
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var startPTS: CMTime?
    private var segmentDuration: CMTime
    private let sampleRate: Int
    private let channels: Int
    private var segmentIndex = 0
    private var isRecording = false
    
    init(configuration: AudioSettingsConfig, audioFileManager: AudioFileManager) {
        self.audioFileManager = audioFileManager
        self.segmentDuration = CMTime(seconds: configuration.segmentDurationSeconds,
                                      preferredTimescale: 600) // Apple often uses 600 as the "default" timescale, let it be
        self.sampleRate = configuration.sampleRate
        self.channels = configuration.channelCount
    }
    
    func updateSegmentDuration(to newDuration: Double) {
        self.segmentDuration = CMTime(seconds: newDuration,
                                      preferredTimescale: 600)
    }
    
    func getListOfAudioFiles() -> [URL] {
        audioFileManager.readAudioFiles()
    }
    
    private func newOutputURL() -> URL {
        segmentIndex += 1
        currentSegmentindex.send(segmentIndex)
        return audioFileManager.setFilenameForCurrentDirectory("segment_\(segmentIndex)")
    }
    
    private func setupWriter(url: URL , startSessionTime: CMTime) throws {
        if writer?.status == .writing { throw SWError.writerIsNotReady }
        let fformat = audioFileManager.fformat
        let settings = getSettings(for: fformat)
        let fType = getFileType(for: fformat)
        
        writer = try AVAssetWriter(outputURL: url, fileType: fType)
        input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        
        guard let writer = writer, let input = input else {
            throw SWError.failedToCreateAssetWriterInput
        }
        guard writer.canAdd(input) else {
            throw SWError.failedToAddAssetWriterInput
        }
        
        input.expectsMediaDataInRealTime = true
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: startSessionTime)
    }
    
    private func startNewSegment(at time: CMTime) throws {
        let url = newOutputURL()
        try setupWriter(url: url, startSessionTime: time)
        
        startPTS = time
        
        print("Started new segment:", url.lastPathComponent)
    }
    
    private func finishSegment() async {
        guard let writer = writer, let input = input else { return }
        input.markAsFinished()
        await writer.finishWriting()
        self.writer = nil
        self.input = nil
        self.startPTS = nil
    }
    
    func append(_ sampleBuffer: CMSampleBuffer) {
        guard let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).isValid
                ? Optional(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                : nil else { return }
        
        // Start first segment
        if writer == nil {
            try? startNewSegment(at: pts)
        }
        
        // Check if duration exceeded
        if let start = startPTS, CMTimeSubtract(pts, start) >= segmentDuration {
            Task { @MainActor in
                await finishSegment()
                try? startNewSegment(at: pts)
                self.append(sampleBuffer) // write the current buffer into new segment
            }
            return
        }
        
        if input?.isReadyForMoreMediaData == true {
            input?.append(sampleBuffer)
        }
    }
    
    func stop() async {
        await finishSegment()
        segmentIndex = 0
        currentSegmentindex.send(segmentIndex)
        currentSegmentindex.send(completion: .finished)
    }
}

extension SegmentedAudioWriter {
    
    func getFileType(for fformat: AudioFileForamts) -> AVFileType {
        switch fformat {
        case .wav : return .wav
        case .m4a : return .m4a
        case .caf : return .caf
        }
    }
    
    func getFormatIDKey(for fformat: AudioFileForamts) -> AudioFormatID {
        switch fformat {
        case .wav : return kAudioFormatLinearPCM
        case .m4a : return kAudioFormatMPEG4AAC
        case .caf : return kAudioFormatLinearPCM
        }
    }
    
    /* THIS IS JUST EXAMPLE MORE/LESS HARDCODED FOR WAV OR CAF FORMAT*/
    func getSettings(for fformat: AudioFileForamts) -> [String: Any] {
        [
            AVFormatIDKey: getFormatIDKey(for: fformat),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}
