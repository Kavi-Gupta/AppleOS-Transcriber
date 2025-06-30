//
//  AvailableModelsView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/24/25.
//

import SwiftUI

struct AvailableModelsView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager

    var body: some View {
        VStack {
            Text("Available Models")
            List {
                ForEach(transcriptionManager.getAvailableModels(), id: \.self) { modelVariant in
                    Text(modelVariant.description)
                }
            }
        }
        
    }
}

#Preview {
    AvailableModelsView()
}
