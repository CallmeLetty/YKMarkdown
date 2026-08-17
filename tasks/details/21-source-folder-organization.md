# 21-source-folder-organization

- Number: 21
- Slug: source-folder-organization

## Notes

- `Sources/App` contains the application entry point and command wiring.
- `Sources/Views` contains SwiftUI views and the WebKit-backed preview view.
- `Sources/Features/Blog` and `Sources/Features/Editor` contain domain models and feature behavior.
- `Sources/Infrastructure` contains design-system helpers, rendering adapters, services, security storage, and bundled resources.
- `project.yml` and the checked-in Xcode project both reference the relocated application `Info.plist`.
- Strict macOS build succeeded. Tests and SwiftLint were not run, following the user's stored workflow preference.
