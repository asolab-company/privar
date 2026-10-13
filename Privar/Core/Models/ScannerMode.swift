import Foundation

enum ScannerMode: String, CaseIterable, Codable, Identifiable {
  case bluetooth, camera, signals
  var id: String { rawValue }
  var title: String {
    switch self {
    case .bluetooth: "Bluetooth Scanner"
    case .camera: "Hidden Camera Scanner"
    case .signals: "Listening Device Scanner"
    }
  }
  var label: String { rawValue.capitalized }
  var description: String {
    switch self {
    case .bluetooth: "Find nearby Bluetooth devices and identify unfamiliar connections around you."
    case .camera: "Scan your surroundings for potential hidden cameras and suspicious objects."
    case .signals:
      "Check your surroundings for signals that may be associated with nearby electronic devices."
    }
  }
}
