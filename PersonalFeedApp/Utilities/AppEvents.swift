import Foundation

enum AppEvents {
    /// 前台/启动/手动触发的统一刷新事件
    static let refreshRequested = Notification.Name("app.refreshRequested")
}
