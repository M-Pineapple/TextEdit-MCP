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
        guard let response = await response(for: line) else {
            return
        }
        do {
            try await sendMessage(response)
        } catch {
            logger.error("Error sending response: \(error)")
        }
    }

    /// Handles one JSON-RPC line and returns the reply, or nil when none is due
    /// (notifications and blank lines). Every request gets exactly one reply,
    /// either a result or a JSON-RPC error, so a client never waits forever.
    func response(for line: String) async -> [String: Any]? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }

        guard let jsonData = trimmed.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) else {
            logger.error("Failed to parse JSON: \(line)")
            return createError(id: nil, code: JSONRPCError.parseError, message: "Parse error")
        }

        guard let message = parsed as? [String: Any] else {
            return createError(id: nil, code: JSONRPCError.invalidRequest, message: "Invalid Request")
        }

        // A message without an id is a notification: never reply to it.
        let isRequest = message.keys.contains("id")
        let id = message["id"]

        guard let method = message["method"] as? String else {
            if isRequest {
                return createError(id: id, code: JSONRPCError.invalidRequest, message: "Invalid Request: missing method")
            }
            return nil
        }

        guard isRequest else {
            logger.debug("Notification: \(method)")
            return nil
        }

        do {
            return try await processRequest(method: method, id: id, params: message["params"] as? [String: Any] ?? [:])
        } catch MCPError.unknownMethod(let name) {
            logger.debug("Unhandled method: \(name)")
            return createError(id: id, code: JSONRPCError.methodNotFound, message: "Method not found: \(name)")
        } catch MCPError.invalidParameters {
            return createError(id: id, code: JSONRPCError.invalidParams, message: "Invalid params: expected name and arguments")
        } catch MCPError.unknownTool(let name) {
            return createError(id: id, code: JSONRPCError.invalidParams, message: "Unknown tool: \(name)")
        } catch {
            logger.error("Error processing \(method): \(error)")
            return createError(id: id, code: JSONRPCError.internalError, message: "Internal error: \(error)")
        }
    }

    private func processRequest(method: String, id: Any?, params: [String: Any]) async throws -> [String: Any] {
        logger.debug("Processing method: \(method)")

        switch method {
        case "initialize":
            return createResponse(id: id, result: [
                "protocolVersion": "2024-11-05",
                "serverInfo": [
                    "name": "textedit-mcp",
                    "version": "1.0.1"
                ],
                "capabilities": [
                    "tools": [:],
                    "prompts": [:],
                    "resources": [:]
                ]
            ])

        case "ping":
            return createResponse(id: id, result: [:])

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

        case "prompts/list":
            // Prompts are advertised, so list them even though there are none yet.
            return createResponse(id: id, result: ["prompts": []])

        case "resources/list":
            return createResponse(id: id, result: ["resources": []])

        case "resources/templates/list":
            return createResponse(id: id, result: ["resourceTemplates": []])

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
        return [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": result
        ]
    }

    private func createError(id: Any?, code: Int, message: String) -> [String: Any] {
        return [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }
}

enum JSONRPCError {
    static let parseError = -32700
    static let invalidRequest = -32600
    static let methodNotFound = -32601
    static let invalidParams = -32602
    static let internalError = -32603
}

enum MCPError: Error {
    case invalidJSON
    case missingMethod
    case unknownMethod(String)
    case invalidParameters
    case unknownTool(String)
    case encodingError
}
