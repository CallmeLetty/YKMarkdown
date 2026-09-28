//
//  DocumentEditingSession.swift
//  YKMarkdown
//
//  Created by liuyuanyuan on 2026/9/24.
//  Copyright © 2026 小宇宙. All rights reserved.
//

import Foundation

enum DocumentEditOrigin: Equatable {
    case source
    case preview
    case reload
    case merge
    case imageInsertion
    case documentSystem
}
struct DocumentSnapshot: Equatable {
    let text: String
    let revision: UInt64
    let origin: DocumentEditOrigin
}

struct DocumentTextChange: Equatable {
    let range: NSRange
    let replacedText: String
    let replacement: String

    static func between(_ oldText: String, and newText: String) -> DocumentTextChange {
        var oldPrefixEnd = oldText.startIndex
        var newPrefixEnd = newText.startIndex

        while oldPrefixEnd < oldText.endIndex,
              newPrefixEnd < newText.endIndex,
              oldText[oldPrefixEnd] == newText[newPrefixEnd] {
            oldPrefixEnd = oldText.index(after: oldPrefixEnd)
            newPrefixEnd = newText.index(after: newPrefixEnd)
        }

        var oldSuffixStart = oldText.endIndex
        var newSuffixStart = newText.endIndex
        while oldSuffixStart > oldPrefixEnd, newSuffixStart > newPrefixEnd {
            let previousOldIndex = oldText.index(before: oldSuffixStart)
            let previousNewIndex = newText.index(before: newSuffixStart)
            guard oldText[previousOldIndex] == newText[previousNewIndex] else { break }
            oldSuffixStart = previousOldIndex
            newSuffixStart = previousNewIndex
        }

        let prefixLength = oldText[..<oldPrefixEnd].utf16.count
        let replacedText = String(oldText[oldPrefixEnd..<oldSuffixStart])
        return DocumentTextChange(
            range: NSRange(location: prefixLength, length: replacedText.utf16.count),
            replacedText: replacedText,
            replacement: String(newText[newPrefixEnd..<newSuffixStart])
        )
    }

    func applying(to text: String) -> String? {
        guard range.location != NSNotFound, range.location >= 0, range.length >= 0 else {
            return nil
        }

        let source = text as NSString
        guard NSMaxRange(range) <= source.length,
              source.substring(with: range) == replacedText
        else {
            return nil
        }
        return source.replacingCharacters(in: range, with: replacement)
    }
}

struct DocumentMutation: Equatable {
    let baseRevision: UInt64
    let origin: DocumentEditOrigin
    let change: DocumentTextChange

    static func replacing(
        snapshot: DocumentSnapshot,
        with text: String,
        origin: DocumentEditOrigin
    ) -> DocumentMutation {
        DocumentMutation(
            baseRevision: snapshot.revision,
            origin: origin,
            change: DocumentTextChange.between(snapshot.text, and: text)
        )
    }
}

enum DocumentMutationRejection: Equatable {
    case staleRevision
    case invalidChange
}

enum DocumentMutationResult: Equatable {
    case applied(DocumentSnapshot)
    case unchanged(DocumentSnapshot)
    case rejected(DocumentSnapshot, reason: DocumentMutationRejection)

    var snapshot: DocumentSnapshot {
        switch self {
        case let .applied(snapshot), let .unchanged(snapshot), let .rejected(snapshot, _):
            snapshot
        }
    }
}

struct DocumentEditingState: Equatable {
    private(set) var snapshot: DocumentSnapshot

    init(text: String) {
        snapshot = DocumentSnapshot(text: text, revision: 0, origin: .documentSystem)
    }

    @discardableResult
    mutating func apply(_ mutation: DocumentMutation) -> DocumentMutationResult {
        guard mutation.baseRevision == snapshot.revision else {
            return .rejected(snapshot, reason: .staleRevision)
        }
        guard let updatedText = mutation.change.applying(to: snapshot.text) else {
            return .rejected(snapshot, reason: .invalidChange)
        }
        guard updatedText != snapshot.text else {
            return .unchanged(snapshot)
        }

        snapshot = DocumentSnapshot(
            text: updatedText,
            revision: snapshot.revision + 1,
            origin: mutation.origin
        )
        return .applied(snapshot)
    }
}
