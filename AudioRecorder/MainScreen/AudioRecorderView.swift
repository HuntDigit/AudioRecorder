//
//  AudioRecorderView.swift
//  AudioRecorder
//
//  Created by Andrii Sabinin on 17.09.2025.
//

import SwiftUI

enum ScreenType: CaseIterable {
    case recording
    case player
}

struct AudioRecorderView: View {
    @StateObject var model: SystemAudioRecorder
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var isPlaing: Bool = false
    @State private var selection: ScreenType = .recording

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: ScreenType.recording) {
                    Label("Record audio", systemImage: "record.circle")
                }
                NavigationLink(value: ScreenType.player) {
                    Label("Play Audio", systemImage: "waveform")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .padding(.vertical, 10)
        } detail: {
            switch selection {
            case .recording:
                recordingView
                    .navigationTitle(Text("Audio Recorder"))
            case .player:
                playerView
                    .navigationTitle(Text("Audio Palyer"))
            }
        }
        .onChange(of: model.segment) {
            updateExistingContentIfAvailable()
        }
        .onChange(of: model.sourceType) {
            taskUpdate()
        }
        .onChange(of: model.durationSlot) {
            taskUpdate()
        }
        .onAppear() {
            taskSetup()
            updateExistingContentIfAvailable()
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400, maxHeight: 400)
    }
    
    var playerView: some View {
        VStack {
            List {
                ForEach(model.litOfFiles, id: \.self) { file in
                    Label(file.lastPathComponent, systemImage: "music.note")
                }
                .listRowSeparator(.hidden)
            }
            .background(Color.red)
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            VStack {
                Text( model.isRecording ? "Recording in progress..." : "Player controls")
                    .foregroundStyle(model.isRecording ? Color.white : Color.primary)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(model.isRecording ? Color.red.opacity(0.75) : Color.clear)
                    }
                HStack {
                    Button {
                        audioPlayer.play()
                    } label: {
                        Label("Play All", systemImage: "play.fill")
                    }
                    .disabled(model.isRecording)
                    .disabled(audioPlayer.isPlaying)

                    Button {
                        audioPlayer.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .disabled(model.isRecording)
                    .disabled(!audioPlayer.isPlaying)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth:.infinity)
        }
    }
    
    var recordingView: some View {
        VStack(alignment: .center) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("\(model.isRecording ? "Recording:" : "Idle:")")
                        .font(.largeTitle)
                    Text("Time: ")
                        .font(.largeTitle)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Current Segment \(segmentText)")
                        .font(.title)
                    Text("\(model.recordingDurationSeconds, specifier: "%.2f")s")
                        .font(.largeTitle)
                }
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            Spacer()
            VStack() {
                Picker("Segment duration:", selection: $model.durationSlot) {
                    ForEach(SegmentDurationSlot.allCases, id: \.self) { type in
                        switch type {
                        case .short:
                            Text("10 seconds")
                        case .medium:
                            Text("20 seconds")
                        case .long:
                            Text("30 seconds")
                        }
                    }
                }
                .frame(width: 260)
                Picker("Input Source:", selection: $model.sourceType) {
                    ForEach(InputSourceType.allCases, id: \.self) { type in
                        switch type {
                        case .microphone:
                            Text("Microphone")
                        case .systemAudio:
                            Text("System audio")
                        }
                    }
                }
                .frame(width: 260)
            }
            HStack(alignment: .center) {
                Button {
                    taskStart()
                } label: {
                    Label("Record", systemImage: "record.circle")
                }
                .disabled(model.isRecording)
                Button {
                    taskStop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!model.isRecording)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth:.infinity)
    }
    
    var segmentText: String {
        model.segment == 0 ? "?" : "[\(model.segment)]"
    }
    
    func updateExistingContentIfAvailable() {
        model.updateListOfFiles()
        audioPlayer.updateAudioFiles(model.litOfFiles)
    }
}

extension AudioRecorderView {
    
    func taskUpdate() {
        Task {
            do {
                try await model.updateStreamSettings()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func taskSetup() {
        Task {
            do {
                try await model.setupStream()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func taskStart() {
        Task {
            do {
                try await model.start()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func taskStop() {
        Task {
            do {
                try await model.stop()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}

#Preview {
    let depMen = DependenciesManager()
    AudioRecorderView(model: depMen.systemAudioRecorder)
}
