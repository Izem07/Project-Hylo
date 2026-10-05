import Foundation

/// Manages downloaded audio files.
/// - Only the song ID list is persisted locally (UserDefaults).
/// - Track metadata is NOT stored — it's always fetched live from the server.
/// - The raw .mp3 files live in the app's Documents directory.
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()

    @Published var downloadedSongIDs: Set<String> = []

    private let idsKey = "hylo_offline_ids"

    init() {
        loadIDs()
    }

    // MARK: - Paths

    private var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func localFileURL(for songID: String) -> URL {
        documentsDir.appendingPathComponent("\(songID).mp3")
    }

    func isDownloaded(songID: String) -> Bool {
        downloadedSongIDs.contains(songID) &&
        FileManager.default.fileExists(atPath: localFileURL(for: songID).path)
    }

    // MARK: - Download

    func download(song: Song, completion: @escaping (Bool) -> Void) {
        guard let remoteURL = NavidromeService.shared.streamURL(for: song.id) else {
            completion(false); return
        }

        let destination = localFileURL(for: song.id)

        if isDownloaded(songID: song.id) {
            completion(true); return
        }

        URLSession.shared.downloadTask(with: remoteURL) { location, _, error in
            guard let location = location, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                DispatchQueue.main.async {
                    self.downloadedSongIDs.insert(song.id)
                    self.saveIDs()
                    completion(true)
                }
            } catch {
                print("Offline save error: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    // MARK: - Delete

    func deleteDownload(songID: String) {
        try? FileManager.default.removeItem(at: localFileURL(for: songID))
        downloadedSongIDs.remove(songID)
        saveIDs()
    }

    // MARK: - Persistence (IDs only)

    private func saveIDs() {
        UserDefaults.standard.set(Array(downloadedSongIDs), forKey: idsKey)
    }

    private func loadIDs() {
        // Also validate that each stored ID still has a file on disk
        let stored = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        downloadedSongIDs = Set(stored.filter {
            FileManager.default.fileExists(atPath: localFileURL(for: $0).path)
        })
    }
}
