# 49-document-conflict-window-crash

- Number: 49
- Slug: document-conflict-window-crash

## Notes

- 在 `docs/问题记录.md` 末尾追加“解决冲突时窗口弱引用崩溃”。
- 记录崩溃栈中的 `weak_register_no_lock`、`objc_storeWeak` 和 `DocumentWindowConfigurator.configure(window:coordinator:)`。
- 说明根因是 SwiftUI/AppKit 桥接视图在窗口 detach/dealloc 期间把 `NSWindow` 写入 weak 存储。
- 记录当前修复策略：用 `ObjectIdentifier` 做窗口身份缓存，并让搜索窗口读取器避免保存 weak observed window。
- 验证：`git diff --check` 通过；文档-only，未运行构建、测试或 SwiftLint。
