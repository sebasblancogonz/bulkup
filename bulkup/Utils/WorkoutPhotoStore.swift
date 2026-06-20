import UIKit

/// Saves workout-feedback photos to the app's Documents directory (on-device
/// only — never uploaded). SwiftData stores just the filenames.
enum WorkoutPhotoStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkoutPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    /// Writes a JPEG and returns its filename, or nil on failure.
    static func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        do {
            try data.write(to: url(for: filename))
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: filename).path)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: url(for: filename))
    }
}
