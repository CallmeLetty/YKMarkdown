import Foundation

enum DocumentMergeSegment: Identifiable, Equatable {
    case resolved(id: UUID, text: String)
    case conflict(DocumentMergeConflict)

    var id: UUID {
        switch self {
        case let .resolved(id, _):
            id
        case let .conflict(conflict):
            conflict.id
        }
    }
}

struct DocumentMergeConflict: Identifiable, Equatable {
    let id: UUID
    let localText: String
    let remoteText: String
    let localChangedRanges: [NSRange]
    let remoteChangedRanges: [NSRange]
}

struct DocumentMergeResult: Equatable {
    let segments: [DocumentMergeSegment]

    var conflicts: [DocumentMergeConflict] {
        segments.compactMap { segment in
            guard case let .conflict(conflict) = segment else { return nil }
            return conflict
        }
    }

    var resolvedText: String? {
        guard conflicts.isEmpty else { return nil }
        return segments.map { segment in
            guard case let .resolved(_, text) = segment else { return "" }
            return text
        }.joined()
    }
}

enum DocumentRefreshDecision: Equatable {
    case unchanged(remoteBaseline: String)
    case preserveLocal
    case apply(text: String, remoteBaseline: String)
    case resolveConflicts(result: DocumentMergeResult, remoteBaseline: String)
}

enum DocumentThreeWayMerge {
    static func refreshDecision(base: String, local: String, remote: String) -> DocumentRefreshDecision {
        if remote == local {
            return .unchanged(remoteBaseline: remote)
        }
        if remote == base {
            return .preserveLocal
        }
        if local == base {
            return .apply(text: remote, remoteBaseline: remote)
        }

        let result = merge(base: base, local: local, remote: remote)
        if let resolvedText = result.resolvedText {
            return .apply(text: resolvedText, remoteBaseline: remote)
        }
        return .resolveConflicts(result: result, remoteBaseline: remote)
    }

    static func merge(base: String, local: String, remote: String) -> DocumentMergeResult {
        let baseLines = linesPreservingTerminators(in: base)
        let localHunks = editHunks(from: baseLines, to: linesPreservingTerminators(in: local))
        let remoteHunks = editHunks(from: baseLines, to: linesPreservingTerminators(in: remote))

        var segments: [DocumentMergeSegment] = []
        var baseCursor = 0
        var localIndex = 0
        var remoteIndex = 0

        func appendResolved(_ text: String) {
            guard !text.isEmpty else { return }
            if case let .resolved(id, existing)? = segments.last {
                segments[segments.count - 1] = .resolved(id: id, text: existing + text)
            } else {
                segments.append(.resolved(id: UUID(), text: text))
            }
        }

        func appendBase(until end: Int) {
            guard baseCursor < end else { return }
            appendResolved(baseLines[baseCursor..<end].joined())
            baseCursor = end
        }

        while localIndex < localHunks.count || remoteIndex < remoteHunks.count {
            let localHunk = localIndex < localHunks.count ? localHunks[localIndex] : nil
            let remoteHunk = remoteIndex < remoteHunks.count ? remoteHunks[remoteIndex] : nil

            if let localHunk, let remoteHunk, hunksOverlap(localHunk, remoteHunk) {
                var localCluster = [localHunk]
                var remoteCluster = [remoteHunk]
                localIndex += 1
                remoteIndex += 1

                var didExpand = true
                while didExpand {
                    didExpand = false
                    if localIndex < localHunks.count {
                        let candidate = localHunks[localIndex]
                        if remoteCluster.contains(where: { hunksOverlap(candidate, $0) }) {
                            localCluster.append(candidate)
                            localIndex += 1
                            didExpand = true
                        }
                    }
                    if remoteIndex < remoteHunks.count {
                        let candidate = remoteHunks[remoteIndex]
                        if localCluster.contains(where: { hunksOverlap(candidate, $0) }) {
                            remoteCluster.append(candidate)
                            remoteIndex += 1
                            didExpand = true
                        }
                    }
                }

                let clusterStart = min(
                    localCluster.map(\.baseRange.lowerBound).min() ?? baseCursor,
                    remoteCluster.map(\.baseRange.lowerBound).min() ?? baseCursor
                )
                let clusterEnd = max(
                    localCluster.map(\.baseRange.upperBound).max() ?? clusterStart,
                    remoteCluster.map(\.baseRange.upperBound).max() ?? clusterStart
                )
                appendBase(until: clusterStart)

                let localText = applying(localCluster, to: clusterStart..<clusterEnd, baseLines: baseLines)
                let remoteText = applying(remoteCluster, to: clusterStart..<clusterEnd, baseLines: baseLines)
                if localText == remoteText {
                    appendResolved(localText)
                } else {
                    let ranges = changedRanges(local: localText, remote: remoteText)
                    segments.append(.conflict(DocumentMergeConflict(
                        id: UUID(),
                        localText: localText,
                        remoteText: remoteText,
                        localChangedRanges: ranges.local,
                        remoteChangedRanges: ranges.remote
                    )))
                }
                baseCursor = clusterEnd
                continue
            }

            let takeLocal: Bool
            switch (localHunk, remoteHunk) {
            case (.some, .none):
                takeLocal = true
            case (.none, .some):
                takeLocal = false
            case let (.some(local), .some(remote)):
                takeLocal = hunkComesBefore(local, remote)
            case (.none, .none):
                takeLocal = false
            }

            let hunk: EditHunk
            if takeLocal, let localHunk {
                hunk = localHunk
                localIndex += 1
            } else if let remoteHunk {
                hunk = remoteHunk
                remoteIndex += 1
            } else {
                break
            }

            appendBase(until: hunk.baseRange.lowerBound)
            appendResolved(hunk.replacement.joined())
            baseCursor = max(baseCursor, hunk.baseRange.upperBound)
        }

        appendBase(until: baseLines.count)
        if segments.isEmpty {
            segments = [.resolved(id: UUID(), text: "")]
        }
        return DocumentMergeResult(segments: segments)
    }
}

private extension DocumentThreeWayMerge {
    struct EditHunk: Equatable {
        let baseRange: Range<Int>
        let replacement: [String]
    }

    static func linesPreservingTerminators(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var lines: [String] = []
        var lineStart = text.startIndex
        while let newline = text[lineStart...].firstIndex(of: "\n") {
            let lineEnd = text.index(after: newline)
            lines.append(String(text[lineStart..<lineEnd]))
            lineStart = lineEnd
            if lineStart == text.endIndex { break }
        }
        if lineStart < text.endIndex {
            lines.append(String(text[lineStart..<text.endIndex]))
        }
        return lines
    }

    static func editHunks(from base: [String], to variant: [String]) -> [EditHunk] {
        let difference = variant.difference(from: base)
        var removedOffsets = Set<Int>()
        var insertedOffsets = Set<Int>()

        for change in difference {
            switch change {
            case let .remove(offset, _, _):
                removedOffsets.insert(offset)
            case let .insert(offset, _, _):
                insertedOffsets.insert(offset)
            }
        }

        var hunks: [EditHunk] = []
        var baseIndex = 0
        var variantIndex = 0

        while baseIndex < base.count || variantIndex < variant.count {
            if baseIndex < base.count,
               variantIndex < variant.count,
               !removedOffsets.contains(baseIndex),
               !insertedOffsets.contains(variantIndex),
               base[baseIndex] == variant[variantIndex] {
                baseIndex += 1
                variantIndex += 1
                continue
            }

            let hunkStart = baseIndex
            var replacement: [String] = []
            var madeProgress = false

            while baseIndex < base.count, removedOffsets.contains(baseIndex) {
                baseIndex += 1
                madeProgress = true
            }
            while variantIndex < variant.count, insertedOffsets.contains(variantIndex) {
                replacement.append(variant[variantIndex])
                variantIndex += 1
                madeProgress = true
            }

            if madeProgress {
                hunks.append(EditHunk(baseRange: hunkStart..<baseIndex, replacement: replacement))
                continue
            }

            // CollectionDifference should align all unchanged elements. This fallback keeps
            // malformed or unexpectedly aligned input progressing without dropping text.
            if baseIndex < base.count { baseIndex += 1 }
            if variantIndex < variant.count {
                replacement.append(variant[variantIndex])
                variantIndex += 1
            }
            hunks.append(EditHunk(baseRange: hunkStart..<baseIndex, replacement: replacement))
        }

        return hunks
    }

    static func hunksOverlap(_ lhs: EditHunk, _ rhs: EditHunk) -> Bool {
        if lhs.baseRange.isEmpty, rhs.baseRange.isEmpty {
            return lhs.baseRange.lowerBound == rhs.baseRange.lowerBound
        }
        if lhs.baseRange.isEmpty {
            let position = lhs.baseRange.lowerBound
            return rhs.baseRange.lowerBound < position && position < rhs.baseRange.upperBound
        }
        if rhs.baseRange.isEmpty {
            let position = rhs.baseRange.lowerBound
            return lhs.baseRange.lowerBound < position && position < lhs.baseRange.upperBound
        }
        return lhs.baseRange.overlaps(rhs.baseRange)
    }

    static func hunkComesBefore(_ lhs: EditHunk, _ rhs: EditHunk) -> Bool {
        if lhs.baseRange.lowerBound != rhs.baseRange.lowerBound {
            return lhs.baseRange.lowerBound < rhs.baseRange.lowerBound
        }
        if lhs.baseRange.isEmpty != rhs.baseRange.isEmpty {
            return lhs.baseRange.isEmpty
        }
        return lhs.baseRange.upperBound <= rhs.baseRange.upperBound
    }

    static func applying(_ hunks: [EditHunk], to range: Range<Int>, baseLines: [String]) -> String {
        var result = ""
        var cursor = range.lowerBound
        for hunk in hunks.sorted(by: { hunkComesBefore($0, $1) }) {
            if cursor < hunk.baseRange.lowerBound {
                result += baseLines[cursor..<hunk.baseRange.lowerBound].joined()
            }
            result += hunk.replacement.joined()
            cursor = max(cursor, hunk.baseRange.upperBound)
        }
        if cursor < range.upperBound {
            result += baseLines[cursor..<range.upperBound].joined()
        }
        return result
    }

    static func changedRanges(local: String, remote: String) -> (local: [NSRange], remote: [NSRange]) {
        guard local != remote else { return ([], []) }
        let localCharacters = Array(local)
        let remoteCharacters = Array(remote)
        let sharedCount = min(localCharacters.count, remoteCharacters.count)

        var prefixCount = 0
        while prefixCount < sharedCount,
              localCharacters[prefixCount] == remoteCharacters[prefixCount] {
            prefixCount += 1
        }

        var suffixCount = 0
        while suffixCount < sharedCount - prefixCount,
              localCharacters[localCharacters.count - suffixCount - 1]
                == remoteCharacters[remoteCharacters.count - suffixCount - 1] {
            suffixCount += 1
        }

        func range(in characters: [Character]) -> [NSRange] {
            let prefixLength = String(characters.prefix(prefixCount)).utf16.count
            let suffixLength = String(characters.suffix(suffixCount)).utf16.count
            let length = String(characters).utf16.count - prefixLength - suffixLength
            guard length > 0 else { return [] }
            return [NSRange(location: prefixLength, length: length)]
        }

        return (range(in: localCharacters), range(in: remoteCharacters))
    }
}
