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

enum EditorFontSize {
    static let storageKey = "editorFontSize"
    static let defaultValue = 14.0
    static let minimum = 11.0
    static let maximum = 22.0
    static let step = 1.0

    static func increased(from value: Double) -> Double {
        clamped(value + step)
    }

    static func decreased(from value: Double) -> Double {
        clamped(value - step)
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, minimum), maximum)
    }
}

/// 当前获得焦点的文档窗口可响应的菜单命令。
struct EditorCommandActions {
    let insertImagesFromPanel: () -> Void
    let beginUpload: () -> Void
    let openSearch: (DocumentSearchScope) -> Void
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
    @AppStorage(EditorFontSize.storageKey) private var editorFontSize = EditorFontSize.defaultValue

    var body: some Commands {
        CommandGroup(before: .textEditing) {
            Button("Find in Current Document…") {
                editorCommandActions?.openSearch(.current)
            }
            .keyboardShortcut("f", modifiers: [.command])
            .disabled(editorCommandActions == nil)

            Button("Find in Open Documents…") {
                editorCommandActions?.openSearch(.all)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(editorCommandActions == nil)

            Divider()
        }

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

        CommandGroup(after: .textFormatting) {
            Divider()

            Button("Increase Font Size") {
                editorFontSize = EditorFontSize.increased(from: editorFontSize)
            }
            .keyboardShortcut("+", modifiers: [.command])
            .disabled(editorFontSize >= EditorFontSize.maximum)

            Button("Decrease Font Size") {
                editorFontSize = EditorFontSize.decreased(from: editorFontSize)
            }
            .keyboardShortcut("-", modifiers: [.command])
            .disabled(editorFontSize <= EditorFontSize.minimum)
        }
    }
}
