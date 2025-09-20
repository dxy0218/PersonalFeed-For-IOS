import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // iOS 26+ 推荐从这里拿快捷项
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcut = connectionOptions.shortcutItem {
            AppRouter.shared.pendingRoute = AppRouter.shared.route(fromShortcutType: shortcut.type, userInfo: shortcut.userInfo)
        }
    }

    // 热启动的快捷项
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let route = AppRouter.shared.route(fromShortcutType: shortcutItem.type, userInfo: shortcutItem.userInfo)
        AppRouter.shared.pendingRoute = route
        completionHandler(route != nil)
    }
}
