import SwiftUI

struct StatusModal: View {
  @Bindable var app: AppState
  let id: UUID
  var body: some View {
    GeometryReader { geometry in
      let width = max(320, geometry.size.width) - 37
      ZStack {
        Color.black.opacity(0.2).ignoresSafeArea()
        ZStack(alignment: .topLeading) {
          RoundedRectangle(cornerRadius: 32).fill(
            Color.gray.opacity(0.15).shadow(
              .inner(color: .white.opacity(0.24), radius: 2, x: 0, y: 2)
            ).shadow(.inner(color: .white.opacity(0.23), radius: 2, x: 0, y: -2))
          )
          .overlay {
            RoundedRectangle(cornerRadius: 32).strokeBorder(.white.opacity(0.18), lineWidth: 1)
          }
          Text("Change Device Status").font(Theme.font(24, .bold)).offset(x: 16, y: 24)
          (Text("Select a status for this device for ")
            + Text(app.store.devices.first(where: { $0.id == id })?.displayName ?? "Unknown").bold())
            .font(Theme.font(14)).lineLimit(1).frame(width: width - 32, alignment: .leading).offset(
              x: 16, y: 57)
          ForEach(Array(DeviceStatus.allCases.enumerated()), id: \.element) { index, status in
            Button {
              app.proposedStatus = status
            } label: {
              HStack {
                Text(status.rawValue).font(Theme.font(16, .bold)).foregroundStyle(status.color)
                  .padding(.horizontal, 16).frame(height: 31).background(
                    status.badgeColor, in: .capsule)
                Spacer()
                ZStack {
                  Circle().fill(.black.opacity(0.5))
                  if app.proposedStatus == status {
                    Image("check").resizable().scaledToFit().frame(width: 24, height: 24)
                      .foregroundStyle(Theme.green)
                  }
                }.frame(width: 24, height: 24)
              }.frame(width: width - 32, height: 31).contentShape(.rect)
            }.buttonStyle(.plain).accessibilityIdentifier("status." + status.rawValue).offset(
              x: 16, y: 98 + CGFloat(index) * 48)
            if index < 2 {
              Rectangle().fill(Theme.muted.opacity(0.3)).frame(width: width - 32, height: 1).offset(
                x: 16, y: 137 + CGFloat(index) * 48)
            }
          }
          HStack(spacing: 16) {
            PrimaryButton(title: "Cancel", outlined: true, height: 50) { app.changingStatus = nil }
            PrimaryButton(title: "Save Changes", height: 50) {
              app.store.setStatus(id, app.proposedStatus)
              app.changingStatus = nil
            }
          }.frame(width: width - 32).offset(x: 16, y: 249)
        }.frame(width: width, height: 316).position(
          x: geometry.size.width / 2, y: geometry.size.height / 2)
      }
    }.ignoresSafeArea()
  }
}
