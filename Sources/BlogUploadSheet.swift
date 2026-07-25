import AppKit
import SwiftUI

struct BlogUploadSheet: View {
    let markdown: String
    let fileURL: URL?
    let settings: BlogUploadSettings
    let onFinished: (GitHubBlogUploader.UploadResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var date: String = BlogFrontmatter.todayString()
    @State private var selectedTags: [String] = []
    @State private var availableTags: [String] = []
    @State private var isLoadingTags = false
    @State private var excerpt: String = ""
    @State private var slug: String = ""
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("上传到 Yakamoz Blog")
                .font(.title2.weight(.semibold))

            Text("目标：\(settings.repositoryFullName)/\(settings.contentDirectory)/\(displaySlug).md")
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Form {
                TextField("标题", text: $title)
                TextField("日期 (yyyy-MM-dd)", text: $date)
                BlogTagPicker(
                    selectedTags: $selectedTags,
                    availableTags: availableTags,
                    isLoading: isLoadingTags
                )
                TextField("摘要 excerpt", text: $excerpt)
                TextField("文件名 slug", text: $slug)
                    .onChange(of: title) { _, newValue in
                        if slugIsDerivedFromTitle {
                            slug = BlogSlug.make(from: newValue)
                        }
                    }
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    Task { await upload() }
                } label: {
                    if isUploading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                        Text("上传中…")
                    } else {
                        Text("上传")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isUploading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear(perform: prefill)
        .task { await loadExistingTags() }
    }

    private var displaySlug: String {
        let value = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "…" : value
    }

    private var slugIsDerivedFromTitle: Bool {
        slug.isEmpty || slug == BlogSlug.make(from: title)
    }

    private func prefill() {
        let parsed = BlogFrontmatter.parse(from: markdown)
        if let meta = parsed.meta {
            title = meta.title
            date = meta.date
            selectedTags = meta.tags
            excerpt = meta.excerpt
        }

        if title.isEmpty {
            title = fileURL?.deletingPathExtension().lastPathComponent ?? "未命名"
        }
        if slug.isEmpty {
            let seed = fileURL?.deletingPathExtension().lastPathComponent ?? title
            slug = BlogSlug.make(from: seed)
        }
        if excerpt.isEmpty {
            excerpt = String(parsed.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
                .replacingOccurrences(of: "\n", with: " ")
        }
    }

    @MainActor
    private func loadExistingTags() async {
        guard let token = KeychainStore.get(account: GitHubBlogUploader.tokenAccount), !token.isEmpty else {
            return
        }
        isLoadingTags = true
        defer { isLoadingTags = false }

        do {
            let tags = try await GitHubBlogUploader.fetchExistingTags(
                settings: settings,
                token: token
            )
            availableTags = tags
        } catch {
            // Keep free-form create when the remote tag list is unavailable.
            availableTags = []
        }
    }

    @MainActor
    private func upload() async {
        errorMessage = nil
        isUploading = true
        defer { isUploading = false }

        guard let token = KeychainStore.get(account: GitHubBlogUploader.tokenAccount), !token.isEmpty else {
            errorMessage = GitHubBlogUploader.UploadError.missingToken.localizedDescription
            return
        }

        let frontmatter = BlogFrontmatter(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags,
            excerpt: excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            let result = try await GitHubBlogUploader.upload(
                markdown: markdown,
                frontmatter: frontmatter,
                slug: slug,
                documentDirectory: fileURL?.deletingLastPathComponent(),
                settings: settings,
                token: token,
                commitMessage: "docs: publish \(slug) via YKMarkdown"
            )
            dismiss()
            onFinished(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BlogTagPicker: View {
    @Binding var selectedTags: [String]
    let availableTags: [String]
    let isLoading: Bool

    @State private var query: String = ""
    @FocusState private var isQueryFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("标签")
                Spacer(minLength: 0)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !selectedTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagChip(title: tag) {
                            selectedTags.removeAll { $0 == tag }
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                TextField("搜索或新增标签", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($isQueryFocused)
                    .onSubmit(commitQuery)

                Menu {
                    if !selectableExistingTags.isEmpty {
                        Section("已有标签") {
                            ForEach(selectableExistingTags, id: \.self) { tag in
                                Button(tag) { addTag(tag) }
                            }
                        }
                    } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(availableTags.isEmpty ? "暂无已有标签" : "已全部选中")
                    }

                    if canCreateFromQuery {
                        Button("新增「\(trimmedQuery)」") {
                            addTag(trimmedQuery)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("选择已有标签或新增")
            }

            if isQueryFocused && (!filteredSuggestions.isEmpty || canCreateFromQuery) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredSuggestions, id: \.self) { tag in
                        Button {
                            addTag(tag)
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                    }

                    if canCreateFromQuery {
                        Button {
                            addTag(trimmedQuery)
                        } label: {
                            HStack {
                                Text("新增「\(trimmedQuery)」")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                    }
                }
                .background(.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectableExistingTags: [String] {
        let selected = Set(selectedTags)
        let source: [String]
        if trimmedQuery.isEmpty {
            source = availableTags
        } else {
            source = availableTags.filter {
                $0.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }
        return source.filter { !selected.contains($0) }
    }

    private var filteredSuggestions: [String] {
        Array(selectableExistingTags.prefix(8))
    }

    private var canCreateFromQuery: Bool {
        guard !trimmedQuery.isEmpty else { return false }
        let exists = availableTags.contains { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
            || selectedTags.contains { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
        return !exists
    }

    private func commitQuery() {
        let parts = trimmedQuery
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return }
        for part in parts {
            addTag(part)
        }
    }

    private func addTag(_ tag: String) {
        let value = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if selectedTags.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            query = ""
            return
        }
        if let known = availableTags.first(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            selectedTags.append(known)
        } else {
            selectedTags.append(value)
        }
        query = ""
    }
}

private struct TagChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.callout)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.8), in: Capsule())
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            width = max(width, x - spacing)
        }

        let height = y + rowHeight
        return (CGSize(width: width, height: height), frames)
    }
}
