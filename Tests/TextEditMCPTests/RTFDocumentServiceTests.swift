//
//  RTFDocumentServiceTests.swift
//  TextEditMCPTests
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import XCTest
@testable import TextEditMCP

final class RTFDocumentServiceTests: XCTestCase {
    
    func testCreateSimpleDocument() async throws {
        let service = RTFDocumentService()
        
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
        
        let outputPath = "~/Desktop/test_document.rtf"
        
        let result = try await service.createDocument(
            content: content,
            outputPath: outputPath,
            template: "business"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }
}
