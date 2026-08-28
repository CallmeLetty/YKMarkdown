# Typography Themes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three persisted typography themes and one optional custom canvas background that update the native Markdown editor and editable WebKit preview together.

**Architecture:** Centralize theme metadata and color resolution in a design-system type. Pass the resolved native appearance into `MarkdownSourceEditor` and the equivalent CSS values into `MarkdownPreviewView`, which updates the loaded document through a small JavaScript appearance API without reloading.

**Tech Stack:** Swift 6, SwiftUI, AppKit `NSTextView`, WebKit `WKWebView`, HTML/CSS/JavaScript, XCTest.

---

### Task 1: Add theme and background model

**Files:**
- Create: `Sources/Infrastructure/DesignSystem/AppTypographyTheme.swift`
- Test: `Tests/AppTests.swift`

1. Add tests for stored-value fallback, per-theme default backgrounds, and foreground contrast for light and dark backgrounds.
2. Implement `AppTypographyTheme` metadata, persisted keys, editor typography metrics, and background/foreground resolution.
3. Compile the test target to verify the public surface is available.

### Task 2: Add settings controls

**Files:**
- Modify: `Sources/Views/SettingsView.swift`

1. Add persisted bindings for theme, custom-background enablement, and custom color.
2. Add a segmented theme picker, contextual theme description, toggle, and conditional `ColorPicker`.
3. Keep the existing accent-color controls and clarify their label.

### Task 3: Apply the appearance to the native editor

**Files:**
- Modify: `Sources/Views/EditorView.swift`
- Modify: `Sources/Features/Editor/MarkdownOutline.swift`

1. Resolve the stored theme and background once in `EditorView` and pass them to the source editor.
2. Apply font, line spacing, text color, insertion-point color, insets, and shared pane background in `MarkdownSourceEditor`.
3. Verify changing settings updates an existing editor without replacing its text or selection.

### Task 4: Apply the appearance to the preview

**Files:**
- Modify: `Sources/Views/MarkdownPreviewView.swift`
- Modify: `Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift`
- Test: `Tests/AppTests.swift`

1. Extend renderer inputs with theme and resolved canvas colors.
2. Add three CSS theme blocks for font stacks, rhythm, content width, headings, quotes, lists, code, tables, and Mermaid containers.
3. Add `window.setAppearance` and coordinator pending-state handling so live updates preserve page state.
4. Re-render Mermaid after theme or contrast changes.

### Task 5: Verify and hand off

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/37-typography-themes.md`

1. Run focused static checks for generated HTML and whitespace.
2. Run a strict macOS build; fix definite compile failures.
3. Perform necessary UI verification without running the test suite or SwiftLint, per local preference.
4. Complete task 37 with the exact verification status.
