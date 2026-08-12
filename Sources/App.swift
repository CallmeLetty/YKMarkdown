import AppKit
import SwiftUI

@main
struct YKMarkdownApp: App {
    @AppStorage(AppThemeColor.modeKey) private var themeColorMode = AppThemeColorMode.system.rawValue
    @AppStorage(AppThemeColor.customHexKey) private var themeColorHex = AppThemeColor.defaultCustomHex

    init() {
        // 允许文档窗口参与系统级标签页，具体行为由每个窗口的打开方式设置控制。
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            EditorView(document: file.$document, fileURL: file.fileURL)
                .tint(AppThemeColor.resolvedColor(modeRawValue: themeColorMode, customHex: themeColorHex))
        }
        .commands {
            EditorDocumentCommands()

            CommandGroup(replacing: .help) {
                Button("Markdown Guide") {
                    NSWorkspace.shared.open(URL(string: "https://www.markdownguide.org/basic-syntax/")!)
                }
            }
        }

        Settings {
            SettingsView()
                .tint(AppThemeColor.resolvedColor(modeRawValue: themeColorMode, customHex: themeColorHex))
        }
    }
}

/// 当前获得焦点的文档窗口可响应的菜单命令。
struct EditorCommandActions {
    let insertImagesFromPanel: () -> Void
    let beginUpload: () -> Void
}

private struct EditorCommandActionsKey: FocusedValueKey {
    typealias Value = EditorCommandActions
}

extension FocusedValues {
    var editorCommandActions: EditorCommandActions? {
        get { self[EditorCommandActionsKey.self] }
        set { self[EditorCommandActionsKey.self] = newValue }
    }
}

private struct EditorDocumentCommands: Commands {
    @FocusedValue(\.editorCommandActions) private var editorCommandActions

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Button("Insert Image…") {
                editorCommandActions?.insertImagesFromPanel()
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .disabled(editorCommandActions == nil)

            Button("Upload to Blog…") {
                editorCommandActions?.beginUpload()
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .disabled(editorCommandActions == nil)
        }
    }
}
