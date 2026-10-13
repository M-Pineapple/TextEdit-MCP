# Release Notes

## v1.0.1 - 2026-10-13

Document creation is limited to new `.rtf` files inside the home folder. Hidden folders, overwrites of existing files, and paths that would leave the home folder are refused.

Please update to this release.

**Full Changelog**: https://github.com/M-Pineapple/TextEdit-MCP/compare/v1.0.0...v1.0.1

## v1.0.0 - Initial Release (2025-01-03)

### 🎉 Features

#### Rich Text Formatting
- **Bold**, *italic*, ***bold italic***, and ~~strikethrough~~ text
- Full heading hierarchy (H1-H4)
- Customizable paragraph spacing

#### Colors & Highlighting
- Text colors: Red, Blue, Green
- Highlight colors: Yellow, Cyan, Green, Orange
- Full color support within table cells

#### Tables
- Native RTF tables with borders
- Header row with bold styling
- Full formatting support within cells
- Automatic cell padding and alignment

#### Additional Features
- Clickable hyperlinks
- Bullet and numbered lists
- Three document templates (Business, Technical, Meeting)
- macOS native RTF generation

### 🔧 Technical Details

- Built with Swift 5.9+ for macOS
- Uses NSAttributedString and NSTextTable for native RTF support
- Implements Model Context Protocol (MCP) for Claude Desktop integration
- Zero external dependencies

### 📦 Installation

Run the included `install.sh` script or follow manual installation in README.md

### 🙏 Acknowledgments

Created by Pineapple 🍍 for the Claude Desktop community.

---

**Full Changelog**: https://github.com/M-Pineapple/TextEdit-MCP/commits/v1.0.0
