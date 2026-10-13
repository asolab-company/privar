import SwiftUI

struct PrimaryButton: View {
  let title: String
  var outlined = false
  var icon: String?
  var height: CGFloat = 48
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let icon { Image(icon).resizable().scaledToFit().frame(width: 20, height: 20) }
        Text(title)
      }.font(Theme.font(16, .bold)).frame(maxWidth: .infinity, minHeight: height).foregroundStyle(
        outlined ? Theme.green : Color(red: 13 / 255, green: 29 / 255, blue: 0)
      ).background {
        if outlined {
          Capsule().fill(Color(red: 0.0520037, green: 0.1121794, blue: 0).opacity(0.3))
        } else {
          Capsule().fill(
            Theme.green.shadow(
              .inner(color: Color(red: 0.18552, green: 0.65705, blue: 0), radius: 2)))
        }
      }.overlay { Capsule().strokeBorder(Theme.green, lineWidth: outlined ? 3 : 0) }.shadow(
        color: outlined ? .clear : Color(red: 0.283, green: 1, blue: 0).opacity(0.8), radius: 4)
    }.buttonStyle(.plain).accessibilityIdentifier(title)
  }
}
