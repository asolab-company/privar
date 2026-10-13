import SwiftUI

struct ScannerTabBar: View {
  let selected: ScannerMode
  var select: (ScannerMode) -> Void
  var body: some View {
    HStack(spacing: 0) {
      ForEach(ScannerMode.allCases) { mode in
        Button {
          select(mode)
        } label: {
          VStack(spacing: 0) {
            Image("tab" + mode.label).resizable().scaledToFit().frame(width: 32, height: 32)
              .shadow(color: mode == selected ? Theme.green.opacity(0.7) : .clear, radius: 2)
            Text(mode.label).font(Theme.font(10, .medium))
          }.offset(y: -1).frame(maxWidth: .infinity).frame(height: 62).contentShape(.rect)
            .foregroundStyle(
              mode == selected ? Theme.green : Theme.muted)
        }.accessibilityIdentifier("tab." + mode.rawValue)
      }
    }.padding(.horizontal, 22).frame(height: 62).background {
      Capsule().fill(Color.white.opacity(0.1))
        .overlay {
          Capsule().strokeBorder(
            LinearGradient(
              colors: [.white.opacity(0.32), .clear], startPoint: .top, endPoint: .bottom),
            lineWidth: 1)
        }
    }
  }
}
