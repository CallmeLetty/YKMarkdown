import AppKit
import SwiftUI

/// 控制新建或打开 Markdown 文档时优先进入标签页还是独立窗口。
enum DocumentOpeningMode: String, CaseIterable, Identifiable {
    case tabs
    case windows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tabs:
            "同一窗口标签页"
        case .windows:
            "独立文档窗口"
        }
    }

    var note: String {
        switch self {
        case .tabs:
            "新建或打开 Markdown 时优先进入同一个标签页窗口，标签页可从标签栏拖出成独立窗口。"
        case .windows:
            "新建或打开 Markdown 时优先使用独立窗口。"
        }
    }

    var tabbingMode: NSWindow.TabbingMode {
        switch self {
        case .tabs:
            .preferred
        case .windows:
            .disallowed
        }
    }

    static func stored(rawValue: String) -> DocumentOpeningMode {
        DocumentOpeningMode(rawValue: rawValue) ?? .tabs
    }
}

struct DocumentWindowConfigurator: NSViewRepresentable {
    private static let documentTabbingIdentifier = "com.yakamoz.YKMarkdown.document"

    @AppStorage("documentOpeningMode") private var documentOpeningMode = DocumentOpeningMode.tabs.rawValue

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> ConfigurationView {
        let view = ConfigurationView()
        view.onWindowChange = {
            configure(window: $0, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ view: ConfigurationView, context: Context) {
        view.onWindowChange = {
            configure(window: $0, coordinator: context.coordinator)
        }
        configure(window: view.window, coordinator: context.coordinator)
    }

    private func configure(window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }
        let mode = DocumentOpeningMode.stored(rawValue: documentOpeningMode)
        // 同一个标识的文档窗口才能被 AppKit 自动组合成标签页。
        window.tabbingIdentifier = Self.documentTabbingIdentifier
        window.tabbingMode = mode.tabbingMode

        if coordinator.window !== window {
            coordinator.window = window
            coordinator.didAttemptInitialTabbing = false
        }

        if mode == .tabs, !coordinator.didAttemptInitialTabbing {
            coordinator.didAttemptInitialTabbing = true
            addToExistingDocumentTabGroup(window)
        }
    }

    private func addToExistingDocumentTabGroup(_ window: NSWindow) {
        guard let targetWindow = NSApp.windows.first(where: {
            $0 !== window
                && $0.tabbingIdentifier == Self.documentTabbingIdentifier
                && $0.tabbingMode != .disallowed
                && $0.tabGroup?.windows.contains(where: { $0 === window }) != true
        }) else {
            return
        }

        targetWindow.addTabbedWindow(window, ordered: .above)
    }

    final class Coordinator {
        weak var window: NSWindow?
        var didAttemptInitialTabbing = false
    }

    final class ConfigurationView: NSView {
        var onWindowChange: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChange?(window)
        }
    }
}
