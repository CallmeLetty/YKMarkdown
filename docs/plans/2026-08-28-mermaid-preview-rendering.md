# Mermaid Preview Rendering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 YKMarkdown 的可编辑预览中离线渲染 Mermaid 围栏代码块，并无损保留原始 Markdown 源码。

**Architecture:** 将固定版本 Mermaid 浏览器包作为应用资源注入 WKWebView。Swift 渲染器生成携带 Base64 源码的专用图块，页面脚本负责渲染、错误回退和主题切换，Turndown 专用规则负责把图块还原成围栏源码。

**Tech Stack:** Swift 6、SwiftUI、WebKit、JavaScript、Mermaid 11.17.2、Turndown

---

### Task 1: 固定 Mermaid 资源

**Files:**
- Create: `Sources/Infrastructure/Resources/mermaid.min.js`
- Create: `Sources/Infrastructure/Resources/Mermaid-LICENSE.txt`
- Create: `Sources/Infrastructure/Rendering/MermaidScript.swift`

1. 从官方 npm 包提取 Mermaid 11.17.2 浏览器 bundle 和 MIT 许可证。
2. 新增资源加载器；资源不存在时返回空脚本，让页面使用可见错误回退。
3. 严格编译确认同步文件夹把 JavaScript 复制进应用资源。

### Task 2: 输出可恢复的 Mermaid 图块

**Files:**
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`
- Modify: `Tests/AppTests.swift`

1. 为 `mermaid` 围栏输出顶层 `.mermaid-diagram`，并保存 Base64 编码的原始源码。
2. 保持普通语言代码块原有 HTML 不变。
3. 增加渲染器覆盖，校验 Unicode 源码可无损恢复。

### Task 3: 渲染、回退和回写保护

**Files:**
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`
- Modify: `Sources/Views/MarkdownPreviewView.swift`

1. 在 WKWebView 文档开始阶段注入 Mermaid 脚本。
2. 初始化 Mermaid `strict` 配置，页面载入和正文更新后逐块渲染。
3. 语法错误时显示源码和错误提示；系统主题变化时重新渲染。
4. 新增 Turndown 规则，把图块恢复为原 `mermaid` 围栏。

### Task 4: 编译和界面验证

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/34-mermaid-preview-rendering.md`

1. 运行 `git diff --check`。
2. 运行严格 macOS Debug 编译；按用户偏好不主动运行测试或 SwiftLint。
3. 打开流程图示例，检查 SVG、深浅色和错误回退。
4. 通过 `scripts/task.sh done` 记录结果。
