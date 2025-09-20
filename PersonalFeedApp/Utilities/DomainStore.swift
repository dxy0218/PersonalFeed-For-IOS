import Foundation
import Combine

/// 域名策略模式
enum DomainMode: String, Codable {
    case allowAllExceptBlacklist   // 默认允许，黑名单阻止
    case allowOnlyWhitelist        // 仅白名单允许
}

/// 管理域名白/黑名单（持久化到 Documents/domains.json）
final class DomainStore: ObservableObject {
    static let shared = DomainStore()

    @Published private(set) var whitelist: Set<String> = []
    @Published private(set) var blacklist: Set<String> = []
    @Published var mode: DomainMode = .allowAllExceptBlacklist

    private let fm = FileManager.default
    private let saveURL: URL

    private init() {
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        saveURL = base.appendingPathComponent("domains.json")
        load()

        // 首次安装：用 Config/ats_whitelist.json 初始化白名单（与 ATS 保持同源）
        if whitelist.isEmpty && blacklist.isEmpty {
            if let bundled = Bundle.main.url(forResource: "ats_whitelist", withExtension: "json", subdirectory: "Config"),
               let data = try? Data(contentsOf: bundled),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let arr = obj["whitelist"] as? [String] {
                whitelist = Set(arr.map(normalize))
            }
            save()
        }
    }

    // MARK: - 对外 API
    func addToWhitelist(_ host: String) {
        let h = normalize(host)
        blacklist.remove(h)
        whitelist.insert(h)
        save()
    }

    func addToBlacklist(_ host: String) {
        let h = normalize(host)
        whitelist.remove(h)
        blacklist.insert(h)
        save()
    }

    func removeFromWhitelist(_ host: String) {
        whitelist.remove(normalize(host))
        save()
    }

    func removeFromBlacklist(_ host: String) {
        blacklist.remove(normalize(host))
        save()
    }

    func isWhitelisted(_ host: String) -> Bool { whitelist.contains(normalize(host)) }
    func isBlacklisted(_ host: String) -> Bool { blacklist.contains(normalize(host)) }

    func setMode(_ newMode: DomainMode) {
        mode = newMode
        save()
    }

    // MARK: - 存取
    private struct SaveModel: Codable {
        var whitelist: [String]
        var blacklist: [String]
        var mode: DomainMode
    }

    private func save() {
        let model = SaveModel(whitelist: Array(whitelist),
                              blacklist: Array(blacklist),
                              mode: mode)
        if let data = try? JSONEncoder().encode(model) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    private func load() {
        guard fm.fileExists(atPath: saveURL.path),
              let data = try? Data(contentsOf: saveURL),
              let model = try? JSONDecoder().decode(SaveModel.self, from: data) else {
            return
        }
        whitelist = Set(model.whitelist.map(normalize))
        blacklist = Set(model.blacklist.map(normalize))
        mode = model.mode
    }

    // 统一化域名/URL → host
    fileprivate func normalize(_ s: String) -> String {
        var host = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if host.hasPrefix("http://") || host.hasPrefix("https://"),
           let h = URL(string: host)?.host?.lowercased() {
            host = h
        }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return host
    }
}
