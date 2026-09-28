//
//  DocumentEditingSessionTests.swift
//  YKMarkdownTests
//
//  Created by liuyuanyuan on 2026/9/24.
//  Copyright © 2026 小宇宙. All rights reserved.
//

import AppKit
import Foundation
import Testing
@testable import YKMarkdown

@Suite("统一文档编辑会话")
struct DocumentEditingSessionTests {
    @Test("正文修改生成新 revision 和来源")
    func appliesMutation() {
        var state = DocumentEditingState(text: "# 标题\n")
        let mutation = DocumentMutation.replacing(
            snapshot: state.snapshot,
            with: "# 新标题\n",
            origin: .source
        )

        let result = state.apply(mutation)

        #expect(result == .applied(state.snapshot))
        #expect(state.snapshot.text == "# 新标题\n")
        #expect(state.snapshot.revision == 1)
        #expect(state.snapshot.origin == .source)
    }

    @Test("无内容变化不会增加 revision")
    func ignoresUnchangedMutation() {
        var state = DocumentEditingState(text: "正文")
        let mutation = DocumentMutation.replacing(
            snapshot: state.snapshot,
            with: "正文",
            origin: .preview
        )

        #expect(state.apply(mutation) == .unchanged(state.snapshot))
        #expect(state.snapshot.revision == 0)
    }

    @Test("过期修改被明确拒绝")
    func rejectsStaleMutation() {
        var state = DocumentEditingState(text: "A")
        let staleSnapshot = state.snapshot
        _ = state.apply(.replacing(snapshot: state.snapshot, with: "AB", origin: .source))

        let result = state.apply(.replacing(snapshot: staleSnapshot, with: "AC", origin: .preview))

        #expect(result == .rejected(state.snapshot, reason: .staleRevision))
        #expect(state.snapshot.text == "AB")
    }

    @Test("替换范围不会拆分 emoji")
    func preservesCharacterBoundaries() throws {
        let change = DocumentTextChange.between("A😀B", and: "A🦊B")

        #expect(change.range == NSRange(location: 1, length: 2))
        #expect(change.replacedText == "😀")
        #expect(change.replacement == "🦊")
        #expect(try #require(change.applying(to: "A😀B")) == "A🦊B")
    }

    @Test("CRLF 与末尾插入保持原文")
    func preservesCRLF() throws {
        let change = DocumentTextChange.between("A\r\nB", and: "A\r\nBC")

        #expect(change.range == NSRange(location: 4, length: 0))
        #expect(try #require(change.applying(to: "A\r\nB")) == "A\r\nBC")
    }

    @Test("原文本不匹配时拒绝应用范围")
    func rejectsInvalidOriginalText() {
        let change = DocumentTextChange.between("ABC", and: "AXC")

        #expect(change.applying(to: "AYC") == nil)
    }

    @Test("可编辑预览把输入法组合视为一次事务")
    func previewCompositionUsesTransactionBoundary() {
        let html = MarkdownHTMLRenderer.editableDocument(
            bodyHTML: "<p data-source-offset=\"0\">正文</p>",
            turndownScript: "function TurndownService(){}"
        )

        #expect(html.contains("content.addEventListener('compositionstart'"))
        #expect(html.contains("content.addEventListener('compositionend'"))
        #expect(html.contains("if (suppressEmit || isComposing) return;"))
        #expect(html.contains("post({ type: 'compositionStarted' })"))
        #expect(html.contains("post({ type: 'compositionEnded' })"))
    }

    @MainActor
    @Test("源码输入法组合期间延迟外部正文快照")
    func sourceEditorDefersSnapshotWhileMarkedTextExists() {
        let initialSnapshot = DocumentSnapshot(
            text: "正文",
            revision: 0,
            origin: .documentSystem
        )
        let editor = MarkdownSourceEditor(
            snapshot: initialSnapshot,
            documentURL: nil,
            fontSize: 14,
            lineSpacingScale: 1,
            backgroundColor: .textBackgroundColor,
            foregroundColor: .textColor,
            scrollAnchorOffsets: [],
            positionRequest: nil,
            searchQuery: "",
            selectedSearchRange: nil,
            searchNavigationRequest: nil,
            onMutation: { _ in .unchanged(initialSnapshot) },
            onPositionChange: { _ in }
        )
        let coordinator = editor.makeCoordinator()
        let textView = MarkdownTextView()
        textView.string = initialSnapshot.text
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        coordinator.textView = textView
        textView.setMarkedText(
            "zhongwen",
            selectedRange: NSRange(location: 8, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
        let composingText = textView.string

        coordinator.receive(DocumentSnapshot(text: "外部正文", revision: 1, origin: .reload))

        #expect(textView.hasMarkedText())
        #expect(textView.string == composingText)
    }
}
