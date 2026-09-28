# ADR-0001：使用带 revision 的统一文档编辑会话

## Status

Accepted

## Context

源码 `NSTextView`、预览 DOM 和 `MarkdownDocument.text` 当前通过全文值与布尔抑制标记互相同步。该方式无法区分用户输入、输入法组合文本、视图刷新回声和外部全文替换。任何状态变化都可能让 SwiftUI 重新调用 representable 更新，并用旧值破坏正在进行的输入事务。

应用需要同时支持两个可编辑表面、FileDocument 持久化、范围预览回写、滚动同步和外部三方合并，但不需要多人并发编辑。

## Decision

引入 `DocumentEditingState` 作为已提交正文的唯一状态机。正文使用包含 `text`、`revision`、`origin` 的 `DocumentSnapshot` 表达；所有入口提交带 `baseRevision` 的 `DocumentMutation`。编辑表面保留输入法、选区和滚动等临时状态，并按 revision 接收快照。内容通道与位置通道分离。

输入法组合期间不提交正文。候选确认后，表面把上次确认正文与当前文本之间的连续替换作为一次 mutation 提交。

## Consequences

### Positive

- 视图刷新不再具有覆盖原生输入状态的副作用。
- 所有正文入口共享一致的版本、来源与过期检查。
- 输入法、预览回声和外部替换拥有明确事务语义。
- 纯状态机和文本替换可以独立验证。

### Negative

- 编辑器适配层需要记录已确认快照，而不只是一个字符串。
- 现有直接写 `document.text` 的入口必须全部迁移。
- 过期 mutation 需要显式恢复或冲突策略，不能继续静默采用最后写入者。

### Neutral

- FileDocument 继续负责读写文件，但它不再承担编辑表面之间的同步协议。
- 当前预览块级 Markdown 保真算法继续使用，只改变其提交方式。

## Alternatives Considered

### 在 `updateNSView` 增加 `hasMarkedText` 判断

能缓解当前中文输入问题，但正文仍由多个位置直接写入，预览也继续依赖时序布尔值。相同类型的问题会在搜索、外部刷新或 Web 输入法中再次出现，因此拒绝。

### 让 `NSTextView` 永久成为唯一事实来源

会使预览编辑、无源码布局、外部刷新和 FileDocument 保存依赖不可见的 AppKit 控件，职责倒置，因此拒绝。

### 使用 OT 或 CRDT

能够处理真正并发的多端修改，但当前应用是单用户、单进程、单焦点编辑，复杂度与维护成本不合理，因此拒绝。

## References

- `docs/plans/2026-09-24-document-editing-session-design.md`
- `docs/plans/2026-08-21-manual-document-three-way-merge-design.md`
- `docs/plans/2026-08-17-semantic-scroll-sync-design.md`
