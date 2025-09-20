import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    private func installDynamicShortcuts() {
        let bundle = Bundle.main.bundleIdentifier ?? "com.example.personalfeed"
        let settingsItem = UIApplicationShortcutItem(
            type: "\(bundle).shortcut.settings",
            localizedTitle: "设置",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: "gearshape"),
            userInfo: nil
        )
        let newItem = UIApplicationShortcutItem(
            type: "\(bundle).shortcut.new",
            localizedTitle: "新建条目",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: "plus.rectangle.on.rectangle"),
            userInfo: nil
        )
        let catHeadline = UIApplicationShortcutItem(
            type: "\(bundle).shortcut.category.headline",
            localizedTitle: "分类：头条",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: "square.grid.2x2"),
            userInfo: ["category": "headline" as NSString]
        )
        let catNews = UIApplicationShortcutItem(
            type: "\(bundle).shortcut.category.news",
            localizedTitle: "分类：新闻",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: "square.grid.2x2"),
            userInfo: ["category": "news" as NSString]
        )
        let catProjects = UIApplicationShortcutItem(
            type: "\(bundle).shortcut.category.projects",
            localizedTitle: "分类：项目",
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: "square.grid.2x2"),
            userInfo: ["category": "projects" as NSString]
        )
        UIApplication.shared.shortcutItems = [settingsItem, newItem, catHeadline, catNews, catProjects]
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        installDynamicShortcuts()
        // 启动即请求刷新
        NotificationCenter.default.post(name: AppEvents.refreshRequested, object: nil)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        installDynamicShortcuts()
        // 回到前台自动刷新
        NotificationCenter.default.post(name: AppEvents.refreshRequested, object: nil)
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let router = AppRouter.shared
        let route = router.route(fromShortcutType: shortcutItem.type, userInfo: shortcutItem.userInfo)
        router.pendingRoute = route
        completionHandler(route != nil)
    }
}
