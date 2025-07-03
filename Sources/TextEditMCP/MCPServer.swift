//
//  MCPServer.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation

class MCPServer {
    private let rtfService = RTFDocumentService()
    private let logger = MCPLogger()
    private let input = FileHandle.standardInput
    private let output = FileHandle.standardOutput
    
    func start() async {
        logger.info("TextEdit MCP Server started")
        
        // Main message loop
        await runEventLoop()
    }
    
    private func runEventLoop() async {
        var buffer = ""
        
        while true {
            // Read from stdin line by line
            if let line = readLine() {
                logger.debug("Received line: \(line)")
                
                // Process the line
                await processLine(line)
            } else {
                // EOF reached, exit
                logger.info("EOF reached, exiting")
                break
            }
        }
    }
    
    private func processLine(_ line: String) async {
        do {
            // Parse JSON
            guard let jsonData = line.data(using: .utf8),
                  let message = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                logger.error("Failed to parse JSON: \(line)")
                return
            }
            
            // Process the message
            let response = try await processMessage(message)
            
            // Send response
            try await sendMessage(response)
            
        } catch {
            logger.error("Error processing line: \(error)")
        }
    }
    
    private func processMessage(_ message: [String: Any]) async throws -> [String: Any] {
        // Extract method and params
        guard let method = message["method"] as? String else {
            throw MCPError.missingMethod
        }
        
        let id = message["id"]
        let params = message["params"] as? [String: Any] ?? [:]
        
        logger.debug("Processing method: \(method)")
        
        // Handle different methods
        switch method {
        case "initialize":
            return createResponse(id: id, result: [
                "protocolVersion": "2024-11-05",
                "serverInfo": [
                    "name": "textedit-mcp",
                    "version": "1.0.0"
                ],
                "capabilities": [
                    "tools": [:],
                    "prompts": [:],
                    "resources": [:]
                ]
            ])
            
        case "notifications/initialized":
            // This is just a notification, no response needed
            return [:]
            
        case "tools/list":
            return createResponse(id: id, result: [
                "tools": [
                    [
                        "name": "create_rtf_document",
                        "description": "Create a formatted RTF document with TextEdit compatibility",
                        "inputSchema": [
                            "type": "object",
                            "properties": [
                                "content": [
                                    "type": "string",
                                    "description": "Document content with formatting markup"
                                ],
                                "output_path": [
                                    "type": "string", 
                                    "description": "Path where the RTF file will be saved"
                                ],
                                "template": [
                                    "type": "string",
                                    "enum": ["business", "technical", "meeting", "custom"],
                                    "description": "Document template to use",
                                    "default": "business"
                                ]
                            ],
                            "required": ["content", "output_path"]
                        ]
                    ]
                ]
            ])
            
        case "resources/list":
            // Return empty resources list
            return createResponse(id: id, result: ["resources": []])
            
        case "tools/call":
            return try await executeTool(params: params, id: id)
            
        default:
            // Log unhandled methods but don't crash
            logger.debug("Unhandled method: \(method)")
            if id != nil {
                // Only respond if there's an ID (it's a request, not a notification)
                return createResponse(id: id, result: [:])
            }
            return [:]
        }
    }
    
    private func executeTool(params: [String: Any], id: Any?) async throws -> [String: Any] {
        guard let toolName = params["name"] as? String,
              let arguments = params["arguments"] as? [String: Any] else {
            throw MCPError.invalidParameters
        }
        
        switch toolName {
        case "create_rtf_document":
            let content = arguments["content"] as? String ?? ""
            let outputPath = arguments["output_path"] as? String ?? ""
            let template = arguments["template"] as? String ?? "business"
            
            logger.info("Creating RTF document at: \(outputPath)")
            
            let result = try await rtfService.createDocument(
                content: content,
                outputPath: outputPath,
                template: template
            )
            
            return createResponse(id: id, result: [
                "content": [
                    [
                        "type": "text",
                        "text": result.success ? 
                            "✅ RTF document created successfully at: \(result.path)" :
                            "❌ Failed to create document: \(result.message)"
                    ]
                ]
            ])
            
        default:
            throw MCPError.unknownTool(toolName)
        }
    }
    
    private func sendMessage(_ message: [String: Any]) async throws {
        // Don't send empty messages (for notifications)
        if message.isEmpty {
            return
        }
        
        let data = try JSONSerialization.data(withJSONObject: message, options: [.sortedKeys])
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw MCPError.encodingError
        }
        
        // Write to stdout with newline
        if let outputData = (jsonString + "\n").data(using: .utf8) {
            output.write(outputData)
        }
    }
    
    private func createResponse(id: Any?, result: [String: Any]) -> [String: Any] {
        var response: [String: Any] = [
            "jsonrpc": "2.0",
            "result": result
        ]
        
        if let id = id {
            response["id"] = id
        }
        
        return response
    }
}

enum MCPError: Error {
    case invalidJSON
    case missingMethod
    case unknownMethod(String)
    case invalidParameters
    case unknownTool(String)
    case encodingError
}
