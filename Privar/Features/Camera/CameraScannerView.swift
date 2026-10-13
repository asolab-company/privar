import SwiftUI

struct CameraScannerView: View {
  @Bindable var app: AppState
  @State private var elapsed = 0
  @State private var sweep = false
  @State private var showingTips = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    DesignCanvas { w, h in
      preview.frame(width: w, height: h).clipped().allowsHitTesting(false)
      if let r = candidate {
        let scale = max(w / frameSize.width, h / frameSize.height)
        let dx = (frameSize.width * scale - w) / 2
        let dy = (frameSize.height * scale - h) / 2
        Ellipse().stroke(.red, lineWidth: 3).frame(
          width: r.width * frameSize.width * scale, height: r.height * frameSize.height * scale
        )
        .position(
          x: r.midX * frameSize.width * scale - dx, y: r.midY * frameSize.height * scale - dy
        )
        .accessibilityLabel("Persistent bright reflection").allowsHitTesting(false)
      } else if cameraActive {
        scanSweep(width: w, height: h).allowsHitTesting(false)
        Text("Scanning For Hidden Cameras").font(Theme.font(16, .bold)).foregroundStyle(
          Color(red: 0.05, green: 0.11, blue: 0)
        )
        .padding(.horizontal, 16).frame(height: 35).background(.white.opacity(0.5), in: .capsule)
        .frame(width: w).offset(y: h - (quiet ? 245 : 125)).allowsHitTesting(false)
        if quiet {
          InspectionNote(
            title: "No persistent reflections detected so far.",
            text:
              "Use the flashlight, move closer and change the angle slowly. A clear scan cannot rule out a camera.",
            guide: { app.go(.guides) }
          )
          .frame(width: w - 37).background(.black.opacity(0.45), in: .rect(cornerRadius: 24))
          .offset(x: 19, y: h - 194)
        }
      }
      HStack(spacing: 4) {
        Button {
          app.go(.home)
        } label: {
          Image("back").resizable().scaledToFit().frame(width: 19.2, height: 19.2).frame(
            width: 44, height: 44
          ).contentShape(.rect)
        }.accessibilityLabel("Back").offset(x: -6)
        Spacer()
        Button {
          showingTips = true
        } label: {
          Image(systemName: "questionmark.circle").frame(width: 44, height: 44).contentShape(.rect)
        }.accessibilityLabel("Camera tips")
        Button {
          app.camera.toggleTorch()
        } label: {
          Image(systemName: app.camera.torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
            .frame(width: 44, height: 44).contentShape(.rect)
        }.accessibilityLabel("Flashlight")
        Button {
          app.camera.zoom = app.camera.zoom >= 3 ? 1 : app.camera.zoom + 1
        } label: {
          Text("\(app.camera.zoom, specifier: "%.0f")×").font(Theme.font(16, .bold)).frame(
            width: 44, height: 44
          ).contentShape(.rect)
        }.accessibilityLabel("Zoom")
        if candidate == nil && cameraActive {
          Button {
            Task { await app.capture() }
          } label: {
            Image("capture").resizable().scaledToFit().frame(width: 20, height: 20).frame(
              width: 44, height: 44
            ).contentShape(.rect)
          }.accessibilityLabel("Capture")
        }
      }.frame(width: w - 37).offset(x: 19, y: 54)
      if candidate != nil {
        HStack(alignment: .top, spacing: 16) {
          Image("cameraAlert").resizable().frame(width: 38, height: 38)
          VStack(alignment: .leading, spacing: 0) {
            Text("Suspicious Reflection Detected").font(Theme.font(16, .bold))
            Text("A persistent bright area was found. Inspect the object carefully.").font(
              Theme.font(14))
          }
        }.padding(16).frame(width: w - 38, height: 85, alignment: .leading).background(
          Color.red.opacity(0.4), in: .rect(cornerRadius: 32)
        ).offset(x: 19, y: h - 214).allowsHitTesting(false)
        HStack(spacing: 16) {
          PrimaryButton(title: "Continue Scanning", outlined: true, height: 50) {
            app.start(.camera, continuing: true)
          }
          PrimaryButton(title: "Capture", icon: "capture", height: 50) {
            Task { await app.capture() }
          }
          .disabled(!cameraActive)
        }.frame(width: w - 37).offset(x: 19, y: h - 113)
      } else if !cameraActive {
        PrimaryButton(title: "Resume") { app.start(.camera, continuing: true) }.frame(width: w - 37)
          .offset(x: 19, y: h - 113)
      }
    }.foregroundStyle(.white).sheet(isPresented: $showingTips) {
      NavigationStack {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            Text("Look for lens reflections").font(Theme.font(24, .bold))
            Text(
              "The flashlight turns on when scanning starts. You can switch it off with the flashlight button."
            )
            Text(
              "Move close enough to keep the object sharp, then slowly change the angle. Hold the phone steady when a small glint appears."
            )
            Text(
              "Privar marks persistent, compact reflections for you to inspect. A mark can also come from glass, metal or an LED. It does not confirm that an object is a camera."
            )
            Text(
              "An unlit or covered lens may show no detectable reflection. Continue with a visual inspection even if nothing is marked."
            )
          }.font(Theme.font(16)).padding(24)
        }.background(Theme.background).foregroundStyle(.white)
          .navigationTitle("Camera Inspection").navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingTips = false } }
          }
      }.presentationDetents([.large]).preferredColorScheme(.dark)
    }.task {
      sweep = true
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        if cameraActive { elapsed += 1 }
      }
    }
  }
  private func scanSweep(width: CGFloat, height: CGFloat) -> some View {
    return VStack(spacing: 0) {
      Rectangle().fill(Theme.green).frame(height: 4)
      LinearGradient(
        colors: [Theme.green.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom
      ).frame(height: 190)
    }
    .frame(width: width).offset(y: sweep ? height - 280 : 120)
    .animation(
      reduceMotion ? nil : .linear(duration: 3).repeatForever(autoreverses: true),
      value: sweep)
  }
  private var preview: some View {
    CameraPreview(session: app.camera.previewSession)
  }
  private var quiet: Bool {
    return elapsed >= 8
  }
  private var cameraActive: Bool {
    return app.camera.running
  }
  private var frameSize: CGSize {
    return app.camera.frameSize
  }
  private var candidate: CGRect? {
    return app.camera.candidate
  }
}
