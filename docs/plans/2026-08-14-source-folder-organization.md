# Source Folder Organization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Organize the application source files by responsibility without changing runtime behavior.

**Architecture:** Keep the application entry point in `App`, SwiftUI and AppKit-backed screens in `Views`, domain code in feature-specific folders under `Features`, and cross-cutting adapters and resources under `Infrastructure`. Preserve every file's contents while moving it, then update the one build setting whose path changes.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XcodeGen, XCTest

---

### Task 1: Create the responsibility-based source layout

**Files:**
- Move: `Sources/App.swift` to `Sources/App/App.swift`
- Move: SwiftUI view files to `Sources/Views/`
- Move: blog and editor domain files to `Sources/Features/Blog/` and `Sources/Features/Editor/`
- Move: shared adapters, services, theme, and resources to `Sources/Infrastructure/`

**Step 1:** Create the destination folders.

**Step 2:** Move each existing file without modifying its contents.

**Step 3:** Compare the moved Swift files with the index to confirm the changes are path-only apart from pre-existing working-tree edits.

### Task 2: Update the build configuration

**Files:**
- Modify: `project.yml`

**Step 1:** Point `INFOPLIST_FILE` at `Sources/Infrastructure/Resources/Info.plist`.

**Step 2:** Regenerate or build the project so the synchronized folder hierarchy is refreshed.

### Task 3: Verify and record completion

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/details/21-source-folder-organization.md`

**Step 1:** Run the strict macOS compile check.

**Step 2:** Inspect Git status and diff summaries for missing, duplicated, or unintentionally edited files.

**Step 3:** Mark task 21 complete with the verification result. Do not run SwiftLint or tests, following the user's stored workflow preference.
