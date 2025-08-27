//
//  CachedAsyncImage.swift
//  bulkup
//
//  Created by sebastian.blanco on 27/8/25.
//
import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image, [Color]) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageLoader = ImageCacheManager.shared
    @State private var uiImage: UIImage?
    @State private var dominantColors: [Color] = [.blue, .blue.opacity(0.7)]
    @State private var isLoading = true
    
    init(url: URL?,
         @ViewBuilder content: @escaping (Image, [Color]) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage), dominantColors)
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        let urlString = url.absoluteString
        
        // Verificar caché primero
        if let cachedImage = imageLoader.getImage(from: urlString) {
            self.uiImage = cachedImage
            self.dominantColors = cachedImage.getDominantColors().map { Color($0) }
            self.isLoading = false
            return
        }
        
        // Descargar imagen si no está en caché
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let originalImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Redimensionar imagen para ahorrar memoria
            let targetSize = CGSize(width: 200, height: 200) // Máximo 200x200
            let resizedImage = originalImage.resized(to: targetSize)
            
            // Guardar en caché la versión optimizada
            imageLoader.setImage(resizedImage, for: urlString)
            
            // Extraer colores dominantes
            let colors = resizedImage.getDominantColors()
            
            DispatchQueue.main.async {
                self.uiImage = resizedImage
                self.dominantColors = colors.map { Color($0) }
                self.isLoading = false
            }
        }.resume()
    }
}
