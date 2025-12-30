# TextEdit MCP

A Model Context Protocol (MCP) server that enables Claude Desktop to create beautifully formatted RTF documents with native macOS TextEdit compatibility.

## Features

- 📝 **Rich Text Formatting**
  - Bold, italic, underline, strikethrough
  - Headings (H1-H2)
  - Paragraph formatting with customizable spacing

- 🎨 **Colors & Highlighting**
  - Text colors: Red, Blue, Green
  - Highlight colors: Yellow, Cyan, Green, Orange
  - Full color support in tables

- 📊 **Tables**
  - Real RTF tables with borders
  - Header row styling
  - Full formatting support within cells
  - Automatic cell padding and alignment

- 🔗 **Hyperlinks**
  - Clickable URLs
  - Formatted link text
  - Works in TextEdit, Pages, and Word

- 📋 **Lists**
  - Bullet points
  - Numbered lists
  - Proper indentation

- 🎯 **Templates**
  - Business (default)
  - Technical (monospace)
  - Meeting (increased line spacing)

## Installation

### Prerequisites

- macOS (required for NSAttributedString and RTF generation)
- Swift 5.0 or later
- Claude Desktop

### Quick Install

1. Clone the repository:
```bash
git clone https://github.com/M-Pineapple/TextEdit-MCP.git
cd TextEdit-MCP
```

2. Run the installer:
```bash
./install.sh
```

3. Restart Claude Desktop

The installer will:
- Build the Swift project
- Install the MCP server binary
- Update your Claude Desktop configuration
- Create a backup of your existing config

## Usage

In Claude Desktop, you can create RTF documents using natural language:

```
"Create an RTF document with my meeting notes"
"Make a formatted report with tables and highlights"
"Generate a technical document with code examples"
```

Or use the tool directly:

```
Use textedit:create_rtf_document to create a document at ~/Desktop/MyDoc.rtf
```

## Formatting Syntax

The TextEdit MCP uses an intuitive markdown-like syntax:

### Text Formatting
- `**Bold text**`
- `*Italic text*`
- `***Bold italic text***`
- `~~Strikethrough text~~`

### Colors
- `{red}Red text{/red}`
- `{blue}Blue text{/blue}`
- `{green}Green text{/green}`

### Highlighting
- `==Yellow highlight==`
- `[[Cyan highlight]]`
- `{{Green highlight}}`
- `((Orange highlight))`

### Headings
```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

### Lists
```markdown
• Bullet point (or use - )
1. Numbered item
2. Another item
```

### Tables
```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| More     | Data     | Here     |
```

### Links
```markdown
[Link text](https://example.com)
```

## Examples

### Simple Document
```markdown
# Meeting Notes

## Agenda
- Review **Q4 results**
- Discuss {red}urgent issues{/red}
- Plan for next quarter

## Action Items
1. ==Update documentation==
2. [[Review code changes]]
3. Schedule follow-up
```

### Table with Formatting
```markdown
| Task | Status | Owner |
|------|--------|-------|
| **Documentation** | {green}✅ Complete{/green} | Team A |
| *Testing* | ==In Progress== | Team B |
| Deployment | {red}Blocked{/red} | DevOps |
```

## Development

### Building from Source

```bash
swift build -c release
```

### Running Tests

```bash
swift test
```

### Project Structure

```
TextEdit-MCP/
├── Sources/
│   └── TextEditMCP/
│       ├── main.swift           # Entry point
│       ├── MCPServer.swift      # MCP protocol handler
│       ├── RTFDocumentService.swift  # RTF generation
│       └── MCPLogger.swift      # Logging utility
├── Package.swift
├── README.md
├── FORMATTING_GUIDE.md
└── install.sh
```

## How It Works

1. **MCP Protocol**: Implements the Model Context Protocol to communicate with Claude Desktop
2. **NSAttributedString**: Uses macOS native APIs for rich text formatting
3. **NSTextTable**: Creates real RTF tables with proper borders and cell formatting
4. **RTF Export**: Generates standard RTF files compatible with TextEdit, Pages, and Word

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines

1. Maintain compatibility with macOS TextEdit
2. Follow Swift naming conventions
3. Add tests for new features
4. Update documentation

## Support

If you find this tool useful, consider supporting development:

<a href="https://www.buymeacoffee.com/mpineapple" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Created for use with Claude Desktop
- Built with Swift and AppKit
- Uses Model Context Protocol (MCP)

---

**Created by Pineapple 🍍**
