import Foundation

extension FeedItem {
    /// 单个示例
    static let sample: FeedItem = FeedItem(
        title: "示例：The Verge",
        body: "用于测试联网抓取",
        date: Date(),
        tags: ["sample"],
        category: .headline,
        viewCount: 0,
        sourceURL: URL(string: "https://www.theverge.com"),
        imageURL: nil,
        sourceTitle: nil,
        sourceDescription: nil,
        sourceDomain: "theverge.com",
        lastImageRefresh: nil
    )

    /// 多个示例（用于列表预览）
    static let samples: [FeedItem] = [
        FeedItem(
            title: "BBC News",
            body: "Top stories",
            date: Date(),
            tags: ["world"],
            category: .news,
            viewCount: 0,
            sourceURL: URL(string: "https://www.bbc.com/news"),
            sourceDomain: "bbc.com"
        ),
        FeedItem(
            title: "Reuters",
            body: "Markets",
            date: Date().addingTimeInterval(-3600),
            tags: ["finance"],
            category: .news,
            viewCount: 0,
            sourceURL: URL(string: "https://www.reuters.com"),
            sourceDomain: "reuters.com"
        ),
        FeedItem.sample
    ]
}
