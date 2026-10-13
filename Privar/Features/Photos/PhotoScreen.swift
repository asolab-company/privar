import SwiftUI

struct PhotoScreen: View {
  @Bindable var app: AppState
  let id: UUID
  var body: some View {
    if let photo = app.store.photos.first(where: { $0.id == id }) {
      DesignCanvas { w, h in
        NavHeader(title: title) { app.go(.home) }.frame(width: w - 37).offset(x: 19, y: 54)
        if app.page == .photoSaved(id) {
          Image("iconSaved").resizable().frame(width: 150, height: 150).position(x: w / 2, y: 274)
            .allowsHitTesting(false)
          DesignText(text: "Photo Saved", size: 24, weight: .bold, width: w - 38, centered: true)
            .offset(x: 19, y: 373)
          DesignText(
            text:
              "Your photo has been saved successfully. You can continue scanning your surroundings for other suspicious objects.",
            width: 219, centered: true
          ).offset(x: (w - 219) / 2, y: 410)
          HStack(spacing: 16) {
            PrimaryButton(title: "Show Photo", outlined: true, height: 50) { app.page = .photo(id) }
            PrimaryButton(title: "Scan Again", height: 50) {
              app.selectedMode = .camera
              app.go(.home)
            }
          }.frame(width: w - 37).offset(x: 19, y: h - 113)
        } else {
          PhotoView(data: app.store.photoData(photo)).frame(width: w - 38, height: h - 240).offset(
            x: 21, y: 108)
          if app.page == .details(id) {
            HStack(spacing: 16) {
              PrimaryButton(title: "Delete", outlined: true, height: 50) {
                do {
                  try app.store.deletePhoto(photo)
                  app.go(.home)
                } catch { app.message = error.localizedDescription }
              }
              PrimaryButton(title: app.savingPhoto ? "Saving…" : "Save To Photos", height: 50) {
                Task { await app.savePhoto(photo) }
              }.disabled(app.savingPhoto)
            }.frame(width: w - 37).offset(x: 19, y: h - 113)
          }
        }
      }
    }
  }
  private var title: String {
    switch app.page {
    case .photoSaved: "Photo Saved"
    case .photo: "Saved Photo"
    default: "Detection Details"
    }
  }
}
