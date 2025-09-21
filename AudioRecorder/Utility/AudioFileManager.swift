//
//  AudioFileManager.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 19.09.2025.
//

import Foundation

enum AudioFileForamts: String {
    case caf = ".caf"
    case m4a = ".m4a"
    case wav = ".wav"
    //.. other
}

class AudioFileManager {
    
    static let defaultDirectoryURL: URL = FileManager.default.temporaryDirectory
    
    private(set) var prefferedDirectory: URL?
    private(set) var filesFromPD: [URL] = []
    private(set) var fformat: AudioFileForamts = AudioFileForamts.wav

    func setFileFormat(_ ff: AudioFileForamts) {
        self.fformat = ff
    }
    
    func setFilenameForCurrentDirectory(_ filename: String) -> URL {
        var directory = Self.defaultDirectoryURL
        if let prefferedDirectory = prefferedDirectory { directory = prefferedDirectory }
        let component = filename + fformat.rawValue
        return directory.appendingPathComponent(component)
    }
    
    func readAudioFiles() -> [URL] {
        do {
            filesFromPD = try readAudioFilesFromPrefferedDirectory()
        } catch {
            print(error.localizedDescription)
        }
        
        return filesFromPD
    }
}

private extension AudioFileManager {
    func readAudioFilesFromPrefferedDirectory() throws -> [URL] {
        var directory = Self.defaultDirectoryURL
        if let prefferredDirectory = prefferedDirectory {
            directory = prefferredDirectory
        }
        
        return try FileManager.default.contentsOfDirectory(at: directory,
                                                           includingPropertiesForKeys: [],
                                                           options: .skipsHiddenFiles).compactMap { url in
            let foramt = AudioFileForamts.wav.rawValue
            return url.lastPathComponent.contains(foramt) ? url : nil
        }
    }
}
