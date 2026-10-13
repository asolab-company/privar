import AVFoundation
import Observation

@MainActor @Observable final class CameraService: CameraScanning {
  let worker = CameraWorker()
  var previewSession: AVCaptureSession { worker.session }
  private(set) var running = false
  private(set) var candidate: CGRect?
  private(set) var frameSize = CGSize(width: 1080, height: 1920)
  private(set) var torchOn = false
  var zoom: CGFloat = 1 { didSet { worker.zoom(zoom) } }
  var error: String?
  var onStarted: (() -> Void)?
  private var generation = 0
  @ObservationIgnored nonisolated(unsafe) private var notifications: [NSObjectProtocol] = []
  init() {
    worker.update = { [weak self] candidate, size in
      Task { @MainActor in
        guard let self, self.running else { return }
        self.candidate = candidate
        self.frameSize = size
      }
    }
    for name in [
      AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification,
    ] {
      notifications.append(
        NotificationCenter.default.addObserver(forName: name, object: worker.session, queue: .main)
        { [weak self] _ in
          Task { @MainActor in
            self?.error = "Camera was interrupted. Return to the scanner and try again."
            self?.stop()
          }
        })
    }
  }
  deinit { for token in notifications { NotificationCenter.default.removeObserver(token) } }
  func start() async {
    error = nil
    generation += 1
    let request = generation
    let allowed: Bool
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: allowed = true
    case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
    default: allowed = false
    }
    guard request == generation else { return }
    guard allowed else {
      error =
        "Camera access is denied or restricted. Enable access in Settings to inspect your room."
      return
    }
    worker.start { [weak self] failure, torchOn in
      Task { @MainActor in
        guard let self, request == self.generation else { return }
        if let failure {
          self.error = failure
        } else {
          self.running = true
          self.torchOn = torchOn
          self.onStarted?()
        }
      }
    }
  }
  func stop() {
    generation += 1
    running = false
    torchOn = false
    candidate = nil
    worker.stop()
  }
  func toggleTorch() {
    let desired = !torchOn
    worker.torch(desired) { [weak self] on in
      Task { @MainActor in
        self?.torchOn = on
        if desired && !on && self?.running == true {
          self?.error =
            "If the torch is unavailable, use another light source to inspect reflections."
        }
      }
    }
  }
  func capture() async throws -> (Data, CGRect?) {
    let result: (Data?, CGRect?) = await withCheckedContinuation { continuation in
      worker.capture { data, rect in continuation.resume(returning: (data, rect)) }
    }
    guard let data = result.0 else {
      throw NSError(
        domain: "Privar", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Wait for a camera frame before capturing."])
    }
    return (data, result.1)
  }
}
