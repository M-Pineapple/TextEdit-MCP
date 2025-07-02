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
    
    func start() async {
        // Initialize stdio transport
        let input = FileHandle.standardInput
        let output = FileHandle.standardOutput
        
        logger.info("TextEdit MCP Server started")
        
        // Process messages continuously
        await processMessages(input: input, output: output)
    }
    
    private func processMessages(input: FileHandle, output: FileHandle) async {
        var buffer = ""
        
        while true {
            autoreleasepool {
                // Read available data
                let data = input.availableData
                
                if data.isEmpty {
                    // No more data, exit gracefully
                    logger.info("No more data, shutting down")
                    return
                }
                
                // Append to buffer
                if let str = String(data: data, encoding: .utf8) {
                    buffer += str
                    
                    // Process complete lines
                    while let lineRange = buffer.range(of: "\n") {
                        let line = String(buffer[..<lineRange.lowerBound])
                        buffer.removeSubrange(...lineRange.lowerBound)
                        
                        if !line.isEmpty {
                            Task {
                                await processLine(line, output: output)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func processLine(_ line: String, output: FileHandle) async {
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
            try await sendMessage(response, to: output)
            
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
                "protocolVersion": "1.0",
                "serverName": "TextEdit MCP",
                "serverVersion": "1.0.0",
                "capabilities": [
                    "tools": true
                ]
            ])
            
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
            
        case "tools/call":
            return try await executeTool(params: params, id: id)
            
        default:
            throw MCPError.unknownMethod(method)
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
    
    private func sendMessage(_ message: [String: Any], to output: FileHandle) async throws {
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
