import AVFoundation

@MainActor protocol CameraScanning: AnyObject {
  var previewSession: AVCaptureSession { get }
  var running: Bool { get }
  var candidate: CGRect? { get }
  var frameSize: CGSize { get }
  var torchOn: Bool { get }
  var zoom: CGFloat { get set }
  var error: String? { get set }
  var onStarted: (() -> Void)? { get set }
  func start() async
  func stop()
  func toggleTorch()
  func capture() async throws -> (Data, CGRect?)
}
