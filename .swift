//
//  AudioStreamTranscriberStatusView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/23/25.
//


struct AudioStreamTranscriberStatusView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager

    var body: some View {
        VStack {
            HStack {
                Text("AudioStreamTranscriber Loaded")
                if transcriptionManager.audioStreamTranscriberLoaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            
            Button("Load AudioStreamTranscriber") {
                Task {
                    transcriptionManager.loadAudioStreamTranscriber()
                    print("Loading AudioStreamTransciber")
                }
            }
            
            Text(transcriptionManager.whisperKitError)
        }
    }
}