import AppKit
import SwiftUI

struct ResolvedTypographyAppearance {
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
    static let defaultBackgroundHex = "#FFFFFF"
    static let defaultCustomBackgroundHex = defaultBackgroundHex
    static let editorLineHeightMultiple = EditorLineSpacing.sourceBaseLineHeight
    static let editorInset = NSSize(width: 24, height: 24)

    /// 默认源码区使用浅灰底；自定义背景仍在两个编辑区域保持一致。
    static func sourceBackground(for appearance: ResolvedTypographyAppearance, isCustom: Bool) -> NSColor {
        if isCustom { return appearance.backgroundColor }
        return AppThemeColor.nsColor(hex: "#F8F8F7") ?? appearance.backgroundColor
    }

    static func editorFont(size: CGFloat) -> NSFont {
        NSFont(name: "SFMono-Regular", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func resolve(
        customBackgroundEnabled: Bool,
        customBackgroundHex: String
    ) -> ResolvedTypographyAppearance {
        let requestedHex = customBackgroundEnabled ? customBackgroundHex : defaultBackgroundHex
        let backgroundColor = AppThemeColor.nsColor(hex: requestedHex)
            ?? AppThemeColor.nsColor(hex: defaultBackgroundHex)
            ?? .textBackgroundColor
        let foregroundColor = contrastingForeground(for: backgroundColor)

        return ResolvedTypographyAppearance(
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
