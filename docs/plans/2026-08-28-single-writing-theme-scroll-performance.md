# Single Writing Theme and Scroll Performance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use @Code to implement this plan task-by-task.

**Goal:** 仅保留温润写作排版和自定义背景色，并消除滚动同步期间重复应用昂贵外观属性导致的卡顿。

**Architecture:** 将排版模型收敛为固定的温润写作令牌，不再通过主题字符串分发样式。编辑器 Coordinator 缓存已经应用的外观签名，只有字体大小或颜色真正变化时才重设 `NSTextView` 属性；预览背景仍实时同步，但只有明暗模式变化才重绘 Mermaid。

**Tech Stack:** SwiftUI、AppKit `NSTextView`、WebKit `WKWebView`、HTML/CSS/JavaScript。

---

### Task 1: 收敛固定排版模型

**Files:**
- Modify: `Sources/Infrastructure/DesignSystem/AppTypographyTheme.swift`
- Modify: `Sources/Views/SettingsView.swift`
- Modify: `Sources/Views/EditorView.swift`

**Steps:**
1. 删除主题枚举、持久化主题键和主题选择器。
2. 将温润写作的背景、字体、行距与留白作为固定排版令牌。
3. 保留自定义背景开关与颜色选择器。

### Task 2: 消除编辑器滚动热路径中的重复外观写入

**Files:**
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

**Steps:**
1. 为字体大小、背景色和前景色建立可比较的外观签名。
2. 在 `makeNSView` 首次应用并缓存外观。
3. 在 `updateNSView` 中仅当签名变化时重设字体、段落样式和输入属性。

### Task 3: 简化预览外观更新

**Files:**
- Modify: `Sources/Views/MarkdownPreviewView.swift`
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`

**Steps:**
1. 移除主题参数和多主题 CSS 分支，只保留温润写作样式。
2. 将 `setAppearance` 收敛为背景、前景和明暗模式更新。
3. 仅在明暗模式变化时重新渲染 Mermaid。

### Task 4: 验证

**Files:**
- Modify: `Tests/AppTests.swift`

**Steps:**
1. 更新静态渲染断言，确保不再包含另外两套主题。
2. 编译应用和测试目标，不运行测试或 SwiftLint。
3. 用独立 QA 应用打开长 Markdown，验证设置界面和连续滚动响应。
