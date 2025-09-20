import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 可持久化的翻译配置
struct TranslationConfig: Codable, Equatable {
    enum Provider: Codable, Equatable, Identifiable {
        case systemWeb                                   // 使用 Safari 网页翻译
        case libreTranslate(baseURL: String, apiKey: String?)
        case deepl(apiKey: String)
        case google(apiKey: String)
        case microsoft(apiKey: String, region: String)

        var id: String {
            switch self {
            case .systemWeb:      return "systemWeb"
            case .libreTranslate: return "libre"
            case .deepl:          return "deepl"
            case .google:         return "google"
            case .microsoft:      return "microsoft"
            }
        }

        var displayName: String {
            switch self {
            case .systemWeb:      return "系统翻译（Safari）"
            case .libreTranslate: return "LibreTranslate"
            case .deepl:          return "DeepL"
            case .google:         return "Google"
            case .microsoft:      return "Microsoft"
            }
        }

        /// 用于内存缓存 key
        var cacheKey: String { id }
    }

    var provider: Provider
    var targetLang: String

    static let defaultConfig = TranslationConfig(
        provider: .systemWeb,
        targetLang: "zh"
    )
}

// MARK: - 翻译服务（类型本身不隔离到主线程）
final class TranslationService {
    static let shared = TranslationService()

    // 当前配置（设置页修改后会写回）
    private(set) var config: TranslationConfig {
        didSet { try? LocalStorage.shared.saveTranslationConfig(config) }
    }

    /// 便捷访问，供 VM/视图读取
    var targetLang: String { config.targetLang }

    private init() {
        // 从本地载入配置；没有则用默认
        self.config = (try? LocalStorage.shared.loadTranslationConfig()) ?? .defaultConfig
    }

    /// 设置页保存/更新配置
    func updateConfig(_ newConfig: TranslationConfig) {
        self.config = newConfig
    }

    // 内存级去重缓存
    private var cache: [String: String] = [:]

    // MARK: - 主功能：站内翻译（返回译文）
    func translate(text: String, to target: String? = nil) async throws -> String {
        let tgt = (target ?? config.targetLang).lowercased()
        let key = "t:\(config.provider.cacheKey)#\(tgt)#\(text)"
        if let hit = cache[key] { return hit }

        let result: String
        switch config.provider {
        case .systemWeb:
            throw TranslationError.unsupportedInApp

        case .libreTranslate(let base, let apiKey):
            // String -> URL（非法时回退官方节点）
            let baseURL = URL(string: base) ?? URL(string: "https://libretranslate.com")!
            result = try await libreTranslate(baseURL: baseURL, apiKey: apiKey, q: text, target: tgt)

        case .deepl(let apiKey):
            result = try await deepl(apiKey: apiKey, q: text, target: mapDeepLCode(tgt))

        case .google(let apiKey):
            result = try await google(apiKey: apiKey, q: text, target: tgt)

        case .microsoft(let apiKey, let region):
            result = try await microsoft(apiKey: apiKey, region: region, q: text, target: tgt)
        }

        cache[key] = result
        return result
    }

    // MARK: - 系统翻译（Safari 打开，仅此方法要求主线程）
    @MainActor
    func openSystemTranslate(text: String, from viewController: AnyObject? = nil) {
        #if canImport(UIKit)
        let tgt = config.targetLang.isEmpty ? "zh" : config.targetLang
        let enc = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlStr = "https://translate.google.com/?sl=auto&tl=\(tgt)&text=\(enc)&op=translate"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}

// MARK: - 错误类型
enum TranslationError: Error {
    case http, parse, unsupportedInApp
}

// MARK: - 各后端实现
private extension TranslationService {
    func libreTranslate(baseURL: URL, apiKey: String?, q: String, target: String) async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent("/translate"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = ["q": q, "source": "auto", "target": target, "format": "text"]
        if let apiKey, !apiKey.isEmpty { payload["api_key"] = apiKey }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw TranslationError.http }

        // 兼容两种返回结构
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let t = obj["translatedText"] as? String { return t }
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let t = arr.first?["translatedText"] as? String { return t }

        throw TranslationError.parse
    }

    func deepl(apiKey: String, q: String, target: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api-free.deepl.com/v2/translate")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        let body = "text=\(percentEncode(q))&target_lang=\(target.uppercased())"
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw TranslationError.http }

        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let arr = obj["translations"] as? [[String: Any]],
           let t = arr.first?["text"] as? String { return t }

        throw TranslationError.parse
    }

    func google(apiKey: String, q: String, target: String) async throws -> String {
        let urlStr = "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)"
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["q": q, "target": target, "format": "text"]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw TranslationError.http }

        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataObj = obj["data"] as? [String: Any],
           let arr = dataObj["translations"] as? [[String: Any]],
           let t = arr.first?["translatedText"] as? String { return t }

        throw TranslationError.parse
    }

    func microsoft(apiKey: String, region: String, q: String, target: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=\(target)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        req.setValue(region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        let body = [[ "Text": q ]]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw TranslationError.http }

        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = arr.first,
           let trans = first["translations"] as? [[String: Any]],
           let t = trans.first?["text"] as? String { return t }

        throw TranslationError.parse
    }

    // MARK: Utils
    func percentEncode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
    func mapDeepLCode(_ code: String) -> String {
        switch code.lowercased() {
        case "zh", "zh-hans", "zh_cn", "zh-cn": return "ZH"
        default: return code.uppercased()
        }
    }
}

// MARK: - 视图小工具（避免在各文件重复声明）
extension TranslationService {
    static func supportsInApp() -> Bool {
        switch TranslationService.shared.config.provider {
        case .systemWeb: return false
        default: return true
        }
    }
    static func sharedTargetLang() -> String { TranslationService.shared.config.targetLang }
    static func sharedTargetLangUpper() -> String { sharedTargetLang().uppercased() }

    static func readCached(for item: FeedItem, key: String) -> String? {
        item.translations?["\(key):\(sharedTargetLang())"]
    }
}
