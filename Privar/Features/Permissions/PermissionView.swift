import SwiftUI

struct PermissionView: View {
  @Bindable var app: AppState
  let mode: ScannerMode
  var body: some View {
    DesignCanvas { w, h in
      DesignText(text: mode.title, size: 24, weight: .bold, width: w - 88).offset(x: 19, y: 62)
      DesignText(text: mode.description, color: Theme.muted, width: min(254, w - 38)).offset(
        x: 19, y: 99)
      Button {
        app.go(.settings)
      } label: {
        Image("settings").resizable().scaledToFit().frame(width: 19.2, height: 19.2)
          .frame(width: 44, height: 44).contentShape(.rect)
      }.offset(x: w - 57, y: 54).accessibilityLabel("Settings")
      Image(mode == .bluetooth ? "iconBluetoothLarge" : "iconCameraLarge").resizable().frame(
        width: 150, height: 150
      ).position(x: w / 2, y: 341)
      DesignText(
        text: mode == .bluetooth ? "Allow Bluetooth Access" : "Allow Camera Access", size: 24,
        weight: .bold, width: w - 38, centered: true
      ).offset(x: 19, y: 439)
      DesignText(
        text: mode == .bluetooth
          ? "Privar needs Bluetooth access to discover and identify nearby Bluetooth devices."
          : "Privar needs access to your camera to scan your surroundings and help detect potential hidden cameras.",
        width: min(mode == .bluetooth ? 291 : 341, w - 52), centered: true
      ).offset(x: (w - min(mode == .bluetooth ? 291 : 341, w - 52)) / 2, y: 475)
      PrimaryButton(title: "Allow Access") { app.start(mode, authorized: true) }.frame(
        width: min(264, w - 38)
      ).position(x: w / 2, y: 559)
      ScannerTabBar(selected: mode) { mode in
        app.selectedMode = mode
        app.go(.home)
      }.frame(width: w - 37).offset(x: 19, y: h - 88)
    }
  }
}
