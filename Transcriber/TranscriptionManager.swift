// TranscriptionManager.swift
import WhisperKit
import Foundation

//enum TranscriptionError: Error {
//  case modelInitializationFailed(String)
//  case networkError(String)
//  case tokenizerUnavailable
//  case unknown(String)
//}

@Observable
class TranscriptionManager {
    var whisperKit: WhisperKit? = nil
    
    var whisperKitError = ""
    var modelSuperFolder = "Models/whisperkit-coreml"
    let tokenizerSuperFolder = "Models/tokenizers"
    var modelVariant = ModelVariant.tinyEn
    var audioStreamTranscriber: AudioStreamTranscriber? = nil
    var timestamps = [Float]()
    
//    var missingModelFiles = ["Checking"]
//    var missingTokenizerFiles = ["Checking"]
    
    var missingModelFiles: [String] {
        let modelFiles = ["AudioEncoder.mlmodelc", "config.json", "generation_config.json", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"]
        print("Looking for model files in: \(modelFolder)")
        let missingFiles = self.findMissingFiles(files: modelFiles, in: modelFolder)
        
        return missingFiles
    }
    
    var missingTokenizerFiles: [String] {
        let tokenizerFiles = ["tokenizer_config.json", "tokenizer.json", "config.json"]
        print("Looking for tokenizer files in: \(tokenizerFolder)")
        let missingFiles = self.findMissingFiles(files: tokenizerFiles, in: tokenizerFolder)
        
        return missingFiles
    }
    
    var modelFolder: String {
        modelSuperFolder + "/openai_whisper-" + modelVariant.description
    }
    
    var tokenizerFolder: String {
        tokenizerSuperFolder + "/whisper-" + modelVariant.description
    }
    
    var whisperKitLoaded: Bool {
        self.whisperKit != nil
    }
    
    var audioStreamTranscriberLoaded: Bool {
        self.audioStreamTranscriber != nil
    }
    
    var modelFilesPresent: Bool {
        missingModelFiles.isEmpty
    }
    
    var tokenizerFilesPresent: Bool {
        missingTokenizerFiles.isEmpty
    }
    
    func getAvailableModels() -> [ModelVariant] {
        var availableModels = [ModelVariant]()
        
        if let modelFolders = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: modelSuperFolder) {
            for modelFolder in modelFolders {
                if let modelVariant = ModelVariant.from(modelFolder.lastPathComponent) {
                    availableModels.append(modelVariant)
                }
            }
        }
        
        return availableModels
    }
    
    private func findMissingFiles(files: [String], in subdirectory: String? = nil) -> [String] {
        return files.filter {
            Bundle.main.url(forResource: $0, withExtension: nil, subdirectory: subdirectory) == nil
        }
    }
    
    func loadWhisperKit() async {
        guard let modelFolder = Bundle.main.url(forResource: self.modelFolder, withExtension: nil, subdirectory: nil) else {
            whisperKitError = "Could not find model folder"
            return
        }
        
        guard let tokenizerFolder = Bundle.main.url(forResource: self.tokenizerSuperFolder, withExtension: nil, subdirectory: nil) else {
            whisperKitError = "Could not find tokenizer folder"
            return
        }
        
        let computeOptions = ModelComputeOptions(melCompute: .cpuAndGPU, audioEncoderCompute: .cpuAndGPU, textDecoderCompute: .cpuAndGPU, prefillCompute: .cpuAndGPU)
        let whisperKitConfiguration = WhisperKitConfig(model: "tiny.en", modelFolder: modelFolder.absoluteString, tokenizerFolder: tokenizerFolder, /*computeOptions: computeOptions,*/ verbose: true, logLevel: .debug, download: false)
        

        do {
            print("Initializing WhisperKit")
            self.whisperKit = try await WhisperKit(whisperKitConfiguration)
            whisperKitError = ""
            print("WhisperKit Initialized")
            print("Model folder: \(whisperKit?.modelFolder)")
            print("Tokenizer folder: \(whisperKit?.tokenizerFolder)")
        } catch {
            whisperKitError = error.localizedDescription
            print(whisperKitError)
        }
        
    }
    
    func loadAudioStreamTranscriber() {
        guard let whisperKit = self.whisperKit else {
            print("Whisper Kit must be initialized")
            return
        }
        
        guard let tokenizer = whisperKit.tokenizer else {
            print("No tokenizer")
            return
        }
        
        let decodingOptions = DecodingOptions(
            verbose: true,
            task: .transcribe,
            language: "en",
            wordTimestamps: true,
            clipTimestamps: self.timestamps
        )
        
        let callback: AudioStreamTranscriberCallback = { previousState, nextState in
//            print("Previous State: \(previousState)")
//            print("Next State: \(nextState)")
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
    
    func startRecording() async {
        guard let transcriber = self.audioStreamTranscriber else {
            print("Transcriber not setup")
            return
        }
        
        do {
            try await transcriber.startStreamTranscription()
        } catch {
            print("Error starting transcription: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() async {
        guard let transcriber = self.audioStreamTranscriber else {
            print("Transcriber not setup")
            return
        }
        
        await transcriber.stopStreamTranscription()
    }
    
    init() {
//        let hubApi = HubApi(downloadBase: self.tokenizerFolder, useBackgroundSession: useBackgroundSession)
//        
//        // Attempt to load tokenizer from local folder if specified
//        let resolvedTokenizerFolder = hubApi.localRepoLocation(HubApi.Repo(id: tokenizerName))
//        let tokenizerConfigPath = resolvedTokenizerFolder.appendingPathComponent("tokenizer.json")
//        
//        // Check if 'tokenizer.json' exists in the folder
//        if FileManager.default.fileExists(atPath: tokenizerConfigPath.path) {
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
