//
//  PersonalFeedAppTests.swift
//  PersonalFeedAppTests
//
//  Created by francis on 9/18/25.
//

import XCTest
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
}
