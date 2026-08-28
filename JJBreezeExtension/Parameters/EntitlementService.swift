import Foundation
import StoreKit

@MainActor
@Observable
final class EntitlementService {
    static let shared = EntitlementService()

    private(set) var accessState: AccessState = UnlockStore.cachedAccessState
    private(set) var trialProduct: Product?
    private(set) var unlockProduct: Product?
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var lastError: String?

    private var updatesTask: Task<Void, Never>?

    var isEffectAllowed: Bool { accessState.isEffectAllowed }

    private init() {
        updatesTask = Task { @MainActor [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }
    }

    func refresh() async {
        var hasUnlock = false
        var trialPurchaseDate: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            switch transaction.productID {
            case PurchaseProducts.unlock:
                hasUnlock = true
            case PurchaseProducts.trial:
                trialPurchaseDate = transaction.purchaseDate
            default:
                break
            }
        }

        let next: AccessState
        if hasUnlock {
            next = .unlocked
        } else if let start = trialPurchaseDate {
            let end = Calendar.current.date(
                byAdding: .day,
                value: PurchaseProducts.trialDurationDays,
                to: start
            ) ?? start
            if Date() < end {
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: end)).day ?? 0
                next = .trialActive(daysRemaining: max(0, days))
            } else {
                next = .trialExpired
            }
        } else {
            next = .trialNotStarted
        }

        apply(next)
    }

    func loadProducts() async {
        guard trialProduct == nil || unlockProduct == nil else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [PurchaseProducts.trial, PurchaseProducts.unlock])
            trialProduct = products.first { $0.id == PurchaseProducts.trial }
            unlockProduct = products.first { $0.id == PurchaseProducts.unlock }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func startTrial() async {
        guard let trialProduct else {
            lastError = "Trial is not available yet. Check your connection and try again."
            return
        }
        await purchase(trialProduct)
    }

    func purchaseUnlock() async {
        guard let unlockProduct else {
            lastError = "Unlock is not available yet. Check your connection and try again."
            return
        }
        await purchase(unlockProduct)
    }

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refresh()
            lastError = accessState.isEffectAllowed ? nil : "No purchases found for this Apple ID."
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                    lastError = nil
                }
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func apply(_ state: AccessState) {
        accessState = state
        UnlockStore.write(accessState: state)
        NotificationCenter.default.post(name: .jjBreezeAccessChanged, object: nil)
    }
}
