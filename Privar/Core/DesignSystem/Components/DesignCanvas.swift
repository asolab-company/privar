import SwiftUI

struct DesignCanvas<Content: View>: View {
  var compactHeight: CGFloat = 852
  @ViewBuilder var content: (CGFloat, CGFloat) -> Content
  var body: some View {
    GeometryReader { g in
      let h = max(g.size.height, g.size.width < 393 ? compactHeight : 852)
      let w = max(g.size.width, 320)
      ScrollView(.vertical) {
        ZStack(alignment: .topLeading) { content(w, h) }.frame(
          width: g.size.width, height: h, alignment: .topLeading)
      }.scrollIndicators(.hidden)
    }.ignoresSafeArea()
  }
}
