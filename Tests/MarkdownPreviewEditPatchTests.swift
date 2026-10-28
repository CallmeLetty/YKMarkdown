//
//  MarkdownPreviewEditPatchTests.swift
//  YKMarkdownTests
//
//  Created by liuyuanyuan on 2026/10/27.
//  Copyright © 2026 小宇宙. All rights reserved.
//

import Foundation
import Testing
@testable import YKMarkdown

@Suite("预览编辑范围事务")
struct MarkdownPreviewEditPatchTests {
    @Test("不相交范围原子替换且保留中间源码")
    func replacesDisjointRangesWithoutTouchingMiddleBlock() throws {
        let original = """
        # 第一段

        中间保留 *原始写法*

        ## 最后一段
        """
        let firstOffset = (original as NSString).range(of: "# 第一段").location
        let lastOffset = (original as NSString).range(of: "## 最后一段").location
        let patched = try #require(MarkdownPreviewEditPatch.replacingRanges(
            in: original,
            with: [
                .init(
                    startSourceOffset: firstOffset,
                    endSourceOffset: firstOffset,
                    markdown: "# 新第一段"
                ),
                .init(
                    startSourceOffset: lastOffset,
                    endSourceOffset: lastOffset,
                    markdown: "## 新最后一段"
                )
            ]
        ))

        #expect(patched.contains("# 新第一段"))
        #expect(patched.contains("中间保留 *原始写法*"))
        #expect(patched.contains("## 新最后一段"))
        #expect(!patched.contains("# 第一段\n"))
    }

    @Test("任一范围无效时拒绝整个事务")
    func rejectsTransactionContainingInvalidRange() {
        let original = "# 标题\n\n正文\n"
        let titleOffset = (original as NSString).range(of: "# 标题").location

        let patched = MarkdownPreviewEditPatch.replacingRanges(
            in: original,
            with: [
                .init(
                    startSourceOffset: titleOffset,
                    endSourceOffset: titleOffset,
                    markdown: "# 新标题"
                ),
                .init(
                    startSourceOffset: 999,
                    endSourceOffset: 999,
                    markdown: "无效修改"
                )
            ]
        )

        #expect(patched == nil)
    }

    @Test("重叠范围不会被部分应用")
    func rejectsOverlappingRanges() {
        let original = """
        第一段

        第二段

        第三段
        """
        let firstOffset = (original as NSString).range(of: "第一段").location
        let secondOffset = (original as NSString).range(of: "第二段").location
        let thirdOffset = (original as NSString).range(of: "第三段").location

        let patched = MarkdownPreviewEditPatch.replacingRanges(
            in: original,
            with: [
                .init(
                    startSourceOffset: firstOffset,
                    endSourceOffset: secondOffset,
                    markdown: "前两段"
                ),
                .init(
                    startSourceOffset: secondOffset,
                    endSourceOffset: thirdOffset,
                    markdown: "后两段"
                )
            ]
        )

        #expect(patched == nil)
    }
}
