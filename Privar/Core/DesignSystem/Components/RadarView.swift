import SwiftUI

struct RadarView: View {
  var icon = "iconBluetoothLarge"
  var animated = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  var body: some View {
    ZStack {
      Image(icon == "iconBluetoothLarge" ? "radarBluetooth" : "radarSignals").resizable().frame(
        width: 300, height: 300)
      if animated && !reduceMotion && scenePhase == .active {
        RadarSweepView()
      }
    }.frame(width: 300, height: 300).accessibilityHidden(true)
      .allowsHitTesting(false)
  }
}
private struct RadarSweepView: View {
  var body: some View {

    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
      let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3) / 3
      ZStack {
        ZStack {
          Circle().fill(
            AngularGradient(
              stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.72),
                .init(color: Theme.green.opacity(0.08), location: 0.8),
                .init(color: Theme.green.opacity(0.36), location: 1),
              ], center: .center))

          Rectangle().fill(Theme.green.opacity(0.85)).frame(width: 89, height: 1.5)
            .offset(x: 94.5).shadow(color: Theme.green, radius: 3)
        }.frame(width: 278, height: 278)
          .mask { Circle().strokeBorder(lineWidth: 89) }
          .rotationEffect(.degrees(phase * 360))
        Circle().stroke(Theme.green.opacity(0.28 * (1 - phase)), lineWidth: 1.5)
          .frame(width: 278, height: 278).scaleEffect(0.4 + 0.6 * phase)
      }.frame(width: 300, height: 300)
    }
  }
}
