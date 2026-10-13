import SwiftUI

struct HomeView: View {
  @Bindable var app: AppState
  var body: some View {
    DesignCanvas { w, h in
      DesignText(text: app.selectedMode.title, size: 24, weight: .bold, width: w - 88).offset(
        x: 19, y: 62)
      DesignText(
        text: app.selectedMode.description, color: Theme.muted,
        width: min(app.selectedMode == .signals ? 287 : 254, w - 38)
      ).offset(x: 19, y: 99)
      Button {
        app.go(.settings)
      } label: {
        Image("settings").resizable().scaledToFit().frame(width: 19.2, height: 19.2).frame(
          width: 44, height: 44
        ).contentShape(.rect)
      }.offset(x: w - 57, y: 54).accessibilityLabel("Settings")
      Image("hero" + app.selectedMode.label).resizable().scaledToFill().frame(
        width: w, height: h - 372
      )
      .clipped().mask {
        if app.selectedMode == .bluetooth {
          Rectangle().fill(.white)
        } else {
          LinearGradient(
            stops: [
              .init(color: .clear, location: 0), .init(color: .white, location: 0.1298077),
              .init(color: .white, location: 0.8846154), .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
      }.offset(y: 165)
      PrimaryButton(title: "Start Scan") { app.start(app.selectedMode) }.frame(width: w - 37)
        .offset(x: 19, y: h - 179)
      ScannerTabBar(selected: app.selectedMode) { mode in
        app.stopHardware()
        app.selectedMode = mode
      }.frame(width: w - 37).offset(x: 19, y: h - 88)
    }
  }
}
