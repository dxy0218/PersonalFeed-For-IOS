//
//  PersonalFeedAppTests.swift
//  PersonalFeedAppTests
//
//  Created by francis on 9/18/25.
//

import XCTest
import UIKit
@testable import PersonalFeedApp

final class PersonalFeedAppTests: XCTestCase {

    func testShortcutRouteParsing() {
        let router = AppRouter.shared
        XCTAssertEqual(router.route(fromShortcutType: "com.example.shortcut.settings", userInfo: nil), .settings)
        XCTAssertEqual(router.route(fromShortcutType: "com.example.shortcut.new", userInfo: nil), .newItem)
        XCTAssertEqual(
            router.route(
                fromShortcutType: "com.example.shortcut.category.news",
                userInfo: ["category": "news" as NSString]
            ),
            .category("news")
        )
        XCTAssertEqual(
            router.route(fromShortcutType: "com.example.shortcut.category.projects", userInfo: nil),
            .category("projects")
        )
    }

    func testViewModelSaveInsertsAndUpdates() {
        try? LocalStorage.shared.save([])
        let vm = FeedViewModel()
        defer { try? LocalStorage.shared.save([]) }

        let first = FeedItem(
            title: "First",
            body: "",
            date: Date(),
            tags: [],
            category: .news
        )
        vm.save(first)
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.id, first.id)

        var second = FeedItem(
            title: "Second",
            body: "",
            date: Date(),
            tags: [],
            category: .news
        )
        vm.save(second)
        XCTAssertEqual(vm.items.count, 2)
        XCTAssertEqual(vm.items.first?.id, second.id)
        XCTAssertEqual(vm.items.last?.id, first.id)

        second.title = "Updated"
        vm.save(second)
        XCTAssertEqual(vm.items.count, 2)
        XCTAssertEqual(vm.items.first?.title, "Updated")
    }

    func testSaveNormalizesSourceDomain() {
        try? LocalStorage.shared.save([])
        let vm = FeedViewModel()
        defer { try? LocalStorage.shared.save([]) }

        var item = FeedItem(
            title: "Link",
            body: "",
            date: Date(),
            tags: [],
            category: .news,
            sourceURL: URL(string: "https://www.Example.com/path")!,
            imageURL: URL(string: "https://example.com/image.png"),
            lastImageRefresh: Date()
        )
        vm.save(item)

        XCTAssertEqual(vm.items.first?.sourceDomain, "example.com")
    }

    func testApplyingContentAddsParagraphs() async {
        try? LocalStorage.shared.save([])
        let vm = FeedViewModel()
        defer { try? LocalStorage.shared.save([]) }

        let item = FeedItem(
            title: "",
            body: "",
            date: Date(),
            tags: [],
            category: .news
        )
        vm.save(item)

        let content = ArticleContent(
            title: "Remote title",
            summary: "A concise summary",
            imageURL: nil,
            paragraphs: ["First paragraph with enough detail to display", "Second paragraph providing more context"]
        )

        await MainActor.run {
            vm.applyContent(content, for: item.id)
        }

        guard let updated = vm.items.first(where: { $0.id == item.id }) else {
            return XCTFail("Item should exist")
        }

        XCTAssertEqual(updated.body, "A concise summary")
        XCTAssertEqual(updated.extractedParagraphs?.count, 2)

        // 后续抓取若不包含段落，不应该覆盖已有内容。
        let fallback = ArticleContent(title: nil, summary: nil, imageURL: nil, paragraphs: [])
        await MainActor.run {
            vm.applyContent(fallback, for: item.id)
        }
        let finalItem = vm.items.first(where: { $0.id == item.id })
        XCTAssertEqual(finalItem?.extractedParagraphs?.count, 2)
    }

    func testImageDiskCacheDownsamplesAndPrunes() {
        let cache = ImageDiskCache.shared
        cache.clear()
        defer { cache.clear() }

        let largeData = makeSolidImageData(size: CGSize(width: 1800, height: 1800))
        let secondData = makeSolidImageData(size: CGSize(width: 1200, height: 1200), color: .blue)
        let urlA = URL(string: "https://example.com/a.png")!
        let urlB = URL(string: "https://example.com/b.png")!

        cache.store(data: largeData, for: urlA, targetHeight: 220)
        cache.store(data: secondData, for: urlB, targetHeight: 64)

        XCTAssertNotNil(cache.image(for: urlA))
        XCTAssertNotNil(cache.image(for: urlB))

        let beforePrune = cache.cacheSize()
        XCTAssertLessThan(beforePrune, largeData.count + secondData.count)

        cache.pruneToSize(maxBytes: 500_000)
        XCTAssertLessThanOrEqual(cache.cacheSize(), 500_000)
    }

    func testDefaultFeedCatalogIntegrity() {
        // 每个分类至少应包含 20 个源。
        let grouped = Dictionary(grouping: FeedIngestor.defaultFeeds, by: { $0.0 })
        FeedCategory.allCases.forEach { category in
            let count = grouped[category]?.count ?? 0
            XCTAssertGreaterThanOrEqual(
                count,
                20,
                "Category \(category.rawValue) should have at least 20 feeds"
            )
        }

        // URL 必须合法且不能重复。
        let invalidFeeds = FeedIngestor.defaultFeeds.filter { URL(string: $0.1) == nil }
        XCTAssertTrue(invalidFeeds.isEmpty, "Default catalog should not contain invalid URLs")

        let duplicateFeeds = Dictionary(grouping: FeedIngestor.defaultFeeds, by: { $0.1.lowercased() })
            .filter { $0.value.count > 1 }
        XCTAssertTrue(duplicateFeeds.isEmpty, "Default catalog should not contain duplicate URLs")
    }

    private func makeSolidImageData(size: CGSize, color: UIColor = .red) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let data = renderer.jpegData(withCompressionQuality: 1.0) { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return data
    }
}
