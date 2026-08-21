# 31-implement-manual-document-three-way-merge

- Number: 31
- Slug: implement-manual-document-three-way-merge

## Notes

- 新增纯 Swift 行级三方合并引擎，自动合并互不重叠的本地与磁盘修改。
- 文档打开内容作为内存基准；完成合并后以本次磁盘内容更新基准，保留合并结果中的未保存本地修改语义。
- 重叠修改使用结构化冲突会话，不向 Markdown 写入文本冲突标记。
- 冲突时只显示源码解决器：本地内容为红色、磁盘内容为绿色，并对行内变化使用更深背景。
- 顶部展示未解决数量，支持循环跳到下一处；每处支持保留当前、使用外部、两者保留、手动编辑和重新选择。
- 严格 macOS App build 与 test build 成功；按用户偏好未运行测试和 SwiftLint。
- 尝试 UI 自动化验证时检测到当前 YKMarkdown 窗口焦点被外部切换，因此立即停止，未修改已打开文档。
