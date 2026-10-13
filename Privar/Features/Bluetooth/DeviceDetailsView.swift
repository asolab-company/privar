import SwiftUI

struct DeviceDetailsView: View {
  @Bindable var app: AppState
  let id: UUID
  var body: some View {
    if let d = app.store.devices.first(where: { $0.id == id }) {
      DesignCanvas { w, h in
        NavHeader(title: "Device Information") { app.go(.bluetoothResults) }.frame(width: w - 37)
          .offset(x: 19, y: 54)
        Image(d.category?.icon ?? "deviceUnknown").resizable().scaledToFit().frame(
          width: 32, height: 32
        ).offset(
          x: (w - 32) / 2, y: 124
        ).allowsHitTesting(false)
        Button {
          app.proposedStatus = d.status
          app.changingStatus = id
        } label: {
          Text(d.status.rawValue).font(Theme.font(12)).foregroundStyle(d.status.color)
            .padding(.horizontal, 8).frame(height: 22).background(
              d.status.badgeColor, in: .capsule
            ).frame(width: 90).contentShape(.rect)
        }.accessibilityIdentifier("device.status").accessibilityHint("Change device status")
          .offset(x: (w - 90) / 2, y: 172)
        DesignText(
          text: d.displayName, size: 16, weight: .bold, width: w - 38, centered: true, lines: 1
        )
        .offset(x: 19, y: 204)
        DesignText(
          text: d.category?.rawValue ?? "Bluetooth LE Device", color: Theme.muted, width: w - 38,
          centered: true
        ).foregroundStyle(
          Theme.muted
        ).offset(x: 19, y: 225)
        VStack(spacing: 8) {
          info("Device Name", d.displayName)
          info("Device Type", "Bluetooth LE")
          info("Identifier", d.id.uuidString)
          info("Connectable", d.connectable.map { $0 ? "Yes" : "No" } ?? "Unknown")
          info("Signal Strength", d.rssi.map { "\($0) dBm" } ?? "Unknown")
          info("First Detected", d.firstSeen.formatted(date: .abbreviated, time: .shortened))
          info("Last Detected", d.lastSeen.formatted(date: .abbreviated, time: .shortened))
        }.padding(16).background(Theme.card, in: .rect(cornerRadius: 24)).frame(width: w - 37)
          .offset(x: 19, y: 266).allowsHitTesting(false)
        PrimaryButton(title: "Change Device Status", outlined: true) {
          app.proposedStatus = d.status
          app.changingStatus = id
        }.frame(width: w - 37).offset(x: 19, y: h - 113)
      }
    }
  }
  private func info(_ name: String, _ value: String) -> some View {
    HStack(alignment: .top) {
      Text(name).foregroundStyle(Theme.muted)
      Spacer()
      Text(value).multilineTextAlignment(.trailing)
    }.font(Theme.font(14))
  }
}
