import AVFoundation
import CoreBluetooth
import Observation
import SwiftUI

@MainActor @Observable final class AppState {
  enum Page: Equatable {
    case loading
    case onboarding(Int)
    case home
    case permission(ScannerMode)
    case bluetoothResults
    case device(UUID)
    case camera, signals
    case details(UUID)
    case photoSaved(UUID)
    case photo(UUID)
    case settings, guides
    case guide(String)
  }
  enum Sheet: Identifiable {
    case legal(LegalDocument)
    case share(URL)
    var id: String {
      switch self {
      case .legal(let document): document.rawValue
      case .share: "share"
      }
    }
  }
  var page: Page = .loading
  var selectedMode: ScannerMode = .bluetooth
  var paywall = false
  var message: String?
  var filter: DeviceStatus?
  var changingStatus: UUID?
  var proposedStatus: DeviceStatus = .unknown
  var confirmDelete = false
  var savingPhoto = false
  var sheet: Sheet?
  let store: LocalStore
  let subscription: SubscriptionService
  var bluetooth: any BluetoothScanning
  var magnetic: any MagneticMeasuring
  let camera: any CameraScanning
  private var startedModes: Set<ScannerMode> = []
  init(
    store: LocalStore? = nil, bluetooth: (any BluetoothScanning)? = nil,
    magnetic: (any MagneticMeasuring)? = nil, camera: (any CameraScanning)? = nil,
    subscription: SubscriptionService? = nil
  ) {
    self.store = store ?? LocalStore()
    self.subscription = subscription ?? SubscriptionService()
    self.bluetooth = bluetooth ?? BluetoothService()
    self.magnetic = magnetic ?? MagneticService()
    self.camera = camera ?? CameraService()
    self.bluetooth.onStarted = { [weak self] in self?.started(.bluetooth) }
    self.bluetooth.onDevice = { [weak self] device in self?.store.upsert(device) }
    self.magnetic.onStarted = { [weak self] in self?.started(.signals) }
    self.camera.onStarted = { [weak self] in self?.started(.camera) }
  }
  func boot() async {
    async let loading: () = subscription.load()
    try? await Task.sleep(for: .milliseconds(850))
    page = store.onboardingComplete ? .home : .onboarding(0)
    await loading
  }
  func started(_ mode: ScannerMode) {
    if !subscription.entitled { store.recordSuccessfulStart(mode) }
    startedModes.insert(mode)
  }
  func advanceOnboarding(_ index: Int) {
    if index < 2 {
      page = .onboarding(index + 1)
    } else {
      store.onboardingComplete = true
      page = .home
      paywall = !subscription.entitled
    }
  }
  func stopHardware() {
    bluetooth.stop()
    magnetic.stop()
    camera.stop()
  }
  func go(_ page: Page) {
    stopHardware()
    switch page {
    case .device, .bluetoothResults: break
    default: startedModes = []
    }
    self.page = page
  }
  var canContinueBluetooth: Bool { startedModes.contains(.bluetooth) && bluetooth.remaining > 0 }
  func start(_ mode: ScannerMode, continuing: Bool = false, authorized: Bool = false) {
    guard
      continuing && startedModes.contains(mode)
        || store.available(mode, subscribed: subscription.entitled)
    else {
      paywall = true
      return
    }
    if !authorized
      && ((mode == .bluetooth && CBCentralManager.authorization == .notDetermined)
        || (mode == .camera && AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined))
    {
      page = .permission(mode)
      return
    }
    switch mode {
    case .bluetooth:
      page = .bluetoothResults
      if continuing { bluetooth.resume() } else { bluetooth.start() }
    case .camera:
      page = .camera
      if !camera.running { Task { await camera.start() } }
    case .signals:
      page = .signals
      if !magnetic.running { if continuing { magnetic.resume() } else { magnetic.start() } }
    }
  }
  func background() { stopHardware() }
  func capture() async {
    do {
      let (data, rect) = try await camera.capture()
      let photo = try store.savePhoto(data, candidate: rect)
      go(.details(photo.id))
    } catch { message = error.localizedDescription }
  }
  func savePhoto(_ photo: InspectionPhoto) async {
    guard !savingPhoto, let data = store.photoData(photo) else {
      message = "The photo is unavailable."
      return
    }
    savingPhoto = true
    defer { savingPhoto = false }
    do {
      try await PhotosService.save(data)
      go(.photoSaved(photo.id))
    } catch { message = error.localizedDescription }
  }
  func openLegal(_ document: LegalDocument) { sheet = .legal(document) }
  func rate() {
    guard let text = Bundle.main.object(forInfoDictionaryKey: "PrivarAppStoreURL") as? String,
      var components = URLComponents(string: text), components.scheme == "https"
    else {
      message = "The App Store link will be available after publication."
      return
    }
    components.queryItems =
      (components.queryItems ?? []) + [URLQueryItem(name: "action", value: "write-review")]
    if let url = components.url { UIApplication.shared.open(url) }
  }
  func share() {
    guard let text = Bundle.main.object(forInfoDictionaryKey: "PrivarAppStoreURL") as? String,
      let url = URL(string: text), url.scheme == "https"
    else {
      message = "The App Store link will be available after publication."
      return
    }
    sheet = .share(url)
  }
  var currentDevices: [NearbyDevice] { store.devices.filter { bluetooth.seen.contains($0.id) } }
  var filteredDevices: [NearbyDevice] {
    currentDevices.filter { filter == nil || $0.status == filter }.sorted {
      $0.firstSeen < $1.firstSeen
    }
  }
}
