import AppKit
import SwiftUI

enum AppThemeColorMode: String, CaseIterable, Identifiable {
    case system
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "跟随系统"
        case .custom:
            "自定义"
        }
    }

    static func stored(rawValue: String) -> AppThemeColorMode {
        AppThemeColorMode(rawValue: rawValue) ?? .system
    }
}

@MainActor
enum AppThemeColor {
    static let modeKey = "themeColorMode"
    static let customHexKey = "themeColorHex"
    static let defaultCustomHex = "#0A84FF"

    static func resolvedColor(modeRawValue: String, customHex: String) -> Color {
        Color(nsColor: resolvedNSColor(modeRawValue: modeRawValue, customHex: customHex))
    }

    static func cssColor(modeRawValue: String, customHex: String) -> String {
        hex(from: resolvedNSColor(modeRawValue: modeRawValue, customHex: customHex))
    }

    static func customColor(hex: String) -> Color {
        Color(nsColor: nsColor(hex: hex) ?? nsColor(hex: defaultCustomHex) ?? .controlAccentColor)
    }

    static func hex(from color: Color) -> String {
        hex(from: NSColor(color))
    }

    private static func resolvedNSColor(modeRawValue: String, customHex: String) -> NSColor {
        switch AppThemeColorMode.stored(rawValue: modeRawValue) {
        case .system:
            .controlAccentColor
        case .custom:
            nsColor(hex: customHex) ?? nsColor(hex: defaultCustomHex) ?? .controlAccentColor
        }
    }

    private static func nsColor(hex: String) -> NSColor? {
        let normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else { return nil }

        return NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func hex(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return defaultCustomHex }
        return String(
            format: "#%02X%02X%02X",
            Int((rgb.redComponent * 255).rounded()),
            Int((rgb.greenComponent * 255).rounded()),
            Int((rgb.blueComponent * 255).rounded())
        )
    }
}
