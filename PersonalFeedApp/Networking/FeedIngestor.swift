import Foundation

/// 从主流媒体 RSS/Atom 拉取最新条目，转为 FeedItem（含分类）
enum FeedIngestor {

    /// 默认订阅清单：每类至少 5 个
    static let defaultFeeds: [(FeedCategory, String)] = [
        // 新闻
        (.news, "https://feeds.bbci.co.uk/news/rss.xml"),
        (.news, "https://rss.cnn.com/rss/edition.rss"),
        (.news, "https://www.reuters.com/world/rss"),
        (.news, "https://www.theguardian.com/world/rss"),
        (.news, "https://apnews.com/hub/ap-top-news?utm_source=apnews.com&utm_medium=referral&utm_campaign=aprss"),
        (.news, "https://www.aljazeera.com/xml/rss/all.xml"),

        // 头条/科技媒体
        (.headline, "https://www.theverge.com/rss/index.xml"),
        (.headline, "https://techcrunch.com/feed/"),
        (.headline, "https://www.wired.com/feed/rss"),
        (.headline, "https://www.engadget.com/rss.xml"),
        (.headline, "https://arstechnica.com/feed/"),

        // 项目/产品/开发动态
        (.projects, "https://github.blog/changelog/feed/"),
        (.projects, "https://news.ycombinator.com/rss"),
        (.projects, "https://producthunt.com/feed"),
        (.projects, "https://stackoverflow.blog/feed/"),
        (.projects, "https://aws.amazon.com/about-aws/whats-new/recent/feed/"),

        // 灵感/人文/随笔
        (.ideas, "https://www.themarginalian.org/feed/"),
        (.ideas, "https://aeon.co/feed.rss"),
        (.ideas, "https://nautil.us/feed/"),
        (.ideas, "https://seths.blog/feed"),
        (.ideas, "https://fs.blog/feed/"),

        // 媒体/文化
        (.media, "https://www.theatlantic.com/feed/all/"),
        (.media, "https://variety.com/feed/"),
        (.media, "https://www.newyorker.com/feed/everything"),
        (.media, "https://www.vulture.com/rss/index.xml"),
        (.media, "https://www.rollingstone.com/music/music-news/feed/"),

        // 科学
        (.science, "https://www.nature.com/nature.rss"),
        (.science, "https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=science"),
        (.science, "https://www.nasa.gov/rss/dyn/breaking_news.rss"),
        (.science, "https://www.cell.com/atom/rss"),
        (.science, "https://www.quantamagazine.org/feed/"),

        // 体育
        (.sports, "https://www.espn.com/espn/rss/news"),
        (.sports, "https://feeds.bbci.co.uk/sport/rss.xml?edition=uk"),
        (.sports, "https://www.skysports.com/rss/12040"),
        (.sports, "https://www.si.com/rss/si_topstories.rss"),
        (.sports, "https://www.reuters.com/sports/rss"),

        // 财经
        (.finance, "https://feeds.a.dj.com/rss/RSSMarketsMain.xml"),
        (.finance, "https://www.ft.com/?format=rss"),
        (.finance, "https://www.cnbc.com/id/100003114/device/rss/rss.html"),
        (.finance, "https://finance.yahoo.com/news/rssindex"),
        (.finance, "https://www.bloomberg.com/feeds/podcasts/etf-report.xml")
    ]

    /// 拉取默认源
    static func ingestDefault(limitPerFeed: Int = 3) async -> [FeedItem] {
        var result: [FeedItem] = []
        for (cat, urlStr) in defaultFeeds {
            guard let url = URL(string: urlStr) else { continue }
            do {
                let items = try await ingestRSS(from: url, as: cat, limit: limitPerFeed)
                result.append(contentsOf: items)
            } catch {
                #if DEBUG
                print("RSS ingest failed:", urlStr, error.localizedDescription)
                #endif
            }
        }
        // 去重（按 link）
        var seen = Set<String>()
        result = result.filter {
            let key = $0.sourceURL?.absoluteString ?? UUID().uuidString
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        return result
    }

    /// 极简 RSS/Atom 解析（title/link/description）
    static func ingestRSS(from feedURL: URL, as category: FeedCategory, limit: Int) async throws -> [FeedItem] {
        let (data, _) = try await URLSession.shared.data(from: feedURL)
        guard let xml = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return []
        }

        let itemsBlocks: [String]
        if xml.contains("<item>") {
            // RSS
            itemsBlocks = _allMatches(xml, pattern: "(?is)<item>(.*?)</item>")
        } else {
            // Atom
            itemsBlocks = _allMatches(xml, pattern: "(?is)<entry>(.*?)</entry>")
        }

        let picked = itemsBlocks.prefix(limit)
        let now = Date()

        return picked.compactMap { block in
            let title = _guessTitle(block)
            let linkStr = _guessLink(block)
            let desc = _guessDescription(block)
            let link = linkStr.flatMap { URL(string: $0) }
            guard link != nil else { return nil }
            return FeedItem(
                title: title ?? "未命名",
                body: desc ?? "",
                date: now,
                tags: [],
                category: category,
                sourceURL: link,
                imageURL: nil,
                sourceTitle: nil,
                sourceDescription: nil,
                sourceDomain: link?.host?.lowercased().replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression),
                lastImageRefresh: nil
            )
        }
    }
}

//
// MARK: - 文件级自由函数（非 actor 隔离，避免 MainActor 警告）
//

fileprivate func _first(_ s: String, _ pattern: String) -> String? {
    guard let r = try? NSRegularExpression(pattern: pattern) else { return nil }
    let ns = s as NSString
    return r.firstMatch(in: s, range: NSRange(location: 0, length: ns.length))
        .flatMap { $0.numberOfRanges >= 2 ? ns.substring(with: $0.range(at: 1)) : nil }
}

fileprivate func _allMatches(_ s: String, pattern: String) -> [String] {
    guard let r = try? NSRegularExpression(pattern: pattern) else { return [] }
    let ns = s as NSString
    return r.matches(in: s, range: NSRange(location: 0, length: ns.length))
        .map { ns.substring(with: $0.range(at: 1)) }
}

fileprivate func _stripTags(_ html: String) -> String {
    var t = html.replacingOccurrences(of: "(?is)<script[^>]*>.*?</script>", with: "", options: .regularExpression)
    t = t.replacingOccurrences(of: "(?is)<style[^>]*>.*?</style>", with: "", options: .regularExpression)
    t = t.replacingOccurrences(of: "(?is)<[^>]+>", with: "", options: .regularExpression)
    return t
}

fileprivate func _decodeEntities(_ s: String?) -> String? {
    guard var t = s else { return nil }
    let map = ["&amp;":"&","&lt;":"<","&gt;":">","&quot;":"\"","&#39;":"'"]
    map.forEach { t = t.replacingOccurrences(of: $0.key, with: $0.value) }
    return t
}

fileprivate func _guessTitle(_ block: String) -> String? {
    _decodeEntities(_first(block, "(?is)<title.*?>(.*?)</title>")).map(_stripTags)
}

fileprivate func _guessLink(_ block: String) -> String? {
    if let l = _first(block, "(?is)<link.*?>(.*?)</link>") { return _decodeEntities(_stripTags(l)) }
    if let href = _first(block, "(?is)<link[^>]*href=['\"](.*?)['\"][^>]*>") { return _decodeEntities(href) }
    return nil
}

fileprivate func _guessDescription(_ block: String) -> String? {
    _decodeEntities(
        _stripTags(
            _first(block, "(?is)<description.*?>(.*?)</description>")
            ?? _first(block, "(?is)<summary.*?>(.*?)</summary>")
            ?? ""
        )
    )
}
