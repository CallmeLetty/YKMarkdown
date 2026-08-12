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
    let canReloadDocument: Bool
    let onReloadDocument: () -> Void

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
        // 同一个标识的文档窗口才能被 AppKit 自动组合成标签页。
        window.tabbingIdentifier = Self.documentTabbingIdentifier
        window.tabbingMode = mode.tabbingMode
        coordinator.reloadAction = onReloadDocument

        if coordinator.window !== window {
            coordinator.removeTitlebarAccessory()
            coordinator.window = window
            coordinator.didAttemptInitialTabbing = false
        }

        coordinator.updateTitlebarAccessory(canReloadDocument: canReloadDocument)

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
        weak var window: NSWindow?
        var didAttemptInitialTabbing = false
        var reloadAction: (() -> Void)?
        private var reloadAccessory: NSTitlebarAccessoryViewController?

        func updateTitlebarAccessory(canReloadDocument: Bool) {
            guard let window else { return }

            let accessory: NSTitlebarAccessoryViewController
            if let reloadAccessory {
                accessory = reloadAccessory
            } else {
                accessory = NSTitlebarAccessoryViewController()
                accessory.layoutAttribute = .right
                accessory.view = ReloadDocumentTitlebarButton(target: self)
                window.addTitlebarAccessoryViewController(accessory)
                reloadAccessory = accessory
            }

            accessory.view.isHidden = !canReloadDocument
            if let button = accessory.view as? NSButton {
                button.isEnabled = canReloadDocument
            }
        }

        func removeTitlebarAccessory() {
            guard let reloadAccessory else { return }
            if let window,
               let index = window.titlebarAccessoryViewControllers.firstIndex(of: reloadAccessory) {
                window.removeTitlebarAccessoryViewController(at: index)
            }
            self.reloadAccessory = nil
        }

        @objc func reloadCurrentDocument() {
            reloadAction?()
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

@MainActor
private final class ReloadDocumentTitlebarButton: NSButton {
    init(target: AnyObject) {
        super.init(frame: NSRect(x: 0, y: 0, width: 28, height: 28))
        self.target = target
        action = #selector(DocumentWindowConfigurator.Coordinator.reloadCurrentDocument)
        bezelStyle = .texturedRounded
        setButtonType(.momentaryPushIn)
        image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "重载当前文档")
        imagePosition = .imageOnly
        isBordered = false
        toolTip = "从磁盘重新载入当前文档"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
