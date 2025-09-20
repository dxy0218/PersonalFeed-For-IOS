import SwiftUI

struct FeedDetailView: View {
    let item: FeedItem
    @State private var showingShare = false
    @State private var showTranslated = true
    @State private var isTranslating = false
    @State private var showMoreContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let url = item.imageURL {
                    AsyncCachedImage(url: url, contentMode: .fill, height: 240)
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 0.6))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text(currentTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .lineSpacing(4)

                    if let desc = currentBody {
                        Text(desc)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineSpacing(5)
                    }

                    if let paragraphs = detailedParagraphs, !paragraphs.isEmpty {
                        Divider()
                            .padding(.vertical, 6)

                        DisclosureGroup(isExpanded: $showMoreContent) {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                                    Text(para)
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineSpacing(5)
                                }
                            }
                            .padding(.top, 10)
                        } label: {
                            Label(showMoreContent ? "收起更多内容" : "展开更多内容", systemImage: showMoreContent ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        .tint(.primary)
                    }

                    HStack(spacing: 14) {
                        Label(formatDate(item.date), systemImage: "calendar")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        if let domain = item.sourceDomain, !domain.isEmpty {
                            Label(domain, systemImage: "globe")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Text(displayName(of: item.category))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
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
                .padding(.vertical, 24)
                .padding(.horizontal, 22)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 0.6)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 26)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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

    private var detailedParagraphs: [String]? {
        item.extractedParagraphs?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
