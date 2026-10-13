import Foundation

struct MagneticAssessment {
  enum Level: String { case calibrating, quiet, elevated, strong }
  private(set) var baseline: Double = 0
  private(set) var smoothed: Double = 0
  private(set) var level: Level = .calibrating
  private var samples: [Double] = []
  mutating func update(_ magnitude: Double) {
    guard magnitude.isFinite, magnitude >= 0 else { return }
    smoothed = samples.isEmpty ? magnitude : 0.2 * magnitude + 0.8 * smoothed
    if samples.count < 20 {
      samples.append(magnitude)
      baseline = samples.reduce(0, +) / Double(samples.count)
      level = .calibrating
      return
    }
    let delta = abs(smoothed - baseline)
    switch level {
    case .strong: level = delta < 35 ? (delta > 12 ? .elevated : .quiet) : .strong
    case .elevated: level = delta > 50 ? .strong : (delta < 10 ? .quiet : .elevated)
    default: level = delta > 50 ? .strong : (delta > 18 ? .elevated : .quiet)
    }
  }
}
