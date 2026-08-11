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

