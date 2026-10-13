import SwiftUI

struct GuideListView: View {
  @Bindable var app: AppState
  var body: some View {
    DesignCanvas(compactHeight: 1010) { w, _ in
      NavHeader(title: "Privacy Guide") { app.go(.settings) }.frame(width: w - 37).offset(
        x: 19, y: 54)
      VStack(spacing: 8) {
        ForEach(Guide.all) { guide in
          Button {
            app.go(.guide(guide.id))
          } label: {
            HStack(alignment: .top, spacing: 14) {
              Image(guide.thumbnail).resizable().scaledToFill().frame(
                width: 142, height: w < 393 ? 210 : 172
              ).clipped()
              VStack(alignment: .leading, spacing: 8) {
                Text(guide.cardTitle).font(Theme.font(16, .bold))
                Text(guide.summary).font(Theme.font(14)).fixedSize(
                  horizontal: false, vertical: true)
                Text("Learn More →").font(Theme.font(16, .medium)).underline()
              }.frame(maxWidth: .infinity, alignment: .leading).padding(.trailing, 16).padding(
                .top, 16)
            }.frame(height: w < 393 ? 210 : 172).background(Theme.card, in: .rect(cornerRadius: 24))
              .clipShape(
                .rect(cornerRadius: 24))
          }.buttonStyle(.plain).accessibilityIdentifier("guide." + guide.id)
        }
      }.frame(width: w - 37).offset(x: 19, y: 124)
    }
  }
}
