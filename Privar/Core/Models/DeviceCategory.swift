import Foundation

enum DeviceCategory: String, Codable {
  case headphones = "Headphones"
  case smartwatch = "Smartwatches"
  case smartHome = "Smart Home Devices"
  var icon: String {
    switch self {
    case .headphones: "deviceHeadphones"
    case .smartwatch: "deviceWatch"
    case .smartHome: "deviceHome"
    }
  }
}
