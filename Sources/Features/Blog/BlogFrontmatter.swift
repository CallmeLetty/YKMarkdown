import Foundation

struct BlogFrontmatter: Equatable {
    var title: String
    var date: String
    var tags: [String]
    var excerpt: String
    /// 发布栏目；空值兼容旧文章，由标签沿用博客的分类规则。
    var category: String = ""

    /// 与博客 categoryOf 保持一致，用于上传弹窗预选旧文章的实际栏目。
    var resolvedCategory: String {
        if !category.isEmpty { return category }
        if tags.contains("播客") { return "播客" }
        if tags.contains(where: { ["技术", "Web", "工具"].contains($0) }) { return "技术" }
        return "随笔"
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 返回文首属性块的原始 UTF-16 范围，供展示和回写保留原始换行格式。
    static func sourceRange(in markdown: String) -> NSRange? {
        guard let regex = try? NSRegularExpression(pattern: #"\A---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)"#),
              let match = regex.firstMatch(in: markdown, range: NSRange(markdown.startIndex..., in: markdown)),
              let fieldsRange = Range(match.range(at: 1), in: markdown)
        else { return nil }
        // 至少有一个属性键，避免把普通分隔线之间的正文或连续分隔线折叠。
        let fields = String(markdown[fieldsRange])
        guard fields.range(of: #"(?m)^[A-Za-z_][A-Za-z0-9_-]*:[ \t]*"#, options: .regularExpression) != nil else { return nil }
        return match.range
    }

    static func parse(from markdown: String) -> (meta: BlogFrontmatter?, body: String) {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        guard sourceRange(in: normalized) != nil,
              let regex = try? NSRegularExpression(pattern: #"\A---\n([\s\S]*?)\n---(?:\n|$)"#, options: []),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let metaRange = Range(match.range(at: 1), in: normalized),
              let fullRange = Range(match.range, in: normalized)
        else {
            return (nil, normalized)
        }

        let metaBlock = String(normalized[metaRange])
        let body = String(normalized[fullRange.upperBound...])

        var title = ""
        var date = todayString()
        var tags: [String] = []
        var excerpt = ""
        var category = ""

        for line in metaBlock.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            guard let idx = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<idx]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            switch key {
            case "title": title = value
            case "date": date = value.isEmpty ? todayString() : value
            case "excerpt": excerpt = value
            case "tags": tags = parseTags(value)
            case "category": category = value
            default: break
            }
        }

        return (
            BlogFrontmatter(title: title, date: date, tags: tags, excerpt: excerpt, category: category),
            body
        )
    }

    func render(body: String) -> String {
        let tagList = tags.map { tag in
            tag.contains(" ") || tag.contains(",") ? "\"\(tag)\"" : tag
        }.joined(separator: ", ")

        var lines = [
            "---",
            "title: \(title)",
            "date: \(date)",
            "tags: [\(tagList)]",
        ]
        if !category.isEmpty {
            lines.append("category: \(category)")
        }
        if !excerpt.isEmpty {
            lines.append("excerpt: \(excerpt)")
        }
        lines.append("---")
        lines.append("")

        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return lines.joined(separator: "\n") + trimmedBody + "\n"
    }

    private static func parseTags(_ value: String) -> [String] {
        var raw = value.trimmingCharacters(in: .whitespaces)
        if raw.hasPrefix("["), raw.hasSuffix("]") {
            raw = String(raw.dropFirst().dropLast())
        }
        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { tag in
                var value = String(tag)
                if (value.hasPrefix("\"") && value.hasSuffix("\""))
                    || (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                return value
            }
            .filter { !$0.isEmpty }
    }
}

enum BlogSlug {
    /// 标题转为无声调拼音或拉丁字母，并限制为上传接口接受的 ASCII 文件名。
    static func make(from titleOrFilename: String) -> String {
        let latin = titleOrFilename.applyingTransform(.toLatin, reverse: false) ?? titleOrFilename
        let folded = latin
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if (97...122).contains(scalar.value) || (48...57).contains(scalar.value) {
                return Character(scalar)
            }
            return "-"
        }
        var slug = String(scalars)
        while slug.contains("--") {
            slug = slug.replacingOccurrences(of: "--", with: "-")
        }
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if slug.isEmpty {
            return "post-\(BlogFrontmatter.todayString())"
        }
        return slug
    }
}
