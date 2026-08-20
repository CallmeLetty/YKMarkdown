# 26-document-search-shortcuts

- Number: 26
- Slug: document-search-shortcuts

## Notes

- 新增 `DocumentSearch` 搜索模型和已打开文档注册表；`Cmd+F` 搜当前源码，`Cmd+Shift+F` 搜当前进程打开的 Markdown 文档。
- `MarkdownSourceEditor` 通过 `NSTextView` 临时背景色高亮全部命中，并在上一条/下一条或全局结果点击时滚动到对应 `NSRange`。
- 已执行 `git diff --check`；按项目规则未运行 SwiftLint、`xcodebuild` 或测试构建。
