import SwiftUI

struct FeedRowView: View {
    let item: FeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let url = item.imageURL {
                    AsyncCachedImage(url: url, height: 72)
                        .transition(.opacity)
                } else {
                    placeholder
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title.isEmpty ? (item.sourceTitle ?? "未命名") : item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(3)
                    .lineSpacing(3)

                if let desc = nonEmpty(item.body.isEmpty ? item.sourceDescription : item.body) {
                    Text(desc)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .lineSpacing(3)
                }

                HStack(spacing: 10) {
                    if let domain = item.sourceDomain, !domain.isEmpty {
                        Label(domain, systemImage: "globe")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Text(displayName(of: item.category))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.16))
                        .clipShape(Capsule())
                    Spacer(minLength: 0)
                    if item.viewCount > 0 {
                        Label("\(item.viewCount)", systemImage: "eye")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.1))
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    private func displayName(of c: FeedCategory) -> String {
        switch c {
        case .headline: return "头条"
        case .news:     return "新闻"
        case .projects: return "项目"
        case .ideas:    return "灵感"
        case .media:    return "媒体"
        case .science:  return "科学"
        case .sports:   return "体育"
        case .finance:  return "财经"
        }
    }
}

