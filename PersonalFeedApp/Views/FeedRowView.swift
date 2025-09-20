import SwiftUI

struct FeedRowView: View {
    let item: FeedItem

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let url = item.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.15))
                                ProgressView()
                            }
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else { placeholder }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.05), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.isEmpty ? (item.sourceTitle ?? "未命名") : item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let desc = nonEmpty(item.body.isEmpty ? item.sourceDescription : item.body) {
                    Text(desc).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let domain = item.sourceDomain, !domain.isEmpty {
                        Label(domain, systemImage: "globe").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(displayName(of: item.category))
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Spacer(minLength: 0)
                    if item.viewCount > 0 {
                        Label("\(item.viewCount)", systemImage: "eye")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.12))
            Image(systemName: "photo").font(.system(size: 20)).foregroundStyle(.secondary)
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

