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
    @AppStorage("outlineSidebarVisible") private var isOutlineVisible = true
    @AppStorage(AppThemeColor.modeKey) private var themeColorMode = AppThemeColorMode.system.rawValue
    @AppStorage(AppThemeColor.customHexKey) private var themeColorHex = AppThemeColor.defaultCustomHex

    @State private var layout: EditorLayout = .split
    @State private var activeHeadingID: String?
    @State private var headingNavigationRequest: HeadingNavigationRequest?
    @State private var insertImageRequest: MarkdownPreviewView.InsertImageRequest?
    @State private var showSaveFirstAlert = false
    @State private var saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var showUploadSheet = false
    @State private var showUploadSuccess = false
    @State private var uploadSuccessMessage = ""
    @State private var uploadedFileURL: URL?
    @State private var showReloadConfirmation = false
    @State private var pendingReloadText: String?
    @State private var lastKnownDiskText: String?

    var body: some View {
        Group {
            switch layout {
            case .split:
                ThreePaneSplitView(
                    isLeadingVisible: isOutlineVisible,
                    initialFractions: (leading: 0.2, middle: 0.4),
                    minimumWidths: (leading: 160, middle: 280, trailing: 280)
                ) {
                    outlinePane
                } middle: {
                    editorPane
                } trailing: {
                    previewPane
                }

            case .editorOnly:
                TwoPaneSplitView(
                    isLeadingVisible: isOutlineVisible,
                    initialLeadingFraction: 0.2,
                    minimumWidths: (160, 320)
                ) {
                    outlinePane
                } trailing: {
                    editorPane
                }

            case .previewOnly:
                TwoPaneSplitView(
                    isLeadingVisible: isOutlineVisible,
                    initialLeadingFraction: 0.2,
                    minimumWidths: (160, 320)
                ) {
                    outlinePane
                } trailing: {
                    previewPane
                }
            }
        }
        .frame(minWidth: isOutlineVisible ? 800 : 720, minHeight: 480)
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    setOutlineVisible(!isOutlineVisible)
                } label: {
                    Label("Outline", systemImage: "sidebar.left")
                }
                .help(isOutlineVisible ? "Hide document outline" : "Show document outline")

                Button {
                    reloadDocumentFromDisk()
                } label: {
                    Label("Reload Current Document", systemImage: "arrow.clockwise")
                }
                .disabled(fileURL == nil)
                .help("从磁盘重新载入当前文档")

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
            Text(saveFirstMessage)
        }
        .alert("无法完成操作", isPresented: $showErrorAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert(reloadConfirmationTitle, isPresented: $showReloadConfirmation) {
            Button("取消", role: .cancel) {
                pendingReloadText = nil
            }
            Button("刷新", role: .destructive) {
                applyPendingReload()
            }
        } message: {
            Text("只会刷新当前文档。刷新会用磁盘上的内容替换当前编辑内容，未保存修改会丢失。")
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
        .background(DocumentWindowConfigurator())
        .focusedValue(\.editorCommandActions, EditorCommandActions(
            insertImagesFromPanel: insertImagesFromPanel,
            beginUpload: beginUpload
        ))
        .onAppear {
            syncKnownDiskTextIfNeeded()
            if activeHeadingID == nil {
                activeHeadingID = headings.first?.id
            }
        }
        .onChange(of: fileURL) { _, _ in
            lastKnownDiskText = fileURL == nil ? nil : document.text
        }
        .onChange(of: document.text) { _, _ in
            guard let activeHeadingID,
                  headings.contains(where: { $0.id == activeHeadingID })
            else {
                self.activeHeadingID = headings.first?.id
                return
            }
        }
    }

    private var outlinePane: some View {
        MarkdownOutlineSidebar(
            headings: headings,
            activeHeadingID: activeHeadingID,
            accentColor: accentColor,
            onSelect: navigate(to:),
            onClose: { setOutlineVisible(false) }
        )
    }

    private var accentColor: Color {
        AppThemeColor.resolvedColor(modeRawValue: themeColorMode, customHex: themeColorHex)
    }

    private var themeColorCSS: String {
        AppThemeColor.cssColor(modeRawValue: themeColorMode, customHex: themeColorHex)
    }

    private func setOutlineVisible(_ isVisible: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isOutlineVisible = isVisible
        }
    }

    private var headings: [MarkdownHeading] {
        MarkdownOutlineParser.headings(in: document.text)
    }

    private var blogSettings: BlogUploadSettings {
        BlogUploadSettings(
            owner: blogOwner,
            repo: blogRepo,
            branch: blogBranch,
            contentDirectory: blogContentDirectory
        )
    }

    private var reloadConfirmationTitle: String {
        guard let fileName = fileURL?.lastPathComponent else {
            return "刷新当前文档？"
        }
        return "刷新 \(fileName)？"
    }

    private var editorPane: some View {
        MarkdownSourceEditor(
            text: editorTextBinding,
            fontSize: editorFontSize,
            headings: headings,
            navigationRequest: headingNavigationRequest,
            onActiveHeadingChange: setActiveHeading
        )
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
            insertImageRequest: insertImageRequest,
            headingNavigationRequest: headingNavigationRequest,
            themeColorCSS: themeColorCSS,
            onActiveHeadingChange: setActiveHeading
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

    private func navigate(to heading: MarkdownHeading) {
        activeHeadingID = heading.id
        headingNavigationRequest = HeadingNavigationRequest(token: UUID(), heading: heading)
    }

    private func setActiveHeading(_ id: String?) {
        guard activeHeadingID != id else { return }
        activeHeadingID = id
    }

    private func reloadDocumentFromDisk() {
        guard let fileURL else { return }
        do {
            let diskText = try String(contentsOf: fileURL, encoding: .utf8)
            if diskText == document.text {
                lastKnownDiskText = diskText
                return
            }
            guard hasLocalReloadConflict else {
                applyReload(text: diskText)
                return
            }
            pendingReloadText = diskText
            showReloadConfirmation = true
        } catch {
            alertMessage = "无法刷新文档：\(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func applyPendingReload() {
        guard let pendingReloadText else { return }
        applyReload(text: pendingReloadText)
        self.pendingReloadText = nil
    }

    private var hasLocalReloadConflict: Bool {
        guard let lastKnownDiskText else { return true }
        return document.text != lastKnownDiskText
    }

    private func applyReload(text: String) {
        document.text = text
        lastKnownDiskText = text
    }

    private func syncKnownDiskTextIfNeeded() {
        guard fileURL != nil, lastKnownDiskText == nil else { return }
        lastKnownDiskText = document.text
    }

    private func beginUpload() {
        let (_, body) = BlogFrontmatter.parse(from: document.text)
        let hasLocalImages = !GitHubBlogUploader.referencedLocalImagePaths(in: body).isEmpty
        if hasLocalImages, fileURL == nil {
            saveFirstMessage = "当前文档引用了本地图片，上传前请先保存 Markdown 文件。"
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
            saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
            showSaveFirstAlert = true
            return
        }
        let urls = ImageImportService.chooseImageURLs()
        guard !urls.isEmpty else { return }
        importImageURLs(urls, intoPreview: layout != .editorOnly)
    }

    private func importPasteboardImages(intoPreview: Bool) {
        guard fileURL != nil else {
            saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
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
            saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
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
            saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
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
