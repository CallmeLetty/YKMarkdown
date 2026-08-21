import AppKit
import SwiftUI

struct DocumentMergeConflictView: View {
    @ObservedObject var session: DocumentMergeSession
    let fontSize: Double
    let onCancel: () -> Void
    let onComplete: () -> Void

    @FocusState private var keyboardFocusedConflictID: UUID?
    @AccessibilityFocusState private var accessibilityFocusedConflictID: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                navigationBar(proxy: proxy)
                Divider()
                ScrollView([.vertical, .horizontal]) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(session.segments) { segment in
                            segmentView(segment)
                                .id(segment.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
            .onAppear {
                focus(session.focusedConflictID, proxy: proxy, animated: false)
            }
            .onChange(of: session.focusedConflictID) { _, id in
                focus(id, proxy: proxy, animated: true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("文档冲突解决，剩余 \(session.unresolvedCount) 个冲突")
    }

    private func navigationBar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 10) {
            Image(systemName: session.isComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(session.isComplete ? .green : .orange)

            Text(session.isComplete ? "所有冲突已解决" : "还有 \(session.unresolvedCount) 个冲突未解决")
                .font(.system(size: 13, weight: .semibold))

            Spacer(minLength: 12)

            Button("下一个冲突") {
                session.focusNextConflict()
                focus(session.focusedConflictID, proxy: proxy, animated: true)
            }
            .disabled(session.unresolvedCount == 0)
            .keyboardShortcut("g", modifiers: [.command, .option])
            .help("跳到下一个未解决冲突（⌥⌘G）")

            Button("取消合并", role: .cancel, action: onCancel)

            Button("完成合并", action: onComplete)
                .buttonStyle(.borderedProminent)
                .disabled(!session.isComplete)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private func segmentView(_ segment: DocumentMergeSessionSegment) -> some View {
        switch segment.content {
        case let .resolved(text):
            sourceText(text)
        case let .conflict(conflict):
            conflictView(segment: segment, conflict: conflict)
                .focusable()
                .focused($keyboardFocusedConflictID, equals: segment.id)
                .accessibilityFocused($accessibilityFocusedConflictID, equals: segment.id)
        }
    }

    private func sourceText(_ text: String) -> some View {
        Text(verbatim: text.isEmpty ? " " : text)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(Color(nsColor: .textColor))
            .textSelection(.enabled)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func conflictView(
        segment: DocumentMergeSessionSegment,
        conflict: DocumentMergeConflict
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(
                    segment.isUnresolved ? "未解决冲突" : "已解决冲突",
                    systemImage: segment.isUnresolved ? "exclamationmark.triangle" : "checkmark.circle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(segment.isUnresolved ? .orange : .secondary)

                Spacer()

                if segment.resolutionText != nil, segment.manualDraft == nil {
                    Button("重新选择") {
                        session.reopen(segment.id)
                    }
                    .buttonStyle(.link)
                }
            }

            if let draft = segment.manualDraft {
                manualEditor(segmentID: segment.id, text: draft)
            } else if let resolutionText = segment.resolutionText {
                resolvedEditor(segmentID: segment.id, text: resolutionText)
            } else {
                candidate(
                    title: "YKMarkdown 当前内容",
                    text: conflict.localText,
                    changedRanges: conflict.localChangedRanges,
                    color: .systemRed
                )
                candidate(
                    title: "磁盘最新内容",
                    text: conflict.remoteText,
                    changedRanges: conflict.remoteChangedRanges,
                    color: .systemGreen
                )

                HStack(spacing: 8) {
                    Button("保留当前") {
                        session.resolve(segment.id, using: .local)
                    }
                    Button("使用外部") {
                        session.resolve(segment.id, using: .remote)
                    }
                    Button("两者保留") {
                        session.resolve(segment.id, using: .both)
                    }
                    Button("手动编辑") {
                        session.beginManualEditing(segment.id)
                    }
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    segment.id == session.focusedConflictID
                        ? Color.accentColor
                        : Color(nsColor: .separatorColor),
                    lineWidth: segment.id == session.focusedConflictID ? 2 : 1
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(segment.isUnresolved ? "未解决冲突" : "已解决冲突")
    }

    private func candidate(
        title: String,
        text: String,
        changedRanges: [NSRange],
        color: NSColor
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(attributedText(text, changedRanges: changedRanges, color: color))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: color).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func manualEditor(segmentID: UUID, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手动编辑最终内容")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextEditor(text: Binding(
                get: { text },
                set: { session.updateManualDraft($0, for: segmentID) }
            ))
            .font(.system(size: fontSize, design: .monospaced))
            .frame(minWidth: 420, minHeight: 110)
            .scrollContentBackground(.hidden)
            .padding(5)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor))
            }

            HStack {
                Button("取消编辑") {
                    session.cancelManualEditing(segmentID)
                }
                Button("完成此处") {
                    session.finishManualEditing(segmentID)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
    }

    private func resolvedEditor(segmentID: UUID, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("最终内容")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            TextEditor(text: Binding(
                get: { text },
                set: { session.updateResolvedText($0, for: segmentID) }
            ))
            .font(.system(size: fontSize, design: .monospaced))
            .frame(minWidth: 420, minHeight: 90)
            .scrollContentBackground(.hidden)
            .padding(5)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }

    private func attributedText(
        _ text: String,
        changedRanges: [NSRange],
        color: NSColor
    ) -> AttributedString {
        let displayText = text.isEmpty ? "（空内容）" : text
        let attributed = NSMutableAttributedString(
            string: displayText,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                .foregroundColor: NSColor.textColor
            ]
        )
        guard !text.isEmpty else { return AttributedString(attributed) }

        let fullLength = (text as NSString).length
        for range in changedRanges where range.location != NSNotFound && NSMaxRange(range) <= fullLength {
            attributed.addAttribute(
                .backgroundColor,
                value: color.withAlphaComponent(0.28),
                range: range
            )
        }
        return AttributedString(attributed)
    }

    private func focus(_ id: UUID?, proxy: ScrollViewProxy, animated: Bool) {
        guard let id else { return }
        let update = {
            proxy.scrollTo(id, anchor: .center)
            keyboardFocusedConflictID = id
            accessibilityFocusedConflictID = id
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.2), update)
        } else {
            update()
        }
    }
}

#Preview("Document Merge Conflicts") {
    DocumentMergeConflictPreview()
        .frame(width: 820, height: 620)
}

@MainActor
private struct DocumentMergeConflictPreview: View {
    @StateObject private var session: DocumentMergeSession

    init() {
        let result = DocumentThreeWayMerge.merge(
            base: "# Layout\n\nVStack(spacing: 5) {\n    HStack(spacing: 7) {\n",
            local: "# Layout\n\nVStack(spacing: 6) {\n    HStack(spacing: 8) {\n",
            remote: "# Layout\n\nVStack(spacing: 4) {\n    HStack(spacing: 6) {\n"
        )
        _session = StateObject(wrappedValue: DocumentMergeSession(
            result: result,
            originalLocalText: "",
            remoteText: ""
        ))
    }

    var body: some View {
        DocumentMergeConflictView(
            session: session,
            fontSize: 14,
            onCancel: {},
            onComplete: {}
        )
    }
}
