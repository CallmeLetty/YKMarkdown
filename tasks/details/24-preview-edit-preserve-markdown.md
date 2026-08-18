# 24-preview-edit-preserve-markdown

- Number: 24
- Slug: preview-edit-preserve-markdown

## Notes

- 预览编辑从默认整篇 `content.innerHTML` 通过 Turndown 回写，改为优先上报当前 `data-source-offset` 对应的顶层块。
- Swift 侧新增块级替换 helper，只替换原 Markdown 中对应块 range，保留未编辑区域原文，避免标题、表格、列表被整篇重排。
- 预览侧补充 heading/table Turndown 规则，降低单块回写时 `1.` 转义和 GFM 表格丢失造成的格式噪音。
- 增加回归测试覆盖块级编辑路径，以及只改首段时后续编号标题和表格保持原样。
- 新增 `docs/问题记录/预览编辑 Markdown 回写问题记录.md` 记录这次踩坑原因、当前处理和后续注意事项。
- 验证：`git diff --check` 通过；预览内嵌 JavaScript 片段 `node --check` 通过。按项目要求未运行 SwiftLint 和 xcodebuild。
