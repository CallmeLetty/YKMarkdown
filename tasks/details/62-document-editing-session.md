# 62-document-editing-session

- Number: 62
- Slug: document-editing-session

## Notes

- Added `DocumentEditingState` as the only committed Markdown state machine, with revision, origin, UTF-16 text changes, stale-revision rejection, and invalid-range rejection.
- Routed source edits, preview edits, reload, merge completion, image insertion, and FileDocument synchronization through `DocumentMutation`; only the accepted snapshot is mirrored back to `MarkdownDocument.text`.
- Changed the AppKit source adapter to receive snapshots by revision. Marked text remains owned by `NSTextView`, transient IME selection does not enter position synchronization, and local snapshot echoes no longer reset `string`.
- Changed the WebKit preview adapter to use the same revision protocol. JavaScript now treats `compositionstart` through `compositionend` as one edit transaction and emits one Markdown patch after composition commits.
- Added an accepted ADR, architecture design, implementation plan, and Swift Testing coverage for revision behavior, Unicode/CRLF text changes, preview composition hooks, and deferred AppKit marked text.
- Verification: strict Swift 6 application build succeeded; application and test targets succeeded with `build-for-testing`; tests were not executed per local preference.
- UI verification: ordinary source input updated the preview, and preview editing updated the source in an unsaved temporary document. The automation environment could not activate a Chinese input source, so real Chinese candidate-window input remains a manual verification item.
