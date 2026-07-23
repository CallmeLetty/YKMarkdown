import Foundation

struct BlogUploadSettings: Equatable {
    var owner: String
    var repo: String
    var branch: String
    var contentDirectory: String

    static let `default` = BlogUploadSettings(
        owner: "CallmeLetty",
        repo: "Yakamoz-Blog",
        branch: "main",
        contentDirectory: "content"
    )

    var repositoryFullName: String { "\(owner)/\(repo)" }

    var contentURL: URL? {
        URL(string: "https://github.com/\(owner)/\(repo)/tree/\(branch)/\(contentDirectory)")
    }
}

enum GitHubBlogUploader {
    struct UploadResult: Equatable {
        let markdownPath: String
        let htmlURL: URL?
        let uploadedAssetCount: Int
    }

    enum UploadError: LocalizedError {
        case missingToken
        case invalidSettings
        case invalidSlug
        case http(Int, String)
        case decoding
        case localAssetMissing(String)

        var errorDescription: String? {
            switch self {
            case .missingToken:
                return "请先在设置中配置 GitHub Token（需要 repo 权限）。"
            case .invalidSettings:
                return "仓库配置不完整，请检查设置里的 Owner / Repo。"
            case .invalidSlug:
                return "文件名（slug）无效，请使用字母、数字和连字符。"
            case .http(let code, let message):
                return "GitHub API 错误 (\(code)): \(message)"
            case .decoding:
                return "无法解析 GitHub 响应。"
            case .localAssetMissing(let path):
                return "找不到本地图片：\(path)"
            }
        }
    }

    static let tokenAccount = "github-token"

    static func upload(
        markdown: String,
        frontmatter: BlogFrontmatter,
        slug: String,
        documentDirectory: URL?,
        settings: BlogUploadSettings,
        token: String,
        commitMessage: String
    ) async throws -> UploadResult {
        let normalizedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSlug.isEmpty,
              normalizedSlug.range(of: #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#, options: .regularExpression) != nil
        else {
            throw UploadError.invalidSlug
        }
        guard !settings.owner.isEmpty, !settings.repo.isEmpty else {
            throw UploadError.invalidSettings
        }
        guard !token.isEmpty else { throw UploadError.missingToken }

        let (_, body) = BlogFrontmatter.parse(from: markdown)
        var preparedBody = body
        var uploadedAssets = 0

        let imagePaths = referencedLocalImagePaths(in: body)
        for relativePath in imagePaths {
            guard let documentDirectory else {
                throw UploadError.localAssetMissing(relativePath)
            }
            let localURL = documentDirectory.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: localURL.path) else {
                throw UploadError.localAssetMissing(relativePath)
            }

            let fileName = localURL.lastPathComponent
            let remotePath = "\(settings.contentDirectory)/assets/\(normalizedSlug)/\(fileName)"
            let data = try Data(contentsOf: localURL)
            _ = try await putFile(
                path: remotePath,
                content: data,
                message: "\(commitMessage) (asset)",
                settings: settings,
                token: token
            )
            uploadedAssets += 1

            let rawURL = "https://raw.githubusercontent.com/\(settings.owner)/\(settings.repo)/\(settings.branch)/\(remotePath)"
            preparedBody = preparedBody.replacingOccurrences(of: "](\(relativePath))", with: "](\(rawURL))")
        }

        let finalMarkdown = frontmatter.render(body: preparedBody)
        let markdownPath = "\(settings.contentDirectory)/\(normalizedSlug).md"
        let response = try await putFile(
            path: markdownPath,
            content: Data(finalMarkdown.utf8),
            message: commitMessage,
            settings: settings,
            token: token
        )

        return UploadResult(
            markdownPath: markdownPath,
            htmlURL: response.htmlURL.flatMap(URL.init(string:)),
            uploadedAssetCount: uploadedAssets
        )
    }

    private struct PutResponse: Decodable {
        let content: Content?

        struct Content: Decodable {
            let htmlURL: String?

            enum CodingKeys: String, CodingKey {
                case htmlURL = "html_url"
            }
        }

        var htmlURL: String? { content?.htmlURL }
    }

    private struct ContentInfo: Decodable {
        let sha: String
    }

    private struct APIErrorBody: Decodable {
        let message: String?
    }

    private static func putFile(
        path: String,
        content: Data,
        message: String,
        settings: BlogUploadSettings,
        token: String
    ) async throws -> PutResponse {
        let encodedPath = path
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")

        let apiURL = URL(string: "https://api.github.com/repos/\(settings.owner)/\(settings.repo)/contents/\(encodedPath)")!
        let existingSHA = try await fetchSHA(url: apiURL, token: token)

        var payload: [String: Any] = [
            "message": message,
            "content": content.base64EncodedString(),
            "branch": settings.branch,
        ]
        if let existingSHA {
            payload["sha"] = existingSHA
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("YKMarkdown", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(code) else {
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw UploadError.http(code, message)
        }
        do {
            return try JSONDecoder().decode(PutResponse.self, from: data)
        } catch {
            throw UploadError.decoding
        }
    }

    private static func fetchSHA(url: URL, token: String) async throws -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("YKMarkdown", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        if code == 404 { return nil }
        guard (200...299).contains(code) else {
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw UploadError.http(code, message)
        }
        return try JSONDecoder().decode(ContentInfo.self, from: data).sha
    }

    private static func referencedLocalImagePaths(in markdown: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"!\[[^\]]*\]\(([^)\s]+)\)"#, options: []) else {
            return []
        }
        let nsRange = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: nsRange)
        var paths: [String] = []
        for match in matches {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: markdown)
            else { continue }
            let path = String(markdown[range])
            if path.hasPrefix("http://") || path.hasPrefix("https://") || path.hasPrefix("data:") {
                continue
            }
            if !paths.contains(path) {
                paths.append(path)
            }
        }
        return paths
    }
}
