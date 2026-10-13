import SwiftUI

struct LoadingView: View {
  var body: some View {
    DesignCanvas { w, h in
      Image("iconLogo").resizable().scaledToFit().frame(width: 250, height: 250).position(
        x: w / 2, y: 426
      ).allowsHitTesting(false)
      Text("Loading...").font(Theme.font(14)).foregroundStyle(Theme.muted).position(
        x: w / 2, y: h - 48)
    }
  }
}
