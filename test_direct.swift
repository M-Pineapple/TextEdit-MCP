//
//  test_direct.swift
//  Direct RTF Test
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation
import AppKit

// Copy the RTFDocumentService code here for testing
struct RTFDocumentService {
    
    struct CreateResult {
        let success: Bool
        let path: String
        let message: String
    }
    
    func createDocument(content: String, outputPath: String, template: String) async throws -> CreateResult {
        // Parse the content and create attributed string
        let attributedString = try parseContent(content, template: template)
        
        // Convert to RTF data
        guard let rtfData = attributedString.rtf(from: NSRange(location: 0, length: attributedString.length),
                                                documentAttributes: [
                                                    .documentType: NSAttributedString.DocumentType.rtf
                                                ]) else {
            return CreateResult(success: false, path: "", message: "Failed to create RTF data")
        }
        
        // Expand tilde in path
        let expandedPath = NSString(string: outputPath).expandingTildeInPath
        
        // Write to file
        do {
            try rtfData.write(to: URL(fileURLWithPath: expandedPath))
            return CreateResult(success: true, path: expandedPath, message: "Document created successfully")
        } catch {
            return CreateResult(success: false, path: "", message: "Failed to write file: \(error)")
        }
    }
    
    private func parseContent(_ content: String, template: String) throws -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        let lines = content.components(separatedBy: .newlines)
        
        // Apply template defaults
        let defaultAttributes = getTemplateAttributes(template)
        
        for line in lines {
            if line.hasPrefix("# ") {
                // H1
                let text = String(line.dropFirst(2))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 24),
                    .paragraphStyle: createParagraphStyle(alignment: .center, spaceBefore: 0, spaceAfter: 12)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                
            } else if line.hasPrefix("## ") {
                // H2
                let text = String(line.dropFirst(3))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 12, spaceAfter: 6)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                
            } else if line.hasPrefix("- ") {
                // Bullet point
                let text = String(line.dropFirst(2))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
                
                var attrs = defaultAttributes
                attrs[.paragraphStyle] = paragraphStyle
                result.append(NSAttributedString(string: "•\t" + text + "\n", attributes: attrs))
                
            } else {
                // Regular paragraph
                result.append(NSAttributedString(string: line + "\n", attributes: defaultAttributes))
            }
        }
        
        return result
    }
    
    private func createParagraphStyle(alignment: NSTextAlignment = .left, 
                                    spaceBefore: CGFloat = 0, 
                                    spaceAfter: CGFloat = 0) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.paragraphSpacingBefore = spaceBefore
        style.paragraphSpacing = spaceAfter
        style.lineSpacing = 1.15
        return style
    }
    
    private func getTemplateAttributes(_ template: String) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
    }
}

// Test it
let service = RTFDocumentService()

let content = """
# TextEdit MCP Works! 🍍

This is a **test document** created by TextEdit MCP.

## Success!

- RTF formatting is working
- File creation is working
- Ready to integrate with MCP

Created by Pineapple 🍍
"""

Task {
    let result = try await service.createDocument(
        content: content,
        outputPath: "~/Desktop/TextEditMCP_DirectTest.rtf",
        template: "business"
    )
    
    print("Success: \(result.success)")
    print("Path: \(result.path)")
    print("Message: \(result.message)")
    
    if result.success {
        print("\n✅ RTF Document created successfully!")
        print("📄 Open it with: open '\(result.path)'")
    }
    
    exit(result.success ? 0 : 1)
}

RunLoop.main.run()
