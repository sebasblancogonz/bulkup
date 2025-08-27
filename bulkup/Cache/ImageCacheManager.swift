//
//  ImageCacheManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 27/8/25.
//
import SwiftUI

// MARK: - Image Cache Manager
final class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, CachedImage>()

    /// Estructura que guarda la imagen y los colores dominantes
    final class CachedImage {
        let image: UIImage
        let colors: [UIColor]

        init(image: UIImage, colors: [UIColor]) {
            self.image = image
            self.colors = colors
        }
    }

    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 20 * 1024 * 1024 // 20 MB

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.cache.removeAllObjects()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    func getCachedImage(from urlString: String) -> CachedImage? {
        cache.object(forKey: urlString as NSString)
    }

    func setCachedImage(_ image: UIImage, colors: [UIColor], for urlString: String) {
        let cached = CachedImage(image: image, colors: colors)
        cache.setObject(cached, forKey: urlString as NSString)
    }
}
