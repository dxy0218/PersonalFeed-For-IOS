import Foundation

final class DomainPolicy {
    static let shared = DomainPolicy(); private init() {}

    func permit(url: URL) -> Bool {
        guard let host0 = url.host?.lowercased() else { return true }
        let host = host0.hasPrefix("www.") ? String(host0.dropFirst(4)) : host0

        let store = DomainStore.shared
        switch store.mode {
        case .allowAllExceptBlacklist:
            return !store.isBlacklisted(host)
        case .allowOnlyWhitelist:
            return store.isWhitelisted(host)
        }
    }
}
