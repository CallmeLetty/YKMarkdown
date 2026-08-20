# 28-extract-document-search-bar-view

- Number: 28
- Slug: extract-document-search-bar-view

## Notes

- 将 `DocumentSearchBar` 从 `EditorView.swift` 抽到 `Sources/Views/DocumentSearchBar.swift`。
- 新增宽版和窄版 `#Preview`，用于检查单行布局和窄宽度换行布局。
- 已执行 `git diff --check`；按项目规则未运行 SwiftLint、`xcodebuild` 或测试构建。
