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

