# 源码行号设计

## 目标

为 Markdown 源码编辑器增加行号栏。行号默认显示，用户可以在设置页隐藏；偏好对所有文档窗口生效并跨启动持久化。行号仅作为编辑辅助，不写入 Markdown，不改变选区、撤销栈、搜索范围或源码与预览的位置同步。

## 方案选择

候选方案包括：在 SwiftUI 中给编辑器并排行号列表、给每行正文添加数字前缀，以及使用 `NSScrollView` 的垂直 ruler。采用第三种方案。

SwiftUI 并排列表需要自行同步滚动、字体和软换行高度；正文前缀会污染文档内容及字符偏移。`NSRulerView` 是 AppKit 为滚动内容提供标尺的原生扩展点，可以共享 `NSTextView` 的布局结果，在不修改正文的前提下按实际可见范围绘制逻辑行号。

## 交互与数据流

应用层定义 `EditorLineNumbers` 偏好模型，集中保存存储键和默认值。`SettingsView` 的 Editor 区增加“显示行号”开关；`EditorView` 通过 `AppStorage` 读取偏好并传入 `MarkdownSourceEditor`。

源码编辑器创建 `MarkdownLineNumberRulerView` 并设置为 `NSScrollView.verticalRulerView`。开关开启时显示垂直 ruler，关闭时隐藏。ruler 从 `NSTextView` 的字符串计算逻辑行起点，再通过 `NSLayoutManager` 把可见字符映射为 glyph rect；同一个逻辑行发生软换行时只在第一条视觉行旁显示一次编号。文本改变、滚动、容器宽度或字体/行距变化时刷新 ruler。

## 外观与边界

行号使用与源码等宽字体一致的字号比例和次要文字色。栏宽随最大行号位数增长，并预留左右间距；背景沿用编辑器背景色，使自定义稿纸背景保持连续。空文档仍显示第 1 行，末尾换行产生的新空行也有独立行号。

关闭行号只切换 ruler 可见性，不重建 `NSTextView`，因此不会影响焦点、光标、滚动位置或输入法组合状态。验证覆盖行起点计算、空文档及尾随换行，并通过严格编译和界面检查确认显示、滚动及开关行为。
