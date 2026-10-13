import Foundation
import Observation
import StoreKit

@MainActor @Observable final class SubscriptionService {
  private(set) var product: Product?
  private(set) var entitled = false
  private(set) var eligibleForTrial = false
  private(set) var busy = false
  var message: String?
  @ObservationIgnored nonisolated(unsafe) private var updates: Task<Void, Never>?
  @ObservationIgnored nonisolated(unsafe) private var expiry: Task<Void, Never>?
  @ObservationIgnored private var refreshTask: Task<Void, Never>?
  private var refreshGeneration = 0
  let productID =
    Bundle.main.object(forInfoDictionaryKey: "PrivarProductID") as? String ?? "com.privar.weekly"
  private func observe() {
    guard updates == nil else { return }
    updates = Task { [weak self] in
      for await result in Transaction.updates {
        guard let self else { return }
        if case .verified(let transaction) = result, transaction.productID == self.productID {
          await self.refresh()
          await transaction.finish()
        }
      }
    }
  }
  deinit {
    updates?.cancel()
    expiry?.cancel()
  }
  func load(reportErrors: Bool = false) async {
    observe()
    await refresh()
    do {
      product = try await Product.products(for: [productID]).first
      if product == nil && reportErrors && !Task.isCancelled {
        message = "Subscription is unavailable. You can continue with the limited version."
      }
    } catch {
      if reportErrors && !Task.isCancelled {
        message = "Unable to load the subscription. Check your connection and try again."
      }
    }
    await refresh()
  }
  func refresh() async {
    guard updates != nil else { return }
    refreshGeneration += 1
    let generation = refreshGeneration
    let preceding = refreshTask
    let task = Task { [weak self] in
      await preceding?.value
      guard let self else { return }
      await self.readEntitlements()
    }
    refreshTask = task
    await task.value
    if generation == refreshGeneration { refreshTask = nil }
  }
  private func readEntitlements() async {
    var active = false
    var end: Date?
    for await result in Transaction.currentEntitlements {
      guard case .verified(let t) = result, t.productID == productID, t.revocationDate == nil,
        !t.isUpgraded
      else { continue }
      if t.expirationDate == nil || t.expirationDate! > Date() {
        active = true
        end = t.expirationDate
      }
    }
    if let subscription = product?.subscription, let statuses = try? await subscription.status {
      for status in statuses where status.state == .inGracePeriod {
        if case .verified(let t) = status.transaction, t.productID == productID,
          t.revocationDate == nil, case .verified(let renewal) = status.renewalInfo,
          let grace = renewal.gracePeriodExpirationDate, grace > Date()
        {
          active = true
          end = grace
        }
      }
    }
    entitled = active
    eligibleForTrial = await product?.subscription?.isEligibleForIntroOffer ?? false
    expiry?.cancel()
    if let end, active {
      expiry = Task { [weak self] in
        try? await Task.sleep(for: .seconds(max(1, end.timeIntervalSinceNow)))
        guard !Task.isCancelled else { return }
        await self?.refresh()
      }
    }
  }
  func purchase() async {
    guard !busy else { return }
    guard let product else {
      await load(reportErrors: true)
      return
    }
    busy = true
    defer { busy = false }
    do {
      switch try await product.purchase() {
      case .success(let result):
        guard case .verified(let transaction) = result else {
          message = "The purchase could not be verified. Please try Restore."
          return
        }
        await refresh()
        await transaction.finish()
      case .pending:
        message = "Your purchase is pending approval. Access will update when it is approved."
      case .userCancelled: break
      @unknown default: message = "The purchase could not be completed."
      }
    } catch StoreKitError.userCancelled {} catch {
      message = "Purchase failed: \(error.localizedDescription)"
    }
  }
  func restore() async {
    observe()
    guard !busy else { return }
    busy = true
    defer { busy = false }
    do {
      try await AppStore.sync()
      await refresh()
      message =
        entitled ? "Your subscription has been restored." : "No active subscription was found."
    } catch { message = "Restore failed: \(error.localizedDescription)" }
  }
  var purchaseAvailable: Bool {
    product?.type == .autoRenewable && product?.subscription != nil
  }
  var planName: String? { product?.displayName }
  var productTypeText: String {
    guard let product else { return "" }
    switch product.type {
    case .autoRenewable: return "Auto-renewable subscription"
    case .nonRenewable: return "Non-renewing subscription"
    case .consumable: return "Consumable"
    case .nonConsumable: return "One-time purchase"
    default: return "Subscription"
    }
  }
  var priceText: String {
    guard let product, let period = product.subscription?.subscriptionPeriod else {
      return "Subscription pricing unavailable"
    }
    let regular = "\(product.displayPrice) / \(intervalText(period))"
    guard eligibleForTrial, let offer = product.subscription?.introductoryOffer else {
      return regular
    }
    let duration = "\(offer.period.value * offer.periodCount)-\(unitText(offer.period.unit))"
    switch offer.paymentMode {
    case .freeTrial: return "\(regular) after a \(duration) free trial"
    case .payUpFront: return "\(offer.displayPrice) for \(duration), then \(regular)"
    case .payAsYouGo:
      return
        "\(offer.displayPrice) / \(intervalText(offer.period)) for \(duration), then \(regular)"
    default: return regular
    }
  }
  private func intervalText(_ period: Product.SubscriptionPeriod) -> String {
    let unit = unitText(period.unit)
    return period.value == 1 ? unit : "\(period.value) \(unit)s"
  }
  private func unitText(_ unit: Product.SubscriptionPeriod.Unit) -> String {
    switch unit {
    case .day: "day"
    case .week: "week"
    case .month: "month"
    case .year: "year"
    default: "period"
    }
  }
}
