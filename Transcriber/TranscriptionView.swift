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
            RecordingStatusView()
            Text(transcriptionManager.mostRecentBufferState?.currentText ?? "")
        }
        
    }
}

//#Preview {
//    TranscriptionView()
//}
