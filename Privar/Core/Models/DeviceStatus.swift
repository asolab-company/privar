import SwiftUI

enum DeviceStatus: String, CaseIterable, Codable {
  case known = "Known"
  case unknown = "Unknown"
  case suspicious = "Suspicious"
  var color: Color {
    switch self {
    case .known: Theme.green
    case .unknown: Color(red: 1, green: 119 / 255, blue: 0)
    case .suspicious: Color(red: 1, green: 0, blue: 4.25 / 255)
    }
  }
  var badgeColor: Color {
    self == .suspicious
      ? Color(red: 0.54167, green: 0, blue: 0.00903).opacity(0.25) : color.opacity(0.25)
  }

}
