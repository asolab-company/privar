import SwiftUI

struct DeviceCard: View {
  let device: NearbyDevice
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(device.category?.icon ?? "deviceUnknown").resizable().scaledToFit().frame(
          width: 32, height: 32)
        VStack(alignment: .leading, spacing: 2) {
          Text(device.displayName).font(Theme.font(16, .bold)).lineLimit(1)
          Text(device.category?.rawValue ?? "Unknown Device").font(Theme.font(14)).foregroundStyle(
            Theme.muted)
        }
        Spacer(minLength: 4)
        Text(device.status.rawValue).font(Theme.font(12)).foregroundStyle(
          device.status.color
        ).padding(.horizontal, 8).frame(height: 22).background(
          device.status.badgeColor, in: .capsule)
        Image("signal").resizable().scaledToFit().frame(width: 32, height: 32).foregroundStyle(
          Theme.muted
        )
        .overlay {
          Image("signal").resizable().scaledToFit().frame(width: 32, height: 32).foregroundStyle(
            Theme.green
          ).mask {
            HStack(spacing: 0) {
              Rectangle().frame(width: 32 * CGFloat(device.signalBars) / 5)
              Spacer(minLength: 0)
            }
          }
        }

      }.padding(.horizontal, 16).frame(height: 64).background(
        Theme.deviceCard, in: .rect(cornerRadius: 24))
    }.buttonStyle(.plain)
  }
}
