# Markdown 统一编辑会话设计

## 背景

YKMarkdown 同时提供原生源码编辑器与 Web 预览编辑器。当前 `document.text`、`NSTextView.string` 和预览 DOM 都会直接保存并回写正文，光标、选区、滚动和正文变化又会共同触发 SwiftUI 更新。更新只有字符串相等判断，没有版本和来源语义，因此一次与正文无关的界面刷新也可能拿旧字符串覆盖输入控件中的临时状态。

中文、日文等输入法的组合文本是输入控件内部的临时事务，并不是已经提交的文档正文。组合期间覆盖 `NSTextView.string` 会取消输入法事务；组合选区被当作跨区域位置事件，又会放大无关刷新。这是当前“光标跳行、字符乱飞、最终没有文字”的根因。

## 目标

- 文档正文只有一个写入口和一个已提交快照。
- 源码、预览、刷新、合并和插图使用同一套 mutation 协议。
- 每个正文快照具有单调递增 revision 和明确 origin。
- 输入法组合文本只属于当前编辑表面；候选确认后才提交正文。
- 内容同步与光标、选区、滚动同步完全分离。
- 任何过期修改都显式拒绝，不允许靠全文覆盖“自动解决”。
- 保持 FileDocument 的保存、撤销和现有预览范围回写能力。

## 非目标

- 不引入多人协同编辑、OT 或 CRDT。
- 不改变 Markdown 解析、HTML 渲染或三方合并算法。
- 不让预览展示尚未确认的拼音或其他组合文本。
- 不在本次改造中实现实时磁盘监听。

## 状态所有权

### 已提交正文

`DocumentEditingState` 持有唯一的 `DocumentSnapshot`：

- `text`：已提交 Markdown。
- `revision`：每次实际正文变化后递增。
- `origin`：产生该 revision 的入口。

`MarkdownDocument.text` 是 FileDocument 的持久化镜像，不再是各编辑控件互相同步时直接读写的总线。`EditorView` 在 mutation 被接受后把快照文本写入 FileDocument；若系统确实提供了新的文档文本，则以 `.documentSystem` 来源导入统一会话。

### 表面临时状态

以下状态归各自表面所有，不进入正文快照：

- 输入法 marked text / browser composition。
- 原生选区、Web Selection 和键盘焦点。
- 滚动位置及程序化滚动抑制状态。
- 尚未到达提交边界的预览输入批次。

这些状态只能产生交互事件，不能触发旧正文反向覆盖编辑表面。

## 数据流

```text
NSTextView commit ───────┐
WKWebView range edit ────┼──▶ DocumentMutation ──▶ DocumentEditingState
reload / merge / image ──┘          │                       │
                                    │ accept/reject          ▼
                                    └────────────── DocumentSnapshot
                                                             │
                                       ┌─────────────────────┴─────────────────────┐
                                       ▼                                           ▼
                              MarkdownSourceEditor                         MarkdownPreviewView
                              按 revision 接收                              按 revision 接收

selection / scroll ──▶ DocumentPositionRequest（独立通道，不修改正文 revision）
```

## Mutation 协议

所有正文修改都提交 `DocumentMutation`：

- `baseRevision`：修改所基于的快照。
- `origin`：`.source`、`.preview`、`.reload`、`.merge`、`.imageInsertion` 或 `.documentSystem`。
- `change`：旧正文到新正文之间的单个连续 UTF-16 替换范围。

源码编辑器可以在一次输入、粘贴或撤销后，将上次确认文本与当前 `NSTextView.string` 计算为一个连续替换。预览仍先使用现有块范围规则生成 Markdown，再转成同一种文本替换。刷新、合并和插图也先生成替换，不再直接赋值。

会话只接受 `baseRevision == current.revision` 且替换范围仍匹配原文本的 mutation。成功后生成下一 revision；内容没有变化时只确认，不增加 revision；过期或范围不匹配时返回显式拒绝结果。

## 输入法事务

### 原生源码编辑器

1. `NSTextView` 开始 marked text 后继续由 AppKit 独占其文本和选区。
2. `NSViewRepresentable.updateNSView` 可以更新外观，但不能替换正文或执行跨表面选区定位。
3. marked text 期间不提交正文，也不发送临时选区位置。
4. 候选确认、`hasMarkedText == false` 后，将上次确认快照到当前字符串的差异作为一次 mutation 提交。
5. 收到自己提交形成的快照时只确认 revision，不重新设置 `textView.string`。

### 可编辑预览

1. JavaScript 使用 `compositionstart` / `compositionend` 定义事务边界。
2. composition 期间记录受影响的源码块，但不发送 Markdown patch 或临时选择位置。
3. compositionend 后发送一次范围 patch。
4. 预览 Coordinator 将 patch 转换为 mutation；自身 revision 的回声只确认，不调用 `setBodyHTML`。
5. 来自其他来源的新快照在 composition 期间排队，事务结束后再处理。

## 位置同步

位置同步保留独立的 `DocumentPositionRequest`，遵守以下规则：

- 只传递已提交正文中的 UTF-16 offset。
- marked text / composition 内部选区不向外传播。
- 请求携带 token 和 origin，目标表面消费后不得回送同一请求。
- 位置事件可以触发视图更新，但正文适配器依据 revision 判断是否需要处理内容，不能再使用字符串不等作为覆盖依据。

## 失败模式

| 情况 | 处理 |
| --- | --- |
| SwiftUI 因滚动或设置变化刷新 | revision 未变化，只更新外观或位置，不触碰正文 |
| 输入法组合期间刷新 | 保留表面临时文本，不提交、不覆盖 |
| 表面收到自己修改的快照 | 确认 revision，不重设原生字符串或 DOM |
| mutation 的 base revision 过期 | 明确拒绝，保留当前表面内容，等待协调；不得静默覆盖 |
| 外部全文替换发生在组合期间 | 排队至组合结束，再走统一冲突或刷新策略 |
| 预览 patch 范围已失效 | mutation 拒绝并用最新快照重建预览，不改写其他正文 |

## 验证标准

- 中文输入法连续输入、候选切换和回车确认时，光标稳定且文字只在确认后进入预览。
- 英文输入、粘贴、删除、撤销和重做仍实时提交。
- 修改源码不会被预览回声重写，修改预览不会触发 DOM 全量重建。
- 光标移动和滚动同步不会产生新的正文 revision。
- 刷新、合并、插图均能在 mutation 日志中看到明确 origin。
- Unicode、CRLF、空文档和末尾无换行文本的替换范围正确。
