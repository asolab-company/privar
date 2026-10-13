import SwiftUI

struct RootView: View {
  @Bindable var app: AppState
  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()
      page.blur(radius: app.changingStatus == nil ? 0 : 16)
    }.foregroundStyle(.white)
      .onChange(of: app.subscription.entitled) { _, active in if active { app.paywall = false } }
      .fullScreenCover(isPresented: $app.paywall) {
        PaywallView(app: app).preferredColorScheme(.dark)
          .sheet(item: $app.sheet) { AppSheetView(sheet: $0) }
      }
      .sheet(item: Binding(get: { app.paywall ? nil : app.sheet }, set: { app.sheet = $0 })) {
        AppSheetView(sheet: $0)
      }
      .alert(
        "Privar", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { clearErrors() } })
      ) {
        Button("OK") { clearErrors() }
        if sensorError {
          Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
            clearErrors()
          }
        }
      } message: {
        Text(alertText ?? "")
      }
      .confirmationDialog(
        "Delete local devices, statuses and inspection photos? Photos saved to your library and scan limits will remain.",
        isPresented: $app.confirmDelete, titleVisibility: .visible
      ) {
        Button("Delete Data", role: .destructive) {
          do { try app.store.deleteData() } catch { app.message = error.localizedDescription }
        }
        Button("Cancel", role: .cancel) {}
      }
      .overlay { if let id = app.changingStatus { StatusModal(app: app, id: id) } }
  }
  private var sensorError: Bool {
    app.bluetooth.error != nil || app.magnetic.error != nil || app.camera.error != nil
  }
  private var alertText: String? {
    guard app.sheet == nil else { return nil }
    return app.message ?? (app.paywall ? nil : app.subscription.message) ?? app.bluetooth.error
      ?? app
      .magnetic.error ?? app.camera.error
  }
  private func clearErrors() {
    app.message = nil
    app.subscription.message = nil
    app.bluetooth.error = nil
    app.magnetic.error = nil
    app.camera.error = nil
  }
  @ViewBuilder private var page: some View {
    switch app.page {
    case .loading:
      LoadingView()
    case .onboarding: OnboardingPager(app: app)
    case .home: HomeView(app: app)
    case .permission(let mode): PermissionView(app: app, mode: mode)
    case .bluetoothResults: BluetoothResultsView(app: app)
    case .device(let id): DeviceDetailsView(app: app, id: id)
    case .camera: CameraScannerView(app: app)
    case .signals: SignalsView(app: app)
    case .details(let id), .photoSaved(let id), .photo(let id): PhotoScreen(app: app, id: id)
    case .settings: SettingsView(app: app)
    case .guides: GuideListView(app: app)
    case .guide(let id):
      if let guide = Guide.all.first(where: { $0.id == id }) { GuideView(app: app, guide: guide) }
    }
  }
}
