# 23-semantic-bidirectional-scroll-sync

- Number: 23
- Slug: semantic-bidirectional-scroll-sync

## Notes

- Added UTF-16 source offsets to top-level rendered Markdown blocks so native text storage and preview DOM share exact semantic anchors.
- Wired source-to-preview and preview-to-source scroll requests through `EditorView`, with token deduplication and programmatic-scroll suppression on both sides.
- Kept outline active-heading reporting and outline navigation independent from scroll synchronization.
- Verified JavaScript syntax and a strict macOS build; no unit tests or SwiftLint were run per local preference.
- Visually verified both directions with an unsaved 18-section document containing paragraphs, lists, fenced code blocks, and tables.
