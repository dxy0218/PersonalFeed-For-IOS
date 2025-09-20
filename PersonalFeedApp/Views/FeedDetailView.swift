import SwiftUI

struct FeedDetailView: View {
    let item: FeedItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingShare = false
    @State private var showTranslated = true
    @State private var isTranslating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = item.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: ZStack { Rectangle().fill(Color.gray.opacity(0.15)); ProgressView() }
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: placeholder
                        @unknown default: placeholder
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 220).clipped().cornerRadius(12)
                }

                Text(currentTitle)
                    .font(.title2.weight(.semibold))

                if let desc = currentBody {
                    Text(desc).font(.body).foregroundStyle(.secondary).lineSpacing(3)
                }

                HStack(spacing: 12) {
                    Label(formatDate(item.date), systemImage: "calendar")
                        .font(.caption).foregroundStyle(.secondary)
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
                        Label("\(item.viewCount)", systemImage: "eye").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showTranslated.toggle()
                    } label: {
                        Label(showTranslated ? "显示原文" : "显示译文",
                              systemImage: showTranslated ? "textformat" : "character.book.closed")
                    }

                    Button {
                        Task {
                            isTranslating = true
                            await translateInApp()
                            isTranslating = false
                            showTranslated = true
                        }
                    } label: {
                        Label("站内翻译到 \(TranslationService.sharedTargetLangUpper())",
                              systemImage: "character.book.closed")
                    }
                    .disabled(isTranslating || !TranslationService.supportsInApp())

                    Button {
                        let full = (item.title.isEmpty ? (item.sourceTitle ?? "") : item.title) + "\n\n" +
                                   ((item.body.isEmpty ? (item.sourceDescription ?? "") : item.body))
                        TranslationService.shared.openSystemTranslate(text: full, from: nil)   // ✅ 直接调用
                    } label: {
                        Label("系统翻译（Safari）", systemImage: "safari")
                    }

                } label: { Image(systemName: isTranslating ? "ellipsis" : "character.book.closed") }

                if item.sourceURL != nil {
                    Button { showingShare = true } label: { Image(systemName: "square.and.arrow.up") }
                        .sheet(isPresented: $showingShare) {
                            if let url = item.sourceURL { ActivityView(activityItems: [url]) }
                        }
                }
            }
        }
    }

    // MARK: - 翻译逻辑
    private func translateInApp() async {
        var srcTitle = item.title.isEmpty ? (item.sourceTitle ?? "") : item.title
        var srcBody  = item.body.isEmpty ? (item.sourceDescription ?? "") : item.body

        srcTitle = srcTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        srcBody  = srcBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !(srcTitle.isEmpty && srcBody.isEmpty) else { return }

        do {
            var dict = item.translations ?? [:]
            if !srcTitle.isEmpty {
                let t = try await TranslationService.shared.translate(text: srcTitle)
                dict["title:\(TranslationService.sharedTargetLang())"] = t
            }
            if !srcBody.isEmpty {
                let t = try await TranslationService.shared.translate(text: srcBody)
                dict["body:\(TranslationService.sharedTargetLang())"] = t
            }
            // 写回磁盘
            var all = (try? LocalStorage.shared.load()) ?? []
            if let idx = all.firstIndex(where: { $0.id == item.id }) {
                all[idx].translations = dict
                try? LocalStorage.shared.save(all)
            }
        } catch {
            #if DEBUG
            print("translate failed:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - 展示文案（优先显示已缓存译文）
    private var currentTitle: String {
        if showTranslated, let t = TranslationService.readCached(for: item, key: "title") { return t }
        return item.title.isEmpty ? (item.sourceTitle ?? "未命名") : item.title
    }
    private var currentBody: String? {
        if showTranslated, let t = TranslationService.readCached(for: item, key: "body") { return t }
        let raw = item.body.isEmpty ? item.sourceDescription : item.body
        let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (s?.isEmpty == false) ? s : nil
    }

    // MARK: - Utils
    private var placeholder: some View {
        ZStack { Rectangle().fill(Color.gray.opacity(0.12)); Image(systemName: "photo").font(.system(size: 24)).foregroundStyle(.secondary) }
    }
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
        return df.string(from: date)
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

// UIKit 分享控制器
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
