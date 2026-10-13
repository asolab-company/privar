import SwiftUI

struct PhotoView: View {
  let data: Data?
  var body: some View {
    if let data, let ui = UIImage(data: data) {
      Image(uiImage: ui).resizable().scaledToFit()
    } else {
      ContentUnavailableView("Photo unavailable", systemImage: "photo")
    }
  }
}
