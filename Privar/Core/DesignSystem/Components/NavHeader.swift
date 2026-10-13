import SwiftUI

struct NavHeader: View {
  let title: String
  var back: () -> Void
  var body: some View {
    ZStack {
      Text(title).font(Theme.font(20, .bold)).lineLimit(1).padding(.horizontal, 32)
        .allowsHitTesting(false)
      HStack {
        Button(action: {
          back()
        }) {
          Image("back").resizable().scaledToFit().frame(width: 19.2, height: 19.2).frame(
            width: 44, height: 44
          ).contentShape(.rect)
        }.accessibilityLabel("Back").offset(x: -6)
        Spacer()
      }
    }.frame(height: 44)
  }
}
