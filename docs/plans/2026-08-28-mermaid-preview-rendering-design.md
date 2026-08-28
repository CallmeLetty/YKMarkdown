# Mermaid 预览渲染设计

## 目标

让 `mermaid` 围栏代码块在 YKMarkdown 的右侧可编辑预览中显示为图形，同时继续以原始围栏代码的形式保存和回写 Markdown。渲染必须离线可用，单张图语法错误不能影响文档其余内容。

## 方案选择

采用应用内置固定版本 Mermaid JavaScript 的方案。CDN 方案体积最小，但文档预览会依赖网络并受 WKWebView 文件访问策略影响；外部 Mermaid CLI 可以预生成图片，但要求用户安装 Node，且不适合实时预览。内置浏览器版 Mermaid 与现有 WKWebView 渲染架构最匹配，也能固定行为和许可证。

Markdown 渲染器把 `mermaid` 围栏输出为顶层 `.mermaid-diagram` 容器。容器保存 UTF-8 源码的 Base64 值以及现有的 `data-source-offset`，内部节点交给 Mermaid 转成 SVG。Base64 避免引号、换行、HTML 字符和中文在 DOM 属性中发生二次转义。普通代码围栏继续输出 `<pre><code>`，行为不变。

## 数据流与编辑保护

Mermaid 脚本作为应用资源在 WKWebView 文档开始阶段注入。页面初始化和 `window.setBodyHTML` 更新后都扫描尚未渲染的图块，恢复源码、逐块解析并渲染。渲染采用 `strict` 安全级别，图块设置为不可直接编辑；系统深浅色改变时，恢复保存的源码并用相应 Mermaid 主题重新渲染。

Turndown 增加专用规则：遇到 `.mermaid-diagram` 时忽略内部 SVG，解码保存的源码并输出 ` ```mermaid ` 围栏。这样编辑其他预览块、全文粘贴或剪切触发 HTML 到 Markdown 转换时，都不会把 SVG 写进文档。语法错误时图块保留源码并显示简短错误提示，Turndown 仍使用保存的原始源码。

## 验证

增加渲染器覆盖，确认 Mermaid 围栏生成专用容器、源码可无损解码、普通代码块保持不变，并确认可编辑页面包含渲染与 Turndown 保护逻辑。遵循本机偏好不主动运行测试；执行严格 Debug 编译，并在应用中打开包含流程图和错误图的 Markdown 做必要界面检查。
