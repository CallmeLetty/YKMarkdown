# 27-fix-search-bar-layout

- Number: 27
- Slug: fix-search-bar-layout

## Notes

- 搜索条改为 `ViewThatFits` 自适应布局：宽度足够时保持单行，空间不足时切成两行。
- 搜索输入框增加最小宽度和更高布局优先级，范围切换控件收窄，避免输入框被上一条/下一条/关闭按钮挤到不可见。
- 已执行 `git diff --check`；按项目规则未运行 SwiftLint、`xcodebuild` 或测试构建。
