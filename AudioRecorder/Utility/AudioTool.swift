//
//  AudioTool.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 18.09.2025.
//

import ScreenCaptureKit
import AVFoundation
import CoreMedia

enum InputSourceType: Int, CaseIterable {
    case systemAudio
    case microphone
}

enum SegmentDurationSlot: Int, CaseIterable {
    case short  = 10
    case medium = 20
    case long   = 30
}

struct AudioSettingsConfig {
    var sampleRate: Int
    var channelCount: Int
    var segmentDurationSeconds: Double
    
    init(sampleRate: Int, channelCount: Int, segmentDurationSeconds: Double) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.segmentDurationSeconds = segmentDurationSeconds
    }
    
    static let defaultConfig = Self.init(sampleRate: 48000,
                                         channelCount: 1,
                                         segmentDurationSeconds: 10.0)
}

struct AudioTool  {
    
    // Apple often uses 600 as the "default" timescale, let it be
    static let defaultPreferredTimescale: CMTimeScale = 600
    
    static func getTimeDuration(buffer: CMSampleBuffer) -> Double {
        CMSampleBufferGetPresentationTimeStamp(buffer).seconds
    }
    
    static func streamConfiguration(configuration: AudioSettingsConfig = .defaultConfig,
                                    sourceType: InputSourceType = .systemAudio) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.capturesAudio = sourceType == .systemAudio
        if #available(macOS 15, *) {
            config.captureMicrophone = sourceType == .microphone
        }
        config.sampleRate = configuration.sampleRate
        config.channelCount = configuration.channelCount
        return config
    }
    
    static func makeSampleBuffer(from pcmBuffer: AVAudioPCMBuffer, time: AVAudioTime) -> CMSampleBuffer? {
        let formatDesc = pcmBuffer.format.formatDescription
        
        let frameCount = CMItemCount(pcmBuffer.frameLength)
        
        // We have obly 1 chanel, for test we may not use it
        // let channels = Int(pcmBuffer.format.channelCount)
        
        let bytesPerFrame = Int(pcmBuffer.format.streamDescription.pointee.mBytesPerFrame)
        let dataSize = Int(pcmBuffer.frameLength) * bytesPerFrame
        
        var blockBuffer: CMBlockBuffer?
        let statusBB = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: pcmBuffer.audioBufferList.pointee.mBuffers.mData,
            blockLength: dataSize,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataSize,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard statusBB == kCMBlockBufferNoErr, let blockBuffer else {
            print("Failed to create CMBlockBuffer: \(statusBB)")
            return nil
        }
        
        let ptsSeconds = Double(time.sampleTime) / pcmBuffer.format.sampleRate
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(pcmBuffer.format.sampleRate)),
            presentationTimeStamp: CMTime(seconds: ptsSeconds, preferredTimescale: Self.defaultPreferredTimescale),
            decodeTimeStamp: CMTime.invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        let statusSB = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleCount: frameCount,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        if statusSB != noErr {
            print("Failed to create CMSampleBuffer: \(statusSB)")
            return nil
        }
        
        return sampleBuffer
    }
}
