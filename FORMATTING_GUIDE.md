# TextEdit MCP Formatting Guide

## Text Formatting Syntax

### Basic Text Formatting
- **Bold**: `**text**`
- *Italic*: `*text*`
- ~~Strikethrough~~: `~~text~~`
- Underline: Automatically applied to hyperlinks

### Heading Hierarchy
```markdown
# H1 - Document Title (24pt, bold, centered)
## H2 - Major Sections (18pt, bold)
### H3 - Subsections (14pt, bold)
#### H4 - Detail Points (12pt, bold)
```

### Highlighting (Background Colors)
- `==text==` → Yellow highlight
- `{{text}}` → Green highlight
- `[[text]]` → Blue highlight
- `((text))` → Orange highlight

### Text Colors
- `{red}text{/red}` → Red text
- `{blue}text{/blue}` → Blue text
- `{green}text{/green}` → Green text

### Hyperlinks
- External URL: `[link text](https://example.com)`
- Email: `[Contact](mailto:user@example.com)`
- File: `[Open Document](file:///path/to/file.pdf)`

### Lists

#### Bullet Points
```markdown
- First item
- Second item
  - Nested item (use spaces)
- Third item
```

#### Numbered Lists
```markdown
1. First step
2. Second step
3. Third step
```

### Combined Formatting
You can combine multiple formatting options:
- `**[Bold Link](https://example.com)**`
- `==**Highlighted Bold Text**==`
- `*This has {red}red italic{/red} text*`

## Templates

### business (default)
- Font: System font, 12pt
- Color: Black
- Line spacing: 1.15

### technical
- Font: Monospace, 11pt
- Color: Dark gray
- Line spacing: 1.15

### meeting
- Font: System font, 11pt
- Color: Black
- Line spacing: 1.5

## Example Document

```markdown
# Meeting Notes

Date: **January 2, 2025**
Attendees: *John Doe, Jane Smith*

## Action Items

- ==High Priority==: Complete proposal by Friday
- {{Completed}}: Review last week's metrics
- [[In Progress]]: Update documentation

## Decisions

1. Approved budget increase of {green}$50,000{/green}
2. Deadline moved to {red}January 15th{/red}
3. New project kickoff [scheduled here](https://calendar.com)

## Next Steps

Contact [support team](mailto:support@company.com) for clarification.

---
Created by Pineapple 🍍
```

## Claude Desktop Usage

After installation, you can use these commands in Claude:

1. **Basic creation**:
   "Create an RTF document with my meeting notes"

2. **With specific path**:
   "Create an RTF at ~/Documents/report.rtf with the quarterly summary"

3. **With template**:
   "Create a technical documentation RTF using the technical template"

## Limitations

- No internal anchor links (RTF format limitation)
- No embedded images (separate handling required)
- No tables support (yet - coming in v2)
- Maximum recommended file size: 10MB

Created by Pineapple 🍍
