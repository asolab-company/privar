import SwiftUI

@main struct PrivarApp: App {
  @State private var app = AppState()
  @Environment(\.scenePhase) private var scenePhase
  var body: some Scene {
    WindowGroup {
      RootView(app: app).preferredColorScheme(.dark).task { await app.boot() }.onChange(
        of: scenePhase
      ) { _, phase in
        if phase == .background {
          app.background()
        } else if phase == .active {
          Task { await app.subscription.refresh() }
        }
      }
    }
  }
}
