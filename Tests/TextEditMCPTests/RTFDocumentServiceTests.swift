//
//  RTFDocumentServiceTests.swift
//  TextEditMCPTests
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import XCTest
@testable import TextEditMCP

final class RTFDocumentServiceTests: XCTestCase {

    #if canImport(AppKit)
    func testCreateSimpleDocument() async throws {
        let service = RTFDocumentService()
        let fileManager = FileManager.default
        let outputURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("textedit-mcp-test-\(UUID().uuidString).rtf")
        defer { try? fileManager.removeItem(at: outputURL) }

        let content = """
        # Test Document

        This is a **bold** test with *italic* text.

        ## Section 1

        - Bullet point 1
        - Bullet point 2

        1. Numbered item
        2. Another item

        ==This text is highlighted==

        ~~This is strikethrough~~
        """

        let result = try await service.createDocument(
            content: content,
            outputPath: outputURL.path,
            template: "business"
        )

        XCTAssertTrue(result.success)
        XCTAssertTrue(fileManager.fileExists(atPath: result.path))
    }
    #endif

    func testRefusesHiddenDotfilesAndExistingFiles() async throws {
        let service = RTFDocumentService()

        let zshrc = try await service.createDocument(content: "x", outputPath: "~/.zshrc", template: "business")
        XCTAssertFalse(zshrc.success)

        let authorizedKeys = try await service.createDocument(
            content: "x",
            outputPath: "~/.ssh/authorized_keys",
            template: "business"
        )
        XCTAssertFalse(authorizedKeys.success)

        let outsideHome = try await service.createDocument(
            content: "x",
            outputPath: "/tmp/textedit-mcp-escape.rtf",
            template: "business"
        )
        XCTAssertFalse(outsideHome.success)

        let notRtf = try await service.createDocument(
            content: "x",
            outputPath: "~/textedit-mcp-not-rtf.txt",
            template: "business"
        )
        XCTAssertFalse(notRtf.success)

        let hidden = service.resolvedCreateURL(from: "~/.hidden.rtf")
        XCTAssertNil(hidden.url)
        XCTAssertTrue((hidden.error ?? "").lowercased().contains("hidden"))

        let fileManager = FileManager.default
        let existing = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("textedit-mcp-existing-\(UUID().uuidString).rtf")
        fileManager.createFile(atPath: existing.path, contents: Data("old".utf8))
        defer { try? fileManager.removeItem(at: existing) }

        let overwrite = try await service.createDocument(
            content: "new",
            outputPath: existing.path,
            template: "business"
        )
        XCTAssertFalse(overwrite.success)
        let kept = try String(contentsOf: existing, encoding: .utf8)
        XCTAssertEqual(kept, "old")
    }

    func testRefusesSymlinkEscapeThroughMissingIntermediateDirectory() async throws {
        let service = RTFDocumentService()
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let outsideRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("textedit-mcp-escape-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: outsideRoot, withIntermediateDirectories: true)
        let linkURL = home.appendingPathComponent("textedit-mcp-link-\(UUID().uuidString)")
        defer {
            try? fileManager.removeItem(at: linkURL)
            try? fileManager.removeItem(at: outsideRoot)
        }
        try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: outsideRoot)

        let outputPath = linkURL
            .appendingPathComponent("newdir")
            .appendingPathComponent("a.rtf")
            .path

        let resolved = service.resolvedCreateURL(from: outputPath)
        XCTAssertNil(resolved.url)
        XCTAssertTrue((resolved.error ?? "").lowercased().contains("home"))

        let result = try await service.createDocument(
            content: "x",
            outputPath: outputPath,
            template: "business"
        )
        XCTAssertFalse(result.success)
        let escapedFile = outsideRoot.appendingPathComponent("newdir").appendingPathComponent("a.rtf")
        XCTAssertFalse(fileManager.fileExists(atPath: escapedFile.path))

        let nestedInsideHome = home
            .appendingPathComponent("textedit-mcp-nested-\(UUID().uuidString)")
            .appendingPathComponent("a.rtf")
        let allowed = service.resolvedCreateURL(from: nestedInsideHome.path)
        XCTAssertNotNil(allowed.url)
    }
}
