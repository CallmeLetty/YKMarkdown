import Foundation

enum MarkdownHTMLRenderer {
    static func bodyHTML(from markdown: String) -> String {
        let rendered = renderBody(markdown)
        if rendered.isEmpty {
            return "<p><br></p>"
        }
        return rendered
    }

    static func editableDocument(bodyHTML: String, turndownScript: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <style>
            :root {
              color-scheme: light dark;
              --text: #1f2328;
              --muted: #656d76;
              --border: #d0d7de;
              --code-bg: #f6f8fa;
              --quote-border: #d0d7de;
              --link: #0969da;
              --bg: transparent;
              --focus: rgba(9, 105, 218, 0.18);
            }
            @media (prefers-color-scheme: dark) {
              :root {
                --text: #e6edf3;
                --muted: #8b949e;
                --border: #30363d;
                --code-bg: #161b22;
                --quote-border: #3d444d;
                --link: #2f81f7;
                --focus: rgba(47, 129, 247, 0.22);
              }
            }
            html, body {
              margin: 0;
              padding: 0;
              background: var(--bg);
              color: var(--text);
              font: 15px/1.65 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
              height: 100%;
            }
            #content {
              min-height: calc(100vh - 40px);
              padding: 20px 24px 40px;
              outline: none;
            }
            #content:focus { box-shadow: inset 0 0 0 2px var(--focus); }
            h1, h2, h3, h4, h5, h6 {
              line-height: 1.25;
              margin: 1.4em 0 0.6em;
              font-weight: 700;
            }
            h1 { font-size: 1.9em; border-bottom: 1px solid var(--border); padding-bottom: 0.3em; }
            h2 { font-size: 1.5em; border-bottom: 1px solid var(--border); padding-bottom: 0.25em; }
            h3 { font-size: 1.25em; }
            p, ul, ol, pre, blockquote, table { margin: 0 0 1em; }
            a { color: var(--link); text-decoration: none; }
            a:hover { text-decoration: underline; }
            code {
              font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
              font-size: 0.9em;
              background: var(--code-bg);
              padding: 0.15em 0.4em;
              border-radius: 6px;
            }
            pre {
              background: var(--code-bg);
              border: 1px solid var(--border);
              border-radius: 10px;
              padding: 14px 16px;
              overflow: auto;
            }
            pre code {
              background: transparent;
              padding: 0;
              border-radius: 0;
              font-size: 0.88em;
            }
            blockquote {
              margin-left: 0;
              padding: 0.2em 0 0.2em 1em;
              color: var(--muted);
              border-left: 4px solid var(--quote-border);
            }
            hr {
              border: none;
              border-top: 1px solid var(--border);
              margin: 1.5em 0;
            }
            table {
              border-collapse: collapse;
              width: 100%;
              display: block;
              overflow: auto;
            }
            th, td {
              border: 1px solid var(--border);
              padding: 8px 12px;
            }
            th { background: var(--code-bg); }
            img { max-width: 100%; height: auto; border-radius: 6px; }
            ul, ol { padding-left: 1.6em; }
            li { margin: 0.25em 0; }
          </style>
        </head>
        <body>
          <div id="content" contenteditable="true" spellcheck="true">\(bodyHTML)</div>
          <script>
          \(turndownScript)
          </script>
          <script>
          (function () {
            const content = document.getElementById('content');
            const turndown = new TurndownService({
              headingStyle: 'atx',
              codeBlockStyle: 'fenced',
              bulletListMarker: '-',
              emDelimiter: '*',
              strongDelimiter: '**'
            });
            turndown.addRule('strikethrough', {
              filter: ['del', 's', 'strike'],
              replacement: function (content) { return '~~' + content + '~~'; }
            });

            let emitTimer = null;
            let suppressEmit = false;

            function post(payload) {
              if (window.webkit && webkit.messageHandlers && webkit.messageHandlers.bridge) {
                webkit.messageHandlers.bridge.postMessage(payload);
              }
            }

            function currentMarkdown() {
              return turndown.turndown(content.innerHTML || '');
            }

            function emitMarkdown() {
              if (suppressEmit) return;
              post({ type: 'markdownChanged', markdown: currentMarkdown() });
            }

            function scheduleEmit() {
              clearTimeout(emitTimer);
              emitTimer = setTimeout(emitMarkdown, 100);
            }

            content.addEventListener('input', scheduleEmit);
            content.addEventListener('keyup', scheduleEmit);
            content.addEventListener('cut', scheduleEmit);

            content.addEventListener('paste', function (event) {
              const items = event.clipboardData ? event.clipboardData.items : null;
              let hasImage = false;
              if (items) {
                for (let i = 0; i < items.length; i++) {
                  if (items[i].type && items[i].type.indexOf('image') === 0) {
                    hasImage = true;
                    break;
                  }
                }
              }
              if (hasImage) {
                event.preventDefault();
                post({ type: 'pasteImages' });
                return;
              }
              setTimeout(scheduleEmit, 0);
            });

            content.addEventListener('click', function (event) {
              const anchor = event.target.closest('a');
              if (anchor && anchor.href) {
                event.preventDefault();
                post({ type: 'openURL', url: anchor.href });
              }
            });

            content.addEventListener('dragover', function (event) {
              event.preventDefault();
            });

            content.addEventListener('drop', function (event) {
              event.preventDefault();
              post({ type: 'requestDropImport' });
            });

            window.setBodyHTML = function (html) {
              suppressEmit = true;
              const htmlValue = html && html.length ? html : '<p><br></p>';
              if (content.innerHTML !== htmlValue) {
                content.innerHTML = htmlValue;
              }
              suppressEmit = false;
            };

            window.insertImageAtCaret = function (src, alt) {
              const safeSrc = String(src).replace(/"/g, '&quot;');
              const safeAlt = String(alt || '').replace(/"/g, '&quot;');
              document.execCommand(
                'insertHTML',
                false,
                '<p><img src="' + safeSrc + '" alt="' + safeAlt + '" /></p>'
              );
              scheduleEmit();
            };

            window.focusEditor = function () {
              content.focus();
            };
          })();
          </script>
        </body>
        </html>
        """
    }

    private static func renderBody(_ markdown: String) -> String {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var html: [String] = []
        var index = 0
        var inCodeBlock = false
        var codeLanguage = ""
        var codeLines: [String] = []
        var paragraph: [String] = []
        var listKind: ListKind?
        var listItems: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.joined(separator: " ")
            html.append("<p>\(renderInline(text))</p>")
            paragraph.removeAll(keepingCapacity: true)
        }

        func flushList() {
            guard let kind = listKind, !listItems.isEmpty else { return }
            let tag = kind == .unordered ? "ul" : "ol"
            let items = listItems.map { "<li>\(renderInline($0))</li>" }.joined()
            html.append("<\(tag)>\(items)</\(tag)>")
            listKind = nil
            listItems.removeAll(keepingCapacity: true)
        }

        while index < lines.count {
            let line = lines[index]

            if line.hasPrefix("```") {
                flushParagraph()
                flushList()
                if inCodeBlock {
                    let code = escapeHTML(codeLines.joined(separator: "\n"))
                    let languageClass = codeLanguage.isEmpty ? "" : " class=\"language-\(escapeHTML(codeLanguage))\""
                    html.append("<pre><code\(languageClass)>\(code)</code></pre>")
                    codeLines.removeAll(keepingCapacity: true)
                    codeLanguage = ""
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                index += 1
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                index += 1
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                index += 1
                continue
            }

            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                flushList()
                html.append("<hr />")
                index += 1
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                flushList()
                html.append("<h\(heading.level)>\(renderInline(heading.text))</h\(heading.level)>")
                index += 1
                continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                flushParagraph()
                flushList()
                var quoteLines: [String] = []
                while index < lines.count {
                    let current = lines[index].trimmingCharacters(in: .whitespaces)
                    if current.hasPrefix("> ") {
                        quoteLines.append(String(current.dropFirst(2)))
                    } else if current == ">" {
                        quoteLines.append("")
                    } else {
                        break
                    }
                    index += 1
                }
                let quoteBody = quoteLines
                    .map { $0.isEmpty ? "<br />" : renderInline($0) }
                    .joined(separator: "<br />")
                html.append("<blockquote><p>\(quoteBody)</p></blockquote>")
                continue
            }

            if let unordered = matchUnorderedListItem(trimmed) {
                flushParagraph()
                if listKind != .unordered {
                    flushList()
                    listKind = .unordered
                }
                listItems.append(unordered)
                index += 1
                continue
            }

            if let ordered = matchOrderedListItem(trimmed) {
                flushParagraph()
                if listKind != .ordered {
                    flushList()
                    listKind = .ordered
                }
                listItems.append(ordered)
                index += 1
                continue
            }

            if looksLikeTableHeader(trimmed), index + 1 < lines.count, isTableSeparator(lines[index + 1]) {
                flushParagraph()
                flushList()
                let headerCells = splitTableRow(trimmed)
                index += 2
                var rows: [[String]] = []
                while index < lines.count {
                    let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if rowLine.isEmpty || !rowLine.contains("|") { break }
                    rows.append(splitTableRow(rowLine))
                    index += 1
                }
                var table = "<table><thead><tr>"
                table += headerCells.map { "<th>\(renderInline($0))</th>" }.joined()
                table += "</tr></thead><tbody>"
                for row in rows {
                    table += "<tr>"
                    table += row.map { "<td>\(renderInline($0))</td>" }.joined()
                    table += "</tr>"
                }
                table += "</tbody></table>"
                html.append(table)
                continue
            }

            flushList()
            paragraph.append(trimmed)
            index += 1
        }

        if inCodeBlock {
            let code = escapeHTML(codeLines.joined(separator: "\n"))
            html.append("<pre><code>\(code)</code></pre>")
        }
        flushParagraph()
        flushList()

        return html.joined(separator: "\n")
    }

    private enum ListKind {
        case unordered
        case ordered
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for character in line {
            if character == "#" {
                level += 1
            } else {
                break
            }
        }
        guard level >= 1, level <= 6 else { return nil }
        let rest = line.dropFirst(level)
        guard rest.first == " " || rest.isEmpty else { return nil }
        let text = rest.trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    private static func matchUnorderedListItem(_ line: String) -> String? {
        for prefix in ["- ", "* ", "+ "] where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count))
        }
        return nil
    }

    private static func matchOrderedListItem(_ line: String) -> String? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let number = line[..<dotIndex]
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else { return nil }
        let after = line[line.index(after: dotIndex)...]
        guard after.first == " " else { return nil }
        return after.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    private static func looksLikeTableHeader(_ line: String) -> Bool {
        line.contains("|")
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") || trimmed.contains("-") else { return false }
        return trimmed.unicodeScalars.allSatisfy { scalar in
            CharacterSet(charactersIn: "|-: ").contains(scalar)
        } && trimmed.contains("-")
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var cells = line.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        if cells.first?.isEmpty == true { cells.removeFirst() }
        if cells.last?.isEmpty == true { cells.removeLast() }
        return cells
    }

    private static func renderInline(_ text: String) -> String {
        var result = escapeHTML(text)

        result = replacePattern(
            in: result,
            pattern: "`([^`]+)`",
            template: "<code>$1</code>"
        )
        result = replacePattern(
            in: result,
            pattern: #"!\[([^\]]*)\]\(([^)\s]+)\)"#,
            template: #"<img src="$2" alt="$1" />"#
        )
        result = replacePattern(
            in: result,
            pattern: #"\[([^\]]+)\]\(([^)\s]+)\)"#,
            template: #"<a href="$2">$1</a>"#
        )
        result = replacePattern(
            in: result,
            pattern: #"\*\*([^*]+)\*\*"#,
            template: "<strong>$1</strong>"
        )
        result = replacePattern(
            in: result,
            pattern: #"__([^_]+)__"#,
            template: "<strong>$1</strong>"
        )
        result = replacePattern(
            in: result,
            pattern: #"\*([^*]+)\*"#,
            template: "<em>$1</em>"
        )
        result = replacePattern(
            in: result,
            pattern: #"_([^_]+)_"#,
            template: "<em>$1</em>"
        )
        result = replacePattern(
            in: result,
            pattern: #"~~([^~]+)~~"#,
            template: "<del>$1</del>"
        )

        return result
    }

    private static func replacePattern(in text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
