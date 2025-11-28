//
//  RecordingButtonStyle.swift
//  Transcriber
//
//  Created by Kavi Gupta on 11/24/25.
//

import SwiftUI

struct RecordingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .fill(.red)
    }
}

#Preview {
    Button("hello") {
        
    }
    .buttonStyle(RecordingButtonStyle())
    
}
