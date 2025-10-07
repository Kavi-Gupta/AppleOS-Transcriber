// TranscriptionManager.swift
import WhisperKit
import Foundation
import OSLog
import struct SwiftUI.Color

@Observable
class TranscriptionManager {
    
    let logger = Logger(subsystem: "Transcriber", category: "TranscriptionManager")
    let microphoneHandler: MicrophoneHandler

    var whisperKit: WhisperKit? = nil
    var audioStreamTranscriber: AudioStreamTranscriber? = nil
    
    var modelSuperFolder = "Models/whisperkit-coreml"
    let tokenizerSuperFolder = "Models/tokenizers"
    
    var modelVariant = ModelVariant.tinyEn
    
    var previousRecordingState = RecordingState.stopped
    var recordingState = RecordingState.stopped {
        willSet {
            previousRecordingState = recordingState
        }
    }
    var isRecording = false
    
    let modelFiles = ["AudioEncoder.mlmodelc", "config.json", "generation_config.json", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"]
    let tokenizerFiles = ["tokenizer_config.json", "tokenizer.json", "config.json"]
    
    var modelFolder: String {
        modelSuperFolder + "/openai_whisper-" + modelVariant.description
    }
    
    var mostRecentBufferState: AudioStreamTranscriber.State? = nil
    
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
            wordTimestamps: false,
//            clipTimestamps: self.timestamps
        )
        
        let callback: AudioStreamTranscriberCallback = { previousState, nextState in
            if nextState.isRecording {
                self.recordingState = .recording
            }
            self.isRecording = nextState.isRecording
            self.mostRecentBufferState = nextState
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
                        
        do {
            logger.info("Starting")
            self.recordingState = .starting
            try await transcriber.startStreamTranscription(inputDeviceID: microphoneHandler.currentInputDevice?.id)
        } catch {
            self.recordingState = .stopped
            logger.error("Error starting recording: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    func pauseRecording() async throws {
        guard let transcriber = self.audioStreamTranscriber else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
        self.recordingState = .pausing
        await transcriber.pauseStreamTranscription()
        self.recordingState = .paused
    }
    
    func resumeRecording() async throws {
        guard let transcriber = self.audioStreamTranscriber else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
        self.recordingState = .resuming
        try await transcriber.resumeStreamTranscription(inputDeviceID: microphoneHandler.currentInputDevice?.id)
        self.recordingState = .recording
    }
    
    func startOrResumeRecording() async throws {
        if recordingState == .stopped {
            try await self.startRecording()
        } else if recordingState == .paused {
            try await self.resumeRecording()
        }
    }
    
    func stopRecording() async throws {
        guard let transcriber = self.audioStreamTranscriber else {
            throw WhisperError.initializationError("Audio stream transcriber not initialized")
        }
        
        logger.info("Stopping")
        self.recordingState = .stopping
        await transcriber.stopStreamTranscription()
        logger.info("Stopped")
        self.recordingState = .stopped
    }
    
    init() {
        self.microphoneHandler = MicrophoneHandler()
        logger.info("Available devices: \(self.microphoneHandler.inputDevices, privacy: .public)")
    }
}

@Observable
class MicrophoneHandler {
    var inputDevices: [AudioDevice]
    var currentInputDevice: AudioDevice? = nil
    
    init() {
        self.inputDevices = AudioProcessor.getAudioDevices()
        if self.inputDevices.count > 0 {
            self.currentInputDevice = inputDevices[0]
        }
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

enum RecordingActions {
    case start, pause, resume, stop
}

enum RecordingButtonTypes {
    case play, pause
}

enum RecordingState {
    case starting, recording, pausing, paused, resuming, stopping, stopped
    
    var color: Color {
        switch self {
            case .starting:
                    .green.opacity(0.5)
            case .recording:
                    .green
            case .pausing, .resuming:
                    .yellow.opacity(0.5)
            case .paused:
                    .yellow
            case .stopping:
                    .blue.opacity(0.5)
            case .stopped:
                    .blue
            
        }
    }
    
    var description: String {
        switch self {
            case .starting:
                "starting"
            case .recording:
                "recording"
            case .pausing:
                "pausing"
            case .paused:
                "paused"
            case .resuming:
                "resuming"
            case .stopping:
                "stopping"
            case .stopped:
                "stopped"
        }
    }
    
    var possibleActions: [RecordingActions] {
        switch self {
            case .starting, .pausing, .resuming:
                [.stop]
            case .stopping:
                []
            case .recording:
                [.pause, .stop]
            case .paused:
                [.resume, .stop]
            case .stopped:
                [.start]
        }
    }
}

extension TranscriptionManager {
    var showPauseOrPlayButton: RecordingButtonTypes {
        
    // intuition: in a intermediate state, show the next state but greyed out, if cancelling an intermediate state, revert to previous
        switch self.recordingState {
            case .starting:
                RecordingButtonTypes.pause
            case .recording:
                RecordingButtonTypes.pause
            case .pausing:
                RecordingButtonTypes.play
            case .resuming:
                RecordingButtonTypes.pause
            case .paused:
                RecordingButtonTypes.play
            case .stopping:
                switch self.previousRecordingState {
                    case .resuming:
                        RecordingButtonTypes.pause
                    default:
                        RecordingButtonTypes.play
                }
            case .stopped:
                RecordingButtonTypes.play
        }
    }
}
