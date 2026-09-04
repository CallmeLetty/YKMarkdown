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

    @MainActor
    private func configure(window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }
        let mode = DocumentOpeningMode.stored(rawValue: documentOpeningMode)
        let windowID = ObjectIdentifier(window)
        let isNewWindow = coordinator.updateWindowIdentity(windowID)
        // 同一个标识的文档窗口才能被 AppKit 自动组合成标签页。
        if isNewWindow || coordinator.configuredMode != mode {
            window.tabbingIdentifier = Self.documentTabbingIdentifier
            window.tabbingMode = mode.tabbingMode
            coordinator.configuredMode = mode
        }

        if mode == .tabs, !coordinator.didAttemptInitialTabbing {
            coordinator.didAttemptInitialTabbing = true
            addToExistingDocumentTabGroup(window)
        }
    }

    @MainActor
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

    @MainActor
    final class Coordinator {
        private(set) var configuredWindowID: ObjectIdentifier?
        var configuredMode: DocumentOpeningMode?
        var didAttemptInitialTabbing = false

        /// 只记录窗口身份，避免在窗口销毁过程中写入 weak NSWindow 触发 ObjC abort。
        func updateWindowIdentity(_ id: ObjectIdentifier) -> Bool {
            guard configuredWindowID != id else { return false }
            configuredWindowID = id
            configuredMode = nil
            didAttemptInitialTabbing = false
            return true
        }
    }

    @MainActor
    final class ConfigurationView: NSView {
        var onWindowChange: (@MainActor (NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindowChange?(window)
        }
    }
}
