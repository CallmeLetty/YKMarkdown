# 预览编辑 Markdown 回写问题记录

## 背景

YKMarkdown 的预览区域是可编辑的 WebKit 页面。早期实现中，用户在预览中输入后，页面会把整个 `content.innerHTML` 通过 Turndown 转回 Markdown，再整体写回原文。

这个策略对简单段落可用，但它不是无损操作。Markdown 源码里有很多语法细节在渲染为 HTML 后会丢失，例如列表缩进风格、标题文字里的转义策略、表格原始排版、空行数量和局部写法偏好。

## 触发过的问题

在一篇包含标题、列表和表格的文档中，用户只修改了首段一句话：

```markdown
本文档说明 YKImageEditor 当前各项图片编辑功能的实现方式、数据流、性能策略和扩展边界。内容对应当前工程代码，不是产品规划文档。
```

保存后 Git 却显示大量 diff。实际原因不是文件编码或行尾变化，而是预览编辑把整篇文档重新序列化：

- `## 1. 技术架构` 被转成 `## 1\. 技术架构`。
- `- xxx` 被转成 `-   xxx`。
- Markdown 表格被拆成普通段落文本。
- 未编辑区域也被写成 Turndown 的默认 Markdown 风格。

其中表格问题尤其严重，因为基础 Turndown 没有 GFM table 规则，HTML 的 `<table>` 回写时会退化为单元格文本。

## 当前处理

预览编辑现在优先走块级回写：

1. 渲染器继续为顶层 Markdown 块写入 `data-source-offset`。
2. 预览发生输入时，JavaScript 侧定位当前光标所在的顶层块。
3. 页面只把这个块转成 Markdown，并通过 `markdownBlockChanged` 上报块起始 offset 和块内容。
4. Swift 侧使用原文的 source offsets 定位块范围，只替换这个块，保留其他未编辑 Markdown 原文。
5. 只有无法定位块，或一次操作可能跨多个块时，才退回全量回写。

同时预览侧为标题和表格补了专用 Turndown 规则，降低单块回写时的格式噪音：

- 标题内容中普通的 `1. ` 不再被转义成 `1\. `。
- `<table>` 会按 GFM 表格格式回写，而不是拆散成普通文本。

## 实现对照

原来的实现只有一个全量回写入口。预览区任意输入都会把整个 DOM 转成 Markdown，再整体替换文档内容：

```javascript
function currentMarkdown() {
  return turndown.turndown(content.innerHTML || '');
}

function emitMarkdown() {
  if (suppressEmit) return;
  post({ type: 'markdownChanged', markdown: currentMarkdown() });
}
```

Swift 侧收到后直接把整篇 Markdown 写回：

```swift
case "markdownChanged":
    guard let markdown = body["markdown"] as? String else { return }
    let normalized = Self.normalizeMarkdown(markdown)
    parent.onMarkdownChange(normalized)
```

新的实现优先定位当前编辑的顶层块，只上报块起点和块内容：

```javascript
function emitMarkdown() {
  if (suppressEmit) return;
  if (pendingPreviewEdit.requiresFullEmit || !pendingPreviewEdit.block) {
    post({ type: 'markdownChanged', markdown: currentMarkdown() });
  } else {
    post({
      type: 'markdownBlockChanged',
      sourceOffset: pendingPreviewEdit.block.sourceOffset,
      markdown: pendingPreviewEdit.block.markdown
    });
  }
}
```

Swift 侧只替换原文中对应 `sourceOffset` 的块范围，未编辑区域不会经过 Turndown：

```swift
case "markdownBlockChanged":
    let patched = MarkdownPreviewEditPatch.replacingBlock(
        in: lastAppliedMarkdown,
        sourceOffset: sourceOffset.intValue,
        with: markdown
    )
    parent.onMarkdownChange(Self.normalizeMarkdown(patched))
```

## 后续注意

可编辑预览无法天然做到 Markdown 源码级无损编辑。只要经过 `HTML -> Markdown`，被编辑的块仍可能丢失局部写法，例如表格列对齐空格、复杂内联 HTML 或非标准 Markdown 扩展。

如果以后继续增强预览编辑，优先考虑这些方向：

- 对常见块类型做局部 patch，不要恢复全量回写作为默认路径。
- 对表格、代码块、引用、列表等结构块分别补回写规则。
- 对跨块粘贴、删除、拖拽插入等操作单独设计 range patch，避免用整篇 Turndown 兜底。
- 修改回写策略时，用包含标题编号、列表、表格和代码块的文档检查 Git diff。
