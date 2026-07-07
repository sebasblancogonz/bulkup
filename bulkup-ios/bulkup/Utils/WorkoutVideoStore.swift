import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Wraps a PhotosPicker-selected video as a file URL we can move into storage.
/// PhotosPicker deletes its delivered file after the importing closure returns,
/// so we copy it to a temp location first.
struct PickedVideo: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { received in
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mov")
            try? FileManager.default.removeItem(at: temp)
            try FileManager.default.copyItem(at: received.file, to: temp)
            return Self(url: temp)
        }
    }
}

/// Stores per-set workout videos in Documents/WorkoutVideos (on-device only —
/// never uploaded). A JSON index maps a set key to its filename. Mirrors
/// WorkoutPhotoStore.
enum WorkoutVideoStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkoutVideos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
    private static var indexURL: URL { directory.appendingPathComponent("index.json") }

    private static func loadIndex() -> [String: String] {
        guard let data = try? Data(contentsOf: indexURL),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }
    private static func saveIndex(_ map: [String: String]) {
        if let data = try? JSONEncoder().encode(map) { try? data.write(to: indexURL) }
    }

    /// File URL of the video for a set, or nil if none / missing on disk.
    static func url(for setKey: String) -> URL? {
        guard let name = loadIndex()[setKey] else { return nil }
        let u = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    static func hasVideo(for setKey: String) -> Bool { url(for: setKey) != nil }

    /// Moves a picked temp video into storage and indexes it under `setKey`,
    /// replacing any existing video for that set. Returns the stored filename.
    @discardableResult
    static func save(from tempURL: URL, for setKey: String) -> String? {
        delete(for: setKey)
        let filename = "\(UUID().uuidString).mov"
        let dest = directory.appendingPathComponent(filename)
        do {
            try FileManager.default.moveItem(at: tempURL, to: dest)
        } catch {
            guard (try? FileManager.default.copyItem(at: tempURL, to: dest)) != nil else { return nil }
        }
        var map = loadIndex(); map[setKey] = filename; saveIndex(map)
        return filename
    }

    static func delete(for setKey: String) {
        var map = loadIndex()
        if let name = map[setKey] {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            map[setKey] = nil; saveIndex(map)
        }
    }

    #if DEBUG
    static func runSelfCheck() {
        // Index encode/decode round-trip (no disk side effects).
        let sample = ["plan-lunes-0-press-0-2026-06-22": "abc.mov"]
        guard let data = try? JSONEncoder().encode(sample),
              let back = try? JSONDecoder().decode([String: String].self, from: data) else {
            assertionFailure("video index codec"); return
        }
        assert(back == sample, "video index round-trip")
    }
    #endif
}
