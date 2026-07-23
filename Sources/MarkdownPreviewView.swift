import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    var onMarkdownChange: (String) -> Void
    var onPasteImages: () -> Void
    var onDropImages: ([URL]) -> Void
    var insertImageRequest: InsertImageRequest?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> PreviewWKWebView {
        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "bridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContent
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = PreviewWKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        let coordinator = context.coordinator
        webView.onFileURLsDropped = { [weak coordinator] urls in
            coordinator?.parent.onDropImages(urls)
        }

        context.coordinator.webView = webView
        context.coordinator.loadInitialPage(in: webView)
        return webView
    }

    func updateNSView(_ webView: PreviewWKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.webView = webView

        if context.coordinator.baseURL != baseURL {
            context.coordinator.baseURL = baseURL
            context.coordinator.loadInitialPage(in: webView)
            return
        }

        context.coordinator.applyMarkdownFromSourceIfNeeded(markdown)

        if let request = insertImageRequest,
           context.coordinator.lastInsertToken != request.token {
            context.coordinator.lastInsertToken = request.token
            context.coordinator.insertImage(path: request.relativePath, alt: request.altText)
        }
    }

    struct InsertImageRequest: Equatable {
        let token: UUID
        let relativePath: String
        let altText: String
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: MarkdownPreviewView
        weak var webView: PreviewWKWebView?
        var baseURL: URL?
        var lastAppliedMarkdown = ""
        var lastInsertToken: UUID?
        private var isPageReady = false
        private var isUpdatingFromPreview = false
        private var pendingBodyHTML: String?

        init(parent: MarkdownPreviewView) {
            self.parent = parent
            self.baseURL = parent.baseURL
        }

        func loadInitialPage(in webView: WKWebView) {
            isPageReady = false
            lastAppliedMarkdown = parent.markdown
            let body = MarkdownHTMLRenderer.bodyHTML(from: parent.markdown)
            let html = MarkdownHTMLRenderer.editableDocument(
                bodyHTML: body,
                turndownScript: Self.turndownScript
            )
            let loadBase = parent.baseURL?.deletingLastPathComponent()
                ?? Bundle.main.resourceURL
            webView.loadHTMLString(html, baseURL: loadBase)
        }

        func applyMarkdownFromSourceIfNeeded(_ markdown: String) {
            guard !isUpdatingFromPreview else { return }
            guard markdown != lastAppliedMarkdown else { return }
            lastAppliedMarkdown = markdown
            let body = MarkdownHTMLRenderer.bodyHTML(from: markdown)
            guard isPageReady else {
                pendingBodyHTML = body
                return
            }
            setBodyHTML(body)
        }

        func insertImage(path: String, alt: String) {
            guard isPageReady, let webView else { return }
            let script = "window.insertImageAtCaret(\(Self.jsString(path)), \(Self.jsString(alt)));"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "bridge",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String
            else { return }

            switch type {
            case "markdownChanged":
                guard let markdown = body["markdown"] as? String else { return }
                let normalized = Self.normalizeMarkdown(markdown)
                guard normalized != lastAppliedMarkdown else { return }
                isUpdatingFromPreview = true
                lastAppliedMarkdown = normalized
                parent.onMarkdownChange(normalized)
                isUpdatingFromPreview = false

            case "pasteImages":
                parent.onPasteImages()

            case "requestDropImport":
                // Native drag handler on PreviewWKWebView performs the import.
                break

            case "openURL":
                if let urlString = body["url"] as? String, let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }

            default:
                break
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageReady = true
            if let pendingBodyHTML {
                setBodyHTML(pendingBodyHTML)
                self.pendingBodyHTML = nil
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        private func setBodyHTML(_ html: String) {
            guard let webView else { return }
            let script = "window.setBodyHTML(\(Self.jsString(html)));"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        private static func normalizeMarkdown(_ markdown: String) -> String {
            var value = markdown.replacingOccurrences(of: "\r\n", with: "\n")
            while value.hasSuffix("\n\n") {
                value.removeLast()
            }
            if !value.isEmpty, !value.hasSuffix("\n") {
                value.append("\n")
            }
            return value
        }

        private static func jsString(_ value: String) -> String {
            let escaped = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
            return "'\(escaped)'"
        }

        private static let turndownScript = TurndownScript.source
    }
}

final class PreviewWKWebView: WKWebView {
    var onFileURLsDropped: (([URL]) -> Void)?

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let urls = Self.imageURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else {
            return super.performDragOperation(sender)
        }
        onFileURLsDropped?(urls)
        return true
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if Self.imageURLs(from: sender.draggingPasteboard).isEmpty {
            return super.draggingEntered(sender)
        }
        return .copy
    }

    private static func imageURLs(from pasteboard: NSPasteboard) -> [URL] {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] else { return [] }

        return urls.filter { url in
            if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                return type.conforms(to: .image)
            }
            return false
        }
    }
}
