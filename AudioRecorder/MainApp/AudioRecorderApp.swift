//
//  AudioRecorderApp.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 17.09.2025.
//

import SwiftUI

@main
struct AudioRecorderApp: App {
        
    private let diManager = DependenciesManager()
    
    var body: some Scene {
        WindowGroup {
            AudioRecorderView(model: diManager.systemAudioRecorder)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 400)
                
        MenuBarExtra("Segment duration", systemImage: "wrench.fill") {
            ForEach(SegmentDurationSlot.allCases, id: \.self) { type in
                Button {
                    diManager.systemAudioRecorder.durationSlot = type
                } label: {
                    Label("\(type.rawValue) seconds", systemImage: "timer")
                }
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
