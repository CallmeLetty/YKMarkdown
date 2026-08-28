# 34-mermaid-preview-rendering

- Number: 34
- Slug: mermaid-preview-rendering

## Notes

- 内置官方 npm 包 `mermaid@11.17.2` 的 `dist/mermaid.min.js`，同时保留 MIT 许可证。
- `mermaid` 围栏使用 Base64 保存 UTF-8 源码，预览渲染为 SVG；普通代码围栏保持原行为。
- Mermaid 使用 `strict` 安全级别，支持系统深浅色重绘；单图解析失败时显示源码和错误信息。
- Turndown 专用规则把图块恢复成原始围栏。真实 QA 中从预览粘贴修改标题后，两段 Mermaid 源码仍完整。
- `node --check` 和 `git diff --check` 通过。真实 QA 验证了正常渲染、错误回退、源码实时更新和预览回写。
- 严格构建两次都输出 `BUILD SUCCEEDED`，资源也成功复制进 App；Xcode beta 均在结果包完成后自身 `Trace/BPT trap`，导致包装脚本返回 133。
- 按本机偏好未运行测试或 SwiftLint。
