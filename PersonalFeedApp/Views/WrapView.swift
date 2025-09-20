import SwiftUI

/// 一个简单的“流式换行”容器。
/// 用法：WrapView(tags: ["A","B"]) { tag in Text(tag) }
struct WrapView<Data: RandomAccessCollection, Content: View, T: Hashable>: View where Data.Element == T {
    let tags: Data
    let spacing: CGFloat
    let runSpacing: CGFloat
    let content: (T) -> Content
    
    init(tags: Data, spacing: CGFloat = 8, runSpacing: CGFloat = 8, @ViewBuilder content: @escaping (T) -> Content) {
        self.tags = tags
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo.size)
        }
        .frame(minHeight: 0)
    }
    
    private func generateContent(in size: CGSize) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(tags), id: \.self) { tag in
                content(tag)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        if (abs(x - 0) > 0 && x + d.width > size.width) {
                            x = 0
                            y -= (d.height + runSpacing)
                        }
                        let result = x
                        if tag == tags.last {
                            x = 0 // 最后一项复位
                        } else {
                            x += d.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = y
                        return result
                    }
            }
        }
    }
}
