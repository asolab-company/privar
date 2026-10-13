import Foundation
import Observation

@MainActor @Observable final class LocalStore {
  private(set) var devices: [NearbyDevice] = []
  private(set) var photos: [InspectionPhoto] = []
  private let defaults: UserDefaults
  let directory: URL
  init(defaults: UserDefaults = .standard, directory: URL? = nil) {
    self.defaults = defaults
    self.directory =
      directory
      ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Privar", isDirectory: true)
    try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    if let d = defaults.data(forKey: "devices") {
      devices = (try? JSONDecoder().decode([NearbyDevice].self, from: d)) ?? []
    }
    if let d = defaults.data(forKey: "photos") {
      photos = (try? JSONDecoder().decode([InspectionPhoto].self, from: d)) ?? []
    }
  }
  var onboardingComplete: Bool {
    get { defaults.bool(forKey: "onboardingComplete") }
    set { defaults.set(newValue, forKey: "onboardingComplete") }
  }
  func available(_ mode: ScannerMode, subscribed: Bool) -> Bool {
    subscribed || !defaults.bool(forKey: "used.\(mode.rawValue)")
  }
  func recordSuccessfulStart(_ mode: ScannerMode) {
    defaults.set(true, forKey: "used.\(mode.rawValue)")
  }
  func upsert(_ device: NearbyDevice) {
    if let i = devices.firstIndex(where: { $0.id == device.id }) {
      var value = device
      value.status = devices[i].status
      value.firstSeen = devices[i].firstSeen
      devices[i] = value
    } else {
      devices.append(device)
    }
    persist()
  }
  func setStatus(_ id: UUID, _ status: DeviceStatus) {
    guard let i = devices.firstIndex(where: { $0.id == id }) else { return }
    devices[i].status = status
    persist()
  }
  func savePhoto(_ data: Data, candidate: CGRect?) throws -> InspectionPhoto {
    let id = UUID()
    let filename = "\(id).jpg"
    try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
    let photo = InspectionPhoto(id: id, filename: filename, createdAt: Date(), candidate: candidate)
    photos.append(photo)
    persist()
    return photo
  }
  func photoData(_ photo: InspectionPhoto) -> Data? {
    try? Data(contentsOf: directory.appendingPathComponent(photo.filename))
  }
  func deletePhoto(_ photo: InspectionPhoto) throws {
    let url = directory.appendingPathComponent(photo.filename)
    if FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }
    photos.removeAll { $0.id == photo.id }
    persist()
  }
  func deleteData() throws {
    for photo in photos {
      let url = directory.appendingPathComponent(photo.filename)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
    }
    photos = []
    devices = []
    persist()
  }
  private func persist() {
    defaults.set(try? JSONEncoder().encode(devices), forKey: "devices")
    defaults.set(try? JSONEncoder().encode(photos), forKey: "photos")
  }
}
