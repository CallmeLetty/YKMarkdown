import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    var text: String

    init(text: String = Self.welcomeMarkdown) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    static let welcomeMarkdown = """
    # Welcome to YKMarkdown

    左侧是 Markdown 原文，右侧是**可编辑预览**：直接在预览里改字，会同步回原文。

    ## 图片怎么加？

    1. 先 **保存** 当前 `.md` 文件  
    2. 点工具栏 **Insert Image**，或拖拽 / 粘贴图片到窗口  
    3. 图片会复制到文档旁的 `assets/`，并插入：

    `![说明](assets/example.png)`

    也可以手写同样的 Markdown；相对路径相对于 `.md` 所在目录。

    ## 快捷写法

    **Bold**, *italic*, `inline code`

    > 预览里也可以直接编辑这段话。

    - 无序列表
    - 另一项

    ```swift
    print("Hello, Markdown")
    ```

    [Markdown Guide](https://www.markdownguide.org)
    """
}

extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}
