import Foundation

final class LocalStorage {
    static let shared = LocalStorage()
    private init() {}

    private let feedFile = "feed_items.json"
    private let transFile = "translation_config.json"

    // MARK: - FeedItem 持久化
    func save(_ items: [FeedItem]) throws {
        let url = try dataURL(for: feedFile)
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: .atomic)
    }

    func load() throws -> [FeedItem] {
        let url = try dataURL(for: feedFile)
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FeedItem].self, from: data)
    }

    // MARK: - 翻译配置 持久化
    func saveTranslationConfig(_ cfg: TranslationConfig) throws {
        let url = try dataURL(for: transFile)
        let data = try JSONEncoder().encode(cfg)
        try data.write(to: url, options: .atomic)
    }

    func loadTranslationConfig() throws -> TranslationConfig {
        let url = try dataURL(for: transFile)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .defaultConfig
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TranslationConfig.self, from: data)
    }

    // MARK: - Util
    private func dataURL(for name: String) throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return dir.appendingPathComponent(name)
    }
}
