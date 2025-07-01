//
//  RecordingStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/30/25.
//

import SwiftUI

struct RecordingStatusView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var bufferEnergy: [Float] {
        transcriptionManager.mostRecentBufferState?.bufferEnergy ?? []
    }
    
    var sum: Float {
       bufferEnergy.reduce(0.0, +)
    }
    
    var average: Float {
        if bufferEnergy.count > 0 {
            return sum / Float(bufferEnergy.count)
        } else {
            return 0.0
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(transcriptionManager.recordingState.color)
            Text(transcriptionManager.recordingState.description.capitalized)
            Text("Avg: \(average)")
            Text("Sum: \(sum)")
        }
    }
}

#Preview {
    RecordingStatusView()
}
