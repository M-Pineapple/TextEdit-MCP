# TextEdit MCP 🍍

A Swift-based Model Context Protocol (MCP) server that provides native RTF document creation with full TextEdit.app compatibility. Create beautifully formatted documents with colors, highlights, fonts, and all the rich text features you need!

## Features

- ✅ **Native Apple RTF Support** - Using NSAttributedString and TextEdit APIs
- ✅ **Full Formatting** - Colors, highlights, bold, italic, underline, strikethrough
- ✅ **Heading Hierarchy** - H1-H4 with proper styling
- ✅ **Lists** - Bullet points and numbered lists with nesting
- ✅ **Tables** - Native RTF table support
- ✅ **100% TextEdit Compatible** - Opens perfectly in TextEdit.app, Pages, and Word
- ✅ **Template System** - Pre-defined templates for common document types

## Installation

### Requirements
- macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

### Quick Start
```bash
# Clone the repository
git clone https://github.com/pineapple/TextEdit-MCP.git
cd TextEdit-MCP

# Build the project
swift build -c release

# Copy to MCP directory
cp .build/release/textedit-mcp ~/Library/Application\ Support/Claude/MCP/
```

### Claude Desktop Configuration
Add to your `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "textedit": {
      "command": "~/Library/Application Support/Claude/MCP/textedit-mcp"
    }
  }
}
```

## Usage

### Available Tools

#### `create_rtf_document`
Create a new RTF document with full formatting support.

```json
{
  "content": "# Document Title\n\nThis is **bold** and *italic* text.",
  "output_path": "~/Documents/formatted_document.rtf",
  "template": "business"
}
```

#### `apply_rtf_formatting`
Apply formatting to specific text ranges.

```json
{
  "file_path": "~/Documents/document.rtf",
  "formatting": [
    {
      "type": "highlight",
      "color": "yellow",
      "range": {"start": 10, "length": 20}
    }
  ]
}
```

## Formatting Syntax

The MCP supports a Markdown-like syntax with extensions:

- `# Heading 1` - Main title
- `## Heading 2` - Section headers
- `**bold text**` - Bold formatting
- `*italic text*` - Italic formatting
- `~~strikethrough~~` - Strikethrough text
- `==highlighted text==` - Yellow highlight
- `{color:red}text{/color}` - Colored text
- `{bg:yellow}text{/bg}` - Background color

## Development

Created by Pineapple 🍍

## License

MIT
