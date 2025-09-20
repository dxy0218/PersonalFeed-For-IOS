import SwiftUI

@main
struct PersonalFeedAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var router = AppRouter.shared   // 注入全局路由器

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
