//
//  WhisperKitStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

//struct WhisperKitStatusView: View {
//    @Environment(TranscriptionManager.self) private var transcriptionManager
//
//    var body: some View {
//        VStack {
//            HStack {
//                Text("WhisperKit Loaded")
//                if transcriptionManager.whisperKitLoaded {
//                    Image(systemName: "checkmark.circle.fill")
//                        .foregroundStyle(.green)
//                } else {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundStyle(.red)
//                }
//            }
//            
//            Button("Load WhisperKit") {
//                Task {
//                    try? await transcriptionManager.loadWhisperKit()
//                    print("Loading WhisperKit")
//                }
//            }
//            
//            Text(transcriptionManager.whisperKitError)
//        }
//    }
//}
