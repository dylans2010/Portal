import Foundation

// MARK: - Guide Parser
class GuideParser {
    static func parse(markdown: String) -> ParsedGuideContent {
        var elements: [GuideElement] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Skip empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }
            
            // Parse headings
            if line.hasPrefix("#") {
                let heading = parseHeading(line)
                if let heading = heading {
                    elements.append(heading)
                }
                i += 1
                continue
            }
            
            // Parse code blocks
            if line.hasPrefix("```") {
                let (codeBlock, linesConsumed) = parseCodeBlock(lines: lines, startIndex: i)
                if let codeBlock = codeBlock {
                    elements.append(codeBlock)
                    i += linesConsumed
                    continue
                }
            }
            
            // Parse blockquotes
            if line.hasPrefix(">") {
                let quote = parseBlockquote(line)
                elements.append(quote)
                i += 1
                continue
            }
            
            // Parse list items (including nested)
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") ||
               line.hasPrefix("  - ") || line.hasPrefix("  * ") || line.hasPrefix("  + ") ||
               line.hasPrefix("    - ") || line.hasPrefix("    * ") || line.hasPrefix("    + ") {
                let listItem = parseListItem(line)
                elements.append(listItem)
                i += 1
                continue
            }
            
            // Parse numbered lists
            if let match = line.range(of: #"^\s*\d+\.\s"#, options: .regularExpression) {
                let level = countLeadingSpaces(line) / 2
                let text = String(line[match.upperBound...])
                let content = parseInlineContent(text)
                elements.append(.listItem(level: level, content: content))
                i += 1
                continue
            }
            
            // Parse images (standalone)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("![") {
                if let image = parseImage(line) {
                    elements.append(image)
                    i += 1
                    continue
                }
            }
            
            // Default: treat as paragraph with inline content
            let content = parseInlineContent(line)
            if !content.isEmpty {
                elements.append(.paragraph(content: content))
            }
            i += 1
        }
        
        return ParsedGuideContent(elements: elements)
    }
    
    private static func countLeadingSpaces(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    private static func parseHeading(_ line: String) -> GuideElement? {
        var level = 0
        var text = line
        
        while text.hasPrefix("#") {
            level += 1
            text = String(text.dropFirst())
        }
        
        text = text.trimmingCharacters(in: .whitespaces)
        
        // Check for accent:// pattern and remove literal brackets
        // Pattern: [Some Text](accent://) -> Some Text with accent flag
        // Pattern: (accent://) at start -> remaining text with accent flag
        // Pattern: Some Text (accent://) -> Some Text with accent flag
        // Pattern: (accent://)Some Text -> Some Text with accent flag
        // Also handles: [Some Text] -> Some Text without accent flag
        var isAccent = false
        let accentPattern = #"^\[([^\]]+)\]\(accent://[^\)]*\)$"#
        let bracketOnlyPattern = #"^\[([^\]]+)\]$"#
        
        if let regex = try? NSRegularExpression(pattern: accentPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let textRange = Range(match.range(at: 1), in: text) {
            text = String(text[textRange])
            isAccent = true
        } else if let regex = try? NSRegularExpression(pattern: bracketOnlyPattern, options: []),
                  let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
                  let textRange = Range(match.range(at: 1), in: text) {
            text = String(text[textRange])
        } else if text.hasPrefix("(accent://)") {
            // Handle (accent://) prefix - strip it and mark as accent
            text = String(text.dropFirst("(accent://)".count)).trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("(accent://)") {
            // Handle text followed by (accent://) anywhere in the line
            // Pattern: "Some Text (accent://)" -> "Some Text" with accent flag
            text = text.replacingOccurrences(of: "(accent://)", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("accent://") {
            // Handle standalone accent:// anywhere in heading
            // Pattern: "accent://Something" or "Some Text accent://more" -> mark as accent and remove accent://
            text = text.replacingOccurrences(of: "accent://", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        }
        
        if level > 0 && !text.isEmpty {
            return .heading(level: level, text: text, isAccent: isAccent)
        }
        
        return nil
    }
    
    private static func parseCodeBlock(lines: [String], startIndex: Int) -> (GuideElement?, Int) {
        let firstLine = lines[startIndex]
        let language = String(firstLine.dropFirst(3).trimmingCharacters(in: .whitespaces))
        
        var codeLines: [String] = []
        var i = startIndex + 1
        
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                // End of code block
                let code = codeLines.joined(separator: "\n")
                return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex + 1)
            }
            codeLines.append(line)
            i += 1
        }
        
        // If we reach here, the code block wasn't closed properly
        let code = codeLines.joined(separator: "\n")
        return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex)
    }
    
    private static func parseBlockquote(_ line: String) -> GuideElement {
        let text = line.dropFirst().trimmingCharacters(in: .whitespaces)
        let content = parseInlineContent(String(text))
        return .blockquote(content: content)
    }
    
    private static func parseListItem(_ line: String) -> GuideElement {
        var text = line
        var level = 0
        
        // Count leading spaces for nested lists
        let leadingSpaces = countLeadingSpaces(text)
        level = leadingSpaces / 2
        
        // Remove leading spaces
        text = text.trimmingCharacters(in: .whitespaces)
        
        // Remove list marker
        if text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("+ ") {
            text = String(text.dropFirst(2))
        }
        
        let content = parseInlineContent(text)
        return .listItem(level: level, content: content)
    }
    
    // Parse inline content (text with embedded links, accent:// references, etc.)
    private static func parseInlineContent(_ text: String) -> [InlineContent] {
        var result: [InlineContent] = []
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // Check for (accent://) wrapped text syntax
            if text[i] == "(" {
                // Look ahead for "accent://"
                let afterParen = text.index(after: i)
                let checkText = String(text[afterParen...])
                
                if checkText.hasPrefix("accent://") {
                    // Find the closing parenthesis
                    if let closeParenRange = text.range(of: ")", range: afterParen..<text.endIndex) {
                        // Save any accumulated text before this
                        if !currentText.isEmpty {
                            result.append(.text(currentText))
                            currentText = ""
                        }
                        
                        // Skip the entire (accent://) wrapper - it's just a marker
                        i = closeParenRange.upperBound
                        continue
                    }
                }
            }
            
            // Check for image syntax (skip it in inline content)
            if text[i] == "!" && i < text.index(before: text.endIndex) && text[text.index(after: i)] == "[" {
                // Find the end of the image
                if let endBracket = text.range(of: "](", range: i..<text.endIndex),
                   let endParen = text.range(of: ")", range: endBracket.upperBound..<text.endIndex) {
                    // Skip the entire image
                    i = endParen.upperBound
                    continue
                }
            }
            
            // Check for link syntax
            if text[i] == "[" {
                // Save any accumulated text
                if !currentText.isEmpty {
                    result.append(.text(currentText))
                    currentText = ""
                }
                
                // Find the matching ] and (
                if let closeBracket = findMatchingBracket(in: text, start: i),
                   closeBracket < text.endIndex,
                   text[closeBracket] == "]" {
                    
                    let nextIndex = text.index(after: closeBracket)
                    if nextIndex < text.endIndex && text[nextIndex] == "(" {
                        // Found a link
                        if let closeParen = text.range(of: ")", range: nextIndex..<text.endIndex) {
                            let linkText = String(text[text.index(after: i)..<closeBracket])
                            let urlStart = text.index(after: nextIndex)
                            var url = String(text[urlStart..<closeParen.lowerBound]).trimmingCharacters(in: .whitespaces)
                            
                            // Clean up URLs with broken brackets or extra spaces
                            url = url.replacingOccurrences(of: " ", with: "")
                            url = url.replacingOccurrences(of: "[", with: "")
                            url = url.replacingOccurrences(of: "]", with: "")
                            
                            // Check if URL uses accent:// scheme
                            if url.hasPrefix("accent://") {
                                // Remove the accent:// prefix for display but mark as accent
                                result.append(.accentLink(url: url, text: linkText))
                            } else {
                                result.append(.link(url: url, text: linkText))
                            }
                            
                            i = closeParen.upperBound
                            continue
                        }
                    }
                }
                
                // Not a valid link, treat as text
                currentText.append(text[i])
                i = text.index(after: i)
            } else {
                currentText.append(text[i])
                i = text.index(after: i)
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            // Check if the text contains (accent://) or accent:// (as plain text reference)
            // This handles cases like: "(accent://)Part 1" or "Check out accent://something"
            var remainingText = currentText
            
            // First check for (accent://) pattern - text immediately following this gets accent color
            while let accentMarkerRange = remainingText.range(of: "(accent://)") {
                // Add text before the marker if any
                let beforeMarker = String(remainingText[..<accentMarkerRange.lowerBound])
                if !beforeMarker.isEmpty {
                    result.append(.text(beforeMarker))
                }
                
                // Skip the (accent://) marker itself
                let afterMarker = accentMarkerRange.upperBound
                
                // Find the end of text to apply accent to (until next space or end)
                var accentTextEnd = afterMarker
                while accentTextEnd < remainingText.endIndex {
                    let char = remainingText[accentTextEnd]
                    if char.isWhitespace {
                        break
                    }
                    accentTextEnd = remainingText.index(after: accentTextEnd)
                }
                
                // Extract the text that should have accent color
                let accentText = String(remainingText[afterMarker..<accentTextEnd])
                if !accentText.isEmpty {
                    result.append(.accentText(accentText))
                }
                
                // Continue with the rest
                if accentTextEnd < remainingText.endIndex {
                    remainingText = String(remainingText[accentTextEnd...])
                } else {
                    remainingText = ""
                    break
                }
            }
            
            // Then check for standalone accent:// pattern
            while let accentRange = remainingText.range(of: "accent://") {
                // Add text before accent if any
                let beforeAccent = String(remainingText[..<accentRange.lowerBound])
                if !beforeAccent.isEmpty {
                    result.append(.text(beforeAccent))
                }
                
                // Find the end of the accent text (next space, punctuation, or end of string)
                let afterPrefix = accentRange.upperBound
                var accentTextEnd = afterPrefix
                
                // Continue until we hit a space, newline, or end of string
                while accentTextEnd < remainingText.endIndex {
                    let char = remainingText[accentTextEnd]
                    if char.isWhitespace || char.isPunctuation {
                        break
                    }
                    accentTextEnd = remainingText.index(after: accentTextEnd)
                }
                
                // Extract the accent text (without the accent:// prefix)
                let accentText = String(remainingText[afterPrefix..<accentTextEnd])
                if !accentText.isEmpty {
                    result.append(.accentText(accentText))
                }
                
                // Continue with the rest of the text
                if accentTextEnd < remainingText.endIndex {
                    remainingText = String(remainingText[accentTextEnd...])
                } else {
                    remainingText = ""
                    break
                }
            }
            
            // Add any remaining text after all accent:// occurrences
            if !remainingText.isEmpty {
                result.append(.text(remainingText))
            }
        }
        
        return result.isEmpty ? [.text(text)] : result
    }
    
    private static func findMatchingBracket(in text: String, start: String.Index) -> String.Index? {
        var depth = 0
        var i = start
        
        while i < text.endIndex {
            if text[i] == "[" {
                depth += 1
            } else if text[i] == "]" {
                depth -= 1
                if depth == 0 {
                    return i
                }
            }
            i = text.index(after: i)
        }
        
        return nil
    }
    
    private static func parseImage(_ line: String) -> GuideElement? {
        // Pattern: ![alt text](url)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let altStart = trimmed.range(of: "!["),
              let altEnd = trimmed.range(of: "](", range: altStart.upperBound..<trimmed.endIndex),
              let urlEnd = trimmed.range(of: ")", range: altEnd.upperBound..<trimmed.endIndex) else {
            return nil
        }
        
        let altText = String(trimmed[altStart.upperBound..<altEnd.lowerBound])
        var url = String(trimmed[altEnd.upperBound..<urlEnd.lowerBound])
        
        // Clean up URL
        url = url.trimmingCharacters(in: .whitespaces)
        url = url.replacingOccurrences(of: " ", with: "")
        
        return .image(url: url, altText: altText)
    }
}
