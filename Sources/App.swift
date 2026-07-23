import AppKit
import SwiftUI

@main
struct YKMarkdownApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            EditorView(document: file.$document, fileURL: file.fileURL)
        }
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Insert Image…") {
                    NotificationCenter.default.post(name: .ykInsertImage, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Upload to Blog…") {
                    NotificationCenter.default.post(name: .ykUploadBlog, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .help) {
                Button("Markdown Guide") {
                    NSWorkspace.shared.open(URL(string: "https://www.markdownguide.org/basic-syntax/")!)
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let ykInsertImage = Notification.Name("ykInsertImage")
    static let ykUploadBlog = Notification.Name("ykUploadBlog")
}
