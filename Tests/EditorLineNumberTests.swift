//
//  EditorLineNumberTests.swift
//  YKMarkdownTests
//
//  Created by liuyuanyuan on 2026/9/29.
//  Copyright © 2026 小宇宙. All rights reserved.
//

import Testing
@testable import YKMarkdown

@Suite("源码行号")
struct EditorLineNumberTests {
    @Test("行号默认显示且使用稳定存储键")
    func preferenceDefaults() {
        #expect(EditorLineNumbers.storageKey == "editorShowsLineNumbers")
        #expect(EditorLineNumbers.defaultValue)
    }

    @Test("空文档和单行文档从第一行开始")
    func mapsSingleLineDocuments() {
        #expect(MarkdownLineMap.starts(in: "") == [0])
        #expect(MarkdownLineMap.starts(in: "正文") == [0])
    }

    @Test("按 UTF-16 偏移记录换行起点")
    func mapsUTF16LineStarts() {
        #expect(MarkdownLineMap.starts(in: "😀\n正文") == [0, 3])
        #expect(MarkdownLineMap.starts(in: "A\r\nB") == [0, 3])
        #expect(MarkdownLineMap.starts(in: "A\rB") == [0, 2])
    }

    @Test("末尾换行生成新的空行")
    func mapsTrailingEmptyLine() {
        #expect(MarkdownLineMap.starts(in: "A\n") == [0, 2])
        #expect(MarkdownLineMap.starts(in: "A\r\n") == [0, 3])
    }
}
