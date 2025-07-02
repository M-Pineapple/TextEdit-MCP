#!/usr/bin/env python3

import json
import subprocess
import os
import time

def test_textedit_mcp():
    """Test the TextEdit MCP server with comprehensive formatting"""
    
    # Path to the built executable
    mcp_path = ".build/debug/textedit-mcp"
    
    if not os.path.exists(mcp_path):
        print("❌ TextEdit MCP not built. Run 'swift build' first.")
        return
    
    print("🚀 Starting TextEdit MCP test...")
    
    # Start the MCP server
    proc = subprocess.Popen(
        [mcp_path],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )
    
    def send_message(message):
        """Send a message and get response"""
        json_str = json.dumps(message)
        print(f"→ Sending: {json_str[:100]}...")
        proc.stdin.write(json_str + "\n")
        proc.stdin.flush()
        
        # Read response
        response = proc.stdout.readline()
        if response:
            print(f"← Response: {response[:100]}...")
            return json.loads(response)
        return None
    
    try:
        # 1. Initialize
        init_response = send_message({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {}
        })
        
        if not init_response:
            print("❌ No response to initialize")
            return
            
        print("✅ Initialized:", init_response.get("result", {}).get("serverName"))
        
        # 2. Create document with all features
        content = """# TextEdit MCP Feature Test 🍍

This document demonstrates **all formatting capabilities** of TextEdit MCP.

## Text Formatting

Basic formatting: **bold text**, *italic text*, ~~strikethrough text~~

## Highlighting Colors

- ==Yellow highlight== for important information
- {{Green highlight}} for success items  
- [[Blue highlight]] for key concepts
- ((Orange highlight)) for warnings

## Text Colors

- {red}Red text for warnings{/red}
- {blue}Blue text for references{/blue}
- {green}Green text for success{/green}

## Hyperlinks

- External: [Visit Claude](https://claude.ai)
- Email: [Contact Support](mailto:support@anthropic.com)
- Bold link: **[Important Link](https://example.com)**

## Lists

### Bullet Points
- First item with ==highlighted text==
- Second item with **bold** emphasis
- Third item with [a link](https://example.com)

### Numbered Lists
1. First step with *italic* instructions
2. Second step with {{green highlight}}
3. Third step with {red}red warning{/red}

---
Created by Pineapple 🍍 using TextEdit MCP"""
        
        create_response = send_message({
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "create_rtf_document",
                "arguments": {
                    "content": content,
                    "output_path": "~/Desktop/TextEditMCP_FullTest.rtf",
                    "template": "business"
                }
            }
        })
        
        if create_response:
            result = create_response.get("result", {})
            print("\n✅ Document creation result:")
            print(json.dumps(result, indent=2))
            
            # Open the document
            os.system("open ~/Desktop/TextEditMCP_FullTest.rtf")
        else:
            print("❌ No response to document creation")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        
    finally:
        # Clean up
        proc.terminate()
        proc.wait()
        print("\n🏁 Test complete")

if __name__ == "__main__":
    test_textedit_mcp()
