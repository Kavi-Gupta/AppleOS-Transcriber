//
//  ModelFilesStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

struct ModelFilesStatusView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager

    var body: some View {
        VStack {
            HStack {
                Text("Model Files")
                if transcriptionManager.modelFilesPresent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                
            }
            List {
                ForEach(transcriptionManager.missingModelFiles, id: \.self) {
                    Text($0)
                }
            }
        }
    }
}
