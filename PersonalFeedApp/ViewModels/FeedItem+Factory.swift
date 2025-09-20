import Foundation

extension FeedItem {
    /// 创建一个用于编辑界面的空白条目。
    static func makeEmpty(
        category: FeedCategory = .news,
        date: Date = Date()
    ) -> FeedItem {
        FeedItem(
            title: "",
            body: "",
            date: date,
            tags: [],
            category: category
        )
    }
}
