//
//  MCPServerProtocolTests.swift
//  TextEditMCPTests
//
//  Every request must get one reply with the shape MCP clients expect.
//  Glama's check failed on prompts/list returning {} and on ping.
//

import XCTest
@testable import TextEditMCP

final class MCPServerProtocolTests: XCTestCase {

    private func reply(_ line: String) async -> [String: Any]? {
        await MCPServer().response(for: line)
    }

    private func result(_ line: String) async throws -> [String: Any] {
        let maybe = await reply(line)
        let response = try XCTUnwrap(maybe, "expected a reply to \(line)")
        XCTAssertNil(response["error"], "unexpected error for \(line)")
        return try XCTUnwrap(response["result"] as? [String: Any])
    }

    private func errorCode(_ line: String) async throws -> Int {
        let maybe = await reply(line)
        let response = try XCTUnwrap(maybe, "expected a reply to \(line)")
        let error = try XCTUnwrap(response["error"] as? [String: Any], "expected an error for \(line)")
        return try XCTUnwrap(error["code"] as? Int)
    }

    func testPingReturnsEmptyResult() async throws {
        let maybe = await reply(#"{"jsonrpc":"2.0","id":7,"method":"ping"}"#)
        let response = try XCTUnwrap(maybe)
        XCTAssertEqual(response["id"] as? Int, 7)
        let result = try XCTUnwrap(response["result"] as? [String: Any])
        XCTAssertTrue(result.isEmpty)
    }

    func testPromptsListReturnsArray() async throws {
        let result = try await result(#"{"jsonrpc":"2.0","id":1,"method":"prompts/list"}"#)
        let prompts = try XCTUnwrap(result["prompts"] as? [Any])
        XCTAssertTrue(prompts.isEmpty)
    }

    func testResourceListsReturnArrays() async throws {
        let resources = try await result(#"{"jsonrpc":"2.0","id":2,"method":"resources/list"}"#)
        XCTAssertNotNil(resources["resources"] as? [Any])
        let templates = try await result(#"{"jsonrpc":"2.0","id":3,"method":"resources/templates/list"}"#)
        XCTAssertNotNil(templates["resourceTemplates"] as? [Any])
    }

    func testToolsListHasOneTool() async throws {
        let result = try await result(#"{"jsonrpc":"2.0","id":4,"method":"tools/list"}"#)
        let tools = try XCTUnwrap(result["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.map { $0["name"] as? String }, ["create_rtf_document"])
    }

    func testNotificationsGetNoReply() async {
        let initialized = await reply(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)
        XCTAssertNil(initialized)
        let unknown = await reply(#"{"jsonrpc":"2.0","method":"notifications/something_new"}"#)
        XCTAssertNil(unknown)
    }

    func testUnknownMethodIsMethodNotFound() async throws {
        let code = try await errorCode(#"{"jsonrpc":"2.0","id":5,"method":"no/such/method"}"#)
        XCTAssertEqual(code, -32601)
    }

    func testBadToolCallsGetErrorsNotSilence() async throws {
        let missingArgs = try await errorCode(#"{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{}}"#)
        XCTAssertEqual(missingArgs, -32602)
        let unknownTool = try await errorCode(#"{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"nope","arguments":{}}}"#)
        XCTAssertEqual(unknownTool, -32602)
    }

    func testMalformedJSONIsParseError() async throws {
        let maybe = await reply("{not json")
        let response = try XCTUnwrap(maybe)
        XCTAssertTrue(response["id"] is NSNull)
        let error = try XCTUnwrap(response["error"] as? [String: Any])
        XCTAssertEqual(error["code"] as? Int, -32700)
    }
}
