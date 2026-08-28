import Foundation

/// Cached unlock state shared between the container app and AUv3 extension.
enum UnlockStore {
    private static let effectAllowedKey = "jjbreeze.effectAllowed.v1"
    private static let accessStateKey = "jjbreeze.accessState.v1"

    static var cachedEffectAllowed: Bool {
        if let suite = groupDefaults, suite.object(forKey: effectAllowedKey) != nil {
            return suite.bool(forKey: effectAllowedKey)
        }
        return UserDefaults.standard.bool(forKey: effectAllowedKey)
    }

    static var cachedAccessState: AccessState {
        let raw = groupDefaults?.string(forKey: accessStateKey)
            ?? UserDefaults.standard.string(forKey: accessStateKey)
        return decode(raw) ?? .trialNotStarted
    }

    static func write(accessState: AccessState) {
        let allowed = accessState.isEffectAllowed
        let encoded = encode(accessState)
        if let suite = groupDefaults {
            suite.set(allowed, forKey: effectAllowedKey)
            suite.set(encoded, forKey: accessStateKey)
        }
        UserDefaults.standard.set(allowed, forKey: effectAllowedKey)
        UserDefaults.standard.set(encoded, forKey: accessStateKey)
    }

    private static var groupDefaults: UserDefaults? {
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserPresetStore.appGroupID) != nil else {
            return nil
        }
        return UserDefaults(suiteName: UserPresetStore.appGroupID)
    }

    private static func encode(_ state: AccessState) -> String {
        switch state {
        case .trialNotStarted: "none"
        case .trialExpired: "expired"
        case .unlocked: "unlock"
        case .trialActive(let days): "trial:\(days)"
        }
    }

    private static func decode(_ raw: String?) -> AccessState? {
        guard let raw else { return nil }
        if raw == "none" { return .trialNotStarted }
        if raw == "expired" { return .trialExpired }
        if raw == "unlock" { return .unlocked }
        if raw.hasPrefix("trial:"), let days = Int(raw.dropFirst(6)) {
            return .trialActive(daysRemaining: days)
        }
        return nil
    }
}
