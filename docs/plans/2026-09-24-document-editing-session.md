# Document Editing Session Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 建立带 revision/origin 的统一 Markdown 编辑状态机，使源码和预览的输入法事务不会被 SwiftUI 回写破坏。

**Architecture:** `DocumentEditingState` 是已提交正文的唯一状态机，所有正文入口提交 `DocumentMutation`。源码和预览适配器各自持有组合输入、选区与滚动等临时状态，并根据 snapshot revision 判断确认、更新或延迟，内容同步与位置同步互不驱动。

**Tech Stack:** Swift 6、SwiftUI、AppKit `NSTextView`、WebKit `WKWebView`、Swift Testing。

---

### Task 1: 建立纯文本 mutation 状态机

**Files:**
- Create: `Sources/Features/Editor/DocumentEditingSession.swift`
- Create: `Tests/DocumentEditingSessionTests.swift`

**Steps:**

1. 定义 `DocumentEditOrigin`、`DocumentSnapshot`、`DocumentTextChange`、`DocumentMutation` 和 `DocumentMutationResult`。
2. 使用 Character 边界计算旧文本到新文本的单个连续 UTF-16 替换，避免拆分 emoji 或组合字符。
3. 实现 `DocumentEditingState.apply`：校验 base revision、原文本和范围，成功后递增 revision，过期时显式拒绝。
4. 增加 Swift Testing 用例，覆盖普通插入、删除、Unicode、CRLF、无变化和过期 mutation。
5. 仅做测试 target 编译检查；按用户偏好不主动运行测试。

### Task 2: 将 EditorView 收敛为统一正文入口

**Files:**
- Modify: `Sources/Views/EditorView.swift`

**Steps:**

1. 用文档初始文本创建 `DocumentEditingState`。
2. 新增唯一 `applyDocumentMutation` 方法：接受 mutation 后同步 `MarkdownDocument.text`。
3. 将源码、预览、刷新、冲突完成和插图入口改为提交 mutation。
4. 将渲染、搜索、上传、目录和偏移计算统一读取 snapshot text。
5. 对系统提供的非会话文本变化使用 `.documentSystem` 导入，不允许形成回写循环。

### Task 3: 把 MarkdownSourceEditor 改成 revision 驱动适配器

**Files:**
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

**Steps:**

1. 将 `@Binding text` 替换为 `DocumentSnapshot` 与 mutation 回调。
2. Coordinator 保存最后确认快照，而不是在每次更新时比较并覆盖全文。
3. revision 未变化时只处理外观和位置请求，不触碰 `NSTextView.string`。
4. marked text 期间不提交正文、不应用外部正文、不上报临时选区。
5. composition 结束后计算一次文本替换 mutation；自己的快照回声只确认 revision。

### Task 4: 把 MarkdownPreviewView 接入相同协议

**Files:**
- Modify: `Sources/Views/MarkdownPreviewView.swift`
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`

**Steps:**

1. 预览接收 `DocumentSnapshot`，并将现有范围 patch 转换为 `DocumentMutation`。
2. 用 revision/origin 确认本地预览编辑，替换 `isUpdatingFromPreview` 时序布尔值。
3. JavaScript 增加 `compositionstart` / `compositionend`，组合期间只记录范围，结束后发送一次 patch。
4. 组合期间停止发送选择位置；外部快照延迟到组合结束后应用。
5. 保持现有表格分隔线、空行和块范围保真逻辑。

### Task 5: 验证数据流和界面行为

**Files:**
- Modify: `tasks/details/62-document-editing-session.md`

**Steps:**

1. 编译应用与测试 target，确保 Swift 6 严格并发和 warnings-as-errors 通过。
2. 手动验证英文输入、删除、粘贴、撤销和重做。
3. 手动验证中文输入法连续拼音、候选切换、回车确认、换行和中英文切换。
4. 验证源码与预览双向编辑、搜索定位、滚动同步、刷新和插图入口。
5. 记录实际验证结果并通过 `scripts/task.sh done` 完成任务。
