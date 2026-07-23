import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @AppStorage("blogOwner") private var blogOwner = BlogUploadSettings.default.owner
    @AppStorage("blogRepo") private var blogRepo = BlogUploadSettings.default.repo
    @AppStorage("blogBranch") private var blogBranch = BlogUploadSettings.default.branch
    @AppStorage("blogContentDirectory") private var blogContentDirectory = BlogUploadSettings.default.contentDirectory
    @AppStorage("editorFontSize") private var editorFontSize = 14.0

    @State private var layout: EditorLayout = .split
    @State private var insertImageRequest: MarkdownPreviewView.InsertImageRequest?
    @State private var showSaveFirstAlert = false
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var showUploadSheet = false
    @State private var showUploadSuccess = false
    @State private var uploadSuccessMessage = ""
    @State private var uploadedFileURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            switch layout {
            case .editorOnly:
                editorPane
            case .previewOnly:
                previewPane
            case .split:
                HSplitView {
                    editorPane
                        .frame(minWidth: 280)
                    previewPane
                        .frame(minWidth: 280)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Picker("Layout", selection: $layout) {
                    Label("Editor", systemImage: "square.and.pencil")
                        .tag(EditorLayout.editorOnly)
                    Label("Split", systemImage: "rectangle.split.2x1")
                        .tag(EditorLayout.split)
                    Label("Preview", systemImage: "eye")
                        .tag(EditorLayout.previewOnly)
                }
                .pickerStyle(.segmented)
                .help("Switch between editor, split, and preview")

                Button {
                    insertImagesFromPanel()
                } label: {
                    Label("Insert Image", systemImage: "photo")
                }
                .help("Insert image into Markdown (saved under ./assets)")

                Button {
                    beginUpload()
                } label: {
                    Label("Upload to Blog", systemImage: "arrow.up.doc")
                }
                .help("Upload current document to Yakamoz-Blog/content")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        .alert("请先保存文档", isPresented: $showSaveFirstAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("插入图片或上传博客前，请先保存 Markdown 文件。")
        }
        .alert("无法完成操作", isPresented: $showErrorAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("上传成功", isPresented: $showUploadSuccess) {
            if let uploadedFileURL {
                Button("在 GitHub 打开") {
                    NSWorkspace.shared.open(uploadedFileURL)
                }
            }
            Button("好的", role: .cancel) {}
        } message: {
            Text(uploadSuccessMessage)
        }
        .sheet(isPresented: $showUploadSheet) {
            BlogUploadSheet(
                markdown: document.text,
                fileURL: fileURL,
                settings: blogSettings,
                onFinished: handleUploadResult
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .ykInsertImage)) { _ in
            insertImagesFromPanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ykUploadBlog)) { _ in
            beginUpload()
        }
    }

    private var blogSettings: BlogUploadSettings {
        BlogUploadSettings(
            owner: blogOwner,
            repo: blogRepo,
            branch: blogBranch,
            contentDirectory: blogContentDirectory
        )
    }

    private var editorPane: some View {
        TextEditor(text: editorTextBinding)
            .font(.system(size: editorFontSize, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .accessibilityLabel("Markdown editor")
    }

    private var previewPane: some View {
        MarkdownPreviewView(
            markdown: document.text,
            baseURL: fileURL,
            onMarkdownChange: { markdown in
                document.text = markdown
            },
            onPasteImages: {
                importPasteboardImages(intoPreview: true)
            },
            onDropImages: { urls in
                importImageURLs(urls, intoPreview: true)
            },
            insertImageRequest: insertImageRequest
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .accessibilityLabel("Editable Markdown preview")
    }

    private var editorTextBinding: Binding<String> {
        Binding(
            get: { document.text },
            set: { document.text = $0 }
        )
    }

    private func beginUpload() {
        guard fileURL != nil else {
            showSaveFirstAlert = true
            return
        }
        if KeychainStore.get(account: GitHubBlogUploader.tokenAccount) == nil {
            alertMessage = "请先打开设置（⌘,），填写并保存 GitHub Token。"
            showErrorAlert = true
            return
        }
        showUploadSheet = true
    }

    private func handleUploadResult(_ upload: GitHubBlogUploader.UploadResult) {
        uploadedFileURL = upload.htmlURL
        var message = "已发布到 \(upload.markdownPath)"
        if upload.uploadedAssetCount > 0 {
            message += "，并上传 \(upload.uploadedAssetCount) 张图片"
        }
        uploadSuccessMessage = message
        showUploadSuccess = true
    }

    private func insertImagesFromPanel() {
        guard fileURL != nil else {
            showSaveFirstAlert = true
            return
        }
        let urls = ImageImportService.chooseImageURLs()
        guard !urls.isEmpty else { return }
        importImageURLs(urls, intoPreview: layout != .editorOnly)
    }

    private func importPasteboardImages(intoPreview: Bool) {
        guard fileURL != nil else {
            showSaveFirstAlert = true
            return
        }
        do {
            let imported = try ImageImportService.importPasteboardImages(documentURL: fileURL)
            applyImportedImages(imported, intoPreview: intoPreview)
        } catch {
            presentImportError(error)
        }
    }

    private func importImageURLs(_ urls: [URL], intoPreview: Bool) {
        guard fileURL != nil else {
            showSaveFirstAlert = true
            return
        }
        do {
            let imported = try urls.map { try ImageImportService.importFile(at: $0, documentURL: fileURL) }
            applyImportedImages(imported, intoPreview: intoPreview)
        } catch {
            presentImportError(error)
        }
    }

    private func applyImportedImages(
        _ imported: [ImageImportService.ImportedImage],
        intoPreview: Bool
    ) {
        guard !imported.isEmpty else { return }

        if intoPreview, layout != .editorOnly, let first = imported.first {
            insertImageRequest = .init(
                token: UUID(),
                relativePath: first.relativePath,
                altText: first.altText
            )
            if imported.count > 1 {
                let extra = imported.dropFirst().map(\.markdown).joined(separator: "\n\n")
                appendMarkdown("\n\n" + extra)
            }
        } else {
            let block = imported.map(\.markdown).joined(separator: "\n\n")
            appendMarkdown("\n\n" + block + "\n")
        }
    }

    private func appendMarkdown(_ snippet: String) {
        if document.text.isEmpty || document.text.hasSuffix("\n") {
            document.text += snippet.trimmingCharacters(in: CharacterSet(charactersIn: "\n")) + "\n"
        } else {
            document.text += snippet
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
            + providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !imageProviders.isEmpty else { return false }

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let itemURL = item as? URL {
                    url = itemURL
                } else {
                    url = nil
                }
                guard let url else { return }
                DispatchQueue.main.async {
                    importImageURLs([url], intoPreview: layout != .editorOnly)
                }
            }
        }
        return true
    }

    private func presentImportError(_ error: Error) {
        if let importError = error as? ImageImportService.ImportError,
           importError == .documentNotSaved {
            showSaveFirstAlert = true
            return
        }
        alertMessage = error.localizedDescription
        showErrorAlert = true
    }
}

private enum EditorLayout: String, CaseIterable, Identifiable {
    case editorOnly
    case split
    case previewOnly

    var id: String { rawValue }
}

#Preview {
    EditorView(document: .constant(MarkdownDocument()), fileURL: nil)
}
