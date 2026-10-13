import SwiftUI

struct SettingsView: View {
  @Bindable var app: AppState
  var body: some View {
    DesignCanvas { w, _ in
      NavHeader(title: "Settings") { app.go(.home) }.frame(width: w - 37).offset(x: 19, y: 54)
      PrimaryButton(title: "Explore Privacy Guides →") { app.go(.guides) }.frame(width: w - 37)
        .offset(x: 19, y: 124)
      DesignText(text: "Support & Legal", size: 16, weight: .bold, width: w - 38).offset(
        x: 19, y: 196)
      VStack(spacing: 0) {
        row("Privacy", "privacy") { app.openLegal(.privacy) }
        settingsDivider
        row("Terms and Conditions", "terms") { app.openLegal(.terms) }
      }.padding(.vertical, 8).background(Theme.settingsCard, in: .rect(cornerRadius: 24)).frame(
        width: w - 37
      ).offset(x: 19, y: 231)
      DesignText(text: "General", size: 16, weight: .bold, width: w - 38).offset(x: 19, y: 372)
      VStack(spacing: 0) {
        row("Share app", "share") { app.share() }
        settingsDivider
        row("Rate Us", "rate") { app.rate() }
        settingsDivider
        if !app.subscription.entitled {
          row("Restore", "restore") { Task { await app.subscription.restore() } }
          settingsDivider
        }
        row("Delete Data", "delete") { app.confirmDelete = true }
      }.padding(.top, 8).padding(.bottom, 9).background(
        Theme.settingsCard, in: .rect(cornerRadius: 24)
      ).frame(
        width: w - 37
      ).offset(x: 19, y: 407)
    }
  }
  private var settingsDivider: some View {
    Rectangle().fill(Theme.muted.opacity(0.25)).frame(height: 1)
  }
  private func iconSize(_ icon: String) -> CGSize {
    switch icon {
    case "delete": CGSize(width: 16, height: 18)
    case "terms": CGSize(width: 16, height: 20)
    case "privacy": CGSize(width: 16, height: 19.75)
    case "share": CGSize(width: 18, height: 19.92)
    case "restore": CGSize(width: 23, height: 20)
    default: CGSize(width: 20, height: 20)
    }
  }
  private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(icon).resizable().scaledToFit().frame(
          width: iconSize(icon).width, height: iconSize(icon).height
        ).frame(
          width: 34, height: 34
        ).offset(x: icon == "restore" ? -1.5 : 0).foregroundStyle(Theme.green)
        Text(title).font(Theme.font(14)).foregroundStyle(.white)
        Spacer()
        Image("chevron").resizable().scaledToFit().frame(width: 9, height: 16).scaleEffect(
          x: -1, y: 1
        ).foregroundStyle(
          Theme.green)
      }.padding(.horizontal, 16).frame(height: 50).contentShape(.rect)
    }.buttonStyle(.plain)
  }
}
