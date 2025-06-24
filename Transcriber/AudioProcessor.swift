//
//  AudioProcessor.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/22/25.
//

import Foundation
import AVFoundation
import WhisperKit

class AudioProcessor {
  let engine = AVAudioEngine()
  
  
  func convertBuffer() {
    guard let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt32, sampleRate: Double(WhisperKit.sampleRate), channels: AVAudioChannelCount(1), interleaved: false) else {
      return
    }
    
    guard let converter = AVAudioConverter(from: engine.inputNode.outputFormat(forBus: 0), to: desiredFormat) else {
      return
    }
  }
}
