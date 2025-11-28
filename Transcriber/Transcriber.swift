//
//  Transcriber.swift
//  Transcriber
//
//  Created by Kavi Gupta on 10/6/25.
//

import Foundation
import SwiftUI
import AVFAudio
import FluidAudio
import OSLog

enum TranscriptionState {
    case starting
    case running
    case ending
    case inactive
}

struct Transcriber: View {
    @State private var microphoneStatus = AVAudioApplication.shared.recordPermission
    
    @State private var startingTranscription = false
    
    @State private var transcriptionState = TranscriptionState.inactive
    
    @State private var volatileTranscript = ""
    
    @State private var finalTranscript = ""
    
    @State private var updateTask: Task<Void, Never>? = nil
        
    private var microphoneAllowed: Bool {
        microphoneStatus == .granted
    }
    
    let streamingASRConfig: StreamingAsrConfig
    let streamingASR: StreamingAsrManager
    
    let audioEngine = AVAudioEngine()
    
    init() {
        streamingASRConfig = .streaming
        streamingASR = StreamingAsrManager(config: streamingASRConfig)
    }
        
    var body: some View {
        VStack {
            Text("Past Recordings")
            if microphoneAllowed {
                switch transcriptionState {
                    case .starting:
                        ProgressView("Starting...")
                    case .running:
                        Text(volatileTranscript)
                    case .ending:
                        ProgressView("Ending...")
                    case .inactive:
                        Text(finalTranscript)
                }
            } else {
                ContentUnavailableView {
                    Label("Recording Not Allowed", systemImage: "microphone.slash")
                } description: {
                    Text("Transcriber does not have permission to access the microphone. Please visit settings.")
                } actions: {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        Link(destination: url) {
                            Label("Microphone settings in Settings", systemImage: "microphone.badge.ellipsis")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                switch transcriptionState {
                    case .starting:
                        ProgressView()
                    case .running:
                        Button {
                            Task {
                                do {
                                    try await stop()
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        } label: {
                            Label("End Recording", systemImage: "stop.fill")
                        }
                    case .ending:
                        ProgressView()
                    case .inactive:
                        Button {
                            Task {
                                do {
                                    try await start()
                                } catch TranscriberError.micPermissionDenied {
                                    await refresh()
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        } label: {
                            Label("Start Recording", systemImage: "play.fill")
                        }
                        .buttonStyle(RecordingButtonStyle())
                }
            }
        }
        .refreshable {
            await refresh()
        }
    }
    
    private func start() async throws {
        
        transcriptionState = .starting
        
        do {
            guard await AVAudioApplication.requestRecordPermission() else {
                throw TranscriberError.micPermissionDenied
            }
            
            //        let models = try await AsrModels.downloadAndLoad(version: .v2)
            
            
            
            //        try await streamingASR.start(models: models, source: .microphone)
            
            try await streamingASR.start()
            
            updateTask = Task {
                for await update in await streamingASR.transcriptionUpdates {
                    if update.isConfirmed {
                        print("CONFIRMED: \(update.text)")
                    } else {
                        print("VOLATILE: \(update.text)")
                    }
                    await  refreshTranscript()
                    Logger.transcription.debug("New Update")
                    print("New Update")
                }
                Logger.transcription.debug("Update complete")
            }
                        
            let inputNode = audioEngine.inputNode
            
            let bufferSize = UInt32(truncatingIfNeeded: Int(inputNode.outputFormat(forBus: 0).sampleRate * streamingASRConfig.hypothesisChunkSeconds))
            
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputNode.outputFormat(forBus: 0)) { (buffer, time) in
                Logger.transcription.debug("New buffer tapped")
                Task {
                    await streamingASR.streamAudio(buffer)
                }
            }
            
            audioEngine.prepare()
            
            try audioEngine.start()
            
            transcriptionState = .running
        } catch {
            transcriptionState = .inactive
            throw error
        }
    }
    
    private func stop() async throws {
        transcriptionState = .ending
        
        do {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            updateTask?.cancel()
            finalTranscript = try await streamingASR.finish()
            try await streamingASR.reset()
            transcriptionState = .inactive
        } catch {
            transcriptionState = .running
            throw error
        }
        
    }
    
    private func refresh() async {
        microphoneStatus = AVAudioApplication.shared.recordPermission
    }
    
    private func refreshTranscript() async {
        volatileTranscript = await streamingASR.volatileTranscript
        finalTranscript = await streamingASR.confirmedTranscript
    }
}

struct MicrophoneNotAllowedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Recording Not Allowed", systemImage: "microphone.slash")
        } description: {
            Text("Transcriber does not have permission to access the microphone. Please visit settings.")
        } actions: {
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                Link(destination: url) {
                    Label("Microphone settings in Settings", systemImage: "microphone.badge.ellipsis")
                }
            }
        }
    }
}

enum TranscriberError: Error {
    case micPermissionDenied
    case modelDownloadAndLoadIssue
}

#Preview {
    Transcriber()
}
