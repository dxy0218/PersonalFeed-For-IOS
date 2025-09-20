import Foundation
import Combine

/// 快捷菜单路由
enum AppShortcutRoute: Equatable {
    case settings
    case newItem
    case category(String) // "headline" / "news" / "projects" / "ideas" / "media"
}

/// 全局路由器（EnvironmentObject 注入到视图树）
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    private init() {}

    @Published var pendingRoute: AppShortcutRoute? = nil

    /// 解析 UIApplicationShortcutItem.type / userInfo -> 路由
    /// 约定：<bundle>.shortcut.settings / .new / .category.<raw>
    func route(fromShortcutType type: String,
               userInfo: [String : NSSecureCoding]?) -> AppShortcutRoute? {
        let parts = type.split(separator: ".").map(String.init)
        guard let last = parts.last else { return nil }

        if last == "settings" { return .settings }
        if last == "new"      { return .newItem }

        if parts.count >= 2, parts[parts.count - 2] == "category" {
            // 兼容 userInfo 或直接拼在 type 末尾的两种方式
            if let raw = userInfo?["category"] as? NSString {
                return .category(raw as String)
            }
            return .category(last)
        }
        return nil
    }
}
