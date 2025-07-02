//
//  MCPServer.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation

class MCPServer {
    private let rtfService = RTFDocumentService()
    
    func start() async {
        // Initialize stdio transport
        let input = FileHandle.standardInput
        let output = FileHandle.standardOutput
        
        // Log to stderr to avoid interfering with protocol
        let logger = MCPLogger()
        logger.info("TextEdit MCP Server started")
        
        // Main message loop
        while true {
            do {
                // Read JSON-RPC message
                guard let message = try await readMessage(from: input) else {
                    break
                }
                
                // Process the message
                let response = try await processMessage(message)
                
                // Send response
                try await sendMessage(response, to: output)
                
            } catch {
                logger.error("Error processing message: \(error)")
            }
        }
    }
    
    private func readMessage(from input: FileHandle) async throws -> [String: Any]? {
        // Read line from stdin
        guard let data = input.availableData.isEmpty ? nil : input.availableData,
              let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !line.isEmpty else {
            return nil
        }
        
        // Parse JSON
        guard let jsonData = line.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw MCPError.invalidJSON
        }
        
        return json
    }
    
    private func processMessage(_ message: [String: Any]) async throws -> [String: Any] {
        // Extract method and params
        guard let method = message["method"] as? String else {
            throw MCPError.missingMethod
        }
        
        let id = message["id"]
        let params = message["params"] as? [String: Any] ?? [:]
        
        // Handle different methods
        switch method {
        case "initialize":
            return createResponse(id: id, result: [
                "protocolVersion": "1.0",
                "serverName": "TextEdit MCP",
                "serverVersion": "1.0.0"
            ])
            
        case "tools/list":
            return createResponse(id: id, result: [
                "tools": [
                    [
                        "name": "create_rtf_document",
                        "description": "Create a formatted RTF document with TextEdit compatibility",
                        "parameters": [
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
                                    "description": "Document template to use"
                                ]
                            ],
                            "required": ["content", "output_path"]
                        ]
                    ],
                    [
                        "name": "apply_rtf_formatting",
                        "description": "Apply formatting to an existing RTF document",
                        "parameters": [
                            "type": "object",
                            "properties": [
                                "file_path": [
                                    "type": "string",
                                    "description": "Path to the RTF file"
                                ],
                                "formatting": [
                                    "type": "array",
                                    "description": "Array of formatting instructions"
                                ]
                            ],
                            "required": ["file_path", "formatting"]
                        ]
                    ]
                ]
            ])
            
        case "tools/execute":
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
            let template = arguments["template"] as? String ?? "custom"
            
            let result = try await rtfService.createDocument(
                content: content,
                outputPath: outputPath,
                template: template
            )
            
            return createResponse(id: id, result: [
                "success": result.success,
                "path": result.path,
                "message": result.message
            ])
            
        case "apply_rtf_formatting":
            let filePath = arguments["file_path"] as? String ?? ""
            let formatting = arguments["formatting"] as? [[String: Any]] ?? []
            
            let result = try await rtfService.applyFormatting(
                filePath: filePath,
                formatting: formatting
            )
            
            return createResponse(id: id, result: [
                "success": result.success,
                "message": result.message
            ])
            
        default:
            throw MCPError.unknownTool(toolName)
        }
    }
    
    private func sendMessage(_ message: [String: Any], to output: FileHandle) async throws {
        let data = try JSONSerialization.data(withJSONObject: message, options: [])
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw MCPError.encodingError
        }
        
        // Write to stdout with newline
        output.write((jsonString + "\n").data(using: .utf8)!)
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
    case messageTooLarge
}
