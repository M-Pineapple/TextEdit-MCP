# Contributing to TextEdit MCP

Thank you for your interest in contributing to TextEdit MCP! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect different viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/M-Pineapple/TextEdit-MCP/issues)
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (macOS version, Swift version)
   - Error logs if available

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with the "enhancement" label
3. Describe the feature and its use case
4. Provide examples if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass (`swift test`)
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/M-Pineapple/TextEdit-MCP.git
cd TextEdit-MCP

# Build the project
swift build

# Run tests
swift test

# Build for release
swift build -c release
```

### Coding Standards

- Follow Swift naming conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Maintain compatibility with macOS 12.0+

### Testing

- Write tests for new features
- Ensure existing tests pass
- Test with Claude Desktop integration
- Verify RTF output in TextEdit

### Documentation

- Update README.md for new features
- Add examples to FORMATTING_GUIDE.md
- Update CHANGELOG.md
- Comment your code appropriately

## Project Structure

```
Sources/TextEditMCP/
├── main.swift              # Entry point
├── MCPServer.swift         # MCP protocol implementation
├── RTFDocumentService.swift # RTF generation logic
└── MCPLogger.swift         # Logging utilities
```

## Key Areas for Contribution

- **New Formatting Features**: Additional text styles, colors, or layouts
- **Template System**: More document templates
- **Table Enhancements**: Cell merging, advanced styling
- **Performance**: Optimization for large documents
- **Error Handling**: Better error messages and recovery
- **Cross-Platform**: Support for other platforms (Linux)

## Questions?

Feel free to open an issue for any questions about contributing!

---

Created by Pineapple 🍍
