import SwiftUI

struct SignalsView: View {
  @Bindable var app: AppState
  var body: some View {
    DesignCanvas { w, h in
      let level = app.magnetic.assessment.level
      let result = level == .strong || (!app.magnetic.running && level == .quiet)
      NavHeader(title: "Scanning For Devices") { app.go(.home) }.frame(width: w - 37).offset(
        x: 19, y: 54)
      if level == .strong || (!app.magnetic.running && level == .quiet) {
        Image(level == .strong ? "iconAlert" : "iconSafe").resizable().frame(
          width: 150, height: 150
        ).position(x: w / 2, y: 274).allowsHitTesting(false)
      } else {
        RadarView(icon: "iconSignalsLarge", animated: app.magnetic.running)
          .position(x: w / 2, y: 274)
      }
      DesignText(text: title(level), size: 20, weight: .bold, width: w - 38, centered: true).offset(
        x: 19, y: result ? 373 : 448)
      let narrowDescription = level == .strong || level == .elevated
      let descriptionWidth = narrowDescription ? min(320, w - 74) : w - 37
      DesignText(
        text: description(level), color: result ? .white : Theme.muted, width: descriptionWidth,
        centered: true
      )
      .offset(x: (w - descriptionWidth) / 2, y: result ? 401 : 476)
      if level != .quiet || app.magnetic.running {
        HStack(spacing: 4) {
          ForEach(0..<11) { bar in
            RoundedRectangle(cornerRadius: 8).fill(
              (bar
                < Int(abs(app.magnetic.assessment.smoothed - app.magnetic.assessment.baseline) / 8)
                ? Theme.green : Color.black.opacity(0.55))
                .shadow(.inner(color: .black.opacity(0.6), radius: 2))
            ).frame(height: 42).shadow(
              color: bar
                < Int(abs(app.magnetic.assessment.smoothed - app.magnetic.assessment.baseline) / 8)
                ? Theme.green.opacity(0.8) : .clear, radius: 4)
          }
        }.padding(.horizontal, 15).padding(.vertical, 16).frame(width: w - 37, height: 74)
          .background(
            Theme.card, in: .rect(cornerRadius: 24)
          ).overlay {
            RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.green.opacity(0.2), lineWidth: 2)
              .shadow(color: Theme.green.opacity(0.6), radius: 4)
          }.offset(x: 19, y: level == .strong ? 476 : 554)
        VStack(spacing: 0) {
          Text("\(app.magnetic.assessment.smoothed, specifier:"%.0f") µT").font(
            Theme.font(16, .bold)
          ).foregroundStyle(Theme.green)
          Text("Magnetic Field").font(Theme.font(14)).foregroundStyle(Theme.muted)
        }.frame(width: w).offset(y: level == .strong ? 566 : 649)
      }
      if !app.magnetic.running && level == .quiet {
        InspectionNote(
          title: "Keep checking your\nsurroundings",
          text:
            "Quiet readings cannot rule out hidden devices. Include a careful visual inspection.",
          guide: { app.go(.guides) }
        ).frame(width: w - 37).offset(x: 19, y: 584)
      }
      if level == .strong {
        HStack(spacing: 16) {
          PrimaryButton(title: "Continue Scanning", outlined: true, height: 50) {
            app.start(.signals, continuing: true)
          }
          PrimaryButton(title: "Scan Again", height: 50) { app.start(.signals) }
        }.frame(width: w - 37).offset(x: 19, y: h - 113)
      } else if !app.magnetic.running {
        PrimaryButton(title: "Scan Again") { app.start(.signals) }.frame(width: w - 37).offset(
          x: 19, y: h - 113)
      }
    }
  }
  private func title(_ level: MagneticAssessment.Level) -> String {
    switch level {
    case .calibrating: "Scanning For Signals..."
    case .quiet: "No Significant Field Change"
    case .elevated: "Strong Magnetic Activity"
    case .strong: "Strong Magnetic Activity"
    }
  }
  private func description(_ level: MagneticAssessment.Level) -> String {
    switch level {
    case .calibrating:
      "Measuring magnetic field changes around your iPhone. Move your iPhone slowly around objects and areas you want to inspect."
    case .quiet:
      "No significant changes in magnetic field strength were detected during this scan.\nSome devices may not produce detectable magnetic activity.\nA visual inspection is also recommended."
    case .elevated, .strong:
      "An increased magnetic field was measured nearby. Check surrounding electronics and inspect the area carefully."
    }
  }
}
