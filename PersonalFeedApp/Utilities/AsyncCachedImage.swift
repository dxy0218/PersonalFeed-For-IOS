import SwiftUI

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure(Error?)
}

struct AsyncCachedImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var height: CGFloat? = nil
    
    @State private var phase: CachedImagePhase = .empty
    
    var body: some View {
        Group {
            switch phase {
            case .empty:
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .opacity(0.08)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            case .failure(_):
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .opacity(0.08)
            }
        }
        .task(id: url) {
            await load()
        }
    }
    
    @MainActor
    private func setPhase(_ new: CachedImagePhase) {
        withAnimation(.default) { self.phase = new }
    }
    
    private func load() async {
        guard let url = url else {
            await MainActor.run { setPhase(.failure(nil)) }
            return
        }
        // 1) 本地磁盘优先
        if let img = ImageDiskCache.shared.image(for: url) {
            await MainActor.run { setPhase(.success(Image(uiImage: img))) }
            return
        }
        // 2) 网络下载 + 写入缓存
        do {
            var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
               let img = UIImage(data: data) {
                ImageDiskCache.shared.store(data: data, for: url)
                await MainActor.run { setPhase(.success(Image(uiImage: img))) }
            } else {
                await MainActor.run { setPhase(.failure(nil)) }
            }
        } catch {
            await MainActor.run { setPhase(.failure(error)) }
        }
    }
}
