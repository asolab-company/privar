import Foundation

@MainActor protocol BluetoothScanning: AnyObject {
  var scanning: Bool { get }
  var remaining: Int { get }
  var seen: Set<UUID> { get }
  var error: String? { get set }
  var onStarted: (() -> Void)? { get set }
  var onDevice: ((NearbyDevice) -> Void)? { get set }
  func start()
  func stop()
  func resume()
}
