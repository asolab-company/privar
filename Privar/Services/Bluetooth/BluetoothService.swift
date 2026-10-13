import CoreBluetooth
import Observation

@MainActor @Observable
final class BluetoothService: NSObject, BluetoothScanning, @preconcurrency CBCentralManagerDelegate
{
  private(set) var scanning = false
  private(set) var remaining = 30
  private(set) var seen: Set<UUID> = []
  var error: String?
  var onStarted: (() -> Void)?
  var onDevice: ((NearbyDevice) -> Void)?
  private var central: CBCentralManager?
  private var requested = false
  private var resuming = false
  private var clock: Task<Void, Never>?
  func start() {
    error = nil
    requested = true
    resuming = false
    if central == nil {
      central = CBCentralManager(delegate: self, queue: .main)
    } else {
      startIfReady()
    }
  }
  func resume() {
    error = nil
    requested = true
    resuming = true
    startIfReady()
  }
  private func startIfReady() {
    guard requested, let central else { return }
    switch central.state {
    case .poweredOn:
      requested = false
      if !resuming {
        seen = []
        remaining = 30
      }
      guard remaining > 0 else { return }
      central.scanForPeripherals(
        withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
      scanning = true
      onStarted?()
      clock?.cancel()
      clock = Task { [weak self] in
        for value in (0..<(self?.remaining ?? 0)).reversed() {
          try? await Task.sleep(for: .seconds(1))
          guard !Task.isCancelled, let self else { return }
          self.remaining = value
        }
        self?.stop()
      }
    case .unauthorized:
      requested = false
      error = "Bluetooth access is denied. Enable it in Settings to scan nearby devices."
    case .poweredOff:
      requested = false
      error = "Bluetooth is turned off. Turn it on in Settings and try again."
    case .unsupported:
      requested = false
      error = "Bluetooth scanning is unavailable on this device."
    case .resetting, .unknown: break
    @unknown default:
      requested = false
      error = "Bluetooth is unavailable. Please try again."
    }
  }
  func stop() {
    requested = false
    central?.stopScan()
    scanning = false
    clock?.cancel()
    clock = nil
  }
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if scanning && central.state != .poweredOn {
      stop()
      error = "Bluetooth became unavailable. The scan has stopped."
    }
    startIfReady()
  }
  func centralManager(
    _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any], rssi RSSI: NSNumber
  ) {
    guard scanning else { return }
    seen.insert(peripheral.identifier)
    onDevice?(
      NearbyDevice(
        id: peripheral.identifier,
        name: advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name,
        rssi: RSSI.intValue == 127 ? nil : RSSI.intValue,
        connectable: (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue,
        firstSeen: Date(), lastSeen: Date()))
  }
}
