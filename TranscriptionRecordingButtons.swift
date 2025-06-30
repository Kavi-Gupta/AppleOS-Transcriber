//
//  TranscriptionRecordingButtons.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/30/25.
//

import SwiftUI

struct TranscriptionRecordingButtons: ToolbarContent {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if transcriptionManager.recordingState == .recording {
                Button {
                    Task {
                        try? await transcriptionManager.pauseRecording()
                    }
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
            } else {
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
            }
            
        }
        
        ToolbarItem(placement: .destructiveAction) {
            Button {
                Task {
                    try? await transcriptionManager.stopRecording()
                }
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .disabled(!(transcriptionManager.recordingState == .paused || transcriptionManager.recordingState == .recording))
        }
    }
}
