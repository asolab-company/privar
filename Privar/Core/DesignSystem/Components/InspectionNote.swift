import SwiftUI

struct InspectionNote: View {
  var title = "No Bluetooth devices were\nfound in this scan."
  var text = "Scanning cannot rule out hidden devices. Combine it with a careful visual inspection."
  var guide: () -> Void
  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Image("iconInfo").resizable().frame(width: 38, height: 38)
      VStack(alignment: .leading, spacing: 0) {
        Text(title).font(Theme.font(16, .bold))
        Text(text).font(Theme.font(14))
        Button("Explore Privacy Guides →", action: guide).font(Theme.font(16, .medium)).underline()
          .padding(.top, 8)
      }
    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(
      Theme.card, in: .rect(cornerRadius: 24))
  }
}
