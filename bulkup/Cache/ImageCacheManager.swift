//
//  ImageCacheManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 27/8/25.
//
import SwiftUI

// MARK: - Image Cache Manager
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 50  // Reducido de 100
        cache.totalCostLimit = 20 * 1024 * 1024 // 20MB (reducido de 50MB)
        
        // Limpieza automática en memoria baja
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
    
    func getImage(from urlString: String) -> UIImage? {
        return cache.object(forKey: urlString as NSString)
    }
    
    func setImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
}
