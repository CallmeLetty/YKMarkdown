import Combine
import Foundation

struct DocumentMergeSessionSegment: Identifiable, Equatable {
    enum Content: Equatable {
        case resolved(String)
        case conflict(DocumentMergeConflict)
    }

    let id: UUID
    let content: Content
    var resolutionText: String?
    var manualDraft: String?

    var isConflict: Bool {
        guard case .conflict = content else { return false }
        return true
    }

    var isUnresolved: Bool {
        isConflict && resolutionText == nil
    }

    var conflict: DocumentMergeConflict? {
        guard case let .conflict(conflict) = content else { return nil }
        return conflict
    }

    var outputText: String? {
        switch content {
        case let .resolved(text):
            text
        case .conflict:
            resolutionText
        }
    }
}

@MainActor
final class DocumentMergeSession: ObservableObject {
    enum Resolution {
        case local
        case remote
        case both
        case manual(String)
    }

    let remoteText: String
    @Published private(set) var segments: [DocumentMergeSessionSegment]
    @Published private(set) var focusedConflictID: UUID?

    init(result: DocumentMergeResult, remoteText: String) {
        self.remoteText = remoteText
        segments = result.segments.map { segment in
            switch segment {
            case let .resolved(id, text):
                DocumentMergeSessionSegment(
                    id: id,
                    content: .resolved(text),
                    resolutionText: text,
                    manualDraft: nil
                )
            case let .conflict(conflict):
                DocumentMergeSessionSegment(
                    id: conflict.id,
                    content: .conflict(conflict),
                    resolutionText: nil,
                    manualDraft: nil
                )
            }
        }
        focusedConflictID = unresolvedConflictIDs.first
    }

    var unresolvedCount: Int {
        segments.filter(\.isUnresolved).count
    }

    var isComplete: Bool {
        unresolvedCount == 0
    }

    var finalText: String? {
        guard isComplete else { return nil }
        return segments.compactMap(\.outputText).joined()
    }

    func resolve(_ id: UUID, using resolution: Resolution) {
        guard let index = conflictIndex(for: id),
              let conflict = segments[index].conflict
        else { return }

        let text: String
        switch resolution {
        case .local:
            text = conflict.localText
        case .remote:
            text = conflict.remoteText
        case .both:
            text = conflict.localText + conflict.remoteText
        case let .manual(value):
            text = value
        }
        segments[index].resolutionText = text
        segments[index].manualDraft = nil
        focusedConflictID = nextUnresolvedID(after: id)
    }

    func beginManualEditing(_ id: UUID) {
        guard let index = conflictIndex(for: id),
              let conflict = segments[index].conflict
        else { return }
        segments[index].manualDraft = segments[index].resolutionText ?? conflict.localText
        focusedConflictID = id
    }

    func updateManualDraft(_ text: String, for id: UUID) {
        guard let index = conflictIndex(for: id), segments[index].manualDraft != nil else { return }
        segments[index].manualDraft = text
    }

    func finishManualEditing(_ id: UUID) {
        guard let index = conflictIndex(for: id),
              let draft = segments[index].manualDraft
        else { return }
        resolve(id, using: .manual(draft))
    }

    func cancelManualEditing(_ id: UUID) {
        guard let index = conflictIndex(for: id) else { return }
        segments[index].manualDraft = nil
    }

    func reopen(_ id: UUID) {
        guard let index = conflictIndex(for: id) else { return }
        segments[index].resolutionText = nil
        segments[index].manualDraft = nil
        focusedConflictID = id
    }

    func focusNextConflict() {
        focusedConflictID = nextUnresolvedID(after: focusedConflictID)
    }

    func updateResolvedText(_ text: String, for id: UUID) {
        guard let index = conflictIndex(for: id), segments[index].resolutionText != nil else { return }
        segments[index].resolutionText = text
    }

    private var unresolvedConflictIDs: [UUID] {
        segments.filter(\.isUnresolved).map(\.id)
    }

    private func conflictIndex(for id: UUID) -> Int? {
        segments.firstIndex { $0.id == id && $0.isConflict }
    }

    private func nextUnresolvedID(after id: UUID?) -> UUID? {
        let ids = unresolvedConflictIDs
        guard !ids.isEmpty else { return nil }
        guard let id, let currentIndex = ids.firstIndex(of: id) else { return ids.first }
        return ids[(currentIndex + 1) % ids.count]
    }
}
