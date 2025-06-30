//
//  TranscriberApp.swift
//  Transcriber
//
//  Created by Kavi Gupta on 6/11/25.
//

import SwiftUI

@main
struct TranscriberApp: App {
    @State var transcriptionManager = TranscriptionManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .environment(transcriptionManager)
    }
}
