//
//  StatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

struct MainView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            RecordingStatusView()
            Spacer()
        } detail: {
            TranscriptionView()
        }
        .toolbar {
            TranscriptionRecordingButtons()
        }
        #elseif os(iOS)
        TabView {
            Tab("Status", systemImage: "list.bullet.clipboard.fill") {
                RecordingStatusView()
                Spacer()
            }
            Tab("Transcribe", systemImage: "microphone.fill") {
                NavigationStack {
                    TranscriptionView()
                        .navigationTitle("Transcribe")
                        .toolbar {
                            TranscriptionRecordingButtons()
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}



#Preview {
    @Previewable @State var transcriptionManager = TranscriptionManager()
    MainView()
        .environment(transcriptionManager)
}
