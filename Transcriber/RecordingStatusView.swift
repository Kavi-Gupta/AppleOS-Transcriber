//
//  RecordingStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/30/25.
//

import SwiftUI

struct RecordingStatusView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(transcriptionManager.recordingState.color)
            Text(transcriptionManager.recordingState.description.capitalized)
        }
    }
}

#Preview {
    RecordingStatusView()
}
