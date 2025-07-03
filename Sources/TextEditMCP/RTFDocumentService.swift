//
//  RTFDocumentService.swift
//  TextEditMCP
//
//  Created by Pineapple 🍍 on 2025-01-02.
//

import Foundation
import AppKit

struct RTFDocumentService {
    
    struct CreateResult {
        let success: Bool
        let path: String
        let message: String
    }
    
    struct FormatResult {
        let success: Bool
        let message: String
    }
    
    func createDocument(content: String, outputPath: String, template: String) async throws -> CreateResult {
        // Parse the content and create attributed string
        let attributedString = try parseContent(content, template: template)
        
        // Convert to RTF data
        guard let rtfData = attributedString.rtf(from: NSRange(location: 0, length: attributedString.length),
                                                documentAttributes: [
                                                    .documentType: NSAttributedString.DocumentType.rtf
                                                ]) else {
            return CreateResult(success: false, path: "", message: "Failed to create RTF data")
        }
        
        // Expand tilde in path
        let expandedPath = NSString(string: outputPath).expandingTildeInPath
        
        // Create directory if needed
        let directory = (expandedPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        
        // Write to file
        do {
            try rtfData.write(to: URL(fileURLWithPath: expandedPath))
            return CreateResult(success: true, path: expandedPath, message: "Document created successfully")
        } catch {
            return CreateResult(success: false, path: "", message: "Failed to write file: \(error)")
        }
    }
    
    private func parseContent(_ content: String, template: String) throws -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        let lines = content.components(separatedBy: .newlines)
        
        // Apply template defaults
        let defaultAttributes = getTemplateAttributes(template)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Check for table
            if isTableStart(line) && i + 1 < lines.count && isTableSeparator(lines[i + 1]) {
                // Parse the table
                let tableResult = parseTable(from: lines, startingAt: i, defaultAttributes: defaultAttributes)
                result.append(tableResult.attributedString)
                i = tableResult.nextLineIndex
                
            } else if line.hasPrefix("# ") {
                // H1
                let text = String(line.dropFirst(2))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 24),
                    .paragraphStyle: createParagraphStyle(alignment: .center, spaceBefore: 0, spaceAfter: 12)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                i += 1
                
            } else if line.hasPrefix("## ") {
                // H2
                let text = String(line.dropFirst(3))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 12, spaceAfter: 6)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                i += 1
                
            } else if line.hasPrefix("### ") {
                // H3
                let text = String(line.dropFirst(4))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 14),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 6, spaceAfter: 3)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                i += 1
                
            } else if line.hasPrefix("#### ") {
                // H4
                let text = String(line.dropFirst(5))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 12),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 3, spaceAfter: 3)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                i += 1
                
            } else if line.hasPrefix("- ") || line.hasPrefix("• ") {
                // Bullet point
                let text = String(line.dropFirst(2))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
                
                var attrs = defaultAttributes
                attrs[.paragraphStyle] = paragraphStyle
                
                let formatted = parseInlineFormatting("• \t" + text, defaultAttributes: attrs)
                result.append(formatted)
                result.append(NSAttributedString(string: "\n"))
                i += 1
                
            } else if line.range(of: "^\\d+\\. ", options: .regularExpression) != nil {
                // Numbered list
                let components = line.components(separatedBy: ". ")
                guard components.count >= 2 else { 
                    i += 1
                    continue 
                }
                let number = components[0]
                let text = components.dropFirst().joined(separator: ". ")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
                
                var attrs = defaultAttributes
                attrs[.paragraphStyle] = paragraphStyle
                
                let formatted = parseInlineFormatting("\(number).\t\(text)", defaultAttributes: attrs)
                result.append(formatted)
                result.append(NSAttributedString(string: "\n"))
                i += 1
                
            } else {
                // Regular paragraph with inline formatting
                let formatted = parseInlineFormatting(line, defaultAttributes: defaultAttributes)
                result.append(formatted)
                result.append(NSAttributedString(string: "\n"))
                i += 1
            }
        }
        
        return result
    }
    
    // Check if a line looks like a table start (has pipes)
    private func isTableStart(_ line: String) -> Bool {
        return line.contains("|") && line.trimmingCharacters(in: .whitespaces).first == "|"
    }
    
    // Check if a line is a table separator (|---|---|)
    private func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("|") && trimmed.contains("-") && 
               trimmed.replacingOccurrences(of: "|", with: "")
                     .replacingOccurrences(of: "-", with: "")
                     .replacingOccurrences(of: " ", with: "")
                     .replacingOccurrences(of: ":", with: "").isEmpty
    }
    
    // Parse a markdown table
    private func parseTable(from lines: [String], startingAt startIndex: Int, defaultAttributes: [NSAttributedString.Key: Any]) -> (attributedString: NSMutableAttributedString, nextLineIndex: Int) {
        let result = NSMutableAttributedString()
        var tableData: [[String]] = []
        var currentIndex = startIndex
        
        // Parse header
        if currentIndex < lines.count {
            let headerCells = parseTableRow(lines[currentIndex])
            tableData.append(headerCells)
            currentIndex += 1
        }
        
        // Skip separator
        if currentIndex < lines.count && isTableSeparator(lines[currentIndex]) {
            currentIndex += 1
        }
        
        // Parse data rows
        while currentIndex < lines.count && isTableStart(lines[currentIndex]) {
            let rowCells = parseTableRow(lines[currentIndex])
            tableData.append(rowCells)
            currentIndex += 1
        }
        
        // Create NSTextTable
        let table = NSTextTable()
        let numColumns = tableData.first?.count ?? 0
        table.numberOfColumns = numColumns
        
        // Create cells
        for (rowIndex, row) in tableData.enumerated() {
            for (colIndex, cellText) in row.enumerated() {
                // Skip if column index exceeds the table columns
                if colIndex >= numColumns { continue }
                
                let textBlock = NSTextTableBlock(table: table, 
                                                startingRow: rowIndex, 
                                                rowSpan: 1, 
                                                startingColumn: colIndex, 
                                                columnSpan: 1)
                
                // Style header row differently
                textBlock.backgroundColor = rowIndex == 0 ? NSColor.lightGray.withAlphaComponent(0.3) : NSColor.clear
                
                // Set borders
                textBlock.setBorderColor(NSColor.black, for: .minX)
                textBlock.setBorderColor(NSColor.black, for: .maxX)
                textBlock.setBorderColor(NSColor.black, for: .minY)
                textBlock.setBorderColor(NSColor.black, for: .maxY)
                
                // Set border width
                textBlock.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .minX)
                textBlock.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .maxX)
                textBlock.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .minY)
                textBlock.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .maxY)
                
                // Set padding
                textBlock.setWidth(5.0, type: .absoluteValueType, for: .padding, edge: .minX)
                textBlock.setWidth(5.0, type: .absoluteValueType, for: .padding, edge: .maxX)
                textBlock.setWidth(5.0, type: .absoluteValueType, for: .padding, edge: .minY)
                textBlock.setWidth(5.0, type: .absoluteValueType, for: .padding, edge: .maxY)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.textBlocks = [textBlock]
                paragraphStyle.alignment = .center
                
                var cellAttributes = defaultAttributes
                cellAttributes[.paragraphStyle] = paragraphStyle
                cellAttributes[.font] = rowIndex == 0 ? NSFont.boldSystemFont(ofSize: 12) : defaultAttributes[.font] ?? NSFont.systemFont(ofSize: 12)
                
                // Parse inline formatting for the cell text
                let formattedCell = parseInlineFormatting(cellText.trimmingCharacters(in: .whitespaces), defaultAttributes: cellAttributes)
                result.append(formattedCell)
                result.append(NSAttributedString(string: "\n", attributes: cellAttributes))
            }
        }
        
        return (result, currentIndex)
    }
    
    // Parse a table row into cells
    private func parseTableRow(_ row: String) -> [String] {
        // Remove leading and trailing pipes
        var cleanRow = row.trimmingCharacters(in: .whitespaces)
        if cleanRow.hasPrefix("|") {
            cleanRow = String(cleanRow.dropFirst())
        }
        if cleanRow.hasSuffix("|") {
            cleanRow = String(cleanRow.dropLast())
        }
        
        // Split by pipe and clean each cell
        return cleanRow.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private func parseInlineFormatting(_ text: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        var workingText = text
        let result = NSMutableAttributedString()
        
        // Process in order: hyperlinks first, then other formatting
        
        // 1. Process hyperlinks [text](url)
        let hyperlinkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let hyperlinkRegex = try? NSRegularExpression(pattern: hyperlinkPattern) {
            let matches = hyperlinkRegex.matches(in: workingText, range: NSRange(workingText.startIndex..., in: workingText))
            
            var lastEnd = workingText.startIndex
            
            for match in matches.reversed() {
                if let totalRange = Range(match.range, in: workingText),
                   let textRange = Range(match.range(at: 1), in: workingText),
                   let urlRange = Range(match.range(at: 2), in: workingText) {
                    
                    // Add text before the link
                    let beforeText = String(workingText[lastEnd..<totalRange.lowerBound])
                    let formattedBefore = applyBasicFormatting(beforeText, defaultAttributes: defaultAttributes)
                    result.append(formattedBefore)
                    
                    // Create the hyperlink
                    let linkText = String(workingText[textRange])
                    let urlString = String(workingText[urlRange])
                    
                    if let url = URL(string: urlString) {
                        let linkAttrs = NSMutableAttributedString(string: linkText, attributes: defaultAttributes)
                        linkAttrs.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
                        linkAttrs.addAttribute(.foregroundColor, value: NSColor.blue, range: NSRange(location: 0, length: linkText.count))
                        linkAttrs.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: linkText.count))
                        result.append(linkAttrs)
                    } else {
                        // If URL is invalid, just add the text
                        result.append(NSAttributedString(string: linkText, attributes: defaultAttributes))
                    }
                    
                    lastEnd = totalRange.upperBound
                }
            }
            
            // Add remaining text
            if lastEnd < workingText.endIndex {
                let remainingText = String(workingText[lastEnd...])
                let formattedRemaining = applyBasicFormatting(remainingText, defaultAttributes: defaultAttributes)
                result.append(formattedRemaining)
            }
            
            return result
        }
        
        // If no hyperlinks, just apply basic formatting
        return applyBasicFormatting(text, defaultAttributes: defaultAttributes)
    }
    
    private func applyBasicFormatting(_ text: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        var workingText = text
        let result = NSMutableAttributedString()
        
        // Define all formatting patterns
        struct FormatPattern {
            let pattern: String
            let startDelimiter: String
            let endDelimiter: String
            let apply: (NSMutableAttributedString) -> Void
        }
        
        let patterns = [
            // Bold
            FormatPattern(pattern: #"\*\*(.+?)\*\*"#, startDelimiter: "**", endDelimiter: "**", apply: { str in
                // Get existing font size
                let existingFont = str.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
                let fontSize = existingFont?.pointSize ?? 12
                str.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: fontSize), 
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Italic (careful not to match bold)
            FormatPattern(pattern: #"(?<!\*)\*([^\*]+?)\*(?!\*)"#, startDelimiter: "*", endDelimiter: "*", apply: { str in
                // Get existing font
                let existingFont = str.attribute(.font, at: 0, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 12)
                let italicFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .italicFontMask)
                str.addAttribute(.font, value: italicFont, range: NSRange(location: 0, length: str.length))
            }),
            
            // Strikethrough
            FormatPattern(pattern: #"~~(.+?)~~"#, startDelimiter: "~~", endDelimiter: "~~", apply: { str in
                str.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Yellow highlight
            FormatPattern(pattern: #"==(.+?)=="#, startDelimiter: "==", endDelimiter: "==", apply: { str in
                str.addAttribute(.backgroundColor, value: NSColor.yellow,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Green highlight
            FormatPattern(pattern: #"\{\{(.+?)\}\}"#, startDelimiter: "{{", endDelimiter: "}}", apply: { str in
                str.addAttribute(.backgroundColor, value: NSColor.green,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Blue highlight
            FormatPattern(pattern: #"\[\[(.+?)\]\]"#, startDelimiter: "[[", endDelimiter: "]]", apply: { str in
                str.addAttribute(.backgroundColor, value: NSColor.cyan,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Orange highlight
            FormatPattern(pattern: #"\(\((.+?)\)\)"#, startDelimiter: "((", endDelimiter: "))", apply: { str in
                str.addAttribute(.backgroundColor, value: NSColor.orange,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Red text
            FormatPattern(pattern: #"\{red\}(.+?)\{/red\}"#, startDelimiter: "{red}", endDelimiter: "{/red}", apply: { str in
                str.addAttribute(.foregroundColor, value: NSColor.red,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Blue text
            FormatPattern(pattern: #"\{blue\}(.+?)\{/blue\}"#, startDelimiter: "{blue}", endDelimiter: "{/blue}", apply: { str in
                str.addAttribute(.foregroundColor, value: NSColor.blue,
                               range: NSRange(location: 0, length: str.length))
            }),
            
            // Green text
            FormatPattern(pattern: #"\{green\}(.+?)\{/green\}"#, startDelimiter: "{green}", endDelimiter: "{/green}", apply: { str in
                str.addAttribute(.foregroundColor, value: NSColor.green,
                               range: NSRange(location: 0, length: str.length))
            })
        ]
        
        // Track processed ranges to avoid overlapping
        var processedRanges: [NSRange] = []
        
        // Process each pattern
        for formatPattern in patterns {
            if let regex = try? NSRegularExpression(pattern: formatPattern.pattern) {
                let matches = regex.matches(in: workingText, range: NSRange(workingText.startIndex..., in: workingText))
                
                for match in matches {
                    // Skip if this range overlaps with already processed ranges
                    let matchRange = match.range
                    if processedRanges.contains(where: { $0.intersection(matchRange) != nil }) {
                        continue
                    }
                    
                    processedRanges.append(matchRange)
                }
            }
        }
        
        // Sort processed ranges by location
        processedRanges.sort { $0.location < $1.location }
        
        // Apply formatting
        var currentIndex = workingText.startIndex
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern.pattern) {
                let matches = regex.matches(in: workingText, range: NSRange(workingText.startIndex..., in: workingText))
                
                for match in matches {
                    if let captureRange = Range(match.range(at: 1), in: workingText) {
                        let capturedText = String(workingText[captureRange])
                        
                        // Find this match in the original text
                        if let range = workingText.range(of: pattern.startDelimiter + capturedText + pattern.endDelimiter) {
                            workingText.replaceSubrange(range, with: capturedText)
                        }
                    }
                }
            }
        }
        
        // Now apply the formatting to the cleaned text
        result.append(NSMutableAttributedString(string: workingText, attributes: defaultAttributes))
        
        // Apply formatting based on the original patterns
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern.pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let captureRange = Range(match.range(at: 1), in: text) {
                        let capturedText = String(text[captureRange])
                        
                        // Find where this text appears in our result
                        let searchRange = NSRange(location: 0, length: result.length)
                        let resultString = result.string
                        
                        if !capturedText.isEmpty, let range = resultString.range(of: capturedText) {
                            let nsRange = NSRange(range, in: resultString)
                            // Ensure range is valid
                            if nsRange.location + nsRange.length <= result.length {
                                // Create a mutable copy of the substring
                                let mutableSubstring = NSMutableAttributedString(attributedString: result.attributedSubstring(from: nsRange))
                                if mutableSubstring.length > 0 {
                                    pattern.apply(mutableSubstring)
                                    // Replace the range in the original with the formatted version
                                    result.replaceCharacters(in: nsRange, with: mutableSubstring)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    private func createParagraphStyle(alignment: NSTextAlignment = .left, 
                                    spaceBefore: CGFloat = 0, 
                                    spaceAfter: CGFloat = 0) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.paragraphSpacingBefore = spaceBefore
        style.paragraphSpacing = spaceAfter
        style.lineSpacing = 1.15
        return style
    }
    
    private func getTemplateAttributes(_ template: String) -> [NSAttributedString.Key: Any] {
        switch template {
        case "business":
            return [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
        case "technical":
            return [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.darkGray
            ]
        case "meeting":
            return [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 1.5
                    return style
                }()
            ]
        default:
            return [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
        }
    }
}
