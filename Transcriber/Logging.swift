//
//  Logging.swift
//  Transcriber
//
//  Created by Kavi Gupta on 11/28/25.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let transcription = Logger(subsystem: subsystem, category: "Transcription")
}
