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
            TabView {
                StatusView()
                    .tabItem {
                        Label("Status", systemImage: "cross.circle.fill")
                    }
                TranscriptionView()
                    .tabItem {
                        Label("Transcribe", systemImage: "list.bullet.rectangle.portrait.fill")
                    }
            }
        }
        .environment(transcriptionManager)
    }
}
