import Foundation
import UIKit
import CryptoKit

/// 简单的磁盘级图片缓存：按 URL 的 SHA256 命名文件，保存在 Caches 目录。
final class ImageDiskCache {
    static let shared = ImageDiskCache()
    private init() {}
    
    private let fm = FileManager.default
    
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
    
    func store(data: Data, for url: URL) {
        let path = fileURL(for: url)
        try? data.write(to: path, options: .atomic)
    }
    
    func remove(for url: URL) {
        let path = fileURL(for: url)
        try? fm.removeItem(at: path)
    }
    
    func clear() {
        try? fm.removeItem(at: cacheDir)
    }
}
