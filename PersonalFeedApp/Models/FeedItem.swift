import Foundation

enum FeedCategory: String, Codable, CaseIterable, Identifiable {
    case headline, news, projects, ideas, media
    case science, sports, finance
    var id: String { rawValue }
}

struct FeedItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var date: Date
    var tags: [String]
    var category: FeedCategory

    var viewCount: Int = 0

    var sourceURL: URL?
    var imageURL: URL?
    var sourceTitle: String?
    var sourceDescription: String?
    var sourceDomain: String?
    var lastImageRefresh: Date?

    /// 译文缓存：key 形如 "title:zh" / "body:zh" / "title:en"
    var translations: [String: String]? = nil

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date,
        tags: [String],
        category: FeedCategory,
        viewCount: Int = 0,
        sourceURL: URL? = nil,
        imageURL: URL? = nil,
        sourceTitle: String? = nil,
        sourceDescription: String? = nil,
        sourceDomain: String? = nil,
        lastImageRefresh: Date? = nil,
        translations: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.tags = tags
        self.category = category
        self.viewCount = viewCount
        self.sourceURL = sourceURL
        self.imageURL = imageURL
        self.sourceTitle = sourceTitle
        self.sourceDescription = sourceDescription
        self.sourceDomain = sourceDomain
        self.lastImageRefresh = lastImageRefresh
        self.translations = translations
    }
}
