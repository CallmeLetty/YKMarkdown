# 34-add-show-in-finder-context-menu

- Number: 34
- Slug: add-show-in-finder-context-menu

## Notes

- 在源码编辑区使用 `MarkdownTextView` 子类保留 `NSTextView` 系统右键菜单，并追加 `Show in Finder`。
- 在预览区使用 `PreviewWKWebView.menu(for:)` 追加同名菜单项，动作复用 `NSWorkspace.shared.activateFileViewerSelecting`。
- 预览区 WebKit 菜单由内部子视图生成时，外层 `WKWebView.menu(for:)` 不一定会参与；已补充本地右键/Control-click 事件标记和 `NSMenu.didBeginTrackingNotification` 注入。
