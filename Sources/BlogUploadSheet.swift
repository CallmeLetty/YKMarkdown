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
    @State private var tagsText: String = ""
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
                TextField("标签（逗号分隔）", text: $tagsText)
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
            tagsText = meta.tags.joined(separator: ", ")
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
    private func upload() async {
        errorMessage = nil
        isUploading = true
        defer { isUploading = false }

        guard let token = KeychainStore.get(account: GitHubBlogUploader.tokenAccount), !token.isEmpty else {
            errorMessage = GitHubBlogUploader.UploadError.missingToken.localizedDescription
            return
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let frontmatter = BlogFrontmatter(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
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
