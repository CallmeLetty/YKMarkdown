# 43-preview-command-link-open

- Number: 43
- Slug: preview-command-link-open

## Notes

- 在可编辑预览 HTML 中新增 Command 键链接打开模式：普通状态下链接保持文本编辑光标，按住 Command 时切换为 pointer。
- 链接只在 Command + mousedown 时通过现有 `openURL` bridge 打开；普通 click 只阻止 WebKit 默认导航，保留编辑行为。
