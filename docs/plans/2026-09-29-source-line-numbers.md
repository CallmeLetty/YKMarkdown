# Source Line Numbers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persisted, default-on line-number gutter to the Markdown source editor that users can hide in Settings.

**Architecture:** Store one application-wide visibility preference and pass it through `EditorView` into the AppKit-backed source editor. Attach a custom `NSRulerView` to the existing `NSScrollView`, derive logical line starts from the source text, and use TextKit layout geometry to draw only visible line numbers without changing document content.

**Tech Stack:** SwiftUI, AppStorage, AppKit, NSTextView, NSLayoutManager, NSRulerView, Swift Testing.

---

### Task 1: Define the preference and line model

**Files:**
- Modify: `Sources/App/App.swift`
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`
- Create: `Tests/EditorLineNumberTests.swift`

**Steps:**
1. Add Swift Testing coverage for logical line starts in empty, single-line, multiline, CRLF, and trailing-newline text.
2. Add `EditorLineNumbers` with a stable storage key and a default value of `true`.
3. Add a small pure `MarkdownLineMap` helper that returns UTF-16 line starts compatible with TextKit ranges.
4. Compile the test target to catch model and concurrency errors; do not run tests unless requested.

### Task 2: Add the persisted setting and pass it to the editor

**Files:**
- Modify: `Sources/Views/SettingsView.swift`
- Modify: `Sources/Views/EditorView.swift`
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

**Steps:**
1. Bind the preference with `AppStorage` in Settings and EditorView.
2. Add a “显示行号” toggle in the existing Editor section.
3. Add `showsLineNumbers` to `MarkdownSourceEditor` and update the existing call site.
4. Confirm the switch updates the existing editor instance instead of replacing its text view.

### Task 3: Draw and refresh the native line-number gutter

**Files:**
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

**Steps:**
1. Add `MarkdownLineNumberRulerView` backed by the existing `MarkdownTextView`.
2. Derive visible logical lines through `NSLayoutManager` glyph geometry and draw right-aligned labels.
3. Resize the gutter as digit count changes and apply the editor background/secondary foreground colors.
4. Refresh on text edits, scroll/layout changes, and appearance changes.

### Task 4: Verify and record completion

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/63-source-line-numbers.md`

**Steps:**
1. Compile the macOS app and test target without running tests.
2. Inspect the UI with line numbers shown and hidden, including scrolling and a trailing empty line.
3. Run `git diff --check` and review the final diff.
4. Complete task 63 through `scripts/task.sh`, recording the actual verification result.
