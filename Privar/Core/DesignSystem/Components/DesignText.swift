import SwiftUI

struct DesignText: View {
  let text: String
  var size: CGFloat = 14
  var weight: Font.Weight = .regular
  var color: Color = .white
  var width: CGFloat
  var centered = false
  var lines: Int?
  var body: some View {
    Text(text).font(Theme.font(size, weight)).foregroundStyle(color).lineSpacing(0).lineLimit(lines)
      .multilineTextAlignment(centered ? .center : .leading).frame(
        width: width, alignment: centered ? .center : .leading
      ).fixedSize(horizontal: false, vertical: true).allowsHitTesting(false)
  }
}
