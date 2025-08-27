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

    @State private var uiImage: UIImage?
    @State private var dominantColors: [Color] = [.blue, .blue.opacity(0.7)]
    @State private var isLoading = true

    private let imageLoader = ImageCacheManager.shared

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

        // Verificar si ya tenemos en caché imagen + colores
        if let cached = imageLoader.getCachedImage(from: urlString) {
            self.uiImage = cached.image
            self.dominantColors = cached.colors.map { Color($0) }
            self.isLoading = false
            return
        }

        // Descargar si no está en caché
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let originalImage = UIImage(data: data) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let targetSize = CGSize(width: 200, height: 200)
                let resizedImage = originalImage.resized(to: targetSize)
                let colors = resizedImage.getDominantColors()

                // Guardamos imagen + colores en caché
                self.imageLoader.setCachedImage(resizedImage,
                                                          colors: colors,
                                                          for: urlString)

                DispatchQueue.main.async {
                    self.uiImage = resizedImage
                    self.dominantColors = colors.map { Color($0) }
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
