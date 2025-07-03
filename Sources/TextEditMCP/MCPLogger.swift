//
//  MCPLogger.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation

struct MCPLogger {
    func info(_ message: String) {
        log(level: "INFO", message: message)
    }
    
    func error(_ message: String) {
        log(level: "ERROR", message: message)
    }
    
    func debug(_ message: String) {
        #if DEBUG
        log(level: "DEBUG", message: message)
        #endif
    }
    
    private func log(level: String, message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [\(level)] \(message)\n"
        
        // Write to stderr to avoid interfering with MCP protocol on stdout
        if let data = logMessage.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        
        // Also write to system log for debugging
        #if DEBUG
        NSLog("TextEditMCP [\(level)]: \(message)")
        #endif
    }
}
