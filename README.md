# YKMarkdown

macOS 上的轻量 Markdown 编辑器：左侧写原文，右侧可编辑预览，并支持一键发布到 [Yakamoz-Blog](https://github.com/CallmeLetty/Yakamoz-Blog)。

## 功能

- **分栏编辑**：原文 / 分栏 / 仅预览
- **可编辑预览**：在预览里直接改字，自动同步回 Markdown
- **图片**：工具栏插入、拖拽、粘贴；保存到文档旁的 `assets/`
- **文档型应用**：原生打开 / 保存 `.md`
- **一键上传博客**：发布到 `Yakamoz-Blog` 仓库的 `content/` 目录（含 frontmatter）

## 要求

- macOS 15.4+
- Xcode 16+（开发构建）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（可选，改 `project.yml` 后重新生成工程）

## 快速开始

```bash
git clone https://github.com/CallmeLetty/YKMarkdown.git
cd YKMarkdown
make run
```

常用命令：

```bash
make build   # 编译
make test    # 单元测试
make run     # 编译并启动
```

也可用 Xcode 打开 `YKMarkdown.xcodeproj` 后运行。

## 使用说明

### 编辑与预览

1. 启动后新建或打开 `.md` 文件
2. 左侧编辑 Markdown，右侧即时预览
3. 也可直接在右侧预览中编辑，内容会写回原文
4. 工具栏可切换「仅编辑 / 分栏 / 仅预览」

### 插入图片

1. 先保存文档
2. 使用工具栏 **Insert Image**、`⌘⇧I`、拖拽或粘贴
3. 图片复制到 `./assets/`，并插入：

```markdown
![说明](assets/example.png)
```

### 上传到 Yakamoz Blog

博客仓库：[CallmeLetty/Yakamoz-Blog](https://github.com/CallmeLetty/Yakamoz-Blog)  
文章目录：`content/*.md`（YAML frontmatter）

#### 1. 准备 GitHub Token

1. 打开 [GitHub Fine-grained token](https://github.com/settings/tokens?type=beta) 或 Classic token
2. 至少授予目标仓库的 **Contents: Read and write**（Classic 可用 `repo`）
3. 在 YKMarkdown 中打开 **Settings（⌘,）** → **Yakamoz Blog 上传**
4. 粘贴 Token 并点 **保存 Token 到钥匙串**

默认仓库配置：

| 项 | 默认值 |
|----|--------|
| Owner | `CallmeLetty` |
| Repository | `Yakamoz-Blog` |
| Branch | `main` |
| Content 目录 | `content` |

#### 2. 发布文章

1. 保存当前 Markdown
2. 点工具栏 **Upload to Blog**，或按 `⌘⇧U`
3. 确认标题、日期、标签、摘要、slug（文件名）
4. 上传成功后会提交到：

```text
content/<slug>.md
```

若文中引用了本地 `assets/` 图片，会一并上传到：

```text
content/assets/<slug>/...
```

并在远程 Markdown 中改写为 `raw.githubusercontent.com` 图片链接（便于博客站点直接显示）。

#### Frontmatter 示例

```markdown
---
title: 你好，Yakamoz
date: 2026-07-23
tags: [随笔, 写作]
excerpt: 一句话摘要
---

正文从这里开始…
```

## 项目结构

```text
YKMarkdown/
├── Sources/           # SwiftUI 应用源码
├── Tests/             # 单元测试
├── Resources/         # 额外资源（如 turndown 源文件）
├── project.yml        # XcodeGen 工程描述
├── Makefile           # make build / run / test
└── README.md
```

## 开发

若修改了 `project.yml`：

```bash
xcodegen generate
make build
```

## 许可

MIT（见仓库 LICENSE；若尚未添加则以你后续声明为准）。
