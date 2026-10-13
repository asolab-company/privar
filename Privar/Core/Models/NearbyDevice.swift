import Foundation

struct NearbyDevice: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String?
  var rssi: Int?
  var connectable: Bool?
  var firstSeen: Date
  var lastSeen: Date
  var status: DeviceStatus = .unknown

  var category: DeviceCategory?
  var displayName: String { name?.isEmpty == false ? name! : "Unknown" }
  var signalBars: Int {
    guard let rssi else { return 0 }
    if rssi >= -50 { return 5 }
    if rssi >= -60 { return 4 }
    if rssi >= -70 { return 3 }
    if rssi >= -80 { return 2 }
    return 1
  }

}
