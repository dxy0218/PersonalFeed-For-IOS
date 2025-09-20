import Foundation
import Combine

final class FeedViewModel: ObservableObject {
    @Published private(set) var items: [FeedItem] = []
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortNewestFirst: Bool = true
    @Published var selectedCategory: FeedCategory? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 1) 加载本地
        let loaded = (try? LocalStorage.shared.load()) ?? []
        self.items = loaded

        // 2) 持久化
        $items
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { items in try? LocalStorage.shared.save(items) }
            .store(in: &cancellables)

        // 3) 网络恢复自动刷新
        NetworkMonitor.shared.$isOnline
            .removeDuplicates()
            .sink { [weak self] online in
                guard online else { return }
                Task { await self?.refreshAll() }
            }
            .store(in: &cancellables)

        // 4) 前台/启动自动刷新
        NotificationCenter.default.publisher(for: AppEvents.refreshRequested)
            .sink { [weak self] _ in
                Task { await self?.refreshAll() }
            }
            .store(in: &cancellables)
    }

    // MARK: CRUD
    func add(_ item: FeedItem) {
        var it = item
        if it.sourceDomain == nil, let host = it.sourceURL?.host?.lowercased() {
            it.sourceDomain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }
        items.insert(it, at: 0)
        Task.detached { [weak self] in await self?.refreshPreviewIfNeeded(for: it.id) }
    }

    func update(_ item: FeedItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        var it = item
        if it.sourceDomain == nil, let host = it.sourceURL?.host?.lowercased() {
            it.sourceDomain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }
        items[idx] = it
        Task.detached { [weak self] in await self?.refreshPreviewIfNeeded(for: it.id) }
    }

    func delete(_ item: FeedItem) { items.removeAll { $0.id == item.id } }

    // MARK: 排序/过滤
    private var rankedItems: [FeedItem] {
        items.sorted { a, b in
            let sa = RankingEngine.score(for: a)
            let sb = RankingEngine.score(for: b)
            if abs(sa - sb) > 0.0001 { return sa > sb }
            return a.date > b.date
        }
    }

    var filteredItems: [FeedItem] {
        var list = rankedItems
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if !searchText.isEmpty {
            let t = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(t)
                || $0.body.lowercased().contains(t)
                || $0.tags.joined(separator: " ").lowercased().contains(t)
                || ($0.sourceTitle?.lowercased().contains(t) ?? false)
                || ($0.sourceDescription?.lowercased().contains(t) ?? false)
            }
        }
        if !selectedTags.isEmpty { list = list.filter { !Set($0.tags).isDisjoint(with: selectedTags) } }
        return list
    }

    var allTags: [String] { Array(Set(items.flatMap { $0.tags })).sorted() }

    // MARK: 刷新
    @MainActor func refreshOnLaunch() async { await refreshAll() }

    @MainActor func refreshAll() async {
        guard NetworkMonitor.shared.isOnline else { return }
        await refreshMissingPreviews()
    }

    @MainActor
    private func applyContent(_ content: ArticleContent?, for id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        if let c = content {
            if items[idx].imageURL == nil   { items[idx].imageURL = c.imageURL }
            if items[idx].sourceTitle == nil { items[idx].sourceTitle = c.title }
            if (items[idx].body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
               let summary = c.summary, !summary.isEmpty {
                items[idx].body = summary
            } else if items[idx].sourceDescription == nil {
                items[idx].sourceDescription = c.summary
            }
        }
        items[idx].lastImageRefresh = Date()
    }

    private func shouldRefresh(_ item: FeedItem) -> Bool {
        guard item.sourceURL != nil else { return false }
        if item.imageURL == nil { return true }
        if let last = item.lastImageRefresh {
            return Date().timeIntervalSince(last) > 60 * 60 * 24
        }
        return true
    }

    func refreshMissingPreviews() async {
        for it in items where shouldRefresh(it) {
            await refreshPreviewIfNeeded(for: it.id)
        }
    }

    /// 抓取受 DomainPolicy 约束；失败也会记 lastImageRefresh
    func refreshPreviewIfNeeded(for id: UUID) async {
        guard let item = items.first(where: { $0.id == id }),
              let page = item.sourceURL,
              shouldRefresh(item) else { return }

        if DomainPolicy.shared.permit(url: page) == false {
            await MainActor.run { self.applyContent(nil, for: id) }
            return
        }

        do {
            let content = try await ContentFetcher.fetch(for: page)
            await MainActor.run { self.applyContent(content, for: id) }
        } catch {
            #if DEBUG
            print("❌ Content fetch failed:", error.localizedDescription)
            #endif
            await MainActor.run { self.applyContent(nil, for: id) }
        }
    }

    // MARK: - 一键替换为默认源（RSS）
    @MainActor func replaceWithDefaultSources(limitPerFeed: Int = 3) async {
        let fetched = await FeedIngestor.ingestDefault(limitPerFeed: limitPerFeed)
        self.items = fetched
        await refreshMissingPreviews()
    }
}

// MARK: - 翻译相关
extension FeedViewModel {

    /// 翻译指定条目的标题与正文；翻译结果写入 item.translations 并持久化。
    @MainActor
    func translateItem(_ id: UUID, targetLang: String? = nil) async {
        let lang = targetLang ?? TranslationService.shared.targetLang
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let srcTitle = items[idx].title.isEmpty ? (items[idx].sourceTitle ?? "") : items[idx].title
        let srcBody  = items[idx].body.isEmpty ? (items[idx].sourceDescription ?? "") : items[idx].body
        guard !(srcTitle.isEmpty && srcBody.isEmpty) else { return }

        do {
            var trans = items[idx].translations ?? [:]
            if !srcTitle.isEmpty {
                let t = try await TranslationService.shared.translate(text: srcTitle, to: lang)
                trans["title:\(lang)"] = t
            }
            if !srcBody.isEmpty {
                let t = try await TranslationService.shared.translate(text: srcBody, to: lang)
                trans["body:\(lang)"] = t
            }
            items[idx].translations = trans
            try? LocalStorage.shared.save(items)   // 落盘
        } catch {
            #if DEBUG
            print("Translate failed:", error.localizedDescription)
            #endif
        }
    }

    /// 从 item.translations 里取出译文
    func translatedText(for item: FeedItem, key: String, lang: String = TranslationService.shared.targetLang) -> String? {
        item.translations?["\(key):\(lang)"]
    }

    #if DEBUG
    /// 调试用：塞入一点示例数据
    @MainActor
    func injectDebugSeeds() {
        let demo = FeedItem(
            title: "示例：The Verge",
            body: "",
            date: Date(),
            tags: ["demo"],
            category: .news,
            sourceURL: URL(string: "https://www.theverge.com"),
            sourceTitle: "The Verge",
            sourceDescription: "用于测试抓取",
            sourceDomain: "theverge.com"
        )
        items.insert(demo, at: 0)
    }
    #endif
}
