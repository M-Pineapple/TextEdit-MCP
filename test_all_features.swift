//
//  test_all_features.swift
//  Test all TextEdit MCP features
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation
import AppKit

// Copy the updated RTFDocumentService here for testing
// [Service code would be copied here in production]

// Load the actual service
let service = RTFDocumentService()

let comprehensiveContent = """
# TextEdit MCP Feature Test 🍍

This document demonstrates all formatting capabilities of TextEdit MCP.

## Text Formatting

Basic formatting: **bold text**, *italic text*, ~~strikethrough text~~

Combined: ***bold and italic***, **~~bold strikethrough~~**

## Highlighting Colors

- ==Yellow highlight== - for important information
- {{Green highlight}} - for success or completed items  
- [[Blue highlight]] - for definitions or key concepts
- ((Orange highlight)) - for warnings or cautions

## Text Colors

- {red}This text is red{/red} - for warnings
- {blue}This text is blue{/blue} - for links or references
- {green}This text is green{/green} - for success

## Hyperlinks

- External link: [Visit Claude](https://claude.ai)
- Email link: [Contact Support](mailto:support@anthropic.com)
- Combined with formatting: **[Bold Link](https://example.com)**

## Lists and Structure

### Bullet Points
- First item with ==highlighted text==
- Second item with **bold** emphasis
- Third item with [a link](https://example.com)

### Numbered Lists
1. First step with *italic* instructions
2. Second step with {{green highlight}}
3. Third step with {red}red warning text{/red}

## Combined Formatting

This paragraph has **bold text with ==yellow highlighting==** and also includes [a hyperlink](https://anthropic.com) with *italic text* nearby.

---

Created by Pineapple 🍍 using TextEdit MCP
"""

Task {
    print("🚀 Testing TextEdit MCP with all features...\n")
    
    let result = try await service.createDocument(
        content: comprehensiveContent,
        outputPath: "~/Desktop/TextEditMCP_AllFeatures.rtf",
        template: "business"
    )
    
    print("Success: \(result.success)")
    print("Path: \(result.path)")
    print("Message: \(result.message)")
    
    if result.success {
        print("\n✅ All features test document created!")
        print("📄 Opening document...")
        
        // Open the document
        NSWorkspace.shared.open(URL(fileURLWithPath: result.path))
    }
    
    exit(result.success ? 0 : 1)
}

RunLoop.main.run()
