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
        
        // Write to file
        do {
            try rtfData.write(to: URL(fileURLWithPath: expandedPath))
            return CreateResult(success: true, path: expandedPath, message: "Document created successfully")
        } catch {
            return CreateResult(success: false, path: "", message: "Failed to write file: \(error)")
        }
    }
    
    func applyFormatting(filePath: String, formatting: [[String: Any]]) async throws -> FormatResult {
        let expandedPath = NSString(string: filePath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        // Read existing RTF
        guard let attributedString = try? NSMutableAttributedString(
            url: url,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return FormatResult(success: false, message: "Failed to read RTF file")
        }
        
        // Apply formatting
        for format in formatting {
            applyFormat(to: attributedString, format: format)
        }
        
        // Save back
        guard let rtfData = attributedString.rtf(from: NSRange(location: 0, length: attributedString.length),
                                                 documentAttributes: [
                                                     .documentType: NSAttributedString.DocumentType.rtf
                                                 ]) else {
            return FormatResult(success: false, message: "Failed to create RTF data")
        }
        
        do {
            try rtfData.write(to: url)
            return FormatResult(success: true, message: "Formatting applied successfully")
        } catch {
            return FormatResult(success: false, message: "Failed to write file: \(error)")
        }
    }
    
    private func parseContent(_ content: String, template: String) throws -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        let lines = content.components(separatedBy: .newlines)
        
        // Apply template defaults
        let defaultAttributes = getTemplateAttributes(template)
        
        for line in lines {
            if line.hasPrefix("# ") {
                // H1
                let text = String(line.dropFirst(2))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 24),
                    .paragraphStyle: createParagraphStyle(alignment: .center, spaceBefore: 0, spaceAfter: 12)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                
            } else if line.hasPrefix("## ") {
                // H2
                let text = String(line.dropFirst(3))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 12, spaceAfter: 6)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                
            } else if line.hasPrefix("### ") {
                // H3
                let text = String(line.dropFirst(4))
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 14),
                    .paragraphStyle: createParagraphStyle(spaceBefore: 6, spaceAfter: 3)
                ]
                result.append(NSAttributedString(string: text + "\n", attributes: attributes))
                
            } else if line.hasPrefix("- ") || line.hasPrefix("• ") {
                // Bullet point
                let text = String(line.dropFirst(2))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
                
                result.append(NSAttributedString(string: "•\t" + text + "\n", 
                                               attributes: [.paragraphStyle: paragraphStyle] + defaultAttributes))
                
            } else if let match = line.firstMatch(of: /^(\d+)\. (.+)$/) {
                // Numbered list
                let number = String(match.1)
                let text = String(match.2)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
                
                result.append(NSAttributedString(string: "\(number).\t\(text)\n",
                                               attributes: [.paragraphStyle: paragraphStyle] + defaultAttributes))
                
            } else {
                // Regular paragraph with inline formatting
                let formatted = parseInlineFormatting(line, defaultAttributes: defaultAttributes)
                result.append(formatted)
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        return result
    }
    
    private func parseInlineFormatting(_ text: String, defaultAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        var currentText = text
        
        // Pattern matching for inline formats
        let patterns: [(pattern: String, apply: (NSMutableAttributedString) -> Void)] = [
            // Bold
            (#"\*\*(.+?)\*\*"#, { str in
                str.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 12), 
                               range: NSRange(location: 0, length: str.length))
            }),
            // Italic
            (#"\*(.+?)\*"#, { str in
                str.addAttribute(.font, value: NSFont.italicSystemFont(ofSize: 12),
                               range: NSRange(location: 0, length: str.length))
            }),
            // Highlight
            (#"==(.+?)=="#, { str in
                str.addAttribute(.backgroundColor, value: NSColor.yellow,
                               range: NSRange(location: 0, length: str.length))
            }),
            // Strikethrough
            (#"~~(.+?)~~"#, { str in
                str.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue,
                               range: NSRange(location: 0, length: str.length))
            })
        ]
        
        // Process patterns
        var lastEnd = currentText.startIndex
        
        for (pattern, applyFormat) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: currentText, 
                                          range: NSRange(currentText.startIndex..., in: currentText))
                
                for match in matches {
                    // Add text before match
                    if let range = Range(match.range, in: currentText) {
                        let beforeText = String(currentText[lastEnd..<range.lowerBound])
                        result.append(NSAttributedString(string: beforeText, attributes: defaultAttributes))
                        
                        // Add formatted text
                        if let captureRange = Range(match.range(at: 1), in: currentText) {
                            let capturedText = String(currentText[captureRange])
                            let formattedString = NSMutableAttributedString(string: capturedText, 
                                                                          attributes: defaultAttributes)
                            applyFormat(formattedString)
                            result.append(formattedString)
                        }
                        
                        lastEnd = range.upperBound
                    }
                }
            }
        }
        
        // Add remaining text
        if lastEnd < currentText.endIndex {
            let remainingText = String(currentText[lastEnd...])
            result.append(NSAttributedString(string: remainingText, attributes: defaultAttributes))
        }
        
        return result.length > 0 ? result : NSMutableAttributedString(string: text, attributes: defaultAttributes)
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
        default:
            return [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
        }
    }
    
    private func applyFormat(to attributedString: NSMutableAttributedString, format: [String: Any]) {
        guard let type = format["type"] as? String else { return }
        
        // Get range
        let start = format["start"] as? Int ?? 0
        let length = format["length"] as? Int ?? 0
        let range = NSRange(location: start, length: length)
        
        // Validate range
        guard range.location + range.length <= attributedString.length else { return }
        
        switch type {
        case "highlight":
            if let colorName = format["color"] as? String,
               let color = colorFromName(colorName) {
                attributedString.addAttribute(.backgroundColor, value: color, range: range)
            }
            
        case "color":
            if let colorName = format["color"] as? String,
               let color = colorFromName(colorName) {
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
            
        case "bold":
            attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 12), range: range)
            
        case "italic":
            attributedString.addAttribute(.font, value: NSFont.italicSystemFont(ofSize: 12), range: range)
            
        default:
            break
        }
    }
    
    private func colorFromName(_ name: String) -> NSColor? {
        switch name.lowercased() {
        case "yellow": return .yellow
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "lightblue": return .cyan
        case "lightgreen": return NSColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        default: return nil
        }
    }
}
