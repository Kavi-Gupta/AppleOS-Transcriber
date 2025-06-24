//
//  ContentView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/11/25.
//

import SwiftUI
import WhisperKit
import AVFoundation

struct WhisperKitView: View {
  var body: some View {
    Text("Whisper")
  }
}

@Observable
class WhisperKitProcessor {
  let whisperKit: WhisperKit?
  var output: [Float] = []
  
  init() async {
    print("Loading")
    self.whisperKit = try? await WhisperKit()
    print("Loaded")
  }
  
  func startRecording() {
    try? whisperKit?.audioProcessor.startRecordingLive { input in
      self.output = input
    }
  }
}

#Preview {
  WhisperKitView()
}
