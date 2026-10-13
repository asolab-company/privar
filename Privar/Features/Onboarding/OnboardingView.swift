import SwiftUI

struct OnboardingView: View {
  @Bindable var app: AppState
  let index: Int
  private let titles = [
    "Know What’s\nAround You", "Look Closer.\nStay Private.", "Stay Aware of\nHidden Risks",
    "Unlimited Access\nTo Features",
  ]
  private let bodies = [
    "Scan for nearby Bluetooth devices and quickly identify unfamiliar connections in your surroundings.",
    "Use your camera to inspect your surroundings and identify potential hidden cameras in unexpected places.",
    "Scan for nearby signals and unknown devices that may require your attention.",
  ]
  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()
      DesignCanvas { w, h in
        let titleY = max(540, w * 535 / 393 + 5)
        Image(
          ["onboardingBluetooth", "onboardingCamera", "onboardingSignals", "paywallArt"][index]
        ).resizable().frame(width: w, height: w * 535 / 393).offset(y: 0)
        DesignText(text: titles[index], size: 32, weight: .bold, width: w - 38).offset(
          x: 19, y: titleY
        ).accessibilityIdentifier("onboarding.title.\(index)")
        DesignText(
          text: index == 3 ? app.subscription.priceText : bodies[index], size: 16,
          width: index == 0 ? min(307, w - 38) : w - 38
        ).offset(x: 19, y: titleY + 88)
          .accessibilityIdentifier(index == 3 ? "subscription.price" : "onboarding.body.\(index)")
        if index == 3, let name = app.subscription.planName {
          DesignText(
            text: "\(name) · \(app.subscription.productTypeText)", size: 12,
            color: Theme.muted, width: w - 38
          ).offset(x: 19, y: titleY + 140).accessibilityIdentifier("subscription.plan")
        }
        if index < 3 {
          HStack(spacing: 8) {
            ForEach(0..<3) { dot in
              Circle().fill(dot == index ? Theme.green : Theme.muted).frame(width: 6, height: 6)
            }
          }.position(x: w / 2, y: h - 140)
        } else {
          Button("or proceed with limited version") {
            app.subscription.message = nil
            app.paywall = false
          }.font(Theme.font(14))
            .foregroundStyle(Theme.muted).frame(width: w - 38, height: 44).position(
              x: w / 2, y: h - 145)
        }
        PrimaryButton(title: app.subscription.busy && index == 3 ? "Please wait…" : "Continue") {
          if index < 3 {
            app.advanceOnboarding(index)
          } else {
            Task {
              await app.subscription.purchase()
              if app.subscription.entitled { app.paywall = false }
            }
          }
        }.disabled(index == 3 && (app.subscription.busy || !app.subscription.purchaseAvailable))
          .frame(
            width: w - 38
          ).offset(x: 19, y: h - 113)
        if index == 0 {
          VStack(spacing: 0) {
            Text("By Proceeding You Accept").foregroundStyle(Theme.muted)
            HStack(spacing: 3) {
              Text("Our").foregroundStyle(Theme.muted)
              Button("Terms Of Use") { app.openLegal(.terms) }.underline()
              Text("And").foregroundStyle(Theme.muted)
              Button("Privacy Policy") { app.openLegal(.privacy) }.underline()
            }
          }.font(Theme.font(12)).foregroundStyle(Theme.green).frame(width: w, height: 28).offset(
            y: h - 56)
        }
        if index == 3 {
          HStack {
            Button("Privacy Policy") { app.openLegal(.privacy) }
            Spacer()
            Button("Restore") {
              Task {
                await app.subscription.restore()
                if app.subscription.entitled { app.paywall = false }
              }
            }
            Spacer()
            Button("Terms of Use") { app.openLegal(.terms) }
          }.font(Theme.font(12)).foregroundStyle(Theme.muted).frame(width: w - 62, height: 30)
            .offset(x: 31, y: h - 51)
        }
      }
    }.foregroundStyle(.white).task {
      if index == 3 { await app.subscription.load(reportErrors: true) }
    }.alert(
      "Subscription",
      isPresented: Binding(
        get: { index == 3 && app.sheet == nil && app.subscription.message != nil },
        set: { if !$0 { app.subscription.message = nil } })
    ) {
      Button("OK") { app.subscription.message = nil }
    } message: {
      Text(app.subscription.message ?? "")
    }
  }
}
