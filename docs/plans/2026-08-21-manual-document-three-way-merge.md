# Manual Document Three-Way Merge Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the existing manual refresh action merge non-overlapping local and disk edits automatically and present overlapping edits in a source-only red/green conflict resolver.

**Architecture:** Keep an in-memory disk baseline per open `EditorView`. A pure Swift merge engine returns ordered resolved and conflicting segments from `base`, `local`, and `remote`; `EditorView` owns the temporary merge session, while dedicated SwiftUI/AppKit views render and resolve conflicts without inserting marker text into the Markdown document.

**Tech Stack:** Swift 6, SwiftUI, AppKit `NSTextView`, XCTest, macOS 15.4.

---

### Task 1: Add the three-way merge domain model

**Files:**
- Create: `Sources/Features/Editor/DocumentThreeWayMerge.swift`
- Test: `Tests/AppTests.swift`

**Step 1: Write failing tests**

Add focused tests for:

```swift
func testThreeWayMergeAppliesNonOverlappingLocalAndRemoteEdits()
func testThreeWayMergeCreatesConflictForOverlappingEdits()
func testThreeWayMergeDeduplicatesIdenticalEdits()
func testThreeWayMergeHandlesDifferentInsertionsAtSameLocationAsConflict()
func testThreeWayMergePreservesMissingFinalNewline()
func testThreeWayMergeUsesUTF16CompatibleInlineRanges()
```

The first test should use a three-line base, edit line one locally and line three remotely, and assert one fully resolved output. The conflict test should edit the same base line differently and assert one conflict containing both exact candidates.

**Step 2: Run the focused tests and verify failure**

Run:

```bash
xcodebuild -project YKMarkdown.xcodeproj -scheme YKMarkdown \
  -destination 'platform=macOS' \
  -only-testing:YKMarkdownTests/YKMarkdownTests/testThreeWayMergeAppliesNonOverlappingLocalAndRemoteEdits \
  test
```

Expected: compilation fails because `DocumentThreeWayMerge` does not exist.

**Step 3: Add the merge types and minimal engine**

Define these public-to-target shapes:

```swift
enum DocumentMergeSegment: Identifiable, Equatable {
    case resolved(id: UUID, text: String)
    case conflict(DocumentMergeConflict)
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
    var conflicts: [DocumentMergeConflict] { /* ordered conflicts */ }
    var resolvedText: String? { /* nil while any conflict remains */ }
}

enum DocumentThreeWayMerge {
    static func merge(base: String, local: String, remote: String) -> DocumentMergeResult
}
```

Implement line tokenization while retaining every line terminator, derive ordered edit hunks for `base -> local` and `base -> remote`, combine non-overlapping hunks, and emit structured conflicts for overlapping unequal replacements. Compute character-level highlight ranges separately for each conflict candidate, expressed as UTF-16 `NSRange` values for AppKit.

**Step 4: Run the merge tests**

Run all new merge-focused tests. Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/Features/Editor/DocumentThreeWayMerge.swift Tests/AppTests.swift
git commit -m "feat: add document three-way merge engine"
```

### Task 2: Add a mutable conflict session

**Files:**
- Create: `Sources/Features/Editor/DocumentMergeSession.swift`
- Test: `Tests/AppTests.swift`

**Step 1: Write failing session tests**

Cover selecting local, remote, both, manual text, ordered final assembly, unresolved count, next-conflict cycling, and cancellation leaving the original local text unchanged.

**Step 2: Run the focused tests and verify failure**

Expected: compilation fails because `DocumentMergeSession` does not exist.

**Step 3: Implement the session**

Use an observable main-actor model:

```swift
@MainActor
final class DocumentMergeSession: ObservableObject {
    enum Resolution { case local, remote, both, manual(String) }

    let originalLocalText: String
    let remoteText: String
    @Published private(set) var segments: [DocumentMergeSessionSegment]
    @Published private(set) var focusedConflictID: UUID?

    var unresolvedCount: Int { /* unresolved conflict count */ }
    var isComplete: Bool { unresolvedCount == 0 }
    var finalText: String? { /* ordered assembly when complete */ }

    func resolve(_ id: UUID, using resolution: Resolution)
    func focusNextConflict()
}
```

Keep resolved conflict results editable in the session. Do not mutate `MarkdownDocument` from this model.

**Step 4: Run session tests**

Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/Features/Editor/DocumentMergeSession.swift Tests/AppTests.swift
git commit -m "feat: add document merge session state"
```

### Task 3: Build the source-only conflict resolver UI

**Files:**
- Create: `Sources/Views/DocumentMergeConflictView.swift`
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

**Step 1: Add preview fixtures for resolver states**

Create SwiftUI previews for multiple unresolved conflicts, a manual-edit conflict, and a completed session. This is the visual verification fixture; do not rely on production documents.

**Step 2: Implement the conflict navigation bar**

Show `还有 N 个冲突未解决`, `下一个冲突`, `取消合并`, and a disabled-until-complete `完成合并` action. Provide accessibility labels containing the unresolved count and preserve visible keyboard focus.

**Step 3: Implement conflict blocks**

Render the local candidate above the remote candidate using semantic system red/green colors with low-opacity backgrounds. Apply deeper temporary backgrounds to the `NSRange` character differences. Add `保留当前`, `使用外部`, `两者保留`, and `手动编辑` actions.

For manual mode, replace the red/green alternatives with an editable monospaced text area initialized from the local candidate. Require an explicit `完成此处` action before decrementing the unresolved count.

**Step 4: Implement navigation**

Use `ScrollViewReader` and stable conflict IDs. `focusNextConflict()` cycles at the end, scrolls the target to the center, and moves accessibility/keyboard focus to it.

**Step 5: Verify the previews visually**

Check light and dark appearance, long lines, empty candidates, keyboard focus, red/green contrast, and a narrow window. Expected: no preview pane is present and no action is clipped.

**Step 6: Commit**

```bash
git add Sources/Views/DocumentMergeConflictView.swift Sources/Features/Editor/MarkdownOutline.swift
git commit -m "feat: add source conflict resolver"
```

### Task 4: Integrate three-way refresh into EditorView

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Test: `Tests/AppTests.swift`

**Step 1: Add decision tests**

Extract a small pure refresh decision helper and test the four paths: equal local/remote, unchanged remote, unchanged local, and three-way merge.

**Step 2: Replace overwrite confirmation state**

Remove `showReloadConfirmation` and `pendingReloadText`. Add an optional `DocumentMergeSession`, the current session's `remoteText`, and the layout value captured before conflict mode.

**Step 3: Route refresh through the three-way merge**

Read `remote`, compare it with `base` and `local`, then:

- no-op and refresh the baseline when `remote == local`;
- preserve local when `remote == base`;
- load remote and update the baseline when `local == base`;
- apply a conflict-free merge immediately while keeping `remote` as the baseline;
- start a merge session when conflicts exist.

**Step 4: Present conflict mode**

When a session exists, replace the normal three-pane content with `DocumentMergeConflictView`. Do not render the outline or preview, and disable refresh from starting another session.

On completion, assign the assembled text to `document.text`, set `lastKnownDiskText` to the session's `remoteText`, clear the session, and restore the previous layout. On cancellation, clear the session and restore the layout without changing the document or baseline.

**Step 5: Run focused tests and compile**

Run the refresh-decision and merge tests, then build:

```bash
xcodebuild -project YKMarkdown.xcodeproj -scheme YKMarkdown \
  -destination 'platform=macOS' build
```

Expected: tests pass and the strict Swift 6 build succeeds without warnings.

**Step 6: Commit**

```bash
git add Sources/Views/EditorView.swift Tests/AppTests.swift
git commit -m "feat: merge document changes on refresh"
```

### Task 5: Final behavior verification and documentation

**Files:**
- Modify: `docs/Markdown 文件外部变更监听方案.md`
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/30-manual-document-three-way-merge.md`

**Step 1: Verify manual scenarios**

Open a saved Markdown file and verify external-only, local-only, non-overlapping, overlapping, identical, insertion, deletion, empty-file, and no-final-newline cases. Confirm conflict navigation cycles and all four resolutions produce exact expected Markdown.

**Step 2: Verify lifecycle behavior**

Confirm cancellation preserves the original local text, completion restores the prior layout, unresolved temporary candidates never enter saved Markdown, and a second refresh compares against the latest remote baseline.

**Step 3: Run repository checks**

Run `git diff --check` and the strict macOS build. Do not run SwiftLint, in accordance with the repository instruction.

**Step 4: Complete the task record**

```bash
AGENT_NAME=CODEX scripts/task.sh done 30 \
  --note "Implemented manual three-way refresh, source-only conflict resolver, navigation/count UI, and verified build/tests"
```

**Step 5: Commit**

```bash
git add docs/Markdown\ 文件外部变更监听方案.md tasks/TASKS.md tasks/details/30-manual-document-three-way-merge.md
git commit -m "docs: record manual document merge behavior"
```
