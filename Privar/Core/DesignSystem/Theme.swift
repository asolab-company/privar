import CoreText
import SwiftUI

enum Theme {
  static let green = Color(red: 169 / 255, green: 250 / 255, blue: 99 / 255)
  static let muted = Color(red: 127 / 255, green: 127 / 255, blue: 127 / 255)
  static let card = Color.white.opacity(0.05)
  static let settingsCard = Color.white.opacity(0.025)
  static let deviceCard = Color.white.opacity(0.045)
  static let background = LinearGradient(
    colors: [
      Color(red: 0.1282049268, green: 0.1282049268, blue: 0.1282049268),
      Color(red: 0, green: 0.04705882445, blue: 0.02352941222),
    ], startPoint: .top, endPoint: .bottom)
  static func uiFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> UIFont {
    let uiWeight: UIFont.Weight =
      weight == .bold
      ? .bold : weight == .medium ? .medium : weight == .semibold ? .semibold : .regular
    let base = UIFont.systemFont(ofSize: size, weight: uiWeight)
    let descriptor = base.fontDescriptor.addingAttributes([
      UIFontDescriptor.AttributeName(rawValue: kCTFontOpticalSizeAttribute as String): 72
    ])
    return UIFont(descriptor: descriptor, size: size)
  }
  static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    Font(uiFont(size, weight))
  }
}
