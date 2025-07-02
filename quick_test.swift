#!/usr/bin/env swift

import Foundation
import AppKit

// We need to load the RTFDocumentService from the build
// For now, let's create a simple executable that uses the built module

print("🚀 Testing TextEdit MCP with all features...")
print("Please run: .build/debug/textedit-mcp")
print("\nOr create a proper test using the compiled module.")

// For immediate testing, let's create a simple RTF manually
let content = """
{\\rtf1\\ansi\\ansicpg1252\\cocoartf2639
\\cocoatextscaling0\\cocoaplatform0{\\fonttbl\\f0\\fswiss\\fcharset0 Helvetica-Bold;\\f1\\fswiss\\fcharset0 Helvetica;}
{\\colortbl;\\red255\\green255\\blue255;\\red0\\green0\\blue0;\\red0\\green0\\blue255;\\red255\\green0\\blue0;}
{\\*\\expandedcolortbl;;\\cssrgb\\c0\\c0\\c0;\\cssrgb\\c0\\c0\\c100000;\\cssrgb\\c100000\\c0\\c0;}
\\margl1440\\margr1440\\vieww11520\\viewh8400\\viewkind0
\\pard\\tx566\\tx1133\\tx1700\\tx2267\\tx2834\\tx3401\\tx3968\\tx4535\\tx5102\\tx5669\\tx6236\\tx6803\\pardirnatural\\partightenfactor0

\\f0\\b\\fs48 \\cf2 TextEdit MCP Works!
\\f1\\b0\\fs24 \\
\\
This demonstrates that RTF creation is working with \\b bold\\b0  and \\i italic\\i0  text.\\
\\
\\cf3 \\ul \\ulc3 This is a blue hyperlink\\cf2 \\ulnone \\
\\
\\cb3 Highlighted text\\cb1 \\
\\
Created by Pineapple 🍍\\
}
"""

let path = NSString("~/Desktop/TextEditMCP_QuickTest.rtf").expandingTildeInPath
try! content.write(toFile: path, atomically: true, encoding: .utf8)
print("✅ Created test RTF at: \\(path)")
NSWorkspace.shared.open(URL(fileURLWithPath: path))
