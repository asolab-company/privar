import CoreMotion
import Observation

@MainActor @Observable final class MagneticService: MagneticMeasuring {
  private let motion = CMMotionManager()
  private(set) var running = false
  private(set) var assessment = MagneticAssessment()
  var error: String?
  var onStarted: (() -> Void)?
  private var started = false
  private var clock: Task<Void, Never>?
  func start() { begin(reset: true) }
  func resume() { begin(reset: false) }
  private func begin(reset: Bool) {
    error = nil
    if reset { assessment = MagneticAssessment() }
    started = false
    guard motion.isMagnetometerAvailable else {
      error = "A magnetometer is unavailable on this device."
      return
    }
    motion.magnetometerUpdateInterval = 0.1
    running = true
    motion.startMagnetometerUpdates(to: .main) { [weak self] data, failure in
      Task { @MainActor in
        guard let self, self.running else { return }
        if let failure {
          self.error = "Magnetic measurements failed: \(failure.localizedDescription)"
          self.stop()
          return
        }
        guard let field = data?.magneticField else { return }
        if !self.started {
          self.started = true
          self.onStarted?()
          self.clock = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            self?.stop()
          }
        }
        self.assessment.update(sqrt(field.x * field.x + field.y * field.y + field.z * field.z))
      }
    }
  }
  func stop() {
    running = false
    motion.stopMagnetometerUpdates()
    clock?.cancel()
    clock = nil
  }
}
