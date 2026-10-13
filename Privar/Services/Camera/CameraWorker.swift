import AVFoundation
import UIKit

final class CameraWorker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
  @unchecked Sendable
{
  let session = AVCaptureSession()
  let queue = DispatchQueue(label: "Privar.camera", qos: .userInitiated)
  private var device: AVCaptureDevice?
  private var output: AVCaptureVideoDataOutput?
  private var detector = BrightSpotDetector()
  private var lastImage: UIImage?
  private var lastCandidate: CGRect?
  private var frame = 0
  private let context = CIContext()
  var update: (@Sendable (CGRect?, CGSize) -> Void)?
  func start(completion: @escaping @Sendable (String?, Bool) -> Void) {
    queue.async { [self] in
      do {
        if session.inputs.isEmpty {
          guard
            let camera = AVCaptureDevice.default(
              .builtInWideAngleCamera, for: .video, position: .back)
          else {
            completion("A rear camera is unavailable.", false)
            return
          }
          session.beginConfiguration()
          session.sessionPreset = .hd1920x1080
          defer { session.commitConfiguration() }
          let input = try AVCaptureDeviceInput(device: camera)
          guard session.canAddInput(input) else {
            completion("Unable to configure the camera.", false)
            return
          }
          session.addInput(input)
          device = camera
          let out = AVCaptureVideoDataOutput()
          out.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
          ]
          out.alwaysDiscardsLateVideoFrames = true
          out.setSampleBufferDelegate(self, queue: queue)
          guard session.canAddOutput(out) else {
            completion("Unable to configure camera frames.", false)
            return
          }
          session.addOutput(out)
          output = out
          if let connection = out.connection(with: .video),
            connection.isVideoRotationAngleSupported(90)
          {
            connection.videoRotationAngle = 90
          }
        }
        detector = BrightSpotDetector()
        lastImage = nil
        lastCandidate = nil
        if let device { try configureDevice(device) }
        session.startRunning()
        if session.isRunning { setTorchLocked(true) }
        completion(
          session.isRunning ? nil : "The camera could not start.", device?.torchMode == .on)
      } catch { completion("Camera error: \(error.localizedDescription)", false) }
    }
  }
  private func configureDevice(_ device: AVCaptureDevice) throws {
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }
    if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
    if device.isExposureModeSupported(.continuousAutoExposure) {
      device.exposureMode = .continuousAutoExposure
    }
    if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
      device.whiteBalanceMode = .continuousAutoWhiteBalance
    }
  }
  func stop() {
    queue.async { [self] in
      setTorchLocked(false)
      session.stopRunning()
      lastImage = nil
      lastCandidate = nil
    }
  }
  private func setTorchLocked(_ on: Bool) {
    guard let device, device.hasTorch else { return }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      if on { try device.setTorchModeOn(level: 0.35) } else { device.torchMode = .off }
    } catch {}
  }
  func torch(_ on: Bool, completion: @escaping @Sendable (Bool) -> Void) {
    queue.async { [self] in
      setTorchLocked(on)
      completion(device?.torchMode == .on)
    }
  }
  func zoom(_ value: CGFloat) {
    queue.async { [self] in
      guard let device else { return }
      do {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        device.videoZoomFactor = min(max(value, 1), min(5, device.activeFormat.videoMaxZoomFactor))
      } catch {}
    }
  }
  func capture(completion: @escaping @Sendable (Data?, CGRect?) -> Void) {
    queue.async { [self] in
      guard let image = lastImage else {
        completion(nil, nil)
        return
      }
      let renderer = UIGraphicsImageRenderer(size: image.size)
      let annotated = renderer.image { ctx in
        image.draw(at: .zero)
        if let r = lastCandidate {
          let rect = CGRect(
            x: r.minX * image.size.width, y: r.minY * image.size.height,
            width: r.width * image.size.width, height: r.height * image.size.height)
          ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
          ctx.cgContext.setLineWidth(max(4, image.size.width / 150))
          ctx.cgContext.strokeEllipse(in: rect)
        }
      }
      completion(annotated.jpegData(compressionQuality: 0.95), lastCandidate)
    }
  }
  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    frame += 1
    guard frame % 3 == 0, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
    let w = CVPixelBufferGetWidth(buffer)
    let h = CVPixelBufferGetHeight(buffer)
    if let address = CVPixelBufferGetBaseAddress(buffer) {
      lastCandidate = detector.detect(
        bytes: address.assumingMemoryBound(to: UInt8.self), width: w, height: h,
        stride: CVPixelBufferGetBytesPerRow(buffer))
    }
    let ci = CIImage(cvPixelBuffer: buffer)
    if let cg = context.createCGImage(ci, from: ci.extent) { lastImage = UIImage(cgImage: cg) }
    update?(lastCandidate, CGSize(width: w, height: h))
  }
}
