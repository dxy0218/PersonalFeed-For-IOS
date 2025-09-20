import SwiftUI

struct EditFeedView: View {
    @ObservedObject var vm: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editingItem: FeedItem
    @State private var urlText: String
    private let isNew: Bool

    init(vm: FeedViewModel, initialItem: FeedItem?) {
        self.vm = vm
        let seed = initialItem ?? FeedItem.makeEmpty()
        _editingItem = State(initialValue: seed)
        _urlText = State(initialValue: seed.sourceURL?.absoluteString ?? "")
        self.isNew = (initialItem == nil)
    }

    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("标题", text: binding(\.title))
                TextField("摘要（可选）", text: binding(\.body), axis: .vertical).lineLimit(3...6)
                DatePicker("日期", selection: binding(\.date), displayedComponents: [.date, .hourAndMinute])
                Picker("分类", selection: binding(\.category)) {
                    ForEach(FeedCategory.allCases) { c in
                        Text(displayName(of: c)).tag(c)
                    }
                }
            }
            Section(header: Text("信息源")) {
                TextField("网页链接（https://…）", text: $urlText)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Section(header: Text("标签（逗号分隔）")) {
                TextField("例如：AI, iOS, 阅读", text: Binding(
                    get: { editingItem.tags.joined(separator: ", ") },
                    set: { editingItem.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }
        }
        .navigationTitle(isNew ? "新建条目" : "编辑条目")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(isNew ? "添加" : "保存") { saveAndClose() }
                    .disabled(editingItem.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveAndClose() {
        if let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)), !urlText.isEmpty {
            editingItem.sourceURL = url
            if editingItem.sourceDomain == nil, let host = url.host?.lowercased() {
                editingItem.sourceDomain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            }
        } else {
            editingItem.sourceURL = nil
            editingItem.sourceDomain = nil
        }

        vm.save(editingItem)
        dismiss()
    }

    private func binding<T>(_ keyPath: WritableKeyPath<FeedItem, T>) -> Binding<T> {
        Binding(get: { editingItem[keyPath: keyPath] },
                set: { editingItem[keyPath: keyPath] = $0 })
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

