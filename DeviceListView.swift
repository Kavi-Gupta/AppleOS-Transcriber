//
//  DeviceListView.swift
//  Transcriber
//
//  Created by Kavi Gupta on 7/2/25.
//

import SwiftUI
import WhisperKit

struct DeviceListView: View {
    @Environment(TranscriptionManager.self) private var transcriptionManager
    
    private var selectedDeviceBinding: Binding<DeviceID?> {
        Binding<DeviceID?>(
            get: {
                transcriptionManager.microphoneHandler.currentInputDevice?.id
            },
            set: { newID in
                if let newID,
                    let newDevice = transcriptionManager.microphoneHandler.inputDevices.first(where: { $0.id == newID }) {
                    transcriptionManager.microphoneHandler.currentInputDevice = newDevice
                }
            }
        )
    }
    
    var body: some View {
        VStack {
            Text("Available Devices")
            List(transcriptionManager.microphoneHandler.inputDevices, id: \.self.id, selection: selectedDeviceBinding) {
                Text($0.name)
            }
        }
    }
}

#Preview {
    DeviceListView()
}
