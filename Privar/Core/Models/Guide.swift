import Foundation

struct Guide: Decodable, Identifiable {
  let id, title, navigationTitle, summary, body, image, thumbnail: String
  var displayNavigationTitle: String {
    switch id {
    case "Camera": "How To Find A Hidden Camera"
    case "Suspicious": "Find A Suspicious Device"
    case "Listening": "How To Check A Room..."
    default: navigationTitle
    }
  }
  var cardTitle: String {
    switch id {
    case "Camera": "How To Find A Hidden\nCamera"
    case "Suspicious": "What To Do If You Find A\nSuspicious Device"
    case "Listening": "How To Check A Room\nFor Listening Devices"
    case "Bluetooth": "Understanding Unknown\nBluetooth Devices"
    default: title
    }
  }
  static let all: [Guide] = {
    guard let url = Bundle.main.url(forResource: "Guides", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let guides = try? JSONDecoder().decode([Guide].self, from: data)
    else { return [] }
    return guides
  }()
}
