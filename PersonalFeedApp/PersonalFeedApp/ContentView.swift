import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var vm = FeedViewModel()
    @State private var showNew = false
    @State private var showSettings = false
    @State private var selectedItem: FeedItem? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部分类条
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button {
                            vm.selectedCategory = nil
                        } label: {
                            Text("全部")
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background((vm.selectedCategory == nil) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                                .cornerRadius(10)
                        }
                        ForEach(FeedCategory.allCases) { c in
                            Button {
                                vm.selectedCategory = c
                            } label: {
                                Text(displayName(of: c))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background((vm.selectedCategory == c) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                List {
                    ForEach(vm.filteredItems) { item in
                        FeedRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = item }
                    }
                    .onDelete { idxSet in
                        idxSet
                            .compactMap { vm.filteredItems[$0] }
                            .forEach { vm.delete($0) }
                    }
                }
                .listStyle(.inset)
                .refreshable { await vm.refreshAll() }
            }
            .navigationTitle("个人信息流")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        #if DEBUG
                        Button { vm.injectDebugSeeds() } label: { Image(systemName: "tornado") }
                        #endif
                        Button { showNew = true } label: { Image(systemName: "plus") }
                    }
                }
            }
        }
        .searchable(text: $vm.searchText, prompt: "搜索内容或标签")
        .sheet(isPresented: $showNew) { EditFeedView(vm: vm, initialItem: nil) }
        .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() } }
        .sheet(item: $selectedItem) { item in FeedDetailView(item: item) }
        .task { await vm.refreshOnLaunch() }     // 注意用异步闭包，不要写 .task(vm.refreshOnLaunch)
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
