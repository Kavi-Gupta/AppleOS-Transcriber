//
//  ContentView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/11/25.
//

import SwiftUI
import WhisperKit
import AVFoundation

@Observable
class MicrophonePermissionsManager {
  private(set) var status = AVCaptureDevice.authorizationStatus(for: .audio)
  
  func refresh() {
    withAnimation {
      status = AVCaptureDevice.authorizationStatus(for: .audio)
    }
  }
  
  func handlePermissions() async -> Bool {
    self.refresh()
    switch status {
      case .authorized:
        return true
      case .notDetermined:
        return await self.requestMicrophonePermissions()
      case .denied:
        return false
      case .restricted:
        return false
      default:
        return false
    }
  }
  
  func requestMicrophonePermissions() async -> Bool {
    let granted = await AVCaptureDevice.requestAccess(for: .audio)
    self.refresh()
    return granted
  }
}

private var audioEngine = AVAudioEngine()

struct ContentViewOld: View {
  @State private var microphonePermissionsManager = MicrophonePermissionsManager()
  @State private var isRecording = false
  var body: some View {
    VStack {
      Text("Hello, world!")
      if !isRecording {
        Button("Start recording") {
          Task {
            let microphoneAccessGranted = await microphonePermissionsManager.handlePermissions()
            guard microphoneAccessGranted else {
              print("Failed to get microphone access")
              return
            }
            
            await startAudioProcessing()
            isRecording = true
          }
        }
      } else {
        Button("Stop Recording") {
          stopAudioProcessing()
          isRecording = false
        }
      }
      
      
      HStack {
        Image(systemName: "microphone.fill")
          .foregroundStyle(microphonePermissionsManager.status.color)
        Text(microphonePermissionsManager.status.text)
      }
      
      Button("Check Microphone Permissions") {
        microphonePermissionsManager.refresh()
      }
    }
    .padding()
  }
}

extension AVAuthorizationStatus {
  var text: String {
    switch self {
      case .authorized:
        return "Allowed"
      case.notDetermined:
        return "Waiting for permissions"
      case .denied:
        return "Denied"
      case .restricted:
        return "Restricted"
      default:
        return "Unknown"
    }
  }
  
  var color: Color {
    switch self {
      case .authorized:
        return .green
      case.notDetermined:
        return .blue
      case .denied:
        return .red
      case .restricted:
        return .red
      default:
        return .gray
    }
  }
}

func recordingCallback(values: [Float]) {
  print(values)
}

func stopAudioProcessing() {
  audioEngine.inputNode.removeTap(onBus: 0)
  audioEngine.stop()
}

func startAudioProcessing() async {
  do {
    let inputNode = audioEngine.inputNode
    let outputNode = audioEngine.outputNode
    let downMixer = AVAudioMixerNode()
    
    audioEngine.attach(downMixer)
    
    if let device = AVCaptureDevice.default(for: .audio) {
      print("Default Device: \(device.localizedName); ID: \(device.uniqueID)")
    }
        
    #if os(iOS)
    await MainActor.run {
      do {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        print("Failed to configure audio session: \(error.localizedDescription)")
      }
    }
    #endif
    
    let inputFormat = inputNode.inputFormat(forBus: 0)
    
    guard let downMixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true) else {
      print("Failed to create format")
      return
    }
    
    print("Down mixer format: \(downMixerFormat.description)")
    
    audioEngine.connect(inputNode, to: downMixer, format: inputFormat)
    audioEngine.connect(downMixer, to: outputNode, format: inputFormat)
    
    downMixer.installTap(onBus: 0, bufferSize: 1024, format: downMixerFormat) { (buffer, time) in
      let channelData = buffer.floatChannelData?[0]
      
      if let data = channelData {
        let frames = buffer.frameLength
        var max: Float = 0
        
        for i in 0..<Int(frames) {
          let sample = data[i]
          if sample > max {
            max = sample
          }
        }
        
        print("Max audio: \(max)")
      }
    }

    
//    inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, time) in
//      let channelData = buffer.floatChannelData?[0]
//      
//      if let data = channelData {
//        let frames = buffer.frameLength
//        var max: Float = 0
//        
//        for i in 0..<Int(frames) {
//          let sample = abs(data[i])
//          if sample > max {
//            max = sample
//          }
//        }
//        
//        print("Max audio level: \(max)")
//      }
//    }
    
    
    audioEngine.prepare()
    try audioEngine.start()
    print("Audio engine started")
  } catch {
    print("Failed to start processing audio: \(error.localizedDescription)")
  }
  
}

#Preview {
  ContentViewOld()
}
