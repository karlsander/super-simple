import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                await loadImage()
            }
    }

    private func loadImage() async {
        guard let url else {
            phase = .empty
            return
        }

        // Check in-memory cache first
        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        // Check disk cache
        if let diskImage = ImageCache.shared.diskImage(for: url) {
            ImageCache.shared.setImage(diskImage, for: url)
            phase = .success(Image(uiImage: diskImage))
            return
        }

        // Download
        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let uiImage = UIImage(data: data) else {
                phase = .failure(URLError(.cannotDecodeContentData))
                return
            }
            ImageCache.shared.setImage(uiImage, for: url)
            ImageCache.shared.saveToDisk(data, for: url)
            phase = .success(Image(uiImage: uiImage))
        } catch {
            if !Task.isCancelled {
                phase = .failure(error)
            }
        }
    }
}

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB in-memory

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    private func cacheKey(for url: URL) -> NSString {
        url.absoluteString as NSString
    }

    private func diskPath(for url: URL) -> URL {
        let hash = url.absoluteString.data(using: .utf8)!
            .map { String(format: "%02x", $0) }.joined()
        return diskCacheURL.appendingPathComponent(hash)
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: cacheKey(for: url))
    }

    func setImage(_ image: UIImage, for url: URL) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: cacheKey(for: url), cost: cost)
    }

    func diskImage(for url: URL) -> UIImage? {
        let path = diskPath(for: url)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    func saveToDisk(_ data: Data, for url: URL) {
        let path = diskPath(for: url)
        try? data.write(to: path, options: .atomic)
    }
}
