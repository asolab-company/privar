import SwiftUI

struct BluetoothResultsView: View {
  @Bindable var app: AppState
  var body: some View {
    DesignCanvas { w, h in
      NavHeader(
        title: app.bluetooth.scanning
          ? "Scanning For Devices"
          : (app.currentDevices.isEmpty ? "No Devices Found" : "Devices Found")
      ) { app.go(.home) }.frame(width: w - 37).offset(x: 19, y: 54)
      if app.bluetooth.scanning {
        RadarView(animated: app.bluetooth.scanning).position(x: w / 2, y: 274)
        DesignText(text: "Scanning...", size: 20, weight: .bold, width: w - 38, centered: true)
          .offset(x: 19, y: 448)
        DesignText(
          text: "Searching for nearby devices · \(app.bluetooth.remaining)s", color: Theme.muted,
          width: w - 38,
          centered: true
        ).foregroundStyle(Theme.muted).offset(x: 19, y: 476)
        ScrollView {
          VStack(spacing: 8) {
            ForEach(app.filteredDevices) { device in
              DeviceCard(device: device) { app.go(.device(device.id)) }
            }
          }
        }.frame(width: w - 38, height: h - 566).offset(x: 19, y: 511)
      } else if app.currentDevices.isEmpty {
        Image("iconBluetoothOff").resizable().frame(width: 150, height: 150).position(
          x: w / 2, y: 274
        ).allowsHitTesting(false)
        DesignText(
          text: "No Bluetooth Devices\nWere Detected Nearby", size: 24, weight: .bold,
          width: w - 38, centered: true
        ).offset(x: 19, y: 373)
        DesignText(
          text:
            "Try moving around the room and scanning again. Make sure Bluetooth is enabled and keep your iPhone close to the area you want to check.",
          width: w - 74, centered: true
        ).offset(x: 37, y: 439)
        InspectionNote(guide: { app.go(.guides) }).frame(width: w - 37).offset(
          x: 19, y: h - (app.canContinueBluetooth ? 334 : 268))
        if app.canContinueBluetooth {
          PrimaryButton(title: "Continue Scanning", outlined: true) {
            app.start(.bluetooth, continuing: true)
          }.frame(width: w - 37).offset(x: 19, y: h - 179)
        }
        PrimaryButton(title: "Scan Again") { app.start(.bluetooth) }.frame(width: w - 37).offset(
          x: 19, y: h - 113)
      } else {
        ScrollView(.horizontal) {
          HStack(spacing: 8) {
            filterButton(nil)
            ForEach(DeviceStatus.allCases, id: \.self) { filterButton($0) }
          }
        }.accessibilityIdentifier("deviceFilters").scrollIndicators(.hidden).scrollClipDisabled()
          .frame(
            width: w - 19, height: 38
          ).offset(x: 19, y: 124)
        ScrollView {
          VStack(spacing: 8) {
            ForEach(app.filteredDevices) { device in
              DeviceCard(device: device) { app.go(.device(device.id)) }
            }
          }
        }.accessibilityIdentifier("deviceResults").frame(
          width: w - 38, height: max(64, h - (app.canContinueBluetooth ? 179 : 113) - 16 - 183)
        ).offset(x: 19, y: 183)
        if app.canContinueBluetooth {
          PrimaryButton(title: "Continue Scanning", outlined: true) {
            app.start(.bluetooth, continuing: true)
          }.frame(width: w - 37).offset(x: 19, y: h - 179)
        }
        PrimaryButton(title: "Scan Again") { app.start(.bluetooth) }.frame(width: w - 37).offset(
          x: 19, y: h - 113)
      }
    }
  }
  private func filterButton(_ status: DeviceStatus?) -> some View {
    Button {
      app.filter = status
    } label: {
      Text(
        "\(status?.rawValue ?? "All") (\(app.currentDevices.filter{status==nil || $0.status==status}.count))"
      ).font(Theme.font(16, app.filter == status ? .bold : .medium)).padding(.horizontal, 16).frame(
        height: 38
      ).background(
        app.filter == status ? Theme.green : Theme.card, in: .capsule
      ).foregroundStyle(app.filter == status ? Color.black : Color.white)
    }.shadow(color: app.filter == status ? Theme.green.opacity(0.8) : .clear, radius: 4)
      .accessibilityIdentifier("filter." + (status?.rawValue ?? "All"))
  }
}
