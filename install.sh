#!/bin/bash

# TextEdit MCP Installation Script
# Created by Pineapple 🍍

echo "🍍 TextEdit MCP Installer"
echo "========================"

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Please run this script from the TextEdit-MCP directory"
    exit 1
fi

# Build the project
echo "📦 Building TextEdit MCP..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Create MCP directory if it doesn't exist
MCP_DIR="$HOME/Library/Application Support/Claude/MCP"
mkdir -p "$MCP_DIR"

# Copy the executable
echo "📄 Installing to Claude MCP directory..."
cp .build/release/textedit-mcp "$MCP_DIR/"

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy executable"
    exit 1
fi

# Make it executable
chmod +x "$MCP_DIR/textedit-mcp"

# Create or update Claude config
CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

echo "🔧 Updating Claude Desktop configuration..."

# Check if config exists
if [ -f "$CONFIG_FILE" ]; then
    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    echo "📋 Backed up existing config to $CONFIG_FILE.backup"
    
    # Check if jq is installed for JSON manipulation
    if command -v jq &> /dev/null; then
        # Use jq to add our server
        jq '.mcpServers.textedit = {
            "command": "'"$MCP_DIR/textedit-mcp"'"
        }' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
        echo "⚠️  jq not found. Please manually add this to your claude_desktop_config.json:"
        echo ""
        echo '  "textedit": {'
        echo '    "command": "'"$MCP_DIR/textedit-mcp"'"'
        echo '  }'
        echo ""
    fi
else
    # Create new config
    cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "textedit": {
      "command": "$MCP_DIR/textedit-mcp"
    }
  }
}
EOF
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📝 TextEdit MCP is now available in Claude Desktop"
echo ""
echo "🚀 Usage:"
echo "   - Restart Claude Desktop"
echo "   - Use tool: create_rtf_document"
echo ""
echo "📖 Example:"
echo '   Create a document with: "Create an RTF document with the meeting notes"'
echo ""
echo "Created by Pineapple 🍍"
