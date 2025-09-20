import Foundation

struct OpenGraphPreview {
    let title: String?
    let description: String?
    let imageURL: URL?
}

enum OpenGraphClient {
    static func fetchPreview(for pageURL: URL) async throws -> OpenGraphPreview {
        guard ["http", "https"].contains(pageURL.scheme?.lowercased()) else {
            return OpenGraphPreview(title: nil, description: nil, imageURL: nil)
        }
        let (data, finalURL) = try await downloadHTML(from: pageURL, maxBytes: 1_500_000)
        #if DEBUG
        print("🌐 Downloaded HTML bytes:", data.count, "from:", finalURL.absoluteString)
        #endif

        let html = decodeHTML(data)
        let og = parseMeta(html: html)
        let fallbackImage = parseIcons(html: html, base: finalURL)

        let imageURL = resolve(urlString: og.image ?? parseTwitterImage(html) ?? fallbackImage, base: finalURL)
        let title = og.title ?? parseTwitterTitle(html) ?? parseTitle(html)
        let desc  = og.description ?? parseTwitterDescription(html) ?? parseMetaDescription(html)

        return OpenGraphPreview(title: title?.trimmed, description: desc?.trimmed, imageURL: imageURL)
    }
}

// MARK: - Networking
private extension OpenGraphClient {
    static func downloadHTML(from url: URL, maxBytes: Int) async throws -> (Data, URL) {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15

        let (tmpURL, resp) = try await URLSession.shared.download(for: req)
        let http = resp as? HTTPURLResponse
        let finalURL = http?.url ?? url

        var data = try Data(contentsOf: tmpURL)
        if data.count > maxBytes { data = data.prefix(maxBytes) }
        return (data, finalURL)
    }

    static var userAgent: String {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    }
}

// MARK: - Parse helpers
private struct OGBucket { var title: String?; var description: String?; var image: String? }

private func parseMeta(html: String) -> OGBucket {
    var r = OGBucket()
    for (prop, content) in findMeta(html: html, keyAttr: "property") {
        switch prop.lowercased() {
        case "og:title":       if r.title == nil       { r.title = content }
        case "og:description": if r.description == nil { r.description = content }
        case "og:image", "og:image:url":
            if r.image == nil { r.image = content }
        default: break
        }
    }
    return r
}

private func parseTwitterTitle(_ html: String) -> String? {
    findMeta(html: html, keyAttr: "name").first { $0.0.lowercased() == "twitter:title" }?.1
}
private func parseTwitterDescription(_ html: String) -> String? {
    findMeta(html: html, keyAttr: "name").first { $0.0.lowercased() == "twitter:description" }?.1
}
private func parseTwitterImage(_ html: String) -> String? {
    let list = findMeta(html: html, keyAttr: "name")
    return list.first { $0.0.lowercased() == "twitter:image" || $0.0.lowercased() == "twitter:image:src" }?.1
}

private func parseTitle(_ html: String) -> String? {
    if let range = html.range(of: "(?is)<title[^>]*>(.*?)</title>", options: .regularExpression) {
        return String(html[range]).replacingOccurrences(of: "(?is)</?title[^>]*>", with: "", options: .regularExpression)
    }
    return nil
}
private func parseMetaDescription(_ html: String) -> String? {
    findMeta(html: html, keyAttr: "name").first { $0.0.lowercased() == "description" }?.1
}

private func findMeta(html: String, keyAttr: String) -> [(String, String)] {
    let pattern = "(?is)<meta\\s+[^>]*\(keyAttr)\\s*=\\s*\"([^\"]+)\"[^>]*content\\s*=\\s*\"([^\"]+)\"[^>]*>"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let ns = html as NSString
    let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
    return matches.compactMap { m in
        guard m.numberOfRanges >= 3 else { return nil }
        let key = ns.substring(with: m.range(at: 1))
        let val = ns.substring(with: m.range(at: 2))
        return (key, val)
    }
}

private func parseIcons(html: String, base: URL) -> String? {
    let pattern = "(?is)<link\\s+[^>]*rel\\s*=\\s*\"([^\"]+)\"[^>]*href\\s*=\\s*\"([^\"]+)\"[^>]*>"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let ns = html as NSString
    let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
    let scored: [(score: Int, href: String)] = matches.compactMap { m in
        guard m.numberOfRanges >= 3 else { return nil }
        let rel = ns.substring(with: m.range(at: 1)).lowercased()
        let href = ns.substring(with: m.range(at: 2))
        if rel.contains("apple-touch-icon") { return (2, href) }
        if rel == "icon" || rel.contains("shortcut icon") { return (1, href) }
        return (0, href)
    }
    return scored.sorted { $0.score > $1.score }.first?.href
}

private func resolve(urlString: String?, base: URL) -> URL? {
    guard let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
    return URL(string: s, relativeTo: base)?.absoluteURL
}

private func decodeHTML(_ data: Data) -> String {
    if let s = String(data: data, encoding: .utf8) { return s }
    if let s = String(data: data, encoding: .isoLatin1) { return s }
    return String(decoding: data, as: UTF8.self)
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
