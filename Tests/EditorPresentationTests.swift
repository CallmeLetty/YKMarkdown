import Foundation
import Testing
@testable import YKMarkdown

@Suite("编辑器展示与属性保留")
struct EditorPresentationTests {
    @Test("属性折叠后正文锚点仍使用原始 UTF-16 偏移", arguments: ["\n", "\r\n"])
    func metadataDoesNotShiftBodyAnchors(newline: String) throws {
        let prefix = ["---", "title: 熊猫🐼", "custom: 保留未知字段", "---", ""].joined(separator: newline)
        let markdown = prefix + "# 标题\(newline)\(newline)正文"
        let offset = (prefix as NSString).length
        #expect(BlogFrontmatter.sourceRange(in: markdown) == NSRange(location: 0, length: offset))
        #expect(MarkdownHTMLRenderer.sourceOffsets(from: markdown).first == offset)
        let patched = try #require(MarkdownPreviewEditPatch.replacingRanges(in: markdown, with: [
            .init(startSourceOffset: offset, endSourceOffset: offset, markdown: "# 新标题")
        ]))
        #expect(patched.hasPrefix(prefix))
        #expect(patched.contains("# 新标题"))
        #expect(patched.hasSuffix("正文"))
    }

    @Test("属性块不能通过正文事务改写或删除")
    func rejectsMetadataReplacement() {
        let markdown = "---\ntitle: 原始标题\n---\n# 正文\n"
        #expect(MarkdownPreviewEditPatch.replacingRanges(in: markdown, with: [
            .init(startSourceOffset: 0, endSourceOffset: 0, markdown: "删除属性")
        ]) == nil)
    }

    @Test("只有属性的文档可以开始输入正文", arguments: ["", "\n", "\r\n"])
    func appendsBodyAfterMetadata(ending: String) throws {
        let markdown = "---\ntitle: 属性\n---" + ending
        let offset = (markdown as NSString).length
        #expect(MarkdownHTMLRenderer.sourceOffsets(from: markdown) == [offset])
        let patched = try #require(MarkdownPreviewEditPatch.replacingRanges(in: markdown, with: [
            .init(startSourceOffset: offset, endSourceOffset: offset, markdown: "新正文")
        ]))
        #expect(patched == markdown + (ending.isEmpty ? "\n" : "") + "新正文\n")
    }

    @Test("分隔线和未闭合属性不被误判", arguments: [
        "---\n---\n---\n", "---\n普通正文\n---\n", "---\ntitle: 未闭合\n正文", "正文\n---\ntitle: 非文首\n---\n"
    ])
    func leavesOrdinaryMarkdownAlone(markdown: String) {
        #expect(BlogFrontmatter.sourceRange(in: markdown) == nil)
        #expect(!MarkdownHTMLRenderer.bodyHTML(from: markdown).contains("document-properties"))
    }

    @Test("属性内容按文字转义，不会变成可执行 HTML")
    func escapesMetadata() {
        let html = MarkdownHTMLRenderer.bodyHTML(from: "---\ntitle: <script>alert(1)</script>\n---\n# 正文")
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>"))
    }

    @Test("源码着色范围兼容中文、emoji 与 CRLF，围栏内标题不着色")
    func syntaxRangesRemainValid() {
        let markdown = "---\r\ntitle: 熊猫🐼\r\n---\r\n# 正文\r\n```\r\n# 代码\r\n```\r\n[链接](https://example.com)"
        let source = markdown as NSString
        let tokens = MarkdownSyntaxHighlighter.tokens(in: markdown)
        #expect(tokens.allSatisfy { $0.range.location >= 0 && NSMaxRange($0.range) <= source.length })
        let headings = tokens.filter { $0.role == .heading }.map { source.substring(with: $0.range) }
        #expect(headings == ["# 正文\r\n"])
        #expect(tokens.contains { $0.role == .link && source.substring(with: $0.range) == "https://example.com" })
    }
}
