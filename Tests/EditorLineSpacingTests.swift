//
//  EditorLineSpacingTests.swift
//  YKMarkdownTests
//
//  Created by liuyuanyuan on 2026/9/23.
//  Copyright © 2026 小宇宙. All rights reserved.
//

import Testing
@testable import YKMarkdown

@Suite("共享行间距")
struct EditorLineSpacingTests {
    @Test("默认值和调节范围稳定")
    func defaultsAndRange() {
        #expect(EditorLineSpacing.storageKey == "editorLineSpacingScale")
        #expect(EditorLineSpacing.defaultValue == 1.0)
        #expect(EditorLineSpacing.minimum == 0.8)
        #expect(EditorLineSpacing.maximum == 1.3)
        #expect(EditorLineSpacing.step == 0.05)
    }

    @Test("越界设置会被钳制")
    func clampsStoredScale() {
        #expect(EditorLineSpacing.clamped(0.2) == EditorLineSpacing.minimum)
        #expect(EditorLineSpacing.clamped(2.0) == EditorLineSpacing.maximum)
        #expect(EditorLineSpacing.clamped(1.1) == 1.1)
    }

    @Test("源码和预览保留各自基础行高")
    func resolvesSurfaceLineHeights() {
        #expect(EditorLineSpacing.sourceLineHeight(for: 1.0) == 1.55)
        #expect(EditorLineSpacing.previewLineHeight(for: 1.0) == 1.9)
        #expect(abs(EditorLineSpacing.sourceLineHeight(for: 1.2) - 1.86) < 0.0001)
        #expect(abs(EditorLineSpacing.previewLineHeight(for: 1.2) - 2.28) < 0.0001)
    }

    @Test("预览文档包含初始行高与实时更新接口")
    func previewDocumentIncludesLineSpacing() {
        let scale = 1.2
        let lineHeight = EditorLineSpacing.previewLineHeight(for: scale)
        let html = MarkdownHTMLRenderer.editableDocument(
            bodyHTML: "<p>Hi</p>",
            turndownScript: "function TurndownService(){}",
            lineSpacingScale: scale
        )

        #expect(html.contains("--line-height: \(lineHeight);"))
        #expect(html.contains("window.setLineSpacing"))
        #expect(html.contains("Math.max(value, \(EditorLineSpacing.minimum))"))
        #expect(html.contains("\(EditorLineSpacing.previewBaseLineHeight) * clamped"))
    }
}
