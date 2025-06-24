// TranscriptionView.swift
import SwiftUI

struct TranscriptionView: View {
  @StateObject private var viewModel = TranscriptionViewModel()
  
  var body: some View {
    VStack(spacing: 20) {
      // Transcription Display
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          // Confirmed Segments
          ForEach(viewModel.confirmedSegments, id: \.text) { segment in
            Text(segment.text)
              .padding(8)
              .background(Color.green.opacity(0.1))
              .cornerRadius(8)
          }
          
          // Unconfirmed Segments
          ForEach(viewModel.unconfirmedSegments, id: \.text) { segment in
            Text(segment.text)
              .padding(8)
              .background(Color.yellow.opacity(0.1))
              .cornerRadius(8)
          }
          
          // Current Text
          if !viewModel.currentText.isEmpty {
            Text(viewModel.currentText)
              .padding(8)
              .background(Color.blue.opacity(0.1))
              .cornerRadius(8)
              .font(.system(size: 6))
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Color.gray.opacity(0.1))
      .cornerRadius(12)
      
      // Audio Level Indicator
      AudioLevelView(energy: viewModel.bufferEnergy)
        .frame(height: 50)
        .padding(.horizontal)
      
      // Status and Controls
      VStack(spacing: 15) {
        // Status Text
        Text(viewModel.statusMessage)
          .foregroundColor(.secondary)
          .font(.system(size: 8))
        
        // Control Buttons
        HStack(spacing: 30) {
          // Record Button
          Button(action: {
            viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
          }) {
            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
              .font(.system(size: 54))
              .foregroundColor(viewModel.isRecording ? .red : .blue)
          }
          
          // Clear Button
          Button(action: viewModel.clearTranscription) {
            Image(systemName: "trash.circle.fill")
              .font(.system(size: 44))
              .foregroundColor(.gray)
          }
        }
      }
    }
    .padding()
    .task {
      await viewModel.setupWhisperKit()
    }
  }
}

struct AudioLevelView: View {
  let energy: [Float]
  
  var body: some View {
    GeometryReader { geometry in
      HStack(alignment: .bottom, spacing: 2) {
        ForEach(Array(energy.enumerated()), id: \.offset) { _, value in
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.blue)
            .frame(width: geometry.size.width / CGFloat(max(1, energy.count)) - 2,
                   height: CGFloat(value) * geometry.size.height)
        }
      }
    }
  }
}
