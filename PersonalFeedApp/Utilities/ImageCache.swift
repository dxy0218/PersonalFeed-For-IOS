import Foundation

/// 简单磁盘图片缓存，供设置页统计/清理使用
actor ImageCache {
    static let shared = ImageCache()

    private let fm = FileManager.default
    private let folder: URL

    init() {
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        folder = caches.appendingPathComponent("Images", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    /// 当前缓存体积（字节）
    func cacheSizeBytes() async -> Int {
        var total = 0
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles) else {
            return 0
        }
        for url in files {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += size // data.count 本就非可选，不需要 ??
            }
        }
        return total
    }

    /// 清空全部缓存
    func clearAll() async {
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return }
        for url in files { try? fm.removeItem(at: url) }
    }

    /// 清理早于 N 天或超出最大 MB 的文件
    func prune(olderThanDays days: Int, maxBytesMB: Int) async {
        let now = Date()
        let threshold = now.addingTimeInterval(-Double(days) * 24 * 3600)
        var entries: [(url: URL, size: Int, date: Date)] = []

        if let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) {
            for url in files {
                let rv = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let size = rv?.fileSize ?? 0
                let date = rv?.contentModificationDate ?? now
                entries.append((url, size, date))
            }
        }

        // 先删过期
        for e in entries where e.date < threshold { try? fm.removeItem(at: e.url) }

        // 再控总量
        var left = await cacheSizeBytes()
        let limit = maxBytesMB * 1024 * 1024
        if left > limit {
            // 从最旧开始删
            let sorted = entries.sorted { $0.date < $1.date }
            for e in sorted {
                if left <= limit { break }
                if fm.fileExists(atPath: e.url.path) {
                    try? fm.removeItem(at: e.url)
                    left -= e.size
                }
            }
        }
    }
}
