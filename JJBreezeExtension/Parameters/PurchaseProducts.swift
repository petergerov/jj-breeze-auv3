import Foundation

enum PurchaseProducts {
    /// $0 non-consumable — Apple trial naming convention (Guideline 3.1.1).
    static let trial = "com.gerov.jjbreeze.trial"
    /// One-time unlock ($2.99 in App Store Connect).
    static let unlock = "com.gerov.jjbreeze.unlock"
    static let trialDurationDays = 7

    static let all: Set<String> = [trial, unlock]
}

enum AccessState: Equatable, Sendable {
    case trialNotStarted
    case trialActive(daysRemaining: Int)
    case trialExpired
    case unlocked

    var isEffectAllowed: Bool {
        switch self {
        case .unlocked, .trialActive: true
        case .trialNotStarted, .trialExpired: false
        }
    }

    var bannerText: String? {
        switch self {
        case .trialNotStarted:
            return "Start your 7-day free trial."
        case .trialActive(let days):
            if days <= 0 { return "Trial ends today — unlock to keep the effect." }
            let unit = days == 1 ? "day" : "days"
            return "\(days) \(unit) left in your trial."
        case .trialExpired:
            return "Trial ended — unlock jj-breeze to hear the effect again."
        case .unlocked:
            return nil
        }
    }
}

extension Notification.Name {
    static let jjBreezeAccessChanged = Notification.Name("jjBreezeAccessChanged")
}
