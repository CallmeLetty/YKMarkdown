# Tasks

## Task IDs

1. blog-tag-dropdown
   Id: 1-blog-tag-dropdown
   Scope: Replace comma-separated tag field in BlogUploadSheet with a dropdown that can select existing repo tags or create new ones
   Files: Sources/BlogUploadSheet.swift,Sources/GitHubBlogUploader.swift,Tests/AppTests.swift
   Note: Tag picker with existing-repo dropdown + create-new; fetchExistingTags from content/*.md; make test passed
   Detail: tasks/details/1-blog-tag-dropdown.md
   Claimed by: CURSOR
   Claimed at: 2026-07-25T03:18:35Z
   Done by: CURSOR
   Done at: 2026-07-25T03:19:37Z

2. allow-upload-without-save-if-no-images
   Id: 2-allow-upload-without-save-if-no-images
   Scope: Allow blog upload without local save when markdown has no local image refs; keep save-required when images exist
   Files: Sources/EditorView.swift,Sources/GitHubBlogUploader.swift,Sources/BlogUploadSheet.swift
   Note: No local images: upload without save; with local images: still require save. make test passed
   Detail: tasks/details/2-allow-upload-without-save-if-no-images.md
   Claimed by: CURSOR
   Claimed at: 2026-07-25T07:00:43Z
   Done by: CURSOR
   Done at: 2026-07-25T07:01:17Z

3. clarify-slug-validation-message
   Id: 3-clarify-slug-validation-message
   Scope: Clarify invalid slug error/UI copy to mention lowercase letters, digits, and hyphens
   Files: Sources/GitHubBlogUploader.swift,Sources/BlogUploadSheet.swift
   Note: Updated slug field label and invalid-slug error to mention lowercase + example
   Detail: tasks/details/3-clarify-slug-validation-message.md
   Claimed by: CURSOR
   Claimed at: 2026-08-09T02:01:15Z
   Done by: CURSOR
   Done at: 2026-08-09T02:01:17Z

4. remove-heading-bottom-borders
   Id: 4-remove-heading-bottom-borders
   Scope: Make Markdown preview horizontal rules come only from explicit Markdown separators
   Files: Sources/MarkdownHTMLRenderer.swift,Tests/AppTests.swift
   Note: Finished: removed h1/h2 bottom borders and restricted horizontal-rule parsing to exact ---; no unit tests per user request; diff check passed
   Detail: tasks/details/4-remove-heading-bottom-borders.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T02:28:50Z
   Done by: CODEX
   Done at: 2026-08-11T02:31:25Z

5. generate-panda-app-icon
   Id: 5-generate-panda-app-icon
   Scope: Generate a full-bleed macOS app icon master based on the provided gothic panda character
   Files: Resources/AppIcon-panda-master.png
   Note: Generated and saved 1024x1024 opaque full-bleed panda app icon master; visually inspected; existing AppIcon left unchanged
   Detail: tasks/details/5-generate-panda-app-icon.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T02:35:38Z
   Done by: CODEX
   Done at: 2026-08-11T02:35:55Z

6. revise-panda-app-icon-markdown
   Id: 6-revise-panda-app-icon-markdown
   Scope: Brighten the panda app icon and make Markdown identity unmistakable
   Files: Resources/AppIcon-panda-master-v2.png
   Note: Generated brighter 1024x1024 opaque v2 icon with prominent white M-down-arrow Markdown mark; visually inspected; v1 preserved
   Detail: tasks/details/6-revise-panda-app-icon-markdown.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T02:38:34Z
   Done by: CODEX
   Done at: 2026-08-11T02:39:57Z

7. revise-panda-app-icon-macaron-blue
   Id: 7-revise-panda-app-icon-macaron-blue
   Scope: Adjust v2 icon background to a balanced macaron blue while preserving panda and Markdown mark
   Files: Resources/AppIcon-panda-master-v3.png
   Note: Generated 1024x1024 opaque v3 with balanced low-saturation macaron-blue background; preserved panda and M-down-arrow mark; visually inspected
   Detail: tasks/details/7-revise-panda-app-icon-macaron-blue.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T03:26:41Z
   Done by: CODEX
   Done at: 2026-08-11T03:34:04Z

8. revise-panda-app-icon-navy-accents
   Id: 8-revise-panda-app-icon-navy-accents
   Scope: Change panda accent colors from purple to deep navy blue while preserving v3 design
   Files: Resources/AppIcon-panda-master-v4.png
   Note: Generated 1024x1024 opaque v4; recolored irises, inner ears, hand pads, and foot pads from purple to deep navy; preserved macaron-blue background and M-down-arrow; visually inspected
   Detail: tasks/details/8-revise-panda-app-icon-navy-accents.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T03:59:06Z
   Done by: CODEX
   Done at: 2026-08-11T04:01:56Z

9. apply-panda-app-icon-v4
   Id: 9-apply-panda-app-icon-v4
   Scope: Replace the macOS AppIcon asset set with the approved macaron-blue panda Markdown icon
   Files: Sources/Assets.xcassets/AppIcon.appiconset/*.png
   Note: Applied approved v4 master to all 10 macOS AppIcon PNG slots; dimensions and opacity validated; actool produced AppIcon.icns and Assets.car successfully; no unit tests requested
   Detail: tasks/details/9-apply-panda-app-icon-v4.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T04:05:55Z
   Done by: CODEX
   Done at: 2026-08-11T04:15:43Z

10. markdown-outline-sidebar
   Id: 10-markdown-outline-sidebar
   Scope: Add a global collapsible, resizable Markdown heading outline to the left of every editor layout
   Files: Sources/EditorView.swift,Sources/MarkdownPreviewView.swift,Sources/MarkdownHTMLRenderer.swift,Sources/MarkdownOutline.swift,Tests/AppTests.swift
   Note: Finished global collapsible Markdown outline sidebar with live heading hierarchy, source/preview navigation and active highlighting; default outline/source/preview ratio 2:4:4; removed outline header divider; no tests per user preference; prior strict compilation succeeded and final diff check passed
   Detail: tasks/details/10-markdown-outline-sidebar.md
   Claimed by: CODEX
   Claimed at: 2026-08-11T07:04:25Z
   Done by: CODEX
   Done at: 2026-08-11T09:11:44Z

11. multi-document-tabs
   Id: 11-multi-document-tabs
   Scope: Add configurable Markdown document opening mode with same-window tabs by default and optional separate windows
   Files: Sources/App.swift,Sources/EditorView.swift,Sources/SettingsView.swift,Tests/AppTests.swift
   Note: Finished configurable document opening mode: default same-window tabs via AppKit tabbing, optional separate windows, current-focused document commands; git diff --check passed; no build/test per project preference
   Detail: tasks/details/11-multi-document-tabs.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T00:20:50Z
   Done by: CODEX
   Done at: 2026-08-12T00:23:15Z

12. fix-document-tab-grouping
   Id: 12-fix-document-tab-grouping
   Scope: Actively group simultaneously opened Markdown document windows into tabs when tab opening mode is selected
   Files: Sources/DocumentOpeningMode.swift,tasks/TASKS.md
   Note: Fixed simultaneous multi-file open by actively adding new document windows to the existing document tab group in tabs mode; removed async window polling; git diff --check passed; no build/test per project preference
   Detail: tasks/details/12-fix-document-tab-grouping.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T00:26:52Z
   Done by: CODEX
   Done at: 2026-08-12T00:30:08Z

13. configurable-theme-color
   Id: 13-configurable-theme-color
   Scope: Add system/custom app theme color setting and apply it to native UI plus Markdown preview accents
   Files: Sources/AppThemeColor.swift,Sources/App.swift,Sources/EditorView.swift,Sources/SettingsView.swift,Sources/MarkdownPreviewView.swift,Sources/MarkdownHTMLRenderer.swift
   Note: Added follow-system/custom theme color setting with live native UI, outline highlight, preview link, and focus updates; strict build succeeded; no tests per user preference
   Detail: tasks/details/13-configurable-theme-color.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T11:49:41Z
   Done by: CODEX
   Done at: 2026-08-12T11:51:29Z

14. fix-outline-row-hit-area
   Id: 14-fix-outline-row-hit-area
   Scope: Expand Markdown outline row hit target to full row width
   Files: Sources/MarkdownOutline.swift
   Note: Added full-row contentShape to outline row buttons; not built or linted per project instructions
   Detail: tasks/details/14-fix-outline-row-hit-area.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T15:52:09Z
   Done by: CODEX
   Done at: 2026-08-12T15:52:28Z

15. refresh-current-document
   Id: 15-refresh-current-document
   Scope: Add toolbar action to reload the current Markdown document from disk with overwrite confirmation
   Files: Sources/EditorView.swift
   Note: Added toolbar refresh action that reloads saved/opened documents from disk with overwrite confirmation; not built per project instructions
   Detail: tasks/details/15-refresh-current-document.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T16:11:40Z
   Done by: CODEX
   Done at: 2026-08-12T16:12:45Z

16. move-refresh-to-titlebar
   Id: 16-move-refresh-to-titlebar
   Scope: Move current document reload action from toolbar into active document titlebar accessory
   Files: Sources/EditorView.swift,Sources/DocumentOpeningMode.swift
   Note: Moved reload action into current document titlebar accessory; direct reload when no local conflict, confirmation only before overwriting local edits; not built per project instructions
   Detail: tasks/details/16-move-refresh-to-titlebar.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T16:33:57Z
   Done by: CODEX
   Done at: 2026-08-12T16:36:54Z

17. fix-titlebar-main-actor
   Id: 17-fix-titlebar-main-actor
   Scope: Fix Swift main actor isolation errors in titlebar reload accessory
   Files: Sources/DocumentOpeningMode.swift
   Note: Fixed Swift 6 main actor isolation for titlebar accessory and corrected NSButton API; macOS xcodebuild succeeded
   Detail: tasks/details/17-fix-titlebar-main-actor.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T16:39:12Z
   Done by: CODEX
   Done at: 2026-08-12T16:43:12Z

18. move-refresh-next-to-outline
   Id: 18-move-refresh-next-to-outline
   Scope: Move reload action from titlebar accessory back into toolbar immediately after outline button
   Files: Sources/EditorView.swift,Sources/DocumentOpeningMode.swift
   Note: Moved reload button next to outline toolbar button, removed titlebar accessory code, and verified macOS build succeeded
   Detail: tasks/details/18-move-refresh-next-to-outline.md
   Claimed by: CODEX
   Claimed at: 2026-08-13T00:17:59Z
   Done by: CODEX
   Done at: 2026-08-13T00:19:10Z

19. document-file-change-monitoring
   Id: 19-document-file-change-monitoring
   Scope: Document real-time Markdown disk change monitoring options, chosen approach, conflict policy, and implementation steps
   Files: docs/plans/2026-08-16-file-change-monitoring-design.md
   Note: Added Chinese design doc covering NSFilePresenter, DispatchSource, FSEvent tradeoffs, recommended parent-directory DispatchSource approach, conflict handling, and implementation steps; no build needed
   Detail: tasks/details/19-document-file-change-monitoring.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T02:56:25Z
   Done by: CODEX
   Done at: 2026-08-16T02:57:30Z

20. editor-font-size-shortcuts
    Id: 19-editor-font-size-shortcuts
    Scope: Add standard Command+Plus and Command+Minus editor font size controls with persisted 11–22 pt limits
    Files: Sources/App.swift,Sources/EditorView.swift,Sources/SettingsView.swift,Tests/AppTests.swift,docs/plans/2026-08-13-editor-font-size-shortcuts-design.md
    Note: Added Format-menu Command+Plus/Command+Minus controls backed by shared persisted 11–22 pt editor font settings, centralized bounds with unit coverage, and verified strict macOS build succeeded; tests and SwiftLint not run per user preference
    Detail: tasks/details/19-editor-font-size-shortcuts.md
    Claimed by: CODEX
    Claimed at: 2026-08-13T03:31:12Z
    Done by: CODEX
    Done at: 2026-08-13T03:34:00Z

21. sync-preview-font-size
    Id: 20-sync-preview-font-size
    Scope: Make Command+Plus and Command+Minus update both source editor and editable Markdown preview without reloading
    Files: Sources/EditorView.swift,Sources/MarkdownPreviewView.swift,Sources/MarkdownHTMLRenderer.swift,Tests/AppTests.swift,docs/plans/2026-08-13-editor-font-size-shortcuts-design.md
    Note: Synchronized persisted font size into Markdown preview CSS with live JavaScript updates that preserve page state; strict macOS build succeeded; tests and SwiftLint not run per user preference
    Detail: tasks/details/20-sync-preview-font-size.md
    Claimed by: CODEX
    Claimed at: 2026-08-13T03:36:53Z
    Done by: CODEX
    Done at: 2026-08-13T03:38:22Z

22. source-folder-organization
    Id: 21-source-folder-organization
    Scope: Reorganize Sources into App, Views, Features, and Infrastructure folders without changing behavior
    Files: Sources,project.yml,docs/plans/2026-08-14-source-folder-organization.md
    Note: Reorganized Sources into App, Views, Features, and Infrastructure folders; updated Info.plist paths; strict macOS build succeeded; file count and unchanged contents verified; tests and SwiftLint not run per user preference
    Detail: tasks/details/21-source-folder-organization.md
    Claimed by: CODEX
    Claimed at: 2026-08-14T03:07:05Z
    Done by: CODEX
    Done at: 2026-08-14T03:09:38Z

23. semantic-bidirectional-scroll-sync
   Id: 23-semantic-bidirectional-scroll-sync
   Scope: Synchronize source editor and preview scrolling bidirectionally using Markdown source anchors without percentage mapping
   Files: Sources/Views/EditorView.swift,Sources/Views/MarkdownPreviewView.swift,Sources/Features/Editor/MarkdownOutline.swift,Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift,Tests/AppTests.swift,docs/plans/2026-08-17-semantic-scroll-sync-design.md
   Note: Implemented bidirectional semantic source-anchor scroll sync without percentage mapping; strict macOS build and two-way UI verification succeeded; JavaScript syntax check passed; tests and SwiftLint not run per local preference
   Detail: tasks/details/23-semantic-bidirectional-scroll-sync.md
   Claimed by: CODEX
   Claimed at: 2026-08-17T07:50:11Z
   Done by: CODEX
   Done at: 2026-08-17T08:34:56Z

24. preview-edit-preserve-markdown
   Id: 24-preview-edit-preserve-markdown
   Scope: Make editable preview patch only changed Markdown blocks and document full HTML-to-Markdown rewrite pitfalls
   Files: Sources/Views/MarkdownPreviewView.swift,Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift,Tests/AppTests.swift,docs/问题记录/预览编辑 Markdown 回写问题记录.md
   Note: Finished block-level editable preview Markdown patching, table/heading Turndown safeguards, regression tests, and pitfall doc; git diff --check and preview JS syntax check passed; SwiftLint/xcodebuild not run per project instructions
   Detail: tasks/details/24-preview-edit-preserve-markdown.md
   Claimed by: CODEX
   Claimed at: 2026-08-18T15:25:19Z
   Done by: CODEX
   Done at: 2026-08-18T15:30:40Z

25. move-preview-edit-doc-to-issue-notes
   Id: 25-move-preview-edit-doc-to-issue-notes
   Scope: Move preview edit pitfall doc into docs issue-notes folder and add old/new implementation snippets
   Files: docs/问题记录/预览编辑 Markdown 回写问题记录.md,tasks/TASKS.md,tasks/details/25-move-preview-edit-doc-to-issue-notes.md
   Note: Moved preview edit pitfall doc into docs/问题记录 and added old/new implementation snippets; git diff --check passed; no SwiftLint/xcodebuild run
   Detail: tasks/details/25-move-preview-edit-doc-to-issue-notes.md
   Claimed by: CODEX
   Claimed at: 2026-08-18T15:44:08Z
   Done by: CODEX
   Done at: 2026-08-18T15:45:17Z

26. document-search-shortcuts
   Id: 26-document-search-shortcuts
   Scope: 实现 Cmd+F 当前源码搜索、Cmd+Shift+F 全部已打开文档搜索、高亮与上一条/下一条跳转
   Files: Sources/Views/EditorView.swift Sources/Features/Editor
   Note: Finished Cmd+F current-source search and Cmd+Shift+F open-document search with NSTextView highlights and previous/next navigation; git diff --check passed; SwiftLint/xcodebuild/tests not run per project instructions
   Detail: tasks/details/26-document-search-shortcuts.md
   Claimed by: CODEX
   Claimed at: 2026-08-20T00:45:07Z
   Done by: CODEX
   Done at: 2026-08-20T00:54:40Z

27. fix-search-bar-layout
   Id: 27-fix-search-bar-layout
   Scope: 修复搜索条窄宽度下输入框被挤压导致搜索文本不可见
   Files: Sources/Views/EditorView.swift
   Note: Fixed search bar compression with adaptive one-line/two-line layout and protected search field width; git diff --check passed; SwiftLint/xcodebuild/tests not run per project instructions
   Detail: tasks/details/27-fix-search-bar-layout.md
   Claimed by: CODEX
   Claimed at: 2026-08-20T01:00:27Z
   Done by: CODEX
   Done at: 2026-08-20T01:02:20Z

28. extract-document-search-bar-view
   Id: 28-extract-document-search-bar-view
   Scope: 将 DocumentSearchBar 从 EditorView 抽到独立 View 文件并补 Preview
   Files: Sources/Views/EditorView.swift Sources/Views/DocumentSearchBar.swift
   Note: Extracted DocumentSearchBar into Sources/Views/DocumentSearchBar.swift and added wide/narrow SwiftUI previews; git diff --check passed; SwiftLint/xcodebuild/tests not run per project instructions
   Detail: tasks/details/28-extract-document-search-bar-view.md
   Claimed by: CODEX
   Claimed at: 2026-08-20T01:03:37Z
   Done by: CODEX
   Done at: 2026-08-20T01:05:25Z

29. compact-search-bar-layout
   Id: 29-compact-search-bar-layout
   Scope: 修复分栏模式下搜索栏过早换行和操作组错位
   Files: Sources/Views/DocumentSearchBar.swift,Sources/Features/Editor/MarkdownOutline.swift
   Note: 搜索栏常规分栏宽度保持紧凑单行，极窄布局操作组靠右；普通命中与当前命中高亮颜色已互换；macOS Debug build succeeded，未运行测试或 SwiftLint
   Detail: tasks/details/29-compact-search-bar-layout.md
   Claimed by: CODEX
   Claimed at: 2026-08-20T03:21:39Z
   Done by: CODEX
   Done at: 2026-08-20T03:40:34Z

30. manual-document-three-way-merge
   Id: 30-manual-document-three-way-merge
   Scope: 设计手动刷新时的三方文本合并、红绿冲突源码模式、冲突导航与计数
   Files: docs/plans/2026-08-21-manual-document-three-way-merge-design.md,docs/plans/2026-08-21-manual-document-three-way-merge.md,tasks/TASKS.md,tasks/details
   Note: 已记录手动三方刷新、源码红绿冲突模式、导航与计数设计及实施计划；git diff --check 通过；未改功能代码，无需构建测试
   Detail: tasks/details/30-manual-document-three-way-merge.md
   Claimed by: CODEX
   Claimed at: 2026-08-21T03:27:27Z
   Done by: CODEX
   Done at: 2026-08-21T03:30:11Z

31. implement-manual-document-three-way-merge
   Id: 31-implement-manual-document-three-way-merge
   Scope: 实现手动刷新三方合并、源码红绿冲突解决、冲突导航与计数
   Files: Sources/Features/Editor/DocumentThreeWayMerge.swift,Sources/Features/Editor/DocumentMergeSession.swift,Sources/Views/DocumentMergeConflictView.swift,Sources/Views/EditorView.swift,Tests/AppTests.swift,tasks/TASKS.md,tasks/details
   Note: 已实现手动刷新三方合并、无标记源码红绿冲突解决、未解决计数与循环导航；严格 App build 和 test build 成功；按用户偏好未运行测试或 SwiftLint；UI 自动化因当前窗口焦点被外部切换而停止
   Detail: tasks/details/31-implement-manual-document-three-way-merge.md
   Claimed by: CODEX
   Claimed at: 2026-08-21T03:39:08Z
   Done by: CODEX
   Done at: 2026-08-21T03:49:54Z

32. cleanup-document-refresh-coordination
   Id: 32-cleanup-document-refresh-coordination
   Scope: Remove unused merge-session state and coordinate refresh reads with the document system
   Files: Sources/Features/Editor/DocumentMergeSession.swift,Sources/Views/DocumentMergeConflictView.swift,Sources/Views/EditorView.swift,Tests/AppTests.swift,docs/plans/2026-08-21-manual-document-three-way-merge.md
   Note: Removed unused originalLocalText state and call-site arguments; refresh now uses NSFileCoordinator .withoutChanges so disk reads remain coordinated without saving local edits first; strict macOS build succeeded; tests and SwiftLint not run per user preference
   Detail: tasks/details/32-cleanup-document-refresh-coordination.md
   Claimed by: CODEX
   Claimed at: 2026-08-21T03:57:52Z
   Done by: CODEX
   Done at: 2026-08-21T04:00:34Z
