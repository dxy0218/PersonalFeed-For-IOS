import Foundation

struct ArticleContent {
    let title: String?
    let summary: String?
    let imageURL: URL?
}

enum ContentFetcher {

    static func fetch(for pageURL: URL) async throws -> ArticleContent {
        // 1) 先用现有 OpenGraphClient 拿到标题/图
        let og = try await OpenGraphClient.fetchPreview(for: pageURL)

        // 2) 再抓 HTML 自己做一个“可读摘要”
        let (data, finalURL) = try await downloadHTML(from: pageURL, maxBytes: 2_000_000)
        let html = decodeHTML(data)

        // 优先在 <article>/<main>/#content 里找 <p>
        let container = firstMatch(html, pattern: "(?is)<(article|main|div[^>]*id\\s*=\\s*\"content\"[^>]*)>(.*?)</\\1>") ?? html
        let paras = allMatches(container, pattern: "(?is)<p[^>]*>(.*?)</p>")
            .map { stripTags($0) }
            .map { collapseSpaces($0) }
            .filter { $0.count >= 40 }               // 太短的过滤掉
            .prefix(5)                                // 取前 5 段
        let combined = paras.joined(separator: "\n\n")

        // 如果没在容器中找到，退化为全局 <p>
        let fallbackCombined: String? = {
            if combined.isEmpty {
                let ps = allMatches(html, pattern: "(?is)<p[^>]*>(.*?)</p>")
                    .map { stripTags($0) }
                    .map { collapseSpaces($0) }
                    .filter { $0.count >= 40 }
                    .prefix(5)
                return ps.isEmpty ? nil : ps.joined(separator: "\n\n")
            }
            return combined
        }()

        // 图片：优先 OG，再尝试 icon
        let image = og.imageURL ?? resolve(urlString: parseIcon(html), base: finalURL)

        return ArticleContent(
            title: og.title,
            summary: (og.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackCombined,
            imageURL: image
        )
    }
}

// MARK: - Networking helpers（复制一小段，避免改动 OpenGraphClient 的内部）
private func downloadHTML(from url: URL, maxBytes: Int) async throws -> (Data, URL) {
    var req = URLRequest(url: url)
    req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
    req.timeoutInterval = 15
    let (tmp, resp) = try await URLSession.shared.download(for: req)
    let http = resp as? HTTPURLResponse
    let finalURL = http?.url ?? url
    var data = try Data(contentsOf: tmp)
    if data.count > maxBytes { data = data.prefix(maxBytes) }
    return (data, finalURL)
}

private func decodeHTML(_ data: Data) -> String {
    if let s = String(data: data, encoding: .utf8) { return s }
    if let s = String(data: data, encoding: .isoLatin1) { return s }
    return String(decoding: data, as: UTF8.self)
}

// MARK: - HTML utils
private func firstMatch(_ s: String, pattern: String) -> String? {
    guard let r = try? NSRegularExpression(pattern: pattern) else { return nil }
    let ns = s as NSString
    guard let m = r.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) else { return nil }
    if m.numberOfRanges >= 3 { return ns.substring(with: m.range(at: 2)) }
    if m.numberOfRanges >= 1 { return ns.substring(with: m.range(at: 1)) }
    return nil
}
private func allMatches(_ s: String, pattern: String) -> [String] {
    guard let r = try? NSRegularExpression(pattern: pattern) else { return [] }
    let ns = s as NSString
    return r.matches(in: s, range: NSRange(location: 0, length: ns.length))
        .compactMap { $0.numberOfRanges >= 2 ? ns.substring(with: $0.range(at: 1)) : nil }
}

private func stripTags(_ html: String) -> String {
    var t = html.replacingOccurrences(of: "(?is)<script[^>]*>.*?</script>", with: "", options: .regularExpression)
    t = t.replacingOccurrences(of: "(?is)<style[^>]*>.*?</style>", with: "", options: .regularExpression)
    t = t.replacingOccurrences(of: "(?is)<[^>]+>", with: "", options: .regularExpression)
    return t.decodingHTMLEntities()
}

private func collapseSpaces(_ s: String) -> String {
    s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
}

private func parseIcon(_ html: String) -> String? {
    firstMatch(html, pattern: "(?is)<link\\s+[^>]*rel\\s*=\\s*\"(?:apple-touch-icon|icon|shortcut icon)\"[^>]*href\\s*=\\s*\"([^\"]+)\"")
}
private func resolve(urlString: String?, base: URL) -> URL? {
    guard let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
    return URL(string: s, relativeTo: base)?.absoluteURL
}

// 小工具：HTML entity 解码
private extension String {
    func decodingHTMLEntities() -> String {
        let map: [String: String] = [
            "&amp;":"&","&lt;":"<","&gt;":">","&quot;":"\"","&#39;":"'"
        ]
        var out = self
        map.forEach { out = out.replacingOccurrences(of: $0.key, with: $0.value) }
        return out
    }
}
