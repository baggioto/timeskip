import SwiftUI

/// Color tokens, mirrored from the `Timeskip` variable collection in Figma (mode: Dark).
enum Theme {
    static let background = Color(hex: 0x0E0F13)
    static let surface = Color(hex: 0x1A1C22)
    static let raised = Color(hex: 0x2A2D36)
    static let tabBar = Color(hex: 0x14151A)
    static let border = Color(hex: 0x262830)
    static let text = Color(hex: 0xF2F2F5)
    static let textSecondary = Color(hex: 0xC9CCD6)
    static let textMuted = Color(hex: 0xA3A6B0)
    static let accent = Color(hex: 0xF5B841)
    static let onAccent = Color(hex: 0x1A1300)
}

extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xF5B841)`.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
