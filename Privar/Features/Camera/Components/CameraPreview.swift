import AVFoundation
import SwiftUI

final class CameraPreviewView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
  var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
struct CameraPreview: UIViewRepresentable {
  let session: AVCaptureSession
  func makeUIView(context: Context) -> CameraPreviewView {
    let view = CameraPreviewView()
    view.preview.session = session
    view.preview.videoGravity = .resizeAspectFill
    return view
  }
  func updateUIView(_ view: CameraPreviewView, context: Context) {
    if let c = view.preview.connection, c.isVideoRotationAngleSupported(90) {
      c.videoRotationAngle = 90
    }
  }
}
