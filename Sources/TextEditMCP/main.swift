//
//  main.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation

// Start the MCP server
let server = MCPServer()

// Create a semaphore to keep the process running
let semaphore = DispatchSemaphore(value: 0)

// Run server in a Task
Task {
    await server.start()
    // This should never be reached as server.start() runs forever
    semaphore.signal()
}

// Wait forever
semaphore.wait()
