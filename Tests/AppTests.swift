import XCTest
@testable import YKMarkdown

final class YKMarkdownTests: XCTestCase {
    func testRendererConvertsHeadingAndEmphasis() {
        let html = MarkdownHTMLRenderer.bodyHTML(from: "# Title\n\nHello **world**")
        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<strong>world</strong>"))
    }

    func testRendererConvertsCodeBlock() {
        let markdown = """
        ```swift
        print("hi")
        ```
        """
        let html = MarkdownHTMLRenderer.bodyHTML(from: markdown)
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">"))
        XCTAssertTrue(html.contains("print(&quot;hi&quot;)"))
    }

    func testEditableDocumentIncludesContentEditable() {
        let html = MarkdownHTMLRenderer.editableDocument(
            bodyHTML: "<p>Hi</p>",
            turndownScript: "function TurndownService(){}"
        )
        XCTAssertTrue(html.contains("contenteditable=\"true\""))
        XCTAssertTrue(html.contains("markdownChanged"))
    }

    func testWelcomeDocumentIsNonEmptyMarkdown() {
        let document = MarkdownDocument()
        XCTAssertFalse(document.text.isEmpty)
        XCTAssertTrue(document.text.contains("# Welcome"))
    }

    func testFrontmatterRoundTrip() {
        let meta = BlogFrontmatter(
            title: "你好",
            date: "2026-07-23",
            tags: ["随笔", "写作"],
            excerpt: "摘要"
        )
        let rendered = meta.render(body: "正文\n")
        let parsed = BlogFrontmatter.parse(from: rendered)
        XCTAssertEqual(parsed.meta?.title, "你好")
        XCTAssertEqual(parsed.meta?.tags, ["随笔", "写作"])
        XCTAssertTrue(parsed.body.contains("正文"))
    }

    func testSlugNormalization() {
        XCTAssertEqual(BlogSlug.make(from: "Hello World"), "hello-world")
        XCTAssertEqual(BlogSlug.make(from: "a--b"), "a-b")
    }
}
