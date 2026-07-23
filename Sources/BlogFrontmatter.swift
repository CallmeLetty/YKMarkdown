import Foundation

struct BlogFrontmatter: Equatable {
    var title: String
    var date: String
    var tags: [String]
    var excerpt: String

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    static func parse(from markdown: String) -> (meta: BlogFrontmatter?, body: String) {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        guard let regex = try? NSRegularExpression(pattern: #"\A---\n([\s\S]*?)\n---\n?"#, options: []),
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
            default: break
            }
        }

        return (
            BlogFrontmatter(title: title, date: date, tags: tags, excerpt: excerpt),
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
    static func make(from titleOrFilename: String) -> String {
        let folded = titleOrFilename
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
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
