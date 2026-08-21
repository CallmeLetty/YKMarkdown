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

    func testMarkdownSearchUsesTextViewCompatibleRanges() {
        let markdown = "Alpha\n    second target line\n😀 TARGET"
        let matches = MarkdownSearch.matches(
            in: markdown,
            query: "target",
            documentID: UUID(),
            documentTitle: "Search.md",
            fileURL: nil
        )

        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches.map(\.lineNumber), [2, 3])
        XCTAssertEqual((markdown as NSString).substring(with: matches[0].range), "target")
        XCTAssertEqual((markdown as NSString).substring(with: matches[1].range), "TARGET")
        XCTAssertTrue(matches[0].snippet.contains("second target line"))
    }

    func testThreeWayMergeAppliesNonOverlappingLocalAndRemoteEdits() {
        let result = DocumentThreeWayMerge.merge(
            base: "first\nsecond\nthird\n",
            local: "local first\nsecond\nthird\n",
            remote: "first\nsecond\nremote third\n"
        )

        XCTAssertTrue(result.conflicts.isEmpty)
        XCTAssertEqual(result.resolvedText, "local first\nsecond\nremote third\n")
    }

    func testThreeWayMergeCreatesConflictForOverlappingEdits() {
        let result = DocumentThreeWayMerge.merge(
            base: "VStack(spacing: 5) {\n",
            local: "VStack(spacing: 6) {\n",
            remote: "VStack(spacing: 4) {\n"
        )

        XCTAssertEqual(result.conflicts.count, 1)
        XCTAssertEqual(result.conflicts.first?.localText, "VStack(spacing: 6) {\n")
        XCTAssertEqual(result.conflicts.first?.remoteText, "VStack(spacing: 4) {\n")
        XCTAssertNil(result.resolvedText)
    }

    func testThreeWayMergeDeduplicatesIdenticalEdits() {
        let result = DocumentThreeWayMerge.merge(
            base: "before\n",
            local: "same change\n",
            remote: "same change\n"
        )

        XCTAssertTrue(result.conflicts.isEmpty)
        XCTAssertEqual(result.resolvedText, "same change\n")
    }

    func testThreeWayMergeHandlesDifferentInsertionsAtSameLocationAsConflict() {
        let result = DocumentThreeWayMerge.merge(
            base: "anchor\n",
            local: "local\nanchor\n",
            remote: "remote\nanchor\n"
        )

        XCTAssertEqual(result.conflicts.count, 1)
        XCTAssertEqual(result.conflicts.first?.localText, "local\n")
        XCTAssertEqual(result.conflicts.first?.remoteText, "remote\n")
    }

    func testThreeWayMergePreservesMissingFinalNewline() {
        let result = DocumentThreeWayMerge.merge(
            base: "first\nsecond",
            local: "local first\nsecond",
            remote: "first\nremote second"
        )

        XCTAssertEqual(result.resolvedText, "local first\nremote second")
    }

    func testThreeWayMergeUsesUTF16CompatibleInlineRanges() throws {
        let result = DocumentThreeWayMerge.merge(
            base: "😀 spacing 5\n",
            local: "😀 spacing 6\n",
            remote: "😀 spacing 4\n"
        )
        let conflict = try XCTUnwrap(result.conflicts.first)
        let localRange = try XCTUnwrap(conflict.localChangedRanges.first)
        let remoteRange = try XCTUnwrap(conflict.remoteChangedRanges.first)

        XCTAssertEqual((conflict.localText as NSString).substring(with: localRange), "6")
        XCTAssertEqual((conflict.remoteText as NSString).substring(with: remoteRange), "4")
    }

    func testRefreshDecisionPreservesLocalWhenDiskIsUnchanged() {
        let decision = DocumentThreeWayMerge.refreshDecision(
            base: "base\n",
            local: "local\n",
            remote: "base\n"
        )

        XCTAssertEqual(decision, .preserveLocal)
    }

    func testRefreshDecisionLoadsRemoteWhenLocalIsUnchanged() {
        let decision = DocumentThreeWayMerge.refreshDecision(
            base: "base\n",
            local: "base\n",
            remote: "remote\n"
        )

        XCTAssertEqual(decision, .apply(text: "remote\n", remoteBaseline: "remote\n"))
    }

    @MainActor
    func testMergeSessionResolvesConflictAndBuildsFinalText() throws {
        let result = DocumentThreeWayMerge.merge(
            base: "heading\nvalue 5\ntail\n",
            local: "heading\nvalue 6\ntail\n",
            remote: "heading\nvalue 4\ntail\n"
        )
        let session = DocumentMergeSession(
            result: result,
            originalLocalText: "heading\nvalue 6\ntail\n",
            remoteText: "heading\nvalue 4\ntail\n"
        )
        let conflictID = try XCTUnwrap(result.conflicts.first?.id)

        XCTAssertEqual(session.unresolvedCount, 1)
        XCTAssertNil(session.finalText)

        session.resolve(conflictID, using: .manual("value resolved\n"))

        XCTAssertEqual(session.unresolvedCount, 0)
        XCTAssertEqual(session.finalText, "heading\nvalue resolved\ntail\n")
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
