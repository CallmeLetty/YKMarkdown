import Foundation

enum MermaidScript {
    static let source: String = {
        guard let url = Bundle.main.url(forResource: "mermaid.min", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8)
        else { return "" }
        return source
    }()
}
