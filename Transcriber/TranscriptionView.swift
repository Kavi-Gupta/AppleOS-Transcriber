//
//  TranscriptionView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

struct TranscriptionView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var body: some View {
        VStack {
            Button("Start Transcribing") {
                Task {
                    do {
                        await transcriptionManager.startRecording()
                    } catch {
                        print("Error starting transcription: \(error.localizedDescription)")
                    }
                }
            }
            
            Button("Stop Transcribing") {
                Task {
                    await transcriptionManager.stopRecording()
                }
            }
        }
    }
}

//#Preview {
//    TranscriptionView()
//}
