import Foundation

/// 维护域名的历史“规模/可信度”画像；可在设置页做简单编辑（此版先内置表）。
enum SourceScale: Int, Codable { case small = 1, medium = 2, large = 3, major = 4 }

struct SourceProfile: Codable {
    var domain: String
    var scale: SourceScale          // 媒体规模（站点体量/覆盖）
    var credibility: Double         // 历史可信度（0.0~1.0）
}

final class SourceReputation {
    static let shared = SourceReputation()
    private init() { loadDefaults() }

    private(set) var profiles: [String: SourceProfile] = [:] // key: domain

    func profile(for domain: String?) -> SourceProfile? {
        guard let d = domain?.lowercased() else { return nil }
        return profiles[d]
    }

    // 你可以在这里维护常见站点的初始画像（示例）
    private func loadDefaults() {
        let seeds: [SourceProfile] = [
            .init(domain: "bbc.com",        scale: .major, credibility: 0.95),
            .init(domain: "nytimes.com",    scale: .major, credibility: 0.95),
            .init(domain: "theverge.com",   scale: .large, credibility: 0.85),
            .init(domain: "medium.com",     scale: .large, credibility: 0.75)
        ]
        for s in seeds { profiles[s.domain] = s }
    }
}
