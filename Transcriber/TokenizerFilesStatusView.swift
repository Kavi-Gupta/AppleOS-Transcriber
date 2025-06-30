//
//  TokenizerFilesStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//

import SwiftUI

struct TokenizerFilesStatusView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    var body: some View {
        VStack {
            HStack {
                Text("Tokenizer Files")
                if transcriptionManager.tokenizerFilesPresent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                
            }
            List {
                ForEach(transcriptionManager.missingTokenizerFiles, id: \.self) {
                    Text($0)
                }
            }
        }
    }
}
