import AppKit
import Foundation
import UniformTypeIdentifiers

enum ImageImportService {
    enum ImportError: LocalizedError, Equatable {
        case documentNotSaved
        case unsupportedFile
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .documentNotSaved:
                return "请先保存 Markdown 文件，图片会复制到同目录的 assets 文件夹。"
            case .unsupportedFile:
                return "不支持的图片格式。"
            case .writeFailed:
                return "无法写入图片文件。"
            }
        }
    }

    struct ImportedImage: Equatable {
        let markdown: String
        let relativePath: String
        let altText: String
    }

    static let assetsFolderName = "assets"

    static func importFile(at sourceURL: URL, documentURL: URL?) throws -> ImportedImage {
        guard let documentURL else { throw ImportError.documentNotSaved }
        guard isImageFile(sourceURL) else { throw ImportError.unsupportedFile }

        let assetsDirectory = assetsDirectory(for: documentURL)
        try FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)

        let destinationURL = uniqueDestination(for: sourceURL, in: assetsDirectory)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let relativePath = "\(assetsFolderName)/\(destinationURL.lastPathComponent)"
        let altText = destinationURL.deletingPathExtension().lastPathComponent
        return ImportedImage(
            markdown: "![\(altText)](\(relativePath))",
            relativePath: relativePath,
            altText: altText
        )
    }

    @MainActor
    static func importPasteboardImages(documentURL: URL?) throws -> [ImportedImage] {
        guard documentURL != nil else { throw ImportError.documentNotSaved }

        let pasteboard = NSPasteboard.general
        var results: [ImportedImage] = []

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] {
            for url in urls where isImageFile(url) {
                results.append(try importFile(at: url, documentURL: documentURL))
            }
        }

        if results.isEmpty, let image = NSImage(pasteboard: pasteboard) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("pasted-\(UUID().uuidString).png")
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:])
            else {
                throw ImportError.writeFailed
            }
            try png.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            results.append(try importFile(at: tempURL, documentURL: documentURL))
        }

        return results
    }

    @MainActor
    static func chooseImageURLs() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .bmp, .tiff, .heic]
        panel.message = "选择要插入的图片（将复制到文档旁的 assets 目录）"
        return panel.runModal() == .OK ? panel.urls : []
    }

    private static func assetsDirectory(for documentURL: URL) -> URL {
        documentURL
            .deletingLastPathComponent()
            .appendingPathComponent(assetsFolderName, isDirectory: true)
    }

    private static func uniqueDestination(for sourceURL: URL, in directory: URL) -> URL {
        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let base = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directory.appendingPathComponent("\(base).\(ext)")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base)-\(suffix).\(ext)")
            suffix += 1
        }
        return candidate
    }

    private static func isImageFile(_ url: URL) -> Bool {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .image)
        }
        let ext = url.pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tif", "tiff", "heic"].contains(ext)
    }
}
