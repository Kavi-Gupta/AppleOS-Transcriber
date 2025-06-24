// TranscriptionViewModel.swift
import SwiftUI
import WhisperKit

@MainActor
class TranscriptionViewModel: ObservableObject {
  @Published var confirmedSegments: [TranscriptionSegment] = []
  @Published var unconfirmedSegments: [TranscriptionSegment] = []
  @Published var currentText: String = ""
  @Published var bufferEnergy: [Float] = []
  @Published var isRecording: Bool = false
  @Published var statusMessage: String = "Ready to record"
  
  private let transcriptionManager = TranscriptionManager()
  private var transcriptionTask: Task<Void, Error>?
  
  func setupWhisperKit() async {
    do {
      try await transcriptionManager.setupWhisperKit()
      statusMessage = "WhisperKit initialized"
    } catch {
      statusMessage = "Error initializing WhisperKit: \(error.localizedDescription)"
    }
  }
  
  func startRecording() {
    transcriptionTask = Task {
      do {
        isRecording = true
        statusMessage = "Recording..."
        
        try await transcriptionManager.startTranscription { [weak self] oldState, newState in
          Task { @MainActor [weak self] in
            self?.updateTranscriptionState(oldState: oldState, newState: newState)
          }
        }
      } catch {
        await MainActor.run {
          statusMessage = "Error: \(error.localizedDescription)"
          isRecording = false
        }
      }
    }
  }
  
  func stopRecording() {
    transcriptionTask?.cancel()
    
    Task {
      await transcriptionManager.stopTranscription()
      await MainActor.run {
        isRecording = false
        statusMessage = "Recording stopped"
      }
    }
  }
  
  private func updateTranscriptionState(oldState: AudioStreamTranscriber.State, newState: AudioStreamTranscriber.State) {
    confirmedSegments = newState.confirmedSegments
    unconfirmedSegments = newState.unconfirmedSegments
    currentText = newState.currentText
    bufferEnergy = newState.bufferEnergy
  }
  
  func clearTranscription() {
    confirmedSegments = []
    unconfirmedSegments = []
    currentText = ""
    statusMessage = "Transcription cleared"
  }
}
