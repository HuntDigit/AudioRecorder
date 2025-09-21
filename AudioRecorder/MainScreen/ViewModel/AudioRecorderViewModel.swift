//
//  AudioRecorderViewModel.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 17.09.2025.
//

import ScreenCaptureKit
import AVFoundation
import CoreMedia
import Combine

struct TotalDuration {
    var startDuration: Double?
    var endDuration: Double?
    
    func total() -> Double {
        guard let startDuration, let endDuration else { return 0 }
        return endDuration - startDuration
    }
    
    mutating func reset() {
        startDuration = nil
        endDuration = nil
    }
}

class SystemAudioRecorder: NSObject, ObservableObject {
    
    private var duration: TotalDuration = .init()
    private var audioWriter: SegmentedAudioWriter
    private var stream: SCStream?
    private let engine = AVAudioEngine()
    private var cancelables = Set<AnyCancellable>()
    
    @Published var litOfFiles: [URL] = []
    @Published var isRecording = false
    @Published var recordingDurationSeconds = 0.0
    @Published var segment = 0

    @Published var sourceType: InputSourceType = .systemAudio
    @Published var durationSlot: SegmentDurationSlot = .short

    init(audioWriter: SegmentedAudioWriter) {
        self.audioWriter = audioWriter
        super.init()
        subscribe()
    }
    
    func subscribe() {
        audioWriter.currentSegmentindex.receive(on: RunLoop.main)
            .sink { self.segment = $0 }.store(in: &cancelables)
    }
    
    @MainActor
    func updateListOfFiles() {
        litOfFiles = audioWriter.getListOfAudioFiles()
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    func updateStreamSettings() async throws {
        audioWriter.updateSegmentDuration(to: Double(durationSlot.rawValue))
        // Remove Previos Setup
        await removeStreamOutputs()
        let config = AudioTool.streamConfiguration(configuration: .defaultConfig,
                                                   sourceType: sourceType)
        try await stream?.updateConfiguration(config)
        try await addStreamOutputs()
        await MainActor.run {
            updateListOfFiles()
        }
    }
    
    private func removeStreamOutputs() async {
        try? stream?.removeStreamOutput(self, type: .audio)
        if #available(macOS 15, *) {
            try? stream?.removeStreamOutput(self, type: .microphone)
        }
    }
    
    private func addStreamOutputs() async throws {
        switch sourceType {
        case .systemAudio:
            try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .main)
        case .microphone:
            if #available(macOS 15, *) {
                try stream?.addStreamOutput(self, type: .microphone, sampleHandlerQueue: .main)
            } else {
                setupAudioEngine()
            }
        }
    }
    
    private func getCurrentDisplay() async throws -> SCDisplay {
        let displays = try await SCShareableContent.current.displays
        guard let display = displays.first else {
            throw NSError(domain: "No display found", code: -1)
        }
        return display
    }
    
    func setupStream() async throws {
        let display = try await getCurrentDisplay()
        let audioFilter = SCContentFilter(display: display,
                                          excludingApplications: [],
                                          exceptingWindows: [])
        let config = AudioTool.streamConfiguration(configuration: .defaultConfig,
                                                   sourceType: sourceType)
        stream = SCStream(filter: audioFilter, configuration: config, delegate: nil)
        try await addStreamOutputs()
    }
    
    func start() async throws {
        Task {
            switch sourceType {
            case .systemAudio:
                try await stream?.startCapture()
            case .microphone:
                if #available(macOS 15, *) {
                    try await stream?.startCapture()
                } else {
                    try engine.start()
                }
            }
            
            await MainActor.run {
                isRecording = true
            }
        }
    }
    
    func stop() async throws {
        Task {
            switch sourceType {
            case .systemAudio:
                try await stream?.stopCapture()
            case .microphone:
                if #available(macOS 15, *) {
                    try await stream?.stopCapture()
                } else {
                    engine.inputNode.removeTap(onBus: 0)
                    engine.stop()
                }
            }
            
            await audioWriter.stop()
            await MainActor.run {
                recordingDurationSeconds = duration.total()
                duration.reset()
                isRecording = false
                updateListOfFiles()
            }
        }
    }
}

extension SystemAudioRecorder {
    
    func calculateTotalRecordingSessionDuration(_ buffer: CMSampleBuffer) -> Double {
        duration.endDuration = AudioTool.getTimeDuration(buffer: buffer)
        if duration.startDuration == nil {
            duration.startDuration = AudioTool.getTimeDuration(buffer: buffer)
        }
        return duration.total()
    }
}

extension SystemAudioRecorder {
    func setupAudioEngine() {
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format, block: streamTap)
    }
    
    func streamTap(buffer: AVAudioPCMBuffer, time: AVAudioTime) -> Void {
        guard self.isRecording else { return }
        guard let sampleBuffer = AudioTool.makeSampleBuffer(from: buffer, time: time) else { return }
        audioWriter.append(sampleBuffer)
        recordingDurationSeconds = calculateTotalRecordingSessionDuration(sampleBuffer)
    }
}

extension SystemAudioRecorder: SCStreamOutput {
    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        recordingDurationSeconds = calculateTotalRecordingSessionDuration(sampleBuffer)

        switch type {
        case .audio:
            audioWriter.append(sampleBuffer)
        case .microphone:
            audioWriter.append(sampleBuffer)
        default: return
        }
    }
}
