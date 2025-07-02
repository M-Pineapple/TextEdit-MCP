#!/usr/bin/env python3

import json
import subprocess
import sys

def test_create_document():
    # Test message to create an RTF document
    message = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/execute",
        "params": {
            "name": "create_rtf_document",
            "arguments": {
                "content": """# TextEdit MCP Test Document

This is a **test document** created by TextEdit MCP with *italic* text.

## Features Demonstrated

- Bullet point with ==highlighted text==
- Another bullet point
- ~~Strikethrough text~~

### Numbered Lists

1. First item
2. Second item
3. Third item with **bold** emphasis

This demonstrates the full RTF formatting capabilities!
""",
                "output_path": "~/Desktop/TextEditMCP_Test.rtf",
                "template": "business"
            }
        }
    }
    
    # Send to MCP server
    proc = subprocess.Popen(
        [".build/debug/textedit-mcp"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Send initialize first
    init_msg = {"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {}}
    proc.stdin.write(json.dumps(init_msg) + "\n")
    proc.stdin.flush()
    
    # Read response
    response = proc.stdout.readline()
    print("Initialize response:", response)
    
    # Send our test message
    proc.stdin.write(json.dumps(message) + "\n")
    proc.stdin.flush()
    
    # Read response
    response = proc.stdout.readline()
    print("Create document response:", response)
    
    # Clean up
    proc.terminate()

if __name__ == "__main__":
    test_create_document()
