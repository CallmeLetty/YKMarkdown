import Foundation
import SwiftUI

struct DocumentSearchBar: View {
    @Binding var scope: DocumentSearchScope
    @Binding var query: String
    let matches: [MarkdownSearchMatch]
    let selectedMatchID: MarkdownSearchMatch.ID?
    let selectedIndex: Int?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void
    let onSelect: (MarkdownSearchMatch) -> Void

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    scopePicker
                    searchField
                    resultCounter
                    navigationButtons
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        scopePicker
                        searchField
                    }

                    HStack(spacing: 6) {
                        Spacer(minLength: 0)
                        resultCounter
                        navigationButtons
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            if scope == .all, !query.isEmpty, !matches.isEmpty {
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(matches) { match in
                            Button {
                                onSelect(match)
                            } label: {
                                searchResultRow(match)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    private var scopePicker: some View {
        Picker("", selection: $scope) {
            ForEach(DocumentSearchScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 96)
    }

    private var searchField: some View {
        TextField("搜索源码", text: $query)
            .textFieldStyle(.roundedBorder)
            .focused($isSearchFieldFocused)
            .frame(minWidth: 90, idealWidth: 90, maxWidth: .infinity)
            .layoutPriority(2)
            .onSubmit(onNext)
    }

    private var resultCounter: some View {
        Text(resultText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .frame(width: 38, alignment: .trailing)
    }

    private var navigationButtons: some View {
        HStack(spacing: 6) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
                    .frame(width: 20, height: 18)
            }
            .buttonStyle(.borderless)
            .disabled(matches.isEmpty)
            .help("上一个")

            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .frame(width: 20, height: 18)
            }
            .buttonStyle(.borderless)
            .disabled(matches.isEmpty)
            .help("下一个")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 18)
            }
            .buttonStyle(.borderless)
            .help("关闭搜索")
        }
        .controlSize(.small)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var resultText: String {
        guard !query.isEmpty else { return "" }
        guard !matches.isEmpty else { return "无结果" }
        guard let selectedIndex else { return "\(matches.count)" }
        return "\(selectedIndex + 1)/\(matches.count)"
    }

    private func searchResultRow(_ match: MarkdownSearchMatch) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(match.documentTitle):\(match.lineNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(match.snippet.isEmpty ? " " : match.snippet)
                    .font(.body)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(match.id == selectedMatchID ? Color.accentColor.opacity(0.16) : Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview("Document Search Bar") {
    DocumentSearchBarPreview()
        .frame(width: 560)
}

#Preview("Narrow Document Search Bar") {
    DocumentSearchBarPreview()
        .frame(width: 280)
}

private struct DocumentSearchBarPreview: View {
    @State private var scope: DocumentSearchScope = .all
    @State private var query = "target"
    private let matches = Self.sampleMatches

    var body: some View {
        DocumentSearchBar(
            scope: $scope,
            query: $query,
            matches: matches,
            selectedMatchID: matches.first?.id,
            selectedIndex: 0,
            onPrevious: {},
            onNext: {},
            onClose: {},
            onSelect: { _ in }
        )
    }

    private static let sampleDocumentID = UUID()

    private static var sampleMatches: [MarkdownSearchMatch] {
        [
            MarkdownSearchMatch(
                documentID: sampleDocumentID,
                documentTitle: "README.md",
                fileURL: nil,
                range: NSRange(location: 24, length: 6),
                lineNumber: 12,
                snippet: "这里是包含 target 的搜索结果摘要"
            ),
            MarkdownSearchMatch(
                documentID: sampleDocumentID,
                documentTitle: "Notes.md",
                fileURL: nil,
                range: NSRange(location: 86, length: 6),
                lineNumber: 31,
                snippet: "另一个 target 命中，用来检查全局搜索列表"
            )
        ]
    }
}
