# 50-refocus-document-search

- Number: 50
- Slug: refocus-document-search

## 说明

- 原因：搜索框仅在搜索栏首次出现时获取焦点，重复打开没有独立的聚焦请求。
- 实现：EditorView 的统一搜索入口每次更新 UUID；DocumentSearchBar 在首次显示和请求变化时聚焦输入框，预览同步传入稳定请求。
- 覆盖入口：Cmd+F、Cmd+Shift+F 及对应菜单命令；搜索词保持不变。
- 验证：静态检查调用点与请求传递；未运行编译、测试或 SwiftLint，实际焦点行为仍需应用内验证。
