import Foundation

@MainActor protocol MagneticMeasuring: AnyObject {
  var running: Bool { get }
  var assessment: MagneticAssessment { get }
  var error: String? { get set }
  var onStarted: (() -> Void)? { get set }
  func start()
  func stop()
  func resume()
}
