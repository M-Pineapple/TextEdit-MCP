//
//  main.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation

// Start the MCP server
@main
struct TextEditMCP {
    static func main() async {
        let server = MCPServer()
        await server.start()
    }
}
