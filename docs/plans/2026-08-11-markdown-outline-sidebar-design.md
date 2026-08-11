# Global Markdown Outline Sidebar

## Interaction

The outline is the first pane in the document window, outside both the source editor and the editable preview. It remains in the same position when the user switches between editor-only, split, and preview-only layouts. A native split-view divider lets the user resize the outline, while toolbar and in-sidebar controls toggle it without changing the selected editor layout.

The outline is generated live from ATX headings (`#` through `######`). Each row is indented according to its heading level. Fenced code blocks are excluded so Markdown examples do not create false outline entries. An empty document or a document without headings shows a compact empty state.

Selecting an outline row navigates every visible document pane to the corresponding heading. The selected or currently visible heading is highlighted, including while the user scrolls the source editor or preview. Heading identifiers are based on source order rather than title text, so duplicate titles remain independently addressable.

## Architecture and verification

`MarkdownOutlineParser` is the shared source of heading levels, titles, source ranges, and stable per-render identifiers. The source editor uses a native text view wrapper to expose range-based scrolling. The preview renderer adds matching identifiers to heading HTML, while its script reports scroll position and accepts navigation requests through the existing WebKit bridge.

Parser tests cover hierarchy, duplicate headings, code fences, and invalid heading syntax. Renderer tests cover heading identifiers and preview navigation support. The full macOS test target and application build verify strict-concurrency and warnings-as-errors compatibility. A launched-app screenshot verifies pane placement, hierarchy, resizing, toggling, and visual consistency.
