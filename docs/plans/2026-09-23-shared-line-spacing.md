# Shared Line Spacing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add one persisted line-spacing control that adjusts both the Markdown source editor and editable preview while preserving their existing default typography.

**Architecture:** Introduce a shared line-spacing scale model with a default of 1.0 and a bounded 0.8–1.3 range. Apply the scale to each surface's existing baseline, update AppKit paragraph styling through the cached editor appearance, and update WebKit through a CSS variable without reloading the page.

**Tech Stack:** SwiftUI, AppStorage, AppKit NSTextView, WebKit WKWebView, HTML/CSS/JavaScript, Swift Testing.

---

### Task 1: Define and test the shared spacing model

**Files:**
- Modify: `Sources/App/App.swift`
- Create: `Tests/EditorLineSpacingTests.swift`

**Steps:**
1. Add Swift Testing coverage for the default, bounds, step, clamping, and source/preview baseline conversions.
2. Run the focused test and confirm it fails because the model does not exist.
3. Add `EditorLineSpacing` with the persisted key, 1.0 default, 0.8–1.3 bounds, 0.05 step, and conversion helpers.
4. Re-run the focused test and confirm it passes.

### Task 2: Add the setting and update the native source editor

**Files:**
- Modify: `Sources/Views/SettingsView.swift`
- Modify: `Sources/Views/EditorView.swift`
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`
- Modify: `Sources/Infrastructure/DesignSystem/AppTypographyTheme.swift`

**Steps:**
1. Add an `AppStorage` binding and an 80%–130% slider in the existing typography section.
2. Pass the shared scale from `EditorView` to `MarkdownSourceEditor`.
3. Include the scale in `EditorAppearance` so cached styling updates only when needed.
4. Apply the resolved source line-height multiple to default and typing paragraph styles.
5. Compile to catch SwiftUI/AppKit signature errors.

### Task 3: Update the editable preview without reloading

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Modify: `Sources/Views/MarkdownPreviewView.swift`
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`
- Modify: `Tests/EditorLineSpacingTests.swift`

**Steps:**
1. Add renderer tests for the initial line-height variable and `window.setLineSpacing` API.
2. Pass the shared scale into initial HTML rendering.
3. Add coordinator caching and pending-state handling matching the existing font-size flow.
4. Update `--line-height` with JavaScript after the page is ready, without calling `loadInitialPage`.
5. Run focused renderer tests.

### Task 4: Verify and record completion

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/61-shared-line-spacing.md`

**Steps:**
1. Run the relevant unit tests.
2. Run the macOS build.
3. Run `git diff --check` and inspect the final diff.
4. Mark task 61 complete through `scripts/task.sh`, recording actual test/build results.
