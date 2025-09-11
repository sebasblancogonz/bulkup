import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image, [Color]) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var dominantColors: [Color] = [.blue, .blue.opacity(0.7)]
    @State private var isLoading = true
    @State private var hasError = false   // <- Nuevo

    private let imageLoader = ImageCacheManager.shared

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image, [Color]) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage), dominantColors)
            } else if hasError {
                // Mostrar placeholder con overlay de error
                ZStack {
                    placeholder()
                }
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
            hasError = true
            return
        }

        let urlString = url.absoluteString

        // Verificar si ya tenemos en caché imagen + colores
        if let cached = imageLoader.getCachedImage(from: urlString) {
            self.uiImage = cached.image
            self.dominantColors = cached.colors.map { Color($0) }
            self.isLoading = false
            return
        } else if let diskImage = imageLoader.getImageFromDisk(for: urlString) {
            let colors = diskImage.getDominantColors()
            imageLoader.setCachedImage(diskImage, colors: colors, for: urlString)
            self.uiImage = diskImage
            self.dominantColors = colors.map { Color($0) }
            self.isLoading = false
            return
        } else {
            URLSession.shared.dataTask(with: url) { data, response, error in
                AppLogger.shared.error("Error loading image with url: \(url). Failed with error: \((error as NSError?)?.localizedDescription ?? "No error description")")
                if let error = error {
                    print("❌ Error descargando imagen: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.hasError = true
                    }
                    return
                }

                guard let data = data,
                      let originalImage = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.hasError = true
                    }
                    return
                }

                DispatchQueue.global(qos: .userInitiated).async {
                    let targetSize = CGSize(width: 200, height: 200)
                    let resizedImage = originalImage.resized(to: targetSize)
                    let colors = resizedImage.getDominantColors()

                    self.imageLoader.setCachedImage(
                        resizedImage,
                        colors: colors,
                        for: urlString
                    )
                    self.imageLoader.saveImageToDisk(resizedImage, for: urlString)

                    DispatchQueue.main.async {
                        self.uiImage = resizedImage
                        self.dominantColors = colors.map { Color($0) }
                        self.isLoading = false
                        self.hasError = false
                    }
                }
            }.resume()
        }
    }
}
