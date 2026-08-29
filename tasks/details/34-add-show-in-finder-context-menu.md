# 34-add-show-in-finder-context-menu

- Number: 34
- Slug: add-show-in-finder-context-menu

## Notes

- 在源码编辑区使用 `MarkdownTextView` 子类保留 `NSTextView` 系统右键菜单，并追加 `Show in Finder`。
- 在预览区使用 `PreviewWKWebView.menu(for:)` 追加同名菜单项，动作复用 `NSWorkspace.shared.activateFileViewerSelecting`。
