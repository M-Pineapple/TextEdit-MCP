# TextEdit MCP Formatting Guide

This guide provides comprehensive examples of all formatting features available in TextEdit MCP.

## Table of Contents

1. [Text Formatting](#text-formatting)
2. [Colors](#colors)
3. [Highlighting](#highlighting)
4. [Headings](#headings)
5. [Lists](#lists)
6. [Tables](#tables)
7. [Hyperlinks](#hyperlinks)
8. [Templates](#templates)
9. [Complete Examples](#complete-examples)

## Text Formatting

### Basic Styles

```markdown
**Bold text**
*Italic text*
***Bold and italic text***
~~Strikethrough text~~
```

### Combining Styles

You can combine multiple formatting styles:

```markdown
**Bold with *italic* inside**
*Italic with **bold** inside*
~~Strikethrough with **bold** and *italic*~~
```

## Colors

TextEdit MCP supports three text colors:

```markdown
{red}This text is red{/red}
{blue}This text is blue{/blue}
{green}This text is green{/green}
```

### Colors with Other Formatting

```markdown
{red}**Bold red text**{/red}
{blue}*Italic blue text*{/blue}
{green}***Bold italic green text***{/green}
```

## Highlighting

Four highlight colors are available:

```markdown
==Yellow highlight== (default)
[[Cyan/Blue highlight]]
{{Green highlight}}
((Orange highlight))
```

### Highlighting with Formatting

```markdown
==**Bold with yellow highlight**==
[[*Italic with cyan highlight*]]
{{***Bold italic with green highlight***}}
((**Bold** and *italic* with orange))
```

## Headings

Four heading levels with automatic styling:

```markdown
# Heading 1 (24pt, bold, centered)
## Heading 2 (18pt, bold)
### Heading 3 (14pt, bold)
#### Heading 4 (12pt, bold)
```

## Lists

### Bullet Points

```markdown
• First item
• Second item
• Third item

OR

- First item
- Second item
- Third item
```

### Numbered Lists

```markdown
1. First item
2. Second item
3. Third item
```

### Lists with Formatting

```markdown
• **Bold** bullet point
• *Italic* bullet point
• {red}Colored{/red} bullet point
• ==Highlighted== bullet point

1. **Bold** numbered item
2. *Italic* numbered item
3. {blue}Colored{/blue} numbered item
```

## Tables

Tables support full formatting within cells:

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Row 2    | Row 2    | Row 2    |
```

### Tables with Formatting

```markdown
| Feature | Example | Notes |
|---------|---------|-------|
| **Bold** | **Sample** | Makes text bold |
| *Italic* | *Sample* | Makes text italic |
| {red}Color{/red} | {blue}Sample{/blue} | Adds color |
| ==Highlight== | [[Sample]] | Adds background |
| [Link](url) | [Google](https://google.com) | Clickable |
```

### Complex Table Example

```markdown
| Status | Task | Owner | Due Date |
|--------|------|-------|----------|
| {green}✅ Done{/green} | **Documentation** | *John* | ==Today== |
| {blue}🔄 In Progress{/blue} | Testing | [[Sarah]] | Tomorrow |
| {red}❌ Blocked{/red} | Deployment | {{Mike}} | Next Week |
```

## Hyperlinks

Create clickable links:

```markdown
[Link text](https://example.com)
[Apple](https://apple.com)
[GitHub](https://github.com)
```

### Links with Formatting

```markdown
[**Bold link**](https://example.com)
[*Italic link*](https://example.com)
[{blue}Colored link{/blue}](https://example.com)
```

## Templates

### Business Template (Default)
- Font: System font, 12pt
- Color: Black
- Standard spacing

### Technical Template
- Font: Monospace, 11pt
- Color: Dark gray
- Compact layout

### Meeting Template
- Font: System font, 11pt
- Color: Black
- 1.5x line spacing

## Complete Examples

### Meeting Notes Example

```markdown
# Team Meeting Notes

## Date: {blue}January 3, 2025{/blue}

### Attendees
• **John Smith** - Project Manager
• *Sarah Johnson* - Developer
• Michael Brown - Designer

### Agenda

1. ==Review Q4 Results==
2. Discuss {red}urgent bugs{/red}
3. Plan Q1 roadmap

### Discussion Points

| Topic | Decision | Action |
|-------|----------|--------|
| **Budget** | {green}Approved{/green} | Submit by ==Friday== |
| *Timeline* | [[Under Review]] | Meeting next week |
| Resources | {red}Need more{/red} | **Hire 2 devs** |

### Action Items

- [ ] Update documentation - *Sarah*
- [ ] Fix {red}critical bug{/red} - **John**
- [ ] Review designs - ((Mike - urgent))

### Next Meeting
[Calendar Link](https://calendar.example.com) - **Monday 2PM**
```

### Technical Report Example

```markdown
# Technical Analysis Report

## Executive Summary

This report analyzes the **system performance** and identifies {red}critical issues{/red} that need immediate attention.

## Performance Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Response Time** | 2.5s | < 1s | {red}❌ Failed{/red} |
| *Memory Usage* | 4GB | < 8GB | {green}✅ Passed{/green} |
| CPU Load | 65% | < 70% | {blue}⚠️ Warning{/blue} |

## Key Findings

1. ==Database queries need optimization==
2. [[Memory leaks in module A]]
3. {{Cache implementation required}}

## Recommendations

• Implement **query caching**
• Add {blue}monitoring tools{/blue}
• Schedule *regular maintenance*

[View Full Report](https://docs.example.com/report)
```

## Tips and Best Practices

1. **Consistency**: Use consistent formatting throughout your document
2. **Hierarchy**: Use headings to create clear document structure
3. **Emphasis**: Use bold for important items, italic for emphasis
4. **Colors**: Use colors sparingly for maximum impact
5. **Tables**: Keep tables simple and use formatting to highlight key data
6. **Links**: Always use descriptive link text

## Limitations

- Maximum 3 text colors (red, blue, green)
- Maximum 4 highlight colors
- Tables are limited to basic grid layout
- No nested tables support
- No custom fonts beyond the three templates

---

*Created by Pineapple 🍍*
