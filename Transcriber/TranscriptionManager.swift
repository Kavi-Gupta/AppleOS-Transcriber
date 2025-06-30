// TranscriptionManager.swift
import WhisperKit
import Foundation
import OSLog
import struct SwiftUI.Color

@Observable
class TranscriptionManager {
    
    let logger = Logger(subsystem: "Transcriber", category: "TranscriptionManager")

    var whisperKit: WhisperKit? = nil
    var audioStreamTranscriber: AudioStreamTranscriber? = nil
    
    var modelSuperFolder = "Models/whisperkit-coreml"
    let tokenizerSuperFolder = "Models/tokenizers"
    
    var modelVariant = ModelVariant.tinyEn
    
    var recordingState = RecordingState.stopped
    var isRecording = false
    
    let modelFiles = ["AudioEncoder.mlmodelc", "config.json", "generation_config.json", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"]
    let tokenizerFiles = ["tokenizer_config.json", "tokenizer.json", "config.json"]
    
    var modelFolder: String {
        modelSuperFolder + "/openai_whisper-" + modelVariant.description
    }
    
    var tokenizerFolder: String {
        tokenizerSuperFolder
    }
    
    var whisperKitLoaded: Bool {
        self.whisperKit != nil
    }
    
    var transcriberLoaded: Bool {
        self.whisperKit != nil && self.audioStreamTranscriber != nil
    }
    
    var audioStreamTranscriberLoaded: Bool {
        self.audioStreamTranscriber != nil
    }
    
    func loadTranscriber() async throws {
        try await self.loadWhisperKit()
        try self.loadAudioStreamTranscriber()
    }
    
    private func loadWhisperKit() async throws {
        guard let modelFolder = Bundle.main.url(forResource: self.modelFolder, withExtension: nil, subdirectory: nil) else {
            throw WhisperError.modelsUnavailable()
        }
        
        guard let tokenizerFolder = Bundle.main.url(forResource: self.tokenizerSuperFolder, withExtension: nil, subdirectory: nil) else {
            throw WhisperError.tokenizerUnavailable()
        }
        
        let whisperKitConfiguration = WhisperKitConfig(
            model: "tiny.en", modelFolder: modelFolder.absoluteString,
            tokenizerFolder: tokenizerFolder,
            verbose: true,
            logLevel: .debug,
            download: false
        )
        
        self.whisperKit = try await WhisperKit(whisperKitConfiguration)
    }
    
    private func loadAudioStreamTranscriber() throws {
        guard let whisperKit = self.whisperKit else {
            throw WhisperError.initializationError("WhisperKit is not initialized")
        }
        
        guard let tokenizer = whisperKit.tokenizer else {
            throw WhisperError.tokenizerUnavailable()
        }
        
        let decodingOptions = DecodingOptions(
            verbose: true,
            task: .transcribe,
            language: "en",
            wordTimestamps: true,
//            clipTimestamps: self.timestamps
        )
        
        let callback: AudioStreamTranscriberCallback = { previousState, nextState in
            
            self.isRecording = nextState.isRecording
            print(previousState.unconfirmedText)
            print(previousState.currentText)
        }
        
        self.audioStreamTranscriber = AudioStreamTranscriber(
            audioEncoder: whisperKit.audioEncoder,
            featureExtractor: whisperKit.featureExtractor,
            segmentSeeker: whisperKit.segmentSeeker,
            textDecoder: whisperKit.textDecoder,
            tokenizer: tokenizer,
            audioProcessor: whisperKit.audioProcessor,
            decodingOptions: decodingOptions,
            useVAD: true,
            stateChangeCallback: callback,
        )
    }
    
    func startRecording() async throws {
        guard let transcriber = self.audioStreamTranscriber else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
//        try await transcriber.startStreamTranscription()
        self.recordingState = .recording
    }
    
    func pauseRecording() async throws {
        guard self.audioStreamTranscriber != nil else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
        try await stopRecording()
        self.recordingState = .paused
    }
    
    func stopRecording() async throws {
        guard let transcriber = self.audioStreamTranscriber else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
//        await transcriber.stopStreamTranscription()
        self.recordingState = .stopped
    }
    
    init() {

    }
    
    
}


extension ModelVariant {
    public static func from(_ fromString: String) -> ModelVariant? {
        if fromString.contains("tiny.en") {
            .tinyEn
        } else if fromString.contains("tiny") {
            .tiny
        } else if fromString.contains("base.en") {
            .baseEn
        } else if fromString.contains("base") {
            .base
        } else if fromString.contains("small.en") {
            .smallEn
        } else  if fromString.contains("small") {
            .small
        } else  if fromString.contains("medium.en") {
            .mediumEn
        } else if fromString.contains("medium") {
            .medium
        } else  if fromString.contains("large-v3") {
            .largev3
        } else if fromString.contains("large-v2") {
            .largev2
        } else if fromString.contains("large") {
            .large
        } else {
            nil
        }
    }
}

enum RecordingState {
    case recording, stopped, paused
    
    var color: Color {
        switch self {
            case .recording:
                    .green
            case .stopped:
                    .red
            case .paused:
                    .yellow
        }
    }
    
    var description: String {
        switch self {
            case .recording:
                "recording"
            case .stopped:
                "stopped"
            case .paused:
                "paused"
        }
    }
}
