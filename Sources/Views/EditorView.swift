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
    @AppStorage(EditorFontSize.storageKey) private var editorFontSize = EditorFontSize.defaultValue
    @AppStorage("outlineSidebarVisible") private var isOutlineVisible = true
    @AppStorage(AppTypographyAppearance.customBackgroundEnabledKey) private var customBackgroundEnabled = false
    @AppStorage(AppTypographyAppearance.customBackgroundHexKey) private var customBackgroundHex = AppTypographyAppearance.defaultCustomBackgroundHex
    @AppStorage(AppThemeColor.modeKey) private var themeColorMode = AppThemeColorMode.system.rawValue
    @AppStorage(AppThemeColor.customHexKey) private var themeColorHex = AppThemeColor.defaultCustomHex

    @State private var layout: EditorLayout = .split
    @State private var sourcePositionRequest: DocumentPositionRequest?
    @State private var previewPositionRequest: DocumentPositionRequest?
    @State private var scrollAnchorOffsets: [Int] = []
    @State private var insertImageRequest: MarkdownPreviewView.InsertImageRequest?
    /// 各区域共享的当前位置，也用于布局切换后恢复定位。
    @State private var documentSourceOffset: Int?
    @State private var showSaveFirstAlert = false
    @State private var saveFirstMessage = "插入图片前，请先保存 Markdown 文件。"
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var showUploadSheet = false
    @State private var showUploadSuccess = false
    @State private var uploadSuccessMessage = ""
    @State private var uploadedFileURL: URL?
    @State private var mergeSession: DocumentMergeSession?
    @State private var lastKnownDiskText: String?
    @ObservedObject private var searchRegistry = OpenDocumentSearchRegistry.shared
    @StateObject private var searchWindowBox = SearchDocumentWindowBox()
    @State private var documentSearchID = UUID()
    @State private var isSearchVisible = false
    /// 每次打开搜索都更新请求，确保搜索栏已显示时仍能重新聚焦。
    @State private var searchFocusRequest = UUID()
    @State private var searchScope: DocumentSearchScope = .current
    @State private var searchQuery = ""
    @State private var selectedSearchMatchID: MarkdownSearchMatch.ID?
    @State private var searchNavigationRequest: DocumentSearchNavigationRequest?

    var body: some View {
        Group {
            if let mergeSession {
                DocumentMergeConflictView(
                    session: mergeSession,
                    fontSize: editorFontSize,
                    onCancel: cancelMerge,
                    onComplete: completeMerge
                )
            } else {
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
        }
        .frame(minWidth: isOutlineVisible ? 800 : 720, minHeight: 480)
        .background(typographyBackgroundColor)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    setOutlineVisible(!isOutlineVisible)
                } label: {
                    Label("Outline", systemImage: "sidebar.left")
                }
                .disabled(mergeSession != nil)
                .help(isOutlineVisible ? "Hide document outline" : "Show document outline")

                Button {
                    reloadDocumentFromDisk()
                } label: {
                    Label("Reload Current Document", systemImage: "arrow.clockwise")
                }
                .disabled(fileURL == nil || mergeSession != nil)
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
                .disabled(mergeSession != nil)
                .help("Switch between editor, split, and preview")

                Button {
                    insertImagesFromPanel()
                } label: {
                    Label("Insert Image", systemImage: "photo")
                }
                .disabled(mergeSession != nil)
                .help("Insert image into Markdown (saved under ./assets)")

                Button {
                    beginUpload()
                } label: {
                    Label("Upload to Blog", systemImage: "arrow.up.doc")
                }
                .disabled(mergeSession != nil)
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
        .background(DocumentSearchWindowReader(
            onWindowChange: { window in
                searchWindowBox.window = window
            },
            onWindowClose: {
                searchRegistry.unregister(id: documentSearchID)
            }
        ))
        .focusedValue(\.editorCommandActions, EditorCommandActions(
            insertImagesFromPanel: insertImagesFromPanel,
            beginUpload: beginUpload,
            openSearch: openSearch
        ))
        .onAppear {
            registerOpenSearchDocument()
            syncKnownDiskTextIfNeeded()
            updateScrollAnchorOffsets()
        }
        .onChange(of: fileURL) { _, _ in
            mergeSession = nil
            lastKnownDiskText = fileURL == nil ? nil : document.text
            registerOpenSearchDocument()
        }
        .onChange(of: document.text) { _, _ in
            registerOpenSearchDocument()
            updateScrollAnchorOffsets()
            validateSearchSelection()
            if let documentSourceOffset {
                self.documentSourceOffset = min(documentSourceOffset, (document.text as NSString).length)
            }
        }
        .onChange(of: layout) { _, _ in
            guard let sourceOffset = documentSourceOffset else { return }
            let request = DocumentPositionRequest(token: UUID(), sourceOffset: sourceOffset)
            // 布局恢复不取消正在执行的搜索选区定位。
            if searchNavigationRequest == nil {
                sourcePositionRequest = request
            }
            previewPositionRequest = request
        }
        .onChange(of: searchQuery) { _, _ in
            selectFirstSearchMatchIfNeeded()
        }
        .onChange(of: searchScope) { _, _ in
            selectFirstSearchMatchIfNeeded()
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

    private var typographyAppearance: ResolvedTypographyAppearance {
        AppTypographyAppearance.resolve(
            customBackgroundEnabled: customBackgroundEnabled,
            customBackgroundHex: customBackgroundHex
        )
    }

    private var typographyBackgroundColor: Color {
        Color(nsColor: typographyAppearance.backgroundColor)
    }

    private func setOutlineVisible(_ isVisible: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isOutlineVisible = isVisible
        }
    }

    /// 目录位置由统一源码位置派生，避免各区域分别写入标题状态。
    private var activeHeadingID: String? {
        let offset = documentSourceOffset ?? 0
        return (headings.last { $0.sourceRange.location <= offset } ?? headings.first)?.id
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

    private var editorPane: some View {
        VStack(spacing: 0) {
            if isSearchVisible {
                DocumentSearchBar(
                    scope: $searchScope,
                    query: $searchQuery,
                    focusRequest: searchFocusRequest,
                    matches: searchMatches,
                    selectedMatchID: selectedSearchMatchID,
                    selectedIndex: selectedSearchIndex,
                    onPrevious: selectPreviousSearchMatch,
                    onNext: selectNextSearchMatch,
                    onClose: closeSearch,
                    onSelect: selectSearchMatch
                )
            }

            MarkdownSourceEditor(
                text: editorTextBinding,
                documentURL: fileURL,
                fontSize: editorFontSize,
                backgroundColor: typographyAppearance.backgroundColor,
                foregroundColor: typographyAppearance.foregroundColor,
                scrollAnchorOffsets: scrollAnchorOffsets,
                positionRequest: sourcePositionRequest,
                searchQuery: isSearchVisible ? searchQuery : "",
                selectedSearchRange: selectedSearchRange,
                searchNavigationRequest: searchNavigationRequest,
                onPositionChange: { synchronizePosition(to: $0, from: .source) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(typographyBackgroundColor)
            .accessibilityLabel("Markdown editor")
        }
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
            positionRequest: previewPositionRequest,
            themeColorCSS: themeColorCSS,
            fontSize: editorFontSize,
            backgroundColorCSS: typographyAppearance.backgroundCSS,
            foregroundColorCSS: typographyAppearance.foregroundCSS,
            colorSchemeCSS: typographyAppearance.colorSchemeCSS,
            onPositionChange: { synchronizePosition(to: $0, from: .preview) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(typographyBackgroundColor)
        .accessibilityLabel("Editable Markdown preview")
    }

    private var editorTextBinding: Binding<String> {
        Binding(
            get: { document.text },
            set: { document.text = $0 }
        )
    }

    /// 位置事件的来源；被动跟随的区域不再上报同一次移动。
    private enum PositionOrigin {
        case outline, source, preview, search
    }

    private func navigate(to heading: MarkdownHeading) {
        synchronizePosition(to: heading.sourceRange.location, from: .outline)
    }

    /// 以源码偏移统一更新目录和其他区域，不改变键盘焦点或被动区域的选区。
    private func synchronizePosition(to sourceOffset: Int, from origin: PositionOrigin) {
        let offset = min(max(sourceOffset, 0), (document.text as NSString).length)
        if (origin == .source || origin == .preview), documentSourceOffset == offset { return }
        documentSourceOffset = offset
        if origin != .search {
            searchNavigationRequest = nil
        }
        let request = DocumentPositionRequest(token: UUID(), sourceOffset: offset)
        if origin != .source && origin != .search {
            sourcePositionRequest = request
        } else {
            sourcePositionRequest = nil
        }
        if origin != .preview {
            previewPositionRequest = request
        }
    }

    private func updateScrollAnchorOffsets() {
        scrollAnchorOffsets = MarkdownHTMLRenderer.sourceOffsets(from: document.text)
    }

    private var documentSearchTitle: String {
        fileURL?.lastPathComponent ?? "未保存文档"
    }

    private var searchMatches: [MarkdownSearchMatch] {
        searchRegistry.matches(
            scope: searchScope,
            activeDocumentID: documentSearchID,
            query: searchQuery
        )
    }

    private var selectedSearchIndex: Int? {
        guard let selectedSearchMatchID else { return nil }
        return searchMatches.firstIndex { $0.id == selectedSearchMatchID }
    }

    private var selectedSearchRange: NSRange? {
        guard let selectedSearchMatchID,
              let match = searchMatches.first(where: { $0.id == selectedSearchMatchID }),
              match.documentID == documentSearchID
        else {
            return nil
        }
        return match.range
    }

    private func registerOpenSearchDocument() {
        searchRegistry.upsert(
            id: documentSearchID,
            title: documentSearchTitle,
            fileURL: fileURL,
            text: document.text,
            windowBox: searchWindowBox,
            navigateToMatch: { query, range, scope in
                navigateToSearchMatch(query: query, range: range, scope: scope)
            }
        )
    }

    private func openSearch(scope: DocumentSearchScope) {
        guard mergeSession == nil else { return }
        registerOpenSearchDocument()
        searchScope = scope
        isSearchVisible = true
        if layout == .previewOnly {
            layout = .split
        }
        selectFirstSearchMatchIfNeeded()
        searchFocusRequest = UUID()
    }

    private func closeSearch() {
        isSearchVisible = false
        selectedSearchMatchID = nil
        searchNavigationRequest = nil
    }

    private func selectFirstSearchMatchIfNeeded() {
        let matches = searchMatches
        guard !matches.isEmpty else {
            selectedSearchMatchID = nil
            searchNavigationRequest = nil
            return
        }

        if let selectedSearchMatchID,
           matches.contains(where: { $0.id == selectedSearchMatchID }) {
            return
        }
        selectSearchMatch(matches[0])
    }

    private func validateSearchSelection() {
        guard isSearchVisible, !searchQuery.isEmpty else { return }
        selectFirstSearchMatchIfNeeded()
    }

    private func selectPreviousSearchMatch() {
        selectSearchMatch(offset: -1)
    }

    private func selectNextSearchMatch() {
        selectSearchMatch(offset: 1)
    }

    private func selectSearchMatch(offset: Int) {
        let matches = searchMatches
        guard !matches.isEmpty else { return }

        let currentIndex = selectedSearchIndex ?? (offset > 0 ? -1 : 0)
        let nextIndex = (currentIndex + offset + matches.count) % matches.count
        selectSearchMatch(matches[nextIndex])
    }

    private func selectSearchMatch(_ match: MarkdownSearchMatch) {
        selectedSearchMatchID = match.id
        if match.documentID == documentSearchID {
            if layout == .previewOnly {
                layout = .split
            }
            navigateToSearchRange(match.range)
        } else {
            searchRegistry.navigate(to: match, query: searchQuery, scope: searchScope)
        }
    }

    private func navigateToSearchMatch(query: String, range: NSRange, scope: DocumentSearchScope) {
        searchQuery = query
        searchScope = scope
        isSearchVisible = true
        selectedSearchMatchID = MarkdownSearchMatch.id(documentID: documentSearchID, range: range)
        if layout == .previewOnly {
            layout = .split
        }
        navigateToSearchRange(range)
    }

    /// 所有搜索入口共享位置路由，源码保留精确的匹配选区。
    private func navigateToSearchRange(_ range: NSRange) {
        searchNavigationRequest = DocumentSearchNavigationRequest(token: UUID(), range: range)
        synchronizePosition(to: range.location, from: .search)
    }

    private func reloadDocumentFromDisk() {
        guard let fileURL, mergeSession == nil else { return }
        do {
            let diskText = try coordinatedDiskText(at: fileURL)
            let localText = document.text
            let baseText = lastKnownDiskText ?? localText

            switch DocumentThreeWayMerge.refreshDecision(
                base: baseText,
                local: localText,
                remote: diskText
            ) {
            case let .unchanged(remoteBaseline):
                lastKnownDiskText = remoteBaseline
            case .preserveLocal:
                break
            case let .apply(text, remoteBaseline):
                document.text = text
                lastKnownDiskText = remoteBaseline
            case let .resolveConflicts(result, remoteBaseline):
                closeSearch()
                mergeSession = DocumentMergeSession(
                    result: result,
                    remoteText: remoteBaseline
                )
            }
        } catch {
            alertMessage = "无法刷新文档：\(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func completeMerge() {
        guard let mergeSession, let finalText = mergeSession.finalText else { return }
        document.text = finalText
        lastKnownDiskText = mergeSession.remoteText
        self.mergeSession = nil
    }

    private func cancelMerge() {
        mergeSession = nil
    }

    private func syncKnownDiskTextIfNeeded() {
        guard fileURL != nil, lastKnownDiskText == nil else { return }
        lastKnownDiskText = document.text
    }

    private func coordinatedDiskText(at fileURL: URL) throws -> String {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var readResult: Result<String, Error>?

        coordinator.coordinate(
            readingItemAt: fileURL,
            options: .withoutChanges,
            error: &coordinationError
        ) { coordinatedURL in
            readResult = Result {
                try String(contentsOf: coordinatedURL, encoding: .utf8)
            }
        }

        if let coordinationError {
            throw coordinationError
        }
        guard let readResult else {
            throw CocoaError(.fileReadUnknown)
        }
        return try readResult.get()
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
