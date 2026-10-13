import SwiftUI

struct GuideView: View {
  @Bindable var app: AppState
  let guide: Guide
  private let headings: Set<String> = [
    "Start With a Visual Check", "Check Common Hiding Places", "Look for a Camera Lens",
    "Scan the Room", "Check Nearby Devices", "If Something Looks Suspicious", "Remember",
    "What Could It Be?", "Check the Signal", "Document It", "Don’t Touch It",
    "Verify First", "Report It", "Check Common Places", "Look for Warning Signs",
    "Scan Nearby Devices",
  ]
  private let bullets: Set<String> = [
    "Headphones and speakers", "Smartwatches and trackers", "TVs and smart home devices",
    "Nearby phones or computers", "Other Bluetooth accessories", "Chargers and power adapters",
    "Clocks and speakers", "Smoke detectors", "Lamps and electronics", "Objects on shelves",
    "Unfamiliar devices", "Smoke detectors and ceiling devices", "Clocks and alarm clocks",
    "Lamps and light fixtures", "Books and objects on shelves", "Picture frames and decorations",
    "TVs, speakers and other electronics", "Toys and stuffed animals",
  ]
  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: guide.displayNavigationTitle) { app.go(.guides) }
        .padding(.horizontal, 19)
      ScrollView {
        article.padding(.horizontal, 19).padding(.top, 26).padding(.bottom, 24)
      }
    }.padding(.top, 54).ignoresSafeArea()
  }
  private var article: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
        if line.isEmpty {
          if !(guide.id == "Camera" && index + 1 < lines.count
            && lines[index + 1] == "If Something Looks Suspicious")
          {
            Spacer().frame(height: 17)
          }
        } else {
          articleLine(index, line).id(index)
        }
        if guide.id == "Camera" && line == "Toys and stuffed animals" {
          Image(guide.image).resizable().scaledToFit().padding(.horizontal, -19).padding(.top, 16)
        }
      }
      if guide.id != "Camera" {
        Image(guide.image).resizable().scaledToFit().padding(.horizontal, -19).padding(.top, 16)
      }
    }
  }
  @ViewBuilder private func articleLine(_ index: Int, _ line: String) -> some View {
    if bullets.contains(line) {
      HStack(alignment: .top, spacing: 0) {
        Text("•").font(Theme.font(14)).frame(width: 21, alignment: .leading).offset(x: 5)
        Text(corrected(line)).font(Theme.font(14)).fixedSize(horizontal: false, vertical: true)
      }
    } else {
      Text(corrected(line)).font(
        Theme.font(
          articleFontSize(index, line),
          index == 0 || (headings.contains(line) && line != "If Something Looks Suspicious")
            || (index > 0 && lines[index - 1] == "Remember")
            ? .bold : .regular)
      ).fixedSize(horizontal: false, vertical: true)
    }
  }
  private func articleFontSize(_ index: Int, _ line: String) -> CGFloat {
    if index == 0 { return 24 }
    if guide.id == "Camera"
      && [
        "Start With a Visual Check", "Check Common Hiding Places", "If Something Looks Suspicious",
        "Remember",
      ].contains(line)
    {
      return 14
    }
    return headings.contains(line) ? 16 : 14
  }
  private var lines: [String] { guide.body.components(separatedBy: "\n") }
  private func corrected(_ line: String) -> String {
    line
      == "Use Signals Scanner in Privar to check for unknown nearby Bluetooth devices and unusual signals."
      ? "Use Bluetooth Scanner to review nearby devices and Signals Scanner to inspect changes in the magnetic field."
      : line
  }
}
