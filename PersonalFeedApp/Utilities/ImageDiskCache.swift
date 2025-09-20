import Foundation
import UIKit
import CryptoKit
import ImageIO

/// 简单的磁盘级图片缓存：按 URL 的 SHA256 命名文件，保存在 Caches 目录。
final class ImageDiskCache {
    static let shared = ImageDiskCache()
    private init() {}

    private let fm = FileManager.default
    private let defaultSizeLimitBytes = 30 * 1024 * 1024
    
    private var cacheDir: URL {
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ImageDiskCache", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private func filename(for url: URL) -> String {
        let key = url.absoluteString.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: key).compactMap { String(format: "%02x", $0) }.joined()
        return hash + "." + (url.pathExtension.isEmpty ? "img" : url.pathExtension)
    }
    
    private func fileURL(for url: URL) -> URL {
        cacheDir.appendingPathComponent(filename(for: url))
    }
    
    func image(for url: URL) -> UIImage? {
        let path = fileURL(for: url)
        guard fm.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path),
              let img = UIImage(data: data) else {
            return nil
        }
        try? fm.setAttributes([.modificationDate: Date()], ofItemAtPath: path.path)
        return img
    }
    
    func data(for url: URL) -> Data? {
        let path = fileURL(for: url)
        guard fm.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path) else {
            return nil
        }
        return data
    }
    
    func store(data: Data, for url: URL, targetHeight: CGFloat? = nil) {
        let path = fileURL(for: url)
        let processed = prepareForStorage(data: data, targetHeight: targetHeight)
        try? processed.write(to: path, options: .atomic)
        pruneToSize(maxBytes: defaultSizeLimitBytes)
    }

    func remove(for url: URL) {
        let path = fileURL(for: url)
        try? fm.removeItem(at: path)
    }

    func clear() {
        try? fm.removeItem(at: cacheDir)
    }

    func pruneToSize(maxBytes: Int) {
        guard maxBytes > 0 else { return }
        let dir = cacheDir
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) else {
            return
        }
        var entries: [(url: URL, size: Int, date: Date)] = []
        var total = 0
        for file in files {
            guard let res = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let size = res.fileSize,
                  let date = res.contentModificationDate else { continue }
            entries.append((file, size, date))
            total += size
        }
        guard total > maxBytes else { return }
        entries.sort { $0.date < $1.date }
        for entry in entries {
            try? fm.removeItem(at: entry.url)
            total -= entry.size
            if total <= maxBytes { break }
        }
    }

    func cacheSize() -> Int {
        let dir = cacheDir
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles) else {
            return 0
        }
        return files.reduce(0) { partial, url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return partial + (values?.fileSize ?? 0)
        }
    }

    private func prepareForStorage(data: Data, targetHeight: CGFloat?) -> Data {
        let maxDimension: CGFloat = {
            guard let targetHeight = targetHeight, targetHeight > 0 else { return 1024 }
            return max(targetHeight * 2.0, 720)
        }()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return data }
        let options: [NSString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return data
        }
        let image = UIImage(cgImage: cgImage)
        let jpeg = image.jpegData(compressionQuality: 0.82) ?? data
        return jpeg.count <= data.count ? jpeg : data
    }
}
