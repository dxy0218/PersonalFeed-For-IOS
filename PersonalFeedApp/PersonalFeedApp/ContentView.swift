import SwiftUI

struct ContentView: View {
    @StateObject private var vm = FeedViewModel()
    @State private var showNew = false
    @State private var showSettings = false
    @State private var selectedItem: FeedItem? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let progress = vm.refreshProgress {
                        RefreshStatusView(progress: progress)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button { vm.selectedCategory = nil } label: {
                                Text("全部")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background((vm.selectedCategory == nil) ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            ForEach(FeedCategory.allCases) { c in
                                Button { vm.selectedCategory = c } label: {
                                    Text(displayName(of: c))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background((vm.selectedCategory == c) ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    List {
                        ForEach(vm.filteredItems) { item in
                            FeedRowView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedItem = item }
                                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { idxSet in
                            idxSet
                                .compactMap { vm.filteredItems[$0] }
                                .forEach { vm.delete($0) }
                        }
                    }
                    .environment(\.defaultMinListRowHeight, 0)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .refreshable { await vm.refreshAll() }
                }
                .animation(.easeInOut(duration: 0.25), value: vm.refreshProgress)
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

private struct RefreshStatusView: View {
    let progress: FeedViewModel.RefreshProgress

    private var iconName: String {
        switch progress.kind {
        case .previews: return "arrow.triangle.2.circlepath"
        case .ingestion: return "dot.radiowaves.left.and.right"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(progress.statusText, systemImage: iconName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Text(progress.detailText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress.fraction)
                .progressViewStyle(.linear)
                .tint(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
