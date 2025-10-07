//
//  TranscriptionRecordingButtons.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/30/25.
//

import SwiftUI

struct TranscriptionRecordingButtons: ToolbarContent {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var recordingState: RecordingState {
        transcriptionManager.recordingState
    }
    
    struct PauseButton: View {
        @Environment(TranscriptionManager.self) private var transcriptionManager
        
        var body: some View {
            Button {
                Task {
                    try? await transcriptionManager.pauseRecording()
                }
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .disabled(!transcriptionManager.recordingState.possibleActions.contains(.pause))
        }
    }
    
    struct PlayButton: View {
        @Environment(TranscriptionManager.self) private var transcriptionManager
        
        var recordingState: RecordingState {
            transcriptionManager.recordingState
        }
        
        var body: some View {
            Button {
                Task {
                    do {
                        if !transcriptionManager.transcriberLoaded {
                            try await transcriptionManager.loadTranscriber()
                        }
                        try? await transcriptionManager.startRecording()
                    } catch {
                        print("\(error.localizedDescription)")
                    }
                }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .disabled(!(recordingState.possibleActions.contains(.start) || recordingState.possibleActions.contains(.resume)))
        }
    }
    
    struct StopButton: View {
        @Environment(TranscriptionManager.self) private var transcriptionManager
        
        var body: some View {
            Button {
                Task {
                    try? await transcriptionManager.stopRecording()
                }
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .disabled(!transcriptionManager.recordingState.possibleActions.contains(.stop))
        }
    }
    var body: some ToolbarContent {
        
        ToolbarItem(placement: .principal) {
            switch transcriptionManager.showPauseOrPlayButton {
                case .play:
                    PlayButton()
                case .pause:
                    PauseButton()
            }
        }
        
        ToolbarItem(placement: .destructiveAction) {
            StopButton()
        }
    }
}


