import Foundation

/// 从主流媒体 RSS/Atom 拉取最新条目，转为 FeedItem（含分类）
enum FeedIngestor {

    /// 默认订阅清单：涵盖主流、小众与争议媒体，每类不少于 20 个
    static let defaultFeeds: [(FeedCategory, String)] = {
        newsFeeds
        + headlineFeeds
        + projectFeeds
        + ideaFeeds
        + mediaFeeds
        + scienceFeeds
        + sportsFeeds
        + financeFeeds
    }()

    private static let newsFeeds = feedList(.news, [
        "https://feeds.bbci.co.uk/news/rss.xml",
        "https://rss.cnn.com/rss/edition.rss",
        "https://www.reuters.com/world/rss",
        "https://www.theguardian.com/world/rss",
        "https://apnews.com/hub/ap-top-news?utm_source=apnews.com&utm_medium=referral&utm_campaign=aprss",
        "https://www.aljazeera.com/xml/rss/all.xml",
        "https://rss.nytimes.com/services/xml/rss/nyt/World.xml",
        "https://feeds.washingtonpost.com/rss/world",
        "https://www.latimes.com/world-nation/rss2.0.xml",
        "https://www.usatoday.com/news/rss/",
        "https://www.politico.com/rss/politics-news.xml",
        "https://theintercept.com/feed/?lang=en",
        "https://www.rt.com/rss/news/",
        "https://www.npr.org/rss/rss.php?id=1004",
        "https://www.csmonitor.com/rss/world",
        "https://time.com/feed/",
        "https://www.economist.com/the-world-this-week/rss.xml",
        "https://www.japantimes.co.jp/feed/",
        "https://www.lemonde.fr/rss/une.xml",
        "https://globalnews.ca/feed/"
    ])

    private static let headlineFeeds = feedList(.headline, [
        "https://www.theverge.com/rss/index.xml",
        "https://techcrunch.com/feed/",
        "https://www.wired.com/feed/rss",
        "https://www.engadget.com/rss.xml",
        "https://arstechnica.com/feed/",
        "https://www.cnet.com/rss/news/",
        "https://www.digitaltrends.com/feed/",
        "https://www.androidauthority.com/feed/",
        "https://9to5mac.com/feed/",
        "https://www.macrumors.com/macrumors.xml",
        "https://rss.slashdot.org/Slashdot/slashdotMain",
        "https://www.xda-developers.com/feed/",
        "https://www.tomshardware.com/feeds/all",
        "https://www.pcgamer.com/rss/",
        "https://www.gamespot.com/feeds/game-news/",
        "https://www.gsmarena.com/rss-news-reviews.php",
        "https://www.techradar.com/rss",
        "https://www.zdnet.com/news/rss.xml",
        "https://www.vice.com/en/rss",
        "https://www.bleepingcomputer.com/feed/"
    ])

    private static let projectFeeds = feedList(.projects, [
        "https://github.blog/changelog/feed/",
        "https://news.ycombinator.com/rss",
        "https://www.producthunt.com/feed",
        "https://stackoverflow.blog/feed/",
        "https://aws.amazon.com/about-aws/whats-new/recent/feed/",
        "https://about.gitlab.com/blog/feed/",
        "https://medium.com/feed/tag/startups",
        "https://www.indiehackers.com/feed",
        "https://dev.to/feed",
        "https://hnrss.org/frontpage",
        "https://www.infoq.com/feed/",
        "https://www.smashingmagazine.com/feed/",
        "https://www.mongodb.com/blog/feed",
        "https://www.docker.com/blog/feed/",
        "https://blog.cloudflare.com/rss/",
        "https://stripe.com/blog/feed.rss",
        "https://slack.engineering/feed/",
        "https://dropbox.tech/feed",
        "https://www.atlassian.com/blog/feed",
        "https://kubernetes.io/feed.xml"
    ])

    private static let ideaFeeds = feedList(.ideas, [
        "https://www.themarginalian.org/feed/",
        "https://aeon.co/feed.rss",
        "https://nautil.us/feed/",
        "https://seths.blog/feed",
        "https://fs.blog/feed/",
        "https://waitbutwhy.com/feed",
        "https://www.lesswrong.com/feed.xml",
        "https://www.ribbonfarm.com/feed/",
        "https://www.gatesnotes.com/rss",
        "https://psyche.co/feed.rss",
        "https://noahpinion.substack.com/feed",
        "https://astralcodexten.substack.com/feed",
        "https://www.edge.org/feed",
        "https://jamesclear.com/feed",
        "https://www.slowboring.com/feed",
        "https://www.freethink.com/feed",
        "https://worksinprogress.co/feed",
        "https://theconversation.com/articles.atom",
        "https://nesslabs.com/feed",
        "https://www.lrb.co.uk/feeds/posts"
    ])

    private static let mediaFeeds = feedList(.media, [
        "https://www.theatlantic.com/feed/all/",
        "https://variety.com/feed/",
        "https://www.newyorker.com/feed/everything",
        "https://www.vulture.com/rss/index.xml",
        "https://www.rollingstone.com/music/music-news/feed/",
        "https://pitchfork.com/feed/feed-news/rss",
        "https://www.billboard.com/feed/",
        "https://www.hollywoodreporter.com/t/hollywood-reporter-news/feed/",
        "https://decider.com/feed/",
        "https://consequence.net/feed/",
        "https://www.npr.org/rss/rss.php?id=1008",
        "https://www.slate.com/feed",
        "https://www.avclub.com/rss",
        "https://www.polygon.com/rss/index.xml",
        "https://www.gamesradar.com/feeds/all",
        "https://www.rollingstone.com/culture/culture-news/feed/",
        "https://www.pastemagazine.com/.rss/full/",
        "https://www.denofgeek.com/feed/",
        "https://www.vox.com/rss/index.xml",
        "https://www.dailywire.com/feeds/latest"
    ])

    private static let scienceFeeds = feedList(.science, [
        "https://www.nature.com/nature.rss",
        "https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=science",
        "https://www.nasa.gov/rss/dyn/breaking_news.rss",
        "https://www.cell.com/atom/rss",
        "https://www.quantamagazine.org/feed/",
        "https://www.sciencedaily.com/rss/top/science.xml",
        "https://www.newscientist.com/feed/home/",
        "https://www.livescience.com/home/feed/site.xml",
        "https://www.scientificamerican.com/feed/",
        "https://www.space.com/feeds/all",
        "https://www.popsci.com/feed/",
        "https://www.smithsonianmag.com/rss/science-nature/",
        "https://www.eurekalert.org/rss.xml",
        "https://www.nature.com/subjects/environmental-sciences.rss",
        "https://www.nih.gov/news-events/news-releases/feed",
        "https://www.sciencenews.org/feed",
        "https://www.symmetrymagazine.org/feed",
        "https://www.chemistryworld.com/rss",
        "https://www.azocleantech.com/xml/news.xml",
        "https://www.jpl.nasa.gov/feeds/news"
    ])

    private static let sportsFeeds = feedList(.sports, [
        "https://www.espn.com/espn/rss/news",
        "https://feeds.bbci.co.uk/sport/rss.xml?edition=uk",
        "https://www.skysports.com/rss/12040",
        "https://www.si.com/rss/si_topstories.rss",
        "https://www.reuters.com/sports/rss",
        "https://bleacherreport.com/articles?format=atom",
        "https://www.cbssports.com/rss/headlines/",
        "https://sports.yahoo.com/rss/",
        "https://www.nbcsports.com/rss",
        "https://www.nhl.com/rss/news",
        "https://www.nba.com/news/feed",
        "https://www.mlb.com/news/feeds/rss.xml",
        "https://www.fifa.com/rss-feeds/news",
        "https://www.formula1.com/rss/news/all",
        "https://www.motogp.com/en/rss",
        "https://www.uefa.com/rssfeed/uefacom-overview-news/",
        "https://www.goal.com/feeds/en/news",
        "https://cyclingtips.com/feed/",
        "https://www.runnersworld.com/rss/all.xml",
        "https://www.espn.com/espn/rss/nfl/news"
    ])

    private static let financeFeeds = feedList(.finance, [
        "https://feeds.a.dj.com/rss/RSSMarketsMain.xml",
        "https://www.ft.com/?format=rss",
        "https://www.cnbc.com/id/100003114/device/rss/rss.html",
        "https://finance.yahoo.com/news/rssindex",
        "https://www.bloomberg.com/feeds/podcasts/etf-report.xml",
        "https://www.marketwatch.com/feeds/topstories",
        "https://seekingalpha.com/market_currents.xml",
        "https://www.investopedia.com/feedbuilder/feed/getfeed/?feedName=rss_headline",
        "https://www.benzinga.com/feed",
        "https://cointelegraph.com/rss",
        "https://www.coindesk.com/arc/outboundfeeds/rss/",
        "https://www.fool.com/feeds/index.aspx",
        "https://www.kitco.com/rss/news/",
        "https://www.zerohedge.com/feed",
        "https://www.theblock.co/rss.xml",
        "https://www.businesstimes.com.sg/feeds/latest",
        "https://asia.nikkei.com/rss/feed/nar",
        "https://www.handelsblatt.com/contentexport/feed/schlagzeilen",
        "https://hbr.org/feed",
        "https://www.pehub.com/feed/"
    ])

    private static func feedList(_ category: FeedCategory, _ urls: [String]) -> [(FeedCategory, String)] {
        urls.map { (category, $0) }
    }

    /// 拉取默认源
    static func ingestDefault(limitPerFeed: Int = 3, progress: ((Int, Int) -> Void)? = nil) async -> [FeedItem] {
        var result: [FeedItem] = []
        let total = defaultFeeds.count
        progress?(0, total)
        var finished = 0
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
            finished += 1
            progress?(finished, total)
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
