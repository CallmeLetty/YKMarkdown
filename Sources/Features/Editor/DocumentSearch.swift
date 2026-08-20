import AppKit
import SwiftUI

/// 搜索范围：当前源码编辑器，或当前进程里已打开的 Markdown 文档。
enum DocumentSearchScope: String, CaseIterable, Identifiable {
    case current
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .current:
            "当前"
        case .all:
            "全部"
        }
    }
}

struct DocumentSearchNavigationRequest: Equatable {
    let token: UUID
    let range: NSRange
}

/// 使用 UTF-16 NSRange 保存命中位置，保持与 NSTextView/TextStorage 的索引体系一致。
struct MarkdownSearchMatch: Identifiable, Equatable {
    let documentID: UUID
    let documentTitle: String
    let fileURL: URL?
    let range: NSRange
    let lineNumber: Int
    let snippet: String

    var id: String {
        Self.id(documentID: documentID, range: range)
    }

    static func id(documentID: UUID, range: NSRange) -> String {
        "\(documentID.uuidString)-\(range.location)-\(range.length)"
    }
}

/// 源码搜索匹配器，负责生成 NSTextView 可直接使用的命中 range 和结果摘要。
enum MarkdownSearch {
    static func ranges(in text: String, query: String) -> [NSRange] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        var searchRange = fullRange
        var ranges: [NSRange] = []

        while searchRange.length > 0 {
            let range = nsText.range(
                of: trimmedQuery,
                options: [.caseInsensitive],
                range: searchRange
            )
            guard range.location != NSNotFound else { break }

            ranges.append(range)
            let nextLocation = range.location + max(range.length, 1)
            searchRange = NSRange(
                location: nextLocation,
                length: max(0, fullRange.length - nextLocation)
            )
        }

        return ranges
    }

    static func matches(
        in text: String,
        query: String,
        documentID: UUID,
        documentTitle: String,
        fileURL: URL?
    ) -> [MarkdownSearchMatch] {
        ranges(in: text, query: query).map {
            MarkdownSearchMatch(
                documentID: documentID,
                documentTitle: documentTitle,
                fileURL: fileURL,
                range: $0,
                lineNumber: lineNumber(in: text, at: $0.location),
                snippet: snippet(in: text, around: $0)
            )
        }
    }

    private static func lineNumber(in text: String, at location: Int) -> Int {
        let nsText = text as NSString
        let safeLocation = min(max(location, 0), nsText.length)
        guard safeLocation > 0 else { return 1 }

        let prefixRange = NSRange(location: 0, length: safeLocation)
        var lineCount = 1
        nsText.enumerateSubstrings(in: prefixRange, options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineCount += 1
        }
        if safeLocation > 0,
           nsText.substring(with: NSRange(location: safeLocation - 1, length: 1)) != "\n" {
            lineCount -= 1
        }
        return max(lineCount, 1)
    }

    private static func snippet(in text: String, around range: NSRange) -> String {
        let nsText = text as NSString
        guard nsText.length > 0 else { return "" }

        let lineRange = nsText.lineRange(for: range)
        let line = nsText.substring(with: lineRange)
            .trimmingCharacters(in: .newlines)
        let lineText = line as NSString
        guard lineText.length > 120 else {
            return line.trimmingCharacters(in: .whitespaces)
        }

        let matchOffsetInLine = min(max(0, range.location - lineRange.location), lineText.length - 1)
        let start = max(0, matchOffsetInLine - 40)
        let snippetRange = NSRange(
            location: start,
            length: min(120, lineText.length - start)
        )
        let snippet = lineText.substring(with: snippetRange)
            .trimmingCharacters(in: .whitespaces)
        let snippetUpperBound = snippetRange.location + snippetRange.length
        return "\(start > 0 ? "..." : "")\(snippet)\(snippetUpperBound < lineText.length ? "..." : "")"
    }
}

@MainActor
final class SearchDocumentWindowBox: ObservableObject {
    weak var window: NSWindow?
}

/// 已打开文档在全局搜索注册表中的快照和跳转入口。
struct OpenSearchDocument: Identifiable {
    let id: UUID
    var title: String
    var fileURL: URL?
    var text: String
    var windowBox: SearchDocumentWindowBox
    var navigateToMatch: @MainActor (_ query: String, _ range: NSRange, _ scope: DocumentSearchScope) -> Void
}

/// 维护当前 App 进程中仍打开的 Markdown 文档，用于 Cmd+Shift+F 全部搜索。
@MainActor
final class OpenDocumentSearchRegistry: ObservableObject {
    static let shared = OpenDocumentSearchRegistry()

    @Published private(set) var documents: [OpenSearchDocument] = []
    private var documentsByID: [UUID: OpenSearchDocument] = [:]

    private init() {}

    func upsert(
        id: UUID,
        title: String,
        fileURL: URL?,
        text: String,
        windowBox: SearchDocumentWindowBox,
        navigateToMatch: @escaping @MainActor (_ query: String, _ range: NSRange, _ scope: DocumentSearchScope) -> Void
    ) {
        documentsByID[id] = OpenSearchDocument(
            id: id,
            title: title,
            fileURL: fileURL,
            text: text,
            windowBox: windowBox,
            navigateToMatch: navigateToMatch
        )
        refreshDocuments()
    }

    func unregister(id: UUID) {
        documentsByID[id] = nil
        refreshDocuments()
    }

    func matches(scope: DocumentSearchScope, activeDocumentID: UUID, query: String) -> [MarkdownSearchMatch] {
        let sourceDocuments: [OpenSearchDocument]
        switch scope {
        case .current:
            sourceDocuments = documentsByID[activeDocumentID].map { [$0] } ?? []
        case .all:
            sourceDocuments = documents.sorted {
                if $0.id == activeDocumentID { return true }
                if $1.id == activeDocumentID { return false }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }

        return sourceDocuments.flatMap {
            MarkdownSearch.matches(
                in: $0.text,
                query: query,
                documentID: $0.id,
                documentTitle: $0.title,
                fileURL: $0.fileURL
            )
        }
    }

    func navigate(to match: MarkdownSearchMatch, query: String, scope: DocumentSearchScope) {
        guard let document = documentsByID[match.documentID] else { return }
        document.windowBox.window?.makeKeyAndOrderFront(nil)
        document.navigateToMatch(query, match.range, scope)
    }

    private func refreshDocuments() {
        documents = documentsByID.values.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }
}

/// 读取 SwiftUI 文档视图所在窗口，并在真实窗口关闭时注销搜索索引。
struct DocumentSearchWindowReader: NSViewRepresentable {
    let onWindowChange: @MainActor (NSWindow?) -> Void
    let onWindowClose: @MainActor () -> Void

    func makeNSView(context: Context) -> WindowReaderView {
        let view = WindowReaderView()
        view.onWindowChange = onWindowChange
        view.onWindowClose = onWindowClose
        return view
    }

    func updateNSView(_ view: WindowReaderView, context: Context) {
        view.onWindowChange = onWindowChange
        view.onWindowClose = onWindowClose
        view.reportWindow()
    }

    @MainActor
    final class WindowReaderView: NSView {
        var onWindowChange: (@MainActor (NSWindow?) -> Void)?
        var onWindowClose: (@MainActor () -> Void)?
        private weak var observedWindow: NSWindow?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateWindowObservation()
            reportWindow()
        }

        deinit {
            if let observedWindow {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.willCloseNotification,
                    object: observedWindow
                )
            }
        }

        func reportWindow() {
            onWindowChange?(window)
        }

        private func updateWindowObservation() {
            if let observedWindow {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.willCloseNotification,
                    object: observedWindow
                )
            }
            observedWindow = window
            if let window {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(windowWillClose),
                    name: NSWindow.willCloseNotification,
                    object: window
                )
            }
        }

        @objc private func windowWillClose() {
            onWindowClose?()
        }
    }
}
