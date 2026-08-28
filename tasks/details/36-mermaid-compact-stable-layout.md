# 36-mermaid-compact-stable-layout

- Number: 36
- Slug: mermaid-compact-stable-layout

## Notes

- Mermaid 字号使用预览正文的 `--font-size` 与系统字体栈，字号调整时同步重绘。
- 收紧图块容器留白、节点 padding、节点间距和层级间距。
- 对顶层且没有显式连接的具名 `subgraph`，仅在送入 Mermaid 的临时源码中按声明顺序追加隐藏边；保存和回写仍使用原始源码。
- SVG 保持按正文字号计算的自然宽度；窄预览栏使用图块内横向滚动，避免整图缩放导致字体再次偏小。
- Swift 临时渲染 harness 编译通过，生成页面的 JavaScript 通过 `node --check`。
- Chrome 和独立 bundle ID 的真实 YKMarkdown WKWebView 均验证：阶段一在阶段二之前、字体与正文一致、内部间距收紧；窄分栏保持字号并按需横向滚动。
- 严格 Debug 编译两次均输出 `BUILD SUCCEEDED`，Xcode beta 都在结果包完成后自身 `Trace/BPT trap: 5`，因此外层状态仍为 133；按本机偏好未运行测试或 SwiftLint。
