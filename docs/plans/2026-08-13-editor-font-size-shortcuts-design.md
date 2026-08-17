# Editor Font Size Shortcuts Design

## Goal

Add standard macOS keyboard controls for the Markdown editor: Command-Plus increases the font size and Command-Minus decreases it. Each invocation changes the size by 1 pt. The existing 11–22 pt range and persisted preference remain the source of truth, so changes made from the menu immediately update open source editors, Markdown previews, and the Settings slider.

## Design

Three approaches were considered: handling key events inside `NSTextView`, exposing per-window actions through `FocusedValues`, and defining SwiftUI menu commands that update the shared `AppStorage` preference. Text-view event handling would work only while the source editor owns keyboard focus and could interfere with native text input. Focused actions would support window-specific state, but the current font size is deliberately shared across every document. The menu-command approach best matches that model and gives users discoverable Format-menu items alongside the shortcuts.

`EditorFontSize` centralizes the storage key, default, limits, step, and bounded increase/decrease operations. `EditorView`, `SettingsView`, and the commands use these values instead of repeating literals. The new commands are inserted after the system text-formatting commands and are disabled at their respective limits. Updating `AppStorage` propagates through SwiftUI to every source editor and the Settings view. `EditorView` also passes the same value to `MarkdownPreviewView`, which updates a CSS base-font-size variable through JavaScript. This preserves the preview's scroll position, selection, and editing focus because the page does not reload. Relative heading and code sizes continue to scale from the shared base size, while images and layout spacing remain unchanged.

## Verification

Unit tests cover normal increments/decrements, both boundaries, and generated preview font-size support. A macOS build verifies the command placement, keyboard shortcut APIs, and WebKit update path compile in the deployment target. No SwiftLint step is run.
