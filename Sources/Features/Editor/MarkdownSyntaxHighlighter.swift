import AppKit

/// 仅提供源码的显示层次，不改写文本、字体或撤销栈；与搜索背景高亮互不覆盖。
enum MarkdownSyntaxHighlighter {
    enum Role: Equatable {
        case marker, heading, property, link, code
    }

    struct Token {
        let range: NSRange
        let role: Role
    }

    /// 所有范围使用 UTF-16，与 NSTextView 及文档定位保持一致。
    static func tokens(in text: String) -> [Token] {
        let source = text as NSString
        let metadataRange = BlogFrontmatter.sourceRange(in: text)
        var result: [Token] = []
        var isCode = false
        var offset = 0

        // 正则只用于着色提示，语义解析仍由 MarkdownHTMLRenderer 负责。
        func appendMatches(_ pattern: String, in range: NSRange, role: Role, group: Int = 0) {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            for match in regex.matches(in: text, range: range) {
                let tokenRange = match.range(at: group)
                if tokenRange.location != NSNotFound {
                    result.append(Token(range: tokenRange, role: role))
                }
            }
        }

        while offset < source.length {
            let range = source.lineRange(for: NSRange(location: offset, length: 0))
            let line = source.substring(with: range).trimmingCharacters(in: .newlines)
            offset = NSMaxRange(range)
            if let metadataRange, range.location < NSMaxRange(metadataRange) {
                if line == "---" {
                    result.append(Token(range: range, role: .marker))
                } else {
                    appendMatches(#"^\s*([A-Za-z_][A-Za-z0-9_-]*:)"#, in: range, role: .property, group: 1)
                }
                continue
            }
            if line.hasPrefix("```") {
                result.append(Token(range: range, role: .marker))
                isCode.toggle()
                continue
            }
            if isCode {
                result.append(Token(range: range, role: .code))
                continue
            }
            if line.range(of: #"^\s{0,3}#{1,6}\s"#, options: .regularExpression) != nil {
                result.append(Token(range: range, role: .heading))
            }
            appendMatches(#"^\s{0,3}(#{1,6}\s+|>\s?|[-+*]\s+|\d+\.\s+)"#, in: range, role: .marker)
            appendMatches(#"`[^`\r\n]+`"#, in: range, role: .code)
            appendMatches(#"!?\[[^\]\r\n]+\]\(([^\s)]+)\)"#, in: range, role: .link, group: 1)
        }
        return result
    }

    /// 使用临时前景色，保证高亮不会触发文档变更，也不影响输入法组合文本。
    @MainActor
    static func apply(to textView: NSTextView, foregroundColor: NSColor) {
        guard let layoutManager = textView.layoutManager, !textView.hasMarkedText() else { return }
        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: fullRange)
        let accent = foregroundColor.blended(withFraction: 0.55, of: .controlAccentColor) ?? foregroundColor
        let property = foregroundColor.blended(withFraction: 0.4, of: .systemPurple) ?? foregroundColor
        for token in tokens(in: textView.string) {
            let color: NSColor
            switch token.role {
            case .marker, .link: color = foregroundColor.withAlphaComponent(0.5)
            case .heading: color = accent
            case .property: color = property
            case .code: color = foregroundColor.withAlphaComponent(0.75)
            }
            layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: token.range)
        }
    }
}
