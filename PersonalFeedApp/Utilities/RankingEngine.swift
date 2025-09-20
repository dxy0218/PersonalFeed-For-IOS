import Foundation

/// 简单排序评分：综合【时效】+【热度(viewCount)】+【是否有图】+【类别权重】
enum RankingEngine {

    /// 计算条目得分（越大越靠前）
    static func score(for item: FeedItem) -> Double {
        // 1) 时效性（7 天半衰期）
        let ageHours = max(0.0, Date().timeIntervalSince(item.date) / 3600.0)
        let freshness = exp(-ageHours / (24.0 * 7.0))        // 0~1

        // 2) 热度（浏览次数，对数压缩）
        let hot = log2(Double(max(0, item.viewCount)) + 1.0) / 6.0  // ~0..1（viewCount≈63 时接近 1）

        // 3) 是否有图
        let hasImage = item.imageURL != nil ? 1.0 : 0.0

        // 4) 类别微调 —— 已补齐所有 case
        let cat: Double = {
            switch item.category {
            case .headline: return 1.00
            case .news:     return 0.95
            case .projects: return 0.90
            case .ideas:    return 0.85
            case .media:    return 0.90
            case .science:  return 0.92
            case .sports:   return 0.88
            case .finance:  return 0.93
            }
        }()

        // 权重可按需调
        let wFresh = 0.55
        let wHot   = 0.30
        let wImg   = 0.10
        let wCat   = 0.05

        let base = wFresh * freshness + wHot * hot + wImg * hasImage + wCat * cat
        return base
    }
}
