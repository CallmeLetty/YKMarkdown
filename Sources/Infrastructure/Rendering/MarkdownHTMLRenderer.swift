import Foundation

enum MarkdownHTMLRenderer {
    static func bodyHTML(from markdown: String) -> String {
        let rendered = renderBody(markdown)
        if rendered.html.isEmpty {
            return "<p><br></p>"
        }
        return rendered.html
    }

    static func sourceOffsets(from markdown: String) -> [Int] {
        renderBody(markdown).sourceOffsets
    }

    static func editableDocument(
        bodyHTML: String,
        turndownScript: String,
        accentColorCSS: String = "#0969DA",
        fontSize: Double = 14
    ) -> String {
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
              --link: \(accentColorCSS);
              --bg: transparent;
              --focus: color-mix(in srgb, \(accentColorCSS) 20%, transparent);
              --font-size: \(fontSize)px;
            }
            @media (prefers-color-scheme: dark) {
              :root {
                --text: #e6edf3;
                --muted: #8b949e;
                --border: #30363d;
                --code-bg: #161b22;
                --quote-border: #3d444d;
              }
            }
            html, body {
              margin: 0;
              padding: 0;
              background: var(--bg);
              color: var(--text);
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
              font-size: var(--font-size);
              line-height: 1.65;
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
              scroll-margin-top: 20px;
            }
            h1 { font-size: 1.9em; }
            h2 { font-size: 1.5em; }
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
            const headingSelector = 'h1, h2, h3, h4, h5, h6';
            const activeHeadingThreshold = 36;
            let activeHeadingTimer = null;
            let activeHeadingID = null;
            const sourceAnchorSelector = '[data-source-offset]';
            let scrollAnchorFrame = null;
            let lastReportedSourceOffset = null;
            let suppressScrollAnchorReport = false;

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

            function ensureHeadingIDs() {
              content.querySelectorAll(headingSelector).forEach(function (heading, index) {
                heading.id = 'yk-heading-' + index;
              });
            }

            function reportActiveHeading() {
              const headings = Array.from(content.querySelectorAll(headingSelector));
              let active = headings.length ? headings[0] : null;
              headings.forEach(function (heading) {
                if (heading.getBoundingClientRect().top <= activeHeadingThreshold) {
                  active = heading;
                }
              });
              const id = active ? active.id : null;
              if (activeHeadingID !== id) {
                activeHeadingID = id;
                post({ type: 'activeHeadingChanged', id: id });
              }
            }

            function scheduleActiveHeadingReport() {
              clearTimeout(activeHeadingTimer);
              activeHeadingTimer = setTimeout(reportActiveHeading, 50);
            }

            function sourceAnchors() {
              return Array.from(content.querySelectorAll(sourceAnchorSelector)).filter(function (element) {
                return Number.isFinite(Number(element.dataset.sourceOffset));
              });
            }

            function reportScrollAnchor() {
              if (suppressScrollAnchorReport) return;
              const anchors = sourceAnchors();
              if (!anchors.length) return;
              const viewportTop = 20;
              let active = anchors[0];
              anchors.forEach(function (anchor) {
                if (anchor.getBoundingClientRect().top <= viewportTop) {
                  active = anchor;
                }
              });
              const sourceOffset = Number(active.dataset.sourceOffset);
              if (sourceOffset === lastReportedSourceOffset) return;
              lastReportedSourceOffset = sourceOffset;
              post({ type: 'scrollAnchorChanged', sourceOffset: sourceOffset });
            }

            function scheduleScrollAnchorReport() {
              if (scrollAnchorFrame !== null) return;
              scrollAnchorFrame = requestAnimationFrame(function () {
                scrollAnchorFrame = null;
                reportScrollAnchor();
              });
            }

            content.addEventListener('input', function () {
              ensureHeadingIDs();
              scheduleEmit();
              scheduleActiveHeadingReport();
            });
            content.addEventListener('keyup', scheduleEmit);
            content.addEventListener('cut', scheduleEmit);
            window.addEventListener('scroll', function () {
              scheduleActiveHeadingReport();
              scheduleScrollAnchorReport();
            }, { passive: true });

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
              ensureHeadingIDs();
              suppressEmit = false;
              requestAnimationFrame(reportActiveHeading);
            };

            window.setSourceOffsets = function (offsets) {
              const children = Array.from(content.children);
              children.forEach(function (element, index) {
                const sourceOffset = Number(offsets[index]);
                if (Number.isFinite(sourceOffset)) {
                  element.dataset.sourceOffset = String(sourceOffset);
                } else {
                  element.removeAttribute('data-source-offset');
                }
              });
            };

            window.scrollToSourceOffset = function (requestedOffset) {
              const sourceOffset = Number(requestedOffset);
              if (!Number.isFinite(sourceOffset)) return;
              const anchors = sourceAnchors();
              if (!anchors.length) return;
              let target = anchors[0];
              anchors.forEach(function (anchor) {
                if (Number(anchor.dataset.sourceOffset) <= sourceOffset) {
                  target = anchor;
                }
              });
              const targetOffset = Number(target.dataset.sourceOffset);
              const targetTop = target.getBoundingClientRect().top + window.scrollY - 20;
              suppressScrollAnchorReport = true;
              lastReportedSourceOffset = targetOffset;
              window.scrollTo({ top: Math.max(0, targetTop), behavior: 'auto' });
              requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                  suppressScrollAnchorReport = false;
                });
              });
            };

            window.setAccentColor = function (color) {
              document.documentElement.style.setProperty('--link', color);
              document.documentElement.style.setProperty(
                '--focus',
                'color-mix(in srgb, ' + color + ' 20%, transparent)'
              );
            };

            window.setFontSize = function (fontSize) {
              const value = Number(fontSize);
              if (!Number.isFinite(value)) return;
              document.documentElement.style.setProperty('--font-size', value + 'px');
            };

            window.scrollToHeading = function (id) {
              ensureHeadingIDs();
              const heading = document.getElementById(id);
              if (!heading) return;
              suppressScrollAnchorReport = true;
              const sourceOffset = Number(heading.dataset.sourceOffset);
              if (Number.isFinite(sourceOffset)) {
                lastReportedSourceOffset = sourceOffset;
              }
              heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
              activeHeadingID = id;
              post({ type: 'activeHeadingChanged', id: id });
              setTimeout(function () {
                suppressScrollAnchorReport = false;
                reportActiveHeading();
              }, 350);
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

            ensureHeadingIDs();
            requestAnimationFrame(reportActiveHeading);
          })();
          </script>
        </body>
        </html>
        """
    }

    private static func renderBody(_ markdown: String) -> RenderedBody {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let source = markdown as NSString
        var lineOffsets = [0]
        if source.length > 0 {
            for location in 0..<source.length where source.character(at: location) == 10 {
                lineOffsets.append(location + 1)
            }
        }
        var html: [String] = []
        var sourceOffsets: [Int] = []
        var index = 0
        var inCodeBlock = false
        var codeBlockOffset = 0
        var codeLanguage = ""
        var codeLines: [String] = []
        var paragraph: [String] = []
        var paragraphOffset = 0
        var listKind: ListKind?
        var listItems: [String] = []
        var listOffset = 0
        var headingIndex = 0

        func appendBlock(_ value: String, sourceOffset: Int) {
            html.append(value)
            sourceOffsets.append(sourceOffset)
        }

        func sourceAttribute(_ sourceOffset: Int) -> String {
            " data-source-offset=\"\(sourceOffset)\""
        }

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.joined(separator: " ")
            appendBlock(
                "<p\(sourceAttribute(paragraphOffset))>\(renderInline(text))</p>",
                sourceOffset: paragraphOffset
            )
            paragraph.removeAll(keepingCapacity: true)
        }

        func flushList() {
            guard let kind = listKind, !listItems.isEmpty else { return }
            let tag = kind == .unordered ? "ul" : "ol"
            let items = listItems.map { "<li>\(renderInline($0))</li>" }.joined()
            appendBlock(
                "<\(tag)\(sourceAttribute(listOffset))>\(items)</\(tag)>",
                sourceOffset: listOffset
            )
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
                    appendBlock(
                        "<pre\(sourceAttribute(codeBlockOffset))><code\(languageClass)>\(code)</code></pre>",
                        sourceOffset: codeBlockOffset
                    )
                    codeLines.removeAll(keepingCapacity: true)
                    codeLanguage = ""
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                    codeBlockOffset = lineOffsets[index]
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

            if trimmed == "---" {
                flushParagraph()
                flushList()
                appendBlock("<hr\(sourceAttribute(lineOffsets[index])) />", sourceOffset: lineOffsets[index])
                index += 1
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                flushList()
                let id = "yk-heading-\(headingIndex)"
                appendBlock(
                    "<h\(heading.level) id=\"\(id)\"\(sourceAttribute(lineOffsets[index]))>\(renderInline(heading.text))</h\(heading.level)>",
                    sourceOffset: lineOffsets[index]
                )
                headingIndex += 1
                index += 1
                continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                flushParagraph()
                flushList()
                let quoteOffset = lineOffsets[index]
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
                appendBlock(
                    "<blockquote\(sourceAttribute(quoteOffset))><p>\(quoteBody)</p></blockquote>",
                    sourceOffset: quoteOffset
                )
                continue
            }

            if let unordered = matchUnorderedListItem(trimmed) {
                flushParagraph()
                if listKind != .unordered {
                    flushList()
                    listKind = .unordered
                    listOffset = lineOffsets[index]
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
                    listOffset = lineOffsets[index]
                }
                listItems.append(ordered)
                index += 1
                continue
            }

            if looksLikeTableHeader(trimmed), index + 1 < lines.count, isTableSeparator(lines[index + 1]) {
                flushParagraph()
                flushList()
                let tableOffset = lineOffsets[index]
                let headerCells = splitTableRow(trimmed)
                index += 2
                var rows: [[String]] = []
                while index < lines.count {
                    let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if rowLine.isEmpty || !rowLine.contains("|") { break }
                    rows.append(splitTableRow(rowLine))
                    index += 1
                }
                var table = "<table\(sourceAttribute(tableOffset))><thead><tr>"
                table += headerCells.map { "<th>\(renderInline($0))</th>" }.joined()
                table += "</tr></thead><tbody>"
                for row in rows {
                    table += "<tr>"
                    table += row.map { "<td>\(renderInline($0))</td>" }.joined()
                    table += "</tr>"
                }
                table += "</tbody></table>"
                appendBlock(table, sourceOffset: tableOffset)
                continue
            }

            flushList()
            if paragraph.isEmpty {
                paragraphOffset = lineOffsets[index]
            }
            paragraph.append(trimmed)
            index += 1
        }

        if inCodeBlock {
            let code = escapeHTML(codeLines.joined(separator: "\n"))
            appendBlock(
                "<pre\(sourceAttribute(codeBlockOffset))><code>\(code)</code></pre>",
                sourceOffset: codeBlockOffset
            )
        }
        flushParagraph()
        flushList()

        return RenderedBody(html: html.joined(separator: "\n"), sourceOffsets: sourceOffsets)
    }

    private struct RenderedBody {
        let html: String
        let sourceOffsets: [Int]
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
