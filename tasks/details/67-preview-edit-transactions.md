# 67-preview-edit-transactions

- Number: 67
- Slug: preview-edit-transactions

## Notes

- 将预览回写协议从单个连续范围升级为多个互不重叠范围组成的事务。
- JavaScript 只合并重叠范围；无法取得可信范围时阻止输入或请求 Swift 恢复预览。
- Swift 对全部 patch 做 offset、重叠和原文范围校验，验证通过后从后向前原子应用。
- 页面消息携带编辑基准 revision；Swift 复用文档编辑会话的 stale revision 拒绝机制。
- 图片插入保留精确光标语义，继续走已验证的局部范围 Turndown；现有顶层 offset 不足以安全地直接定位行内 Markdown 插入点。
- 新增 Swift Testing 覆盖不相交范围、无效范围和重叠范围。

## 验证

- `git diff --check` 通过。
- 生成真实可编辑预览 HTML 后，2 段内嵌 JavaScript 均通过 Node 语法解析。
- 聚焦运行 3 个新增 Swift Testing 和 6 个既有预览回写测试，全部通过。
- 完整运行既有 `YKMarkdownTests` XCTest 类时，44 个测试中 43 个通过；唯一失败为 `testEditableDocumentIncludesContentEditable` 中既有 `#content` CSS 字符串缩进断言，与本任务修改无关。
