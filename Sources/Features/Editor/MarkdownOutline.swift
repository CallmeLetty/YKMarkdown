import AppKit
import SwiftUI

struct TwoPaneSplitView<Leading: View, Trailing: View>: View {
    let isLeadingVisible: Bool
    let initialLeadingFraction: CGFloat
    let minimumWidths: (leading: CGFloat, trailing: CGFloat)
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    @State private var leadingFraction: CGFloat
    @State private var dragStartFraction: CGFloat?

    init(
        isLeadingVisible: Bool,
        initialLeadingFraction: CGFloat,
        minimumWidths: (leading: CGFloat, trailing: CGFloat),
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.isLeadingVisible = isLeadingVisible
        self.initialLeadingFraction = initialLeadingFraction
        self.minimumWidths = minimumWidths
        self.leading = leading
        self.trailing = trailing
        _leadingFraction = State(initialValue: initialLeadingFraction)
    }

    var body: some View {
        GeometryReader { geometry in
            let dividerWidth = isLeadingVisible ? SplitDivider.width : 0
            let availableWidth = max(geometry.size.width - dividerWidth, 1)
            let leadingWidth = isLeadingVisible ? resolvedLeadingWidth(in: availableWidth) : 0

            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth)
                    .clipped()
                    .opacity(isLeadingVisible ? 1 : 0)
                    .offset(x: isLeadingVisible ? 0 : -18)

                SplitDivider {
                    dragStartFraction = dragStartFraction ?? leadingFraction
                    let proposed = (dragStartFraction ?? leadingFraction) + $0 / availableWidth
                    leadingFraction = clampedLeadingFraction(proposed, in: availableWidth)
                } onEnded: {
                    dragStartFraction = nil
                }
                .frame(width: dividerWidth)
                .opacity(isLeadingVisible ? 1 : 0)
                .allowsHitTesting(isLeadingVisible)

                trailing()
                    .frame(width: availableWidth - leadingWidth)
                    .clipped()
            }
            .animation(.easeInOut(duration: 0.15), value: isLeadingVisible)
        }
    }

    private func resolvedLeadingWidth(in availableWidth: CGFloat) -> CGFloat {
        clampedLeadingFraction(leadingFraction, in: availableWidth) * availableWidth
    }

    private func clampedLeadingFraction(_ proposed: CGFloat, in availableWidth: CGFloat) -> CGFloat {
        let minimum = min(minimumWidths.leading / availableWidth, 0.5)
        let maximum = max(1 - minimumWidths.trailing / availableWidth, 0.5)
        return min(max(proposed, minimum), maximum)
    }
}

struct ThreePaneSplitView<Leading: View, Middle: View, Trailing: View>: View {
    let isLeadingVisible: Bool
    let initialFractions: (leading: CGFloat, middle: CGFloat)
    let minimumWidths: (leading: CGFloat, middle: CGFloat, trailing: CGFloat)
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let middle: () -> Middle
    @ViewBuilder let trailing: () -> Trailing

    @State private var leadingFraction: CGFloat
    @State private var trailingStartFraction: CGFloat
    @State private var firstDragStart: CGFloat?
    @State private var secondDragStart: CGFloat?

    init(
        isLeadingVisible: Bool,
        initialFractions: (leading: CGFloat, middle: CGFloat),
        minimumWidths: (leading: CGFloat, middle: CGFloat, trailing: CGFloat),
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder middle: @escaping () -> Middle,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.isLeadingVisible = isLeadingVisible
        self.initialFractions = initialFractions
        self.minimumWidths = minimumWidths
        self.leading = leading
        self.middle = middle
        self.trailing = trailing
        _leadingFraction = State(initialValue: initialFractions.leading)
        _trailingStartFraction = State(initialValue: initialFractions.leading + initialFractions.middle)
    }

    var body: some View {
        GeometryReader { geometry in
            let leadingDividerWidth = isLeadingVisible ? SplitDivider.width : 0
            let availableWidth = max(
                geometry.size.width - SplitDivider.width - leadingDividerWidth,
                1
            )
            let boundaries = resolvedBoundaries(in: availableWidth)
            let leadingWidth = isLeadingVisible ? boundaries.leading * availableWidth : 0
            let middleWidth = isLeadingVisible
                ? (boundaries.trailingStart - boundaries.leading) * availableWidth
                : availableWidth * 0.5
            let trailingWidth = availableWidth - leadingWidth - middleWidth

            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth)
                    .clipped()
                    .opacity(isLeadingVisible ? 1 : 0)
                    .offset(x: isLeadingVisible ? 0 : -18)

                SplitDivider {
                    firstDragStart = firstDragStart ?? leadingFraction
                    let proposed = (firstDragStart ?? leadingFraction) + $0 / availableWidth
                    leadingFraction = clampedLeadingBoundary(
                        proposed,
                        trailingStart: boundaries.trailingStart,
                        availableWidth: availableWidth
                    )
                } onEnded: {
                    firstDragStart = nil
                }
                .frame(width: leadingDividerWidth)
                .opacity(isLeadingVisible ? 1 : 0)
                .allowsHitTesting(isLeadingVisible)

                middle()
                    .frame(width: middleWidth)
                    .clipped()

                SplitDivider {
                    secondDragStart = secondDragStart ?? trailingStartFraction
                    let proposed = (secondDragStart ?? trailingStartFraction) + $0 / availableWidth
                    trailingStartFraction = clampedTrailingBoundary(
                        proposed,
                        leading: boundaries.leading,
                        availableWidth: availableWidth
                    )
                } onEnded: {
                    secondDragStart = nil
                }

                trailing()
                    .frame(width: trailingWidth)
                    .clipped()
            }
            .animation(.easeInOut(duration: 0.15), value: isLeadingVisible)
        }
    }

    private func resolvedBoundaries(in availableWidth: CGFloat) -> (leading: CGFloat, trailingStart: CGFloat) {
        let resolvedLeading = clampedLeadingBoundary(
            leadingFraction,
            trailingStart: trailingStartFraction,
            availableWidth: availableWidth
        )
        let resolvedTrailing = clampedTrailingBoundary(
            trailingStartFraction,
            leading: resolvedLeading,
            availableWidth: availableWidth
        )
        return (resolvedLeading, resolvedTrailing)
    }

    private func clampedLeadingBoundary(
        _ proposed: CGFloat,
        trailingStart: CGFloat,
        availableWidth: CGFloat
    ) -> CGFloat {
        let minimum = minimumWidths.leading / availableWidth
        let maximum = trailingStart - minimumWidths.middle / availableWidth
        return min(max(proposed, minimum), maximum)
    }

    private func clampedTrailingBoundary(
        _ proposed: CGFloat,
        leading: CGFloat,
        availableWidth: CGFloat
    ) -> CGFloat {
        let minimum = leading + minimumWidths.middle / availableWidth
        let maximum = 1 - minimumWidths.trailing / availableWidth
        return min(max(proposed, minimum), maximum)
    }
}

private struct SplitDivider: View {
    static let width: CGFloat = 7

    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack {
            Color.clear
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)
        }
        .frame(width: Self.width)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .background(isHovering ? Color.primary.opacity(0.035) : Color.clear)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { onChanged($0.translation.width) }
                .onEnded { _ in onEnded() }
        )
    }
}

struct MarkdownHeading: Equatable, Identifiable {
    let id: String
    let level: Int
    let title: String
    let sourceRange: NSRange
}

struct HeadingNavigationRequest: Equatable {
    let token: UUID
    let heading: MarkdownHeading
}

enum MarkdownOutlineParser {
    static func headings(in markdown: String) -> [MarkdownHeading] {
        let source = markdown as NSString
        var result: [MarkdownHeading] = []
        var location = 0
        var isInsideCodeFence = false

        while location < source.length {
            let lineRange = source.lineRange(for: NSRange(location: location, length: 0))
            let contentRange = lineContentRange(lineRange, in: source)
            let line = source.substring(with: contentRange)

            if line.hasPrefix("```") {
                isInsideCodeFence.toggle()
            } else if !isInsideCodeFence,
                      let parsed = parseHeading(line.trimmingCharacters(in: .whitespaces)) {
                result.append(
                    MarkdownHeading(
                        id: "yk-heading-\(result.count)",
                        level: parsed.level,
                        title: displayTitle(from: parsed.title),
                        sourceRange: contentRange
                    )
                )
            }

            location = NSMaxRange(lineRange)
        }

        return result
    }

    private static func lineContentRange(_ lineRange: NSRange, in source: NSString) -> NSRange {
        var length = lineRange.length
        while length > 0 {
            let character = source.character(at: lineRange.location + length - 1)
            guard character == 10 || character == 13 else { break }
            length -= 1
        }
        return NSRange(location: lineRange.location, length: length)
    }

    private static func parseHeading(_ line: String) -> (level: Int, title: String)? {
        guard line.hasPrefix("#") else { return nil }
        let level = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(level) else { return nil }

        let remainder = line.dropFirst(level)
        guard remainder.isEmpty || remainder.first == " " else { return nil }
        let title = remainder.trimmingCharacters(in: .whitespaces)
        return (level, title.isEmpty ? "未命名标题" : title)
    }

    private static func displayTitle(from title: String) -> String {
        var result = title
        let replacements: [(String, String)] = [
            (#"!\[([^\]]*)\]\([^)]*\)"#, "$1"),
            (#"\[([^\]]+)\]\([^)]*\)"#, "$1"),
            (#"[`*_~]+"#, "")
        ]

        for (pattern, template) in replacements {
            guard let expression = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = expression.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: template
            )
        }
        return result.isEmpty ? "未命名标题" : result
    }
}

struct MarkdownOutlineSidebar: View {
    let headings: [MarkdownHeading]
    let activeHeadingID: String?
    let accentColor: Color
    let onSelect: (MarkdownHeading) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Label("目录", systemImage: "list.bullet.indent")
                    .font(.headline)
                Spacer(minLength: 4)
                Button(action: onClose) {
                    Image(systemName: "sidebar.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("收起目录")
                .accessibilityLabel("收起目录")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if headings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.title2)
                    Text("暂无标题")
                        .font(.callout.weight(.medium))
                    Text("使用 # 到 ###### 创建目录")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(headings) { heading in
                                Button {
                                    onSelect(heading)
                                } label: {
                                    Text(heading.title)
                                        .font(.system(size: fontSize(for: heading.level), weight: fontWeight(for: heading.level)))
                                        .foregroundStyle(activeHeadingID == heading.id ? accentColor : Color.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, CGFloat(heading.level - 1) * 13)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 6)
                                        .background {
                                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .fill(activeHeadingID == heading.id ? accentColor.opacity(0.12) : Color.clear)
                                        }
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .id(heading.id)
                                .accessibilityLabel("\(heading.level) 级标题，\(heading.title)")
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: activeHeadingID) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func fontSize(for level: Int) -> CGFloat {
        level <= 2 ? 13 : 12
    }

    private func fontWeight(for level: Int) -> Font.Weight {
        level <= 2 ? .semibold : .regular
    }
}

struct MarkdownScrollSyncRequest: Equatable {
    let token: UUID
    let sourceOffset: Int
}

struct MarkdownSourceEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    let headings: [MarkdownHeading]
    let scrollAnchorOffsets: [Int]
    let navigationRequest: HeadingNavigationRequest?
    let scrollSyncRequest: MarkdownScrollSyncRequest?
    let searchQuery: String
    let selectedSearchRange: NSRange?
    let searchNavigationRequest: DocumentSearchNavigationRequest?
    let onActiveHeadingChange: (String?) -> Void
    let onScrollAnchorChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.contentView.postsBoundsChangedNotifications = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.startObservingScroll()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView else { return }

        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.string != text {
            let selection = textView.selectedRange()
            textView.string = text
            let textLength = (text as NSString).length
            let selectionLocation = min(selection.location, textLength)
            let selectionLength = min(selection.length, textLength - selectionLocation)
            textView.setSelectedRange(NSRange(location: selectionLocation, length: selectionLength))
        }
        context.coordinator.applySearchHighlights(query: searchQuery, selectedRange: selectedSearchRange)

        if let request = navigationRequest,
           context.coordinator.lastNavigationToken != request.token {
            context.coordinator.lastNavigationToken = request.token
            context.coordinator.scroll(toSourceOffset: request.heading.sourceRange.location)
            onActiveHeadingChange(request.heading.id)
        }

        if let request = scrollSyncRequest,
           context.coordinator.lastScrollSyncToken != request.token {
            context.coordinator.lastScrollSyncToken = request.token
            context.coordinator.scroll(toSourceOffset: request.sourceOffset)
        }

        if let request = searchNavigationRequest,
           context.coordinator.lastSearchNavigationToken != request.token {
            context.coordinator.lastSearchNavigationToken = request.token
            context.coordinator.navigateToSearchRange(request.range)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownSourceEditor
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var lastNavigationToken: UUID?
        var lastScrollSyncToken: UUID?
        var lastSearchNavigationToken: UUID?
        private var isApplyingSyncedScroll = false
        private var lastReportedScrollAnchor: Int?

        init(parent: MarkdownSourceEditor) {
            self.parent = parent
        }

        func startObservingScroll() {
            guard let scrollView else { return }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(scrollBoundsDidChange),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }

        @objc private func scrollBoundsDidChange() {
            reportActiveHeading()
            reportScrollAnchor()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            parent.text = textView.string
        }

        func scroll(toSourceOffset sourceOffset: Int) {
            guard let textView,
                  let scrollView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer
            else { return }

            let textLength = (textView.string as NSString).length
            guard textLength > 0 else {
                scrollView.contentView.scroll(to: .zero)
                return
            }

            let location = min(max(sourceOffset, 0), textLength - 1)
            let characterRange = NSRange(location: location, length: 1)
            layoutManager.ensureLayout(forCharacterRange: characterRange)
            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: characterRange,
                actualCharacterRange: nil
            )
            let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            isApplyingSyncedScroll = true
            lastReportedScrollAnchor = sourceOffset
            scrollView.contentView.scroll(
                to: NSPoint(x: scrollView.contentView.bounds.minX, y: max(0, glyphRect.minY))
            )
            scrollView.reflectScrolledClipView(scrollView.contentView)
            DispatchQueue.main.async { [weak self] in
                self?.isApplyingSyncedScroll = false
            }
        }

        func applySearchHighlights(query: String, selectedRange: NSRange?) {
            guard let textView,
                  let layoutManager = textView.layoutManager
            else { return }

            let textLength = (textView.string as NSString).length
            guard textLength > 0 else { return }

            let fullRange = NSRange(location: 0, length: textLength)
            layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)

            let ranges = MarkdownSearch.ranges(in: textView.string, query: query)
            guard !ranges.isEmpty else { return }

            let highlightColor = NSColor.controlAccentColor.withAlphaComponent(0.35)
            let selectedColor = NSColor.systemYellow.withAlphaComponent(0.35)
            for range in ranges {
                let color = selectedRange == range ? selectedColor : highlightColor
                layoutManager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
            }
        }

        func navigateToSearchRange(_ range: NSRange) {
            guard let textView else { return }
            let textLength = (textView.string as NSString).length
            guard textLength > 0, range.location != NSNotFound else { return }

            let safeLocation = min(range.location, textLength - 1)
            let safeLength = min(range.length, textLength - safeLocation)
            let safeRange = NSRange(location: safeLocation, length: safeLength)
            textView.setSelectedRange(safeRange)
            textView.scrollRangeToVisible(safeRange)
        }

        private func reportActiveHeading() {
            guard let characterIndex = visibleCharacterIndex() else { return }
            let active = parent.headings.last { $0.sourceRange.location <= characterIndex }
                ?? parent.headings.first
            parent.onActiveHeadingChange(active?.id)
        }

        private func reportScrollAnchor() {
            guard !isApplyingSyncedScroll,
                  let characterIndex = visibleCharacterIndex(),
                  let sourceOffset = parent.scrollAnchorOffsets.last(where: { $0 <= characterIndex })
                    ?? parent.scrollAnchorOffsets.first,
                  sourceOffset != lastReportedScrollAnchor
            else { return }

            lastReportedScrollAnchor = sourceOffset
            parent.onScrollAnchorChange(sourceOffset)
        }

        private func visibleCharacterIndex() -> Int? {
            guard let textView,
                  let scrollView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer
            else { return nil }

            let visibleTop = scrollView.contentView.bounds.minY + textView.textContainerInset.height
            let glyphIndex = layoutManager.glyphIndex(
                for: NSPoint(x: textView.textContainerInset.width, y: visibleTop),
                in: textContainer
            )
            return layoutManager.characterIndexForGlyph(at: glyphIndex)
        }
    }
}
