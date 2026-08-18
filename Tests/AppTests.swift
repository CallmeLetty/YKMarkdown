import XCTest
@testable import YKMarkdown

final class YKMarkdownTests: XCTestCase {
    func testRendererConvertsHeadingAndEmphasis() {
        let html = MarkdownHTMLRenderer.bodyHTML(from: "# Title\n\nHello **world**")
        XCTAssertTrue(html.contains("<h1 id=\"yk-heading-0\" data-source-offset=\"0\">Title</h1>"))
        XCTAssertTrue(html.contains("<strong>world</strong>"))
    }

    func testRendererAddsSemanticSourceOffsetsWithoutScrollPercentages() {
        let markdown = "# Title\n\nParagraph\n\n```swift\nx\n```"
        let html = MarkdownHTMLRenderer.bodyHTML(from: markdown)

        XCTAssertEqual(MarkdownHTMLRenderer.sourceOffsets(from: markdown), [0, 9, 20])
        XCTAssertTrue(html.contains("<p data-source-offset=\"9\">Paragraph</p>"))
        XCTAssertTrue(html.contains("<pre data-source-offset=\"20\">"))
    }

    func testRendererSourceOffsetsMatchUTF16TextStorageWithCRLF() {
        let markdown = "# A\r\n\r\n😀"

        XCTAssertEqual(MarkdownHTMLRenderer.sourceOffsets(from: markdown), [0, 7])
    }

    func testRendererConvertsCodeBlock() {
        let markdown = """
        ```swift
        print("hi")
        ```
        """
        let html = MarkdownHTMLRenderer.bodyHTML(from: markdown)
        XCTAssertTrue(html.contains("<pre data-source-offset=\"0\"><code class=\"language-swift\">"))
        XCTAssertTrue(html.contains("print(&quot;hi&quot;)"))
    }

    func testEditableDocumentIncludesContentEditable() {
        let html = MarkdownHTMLRenderer.editableDocument(
            bodyHTML: "<p>Hi</p>",
            turndownScript: "function TurndownService(){}",
            fontSize: 18
        )
        XCTAssertTrue(html.contains("contenteditable=\"true\""))
        XCTAssertTrue(html.contains("markdownChanged"))
        XCTAssertTrue(html.contains("--font-size: 18.0px"))
        XCTAssertTrue(html.contains("window.setFontSize"))
        XCTAssertTrue(html.contains("window.setSourceOffsets"))
        XCTAssertTrue(html.contains("window.scrollToSourceOffset"))
        XCTAssertFalse(html.contains("scrollPercentage"))
    }

    func testEditableDocumentUsesBlockLevelPreviewEdits() {
        let html = MarkdownHTMLRenderer.editableDocument(
            bodyHTML: "<p data-source-offset=\"0\">Hi</p>",
            turndownScript: "function TurndownService(){}"
        )

        XCTAssertTrue(html.contains("markdownBlockChanged"))
        XCTAssertTrue(html.contains("turndown.addRule('table'"))
        XCTAssertTrue(html.contains("turndown.addRule('heading'"))
    }

    func testPreviewBlockPatchPreservesUneditedMarkdown() {
        let original = """
        # 图片编辑功能技术说明

        本文档说明 YKImageEditor 当前各项图片编辑功能的实现方式、数据流、性能策略和扩展边界。内容对应当前工程代码，不是产品规划文档。

        ## 1. 技术架构

        | 层级 | 主要类型 | 职责 |
        | --- | --- | --- |
        | 对外入口 | `ImageEditorView` | SwiftUI/UIKit 接入 |
        """
        let paragraphOffset = (original as NSString).range(of: "本文档说明").location
        let patched = MarkdownPreviewEditPatch.replacingBlock(
            in: original,
            sourceOffset: paragraphOffset,
            with: "本文档说明YKImageEditor 当前各项图片编辑功能的实现方式、数据流、性能策略和扩展边界。内容对应当前工程代码，不是产品规划文档。"
        )

        XCTAssertTrue(patched.contains("本文档说明YKImageEditor 当前各项图片编辑功能"))
        XCTAssertTrue(patched.contains("## 1. 技术架构"))
        XCTAssertTrue(patched.contains("| 层级 | 主要类型 | 职责 |"))
        XCTAssertFalse(patched.contains("## 1\\. 技术架构"))
    }

    func testWelcomeDocumentIsNonEmptyMarkdown() {
        let document = MarkdownDocument()
        XCTAssertFalse(document.text.isEmpty)
        XCTAssertTrue(document.text.contains("# Welcome"))
    }

    func testDocumentOpeningModeDefaultsToTabs() {
        XCTAssertEqual(DocumentOpeningMode.stored(rawValue: "unknown"), .tabs)
        XCTAssertEqual(DocumentOpeningMode.stored(rawValue: DocumentOpeningMode.windows.rawValue), .windows)
    }

    func testEditorFontSizeAdjustmentsUseOnePointSteps() {
        XCTAssertEqual(EditorFontSize.increased(from: 14), 15)
        XCTAssertEqual(EditorFontSize.decreased(from: 14), 13)
    }

    func testEditorFontSizeAdjustmentsStopAtBounds() {
        XCTAssertEqual(
            EditorFontSize.increased(from: EditorFontSize.maximum),
            EditorFontSize.maximum
        )
        XCTAssertEqual(
            EditorFontSize.decreased(from: EditorFontSize.minimum),
            EditorFontSize.minimum
        )
        XCTAssertEqual(
            EditorFontSize.increased(from: EditorFontSize.minimum - 5),
            EditorFontSize.minimum
        )
        XCTAssertEqual(
            EditorFontSize.decreased(from: EditorFontSize.maximum + 5),
            EditorFontSize.maximum
        )
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

    func testReferencedLocalImagePathsIgnoresRemoteAndFindsLocal() {
        let markdown = """
        ![](https://example.com/a.png)
        ![](assets/local.png)
        ![](data:image/png;base64,xxx)
        ![](assets/local.png)
        """
        XCTAssertEqual(
            GitHubBlogUploader.referencedLocalImagePaths(in: markdown),
            ["assets/local.png"]
        )
    }

    func testReferencedLocalImagePathsIgnoresCodeExamples() {
        let markdown = """
        示例：`![说明](assets/example.png)`

        ```md
        ![demo](assets/in-fence.png)
        ```

        ![](assets/real.png)
        """
        XCTAssertEqual(
            GitHubBlogUploader.referencedLocalImagePaths(in: markdown),
            ["assets/real.png"]
        )
        XCTAssertTrue(
            GitHubBlogUploader.referencedLocalImagePaths(in: MarkdownDocument.welcomeMarkdown).isEmpty
        )
    }
}
