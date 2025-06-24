// TranscriptionManager.swift
import WhisperKit
import Foundation

enum TranscriptionError: Error {
  case modelInitializationFailed(String)
  case networkError(String)
  case tokenizerUnavailable
  case unknown(String)
}

actor TranscriptionManager {
  private var whisperKit: WhisperKit?
  private var audioStreamTranscriber: AudioStreamTranscriber?
  
  func setupWhisperKit() async throws {
    guard let resourcePath = Bundle.main.resourcePath else {
      throw TranscriptionError.modelInitializationFailed("Could not find resource path")
    }
    
    let modelPath = Bundle.main.url(forResource: "distil-whisper_distil-large-v3", withExtension: nil)
    let tokenizerPath = Bundle.main.url(forResource: "tokenizer", withExtension: nil)
    
    print("Model Path: \(modelPath)")
    print("Tokenizer Path: \(tokenizerPath)")

    
    print("\nResource path: \(resourcePath)")
    
    // Verify the model files exist
    let modelFiles = ["AudioEncoder.mlmodelc", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"]
    for file in modelFiles {
      let path = (resourcePath as NSString).appendingPathComponent(file)
      if FileManager.default.fileExists(atPath: path) {
        print("✓ Found \(file)")
      } else {
        print("✗ Missing \(file)")
        throw TranscriptionError.modelInitializationFailed("Missing model file: \(file)")
      }
    }
    
//    let config = WhisperKitConfig(
//      modelFolder: resourcePath,
//      tokenizerFolder: URL(fileURLWithPath: resourcePath),
//      computeOptions: ModelComputeOptions(
//        melCompute: .cpuAndGPU,
//        audioEncoderCompute: .cpuAndNeuralEngine,
//        textDecoderCompute: .cpuAndNeuralEngine
//      ),
//      verbose: true,
//      logLevel: .debug,
//      prewarm: false
//    )
    
//    let config = WhisperKitConfig(
//      modelFolder: modelPath?.absoluteString,
//      tokenizerFolder: tokenizerPath,
//      verbose: true,
//      logLevel: .debug,
//      prewarm: false
//    )
    
    do {
      print("\nInitializing WhisperKit...")
      whisperKit = try await WhisperKit(WhisperKitConfig(model: "tiny.en"))
      try? await whisperKit?.loadModels()
      
      guard let tokenizer = whisperKit?.tokenizer else {
        throw TranscriptionError.tokenizerUnavailable
      }
      print("WhisperKit initialized successfully with tokenizer")
      
    } catch {
      print("Error details: \(error)")
      throw TranscriptionError.modelInitializationFailed("Failed to initialize WhisperKit: \(error.localizedDescription)")
    }
  }
  
  private func listFiles(at path: String, label: String) {
    let fileManager = FileManager.default
    do {
      let items = try fileManager.contentsOfDirectory(atPath: path)
      print("\(label) contents at \(path):")
      for item in items.sorted() {
        let fullPath = (path as NSString).appendingPathComponent(item)
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)
        print("  - \(item)\(isDirectory.boolValue ? "/" : "")")
      }
    } catch {
      print("Error listing \(label): \(error)")
    }
  }
  
  func startTranscription(stateChangeCallback: @escaping (AudioStreamTranscriber.State, AudioStreamTranscriber.State) -> Void) async throws {
    guard let whisperKit = whisperKit,
          let tokenizer = whisperKit.tokenizer else {
      throw WhisperError.tokenizerUnavailable()
    }
    
    audioStreamTranscriber = AudioStreamTranscriber(
      audioEncoder: whisperKit.audioEncoder,
      featureExtractor: whisperKit.featureExtractor,
      segmentSeeker: whisperKit.segmentSeeker,
      textDecoder: whisperKit.textDecoder,
      tokenizer: tokenizer,
      audioProcessor: whisperKit.audioProcessor,
      decodingOptions: DecodingOptions()
    ) { oldState, newState in
      stateChangeCallback(oldState, newState)
    }
    
    try await audioStreamTranscriber?.startStreamTranscription()
  }
  
  func stopTranscription() async {
    await audioStreamTranscriber?.stopStreamTranscription()
  }
}
