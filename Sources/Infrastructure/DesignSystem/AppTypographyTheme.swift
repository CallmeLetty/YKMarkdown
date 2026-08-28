import AppKit
import SwiftUI

enum AppTypographyTheme: String, CaseIterable, Identifiable {
    case writing
    case minimal
    case developer

    static let storageKey = "typographyTheme"
    static let defaultTheme = AppTypographyTheme.writing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .writing:
            "温润写作"
        case .minimal:
            "现代极简"
        case .developer:
            "程序员"
        }
    }

    var note: String {
        switch self {
        case .writing:
            "宋体预览、舒展行距与偏暖纸张，适合中文长文。"
        case .minimal:
            "清爽无衬线与克制层级，适合日常笔记和短文。"
        case .developer:
            "暗色等宽、高信息密度，适合技术文档与代码。"
        }
    }

    var defaultBackgroundHex: String {
        switch self {
        case .writing:
            "#FFFDF8"
        case .minimal:
            "#FFFFFF"
        case .developer:
            "#19201E"
        }
    }

    var editorLineHeightMultiple: CGFloat {
        switch self {
        case .writing:
            1.55
        case .minimal:
            1.45
        case .developer:
            1.50
        }
    }

    var editorInset: NSSize {
        switch self {
        case .writing:
            NSSize(width: 26, height: 22)
        case .minimal:
            NSSize(width: 30, height: 24)
        case .developer:
            NSSize(width: 22, height: 18)
        }
    }

    func editorFont(size: CGFloat) -> NSFont {
        switch self {
        case .writing:
            NSFont(name: "SFMono-Regular", size: size)
                ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        case .minimal:
            NSFont(name: "AvenirNext-Regular", size: size)
                ?? .systemFont(ofSize: size, weight: .regular)
        case .developer:
            NSFont(name: "SFMono-Regular", size: size)
                ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    static func stored(rawValue: String) -> AppTypographyTheme {
        AppTypographyTheme(rawValue: rawValue) ?? defaultTheme
    }
}

struct ResolvedTypographyAppearance {
    let theme: AppTypographyTheme
    let backgroundColor: NSColor
    let foregroundColor: NSColor
    let backgroundCSS: String
    let foregroundCSS: String
    let colorSchemeCSS: String
}

@MainActor
enum AppTypographyAppearance {
    static let customBackgroundEnabledKey = "customEditorBackgroundEnabled"
    static let customBackgroundHexKey = "customEditorBackgroundHex"
    static let defaultCustomBackgroundHex = AppTypographyTheme.writing.defaultBackgroundHex

    static func resolve(
        themeRawValue: String,
        customBackgroundEnabled: Bool,
        customBackgroundHex: String
    ) -> ResolvedTypographyAppearance {
        let theme = AppTypographyTheme.stored(rawValue: themeRawValue)
        let fallbackHex = theme.defaultBackgroundHex
        let requestedHex = customBackgroundEnabled ? customBackgroundHex : fallbackHex
        let backgroundColor = AppThemeColor.nsColor(hex: requestedHex)
            ?? AppThemeColor.nsColor(hex: fallbackHex)
            ?? .textBackgroundColor
        let foregroundColor = contrastingForeground(for: backgroundColor)

        return ResolvedTypographyAppearance(
            theme: theme,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            backgroundCSS: AppThemeColor.hex(from: backgroundColor),
            foregroundCSS: AppThemeColor.hex(from: foregroundColor),
            colorSchemeCSS: relativeLuminance(of: foregroundColor) > 0.5 ? "dark" : "light"
        )
    }

    static func customBackgroundColor(hex: String) -> Color {
        let color = AppThemeColor.nsColor(hex: hex)
            ?? AppThemeColor.nsColor(hex: defaultCustomBackgroundHex)
            ?? .textBackgroundColor
        return Color(nsColor: color)
    }

    private static func contrastingForeground(for background: NSColor) -> NSColor {
        let dark = AppThemeColor.nsColor(hex: "#202522") ?? .textColor
        let light = AppThemeColor.nsColor(hex: "#F2F6F4") ?? .textColor
        let backgroundLuminance = relativeLuminance(of: background)
        let darkContrast = contrastRatio(backgroundLuminance, relativeLuminance(of: dark))
        let lightContrast = contrastRatio(backgroundLuminance, relativeLuminance(of: light))
        return darkContrast >= lightContrast ? dark : light
    }

    private static func contrastRatio(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(of color: NSColor) -> CGFloat {
        guard let rgb = color.usingColorSpace(.sRGB) else { return 0 }

        func linearized(_ component: CGFloat) -> CGFloat {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearized(rgb.redComponent)
            + 0.7152 * linearized(rgb.greenComponent)
            + 0.0722 * linearized(rgb.blueComponent)
    }
}
