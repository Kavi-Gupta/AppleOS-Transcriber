//
//  StatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

struct StatusView: View {
    var body: some View {
        Group {
            #if os(macOS)
            HStack {
                ModelFilesStatusView()
                TokenizerFilesStatusView()
                AvailableModelsView()
                WhisperKitStatusView()
                AudioStreamTranscriberStatusView()
            }
            #elseif os(iOS)
            VStack {
                ModelFilesStatusView()
                TokenizerFilesStatusView()
                WhisperKitStatusView()
                AudioStreamTranscriberStatusView()
                AvailableModelsView()
            }
            #endif
        }
        .padding()
        
    }
}

#Preview {
    StatusView()
}
