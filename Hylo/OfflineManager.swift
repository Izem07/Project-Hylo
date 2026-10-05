import Foundation

/// Manages downloaded audio files.
/// - Song IDs are persisted in UserDefaults.
/// - Song metadata is stored as JSON sidecar files (.json) beside each .mp3.
/// - The raw .mp3 files live in the app's Documents directory.
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()

    @Published var downloadedSongIDs: Set<String> = []
    @Published var downloadedSongs: [Song] = []

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

    func sidecarURL(for songID: String) -> URL {
        documentsDir.appendingPathComponent("\(songID).json")
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

                // Write sidecar JSON with song metadata
                let sidecarData = try JSONEncoder().encode(song)
                try sidecarData.write(to: self.sidecarURL(for: song.id))

                DispatchQueue.main.async {
                    self.downloadedSongIDs.insert(song.id)
                    self.saveIDs()
                    self.rebuildDownloadedSongs()
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
        try? FileManager.default.removeItem(at: sidecarURL(for: songID))
        downloadedSongIDs.remove(songID)
        saveIDs()
        rebuildDownloadedSongs()
    }

    // MARK: - Rebuild metadata list

    private func rebuildDownloadedSongs() {
        downloadedSongs = downloadedSongIDs.compactMap { songID in
            let url = sidecarURL(for: songID)
            guard let data = try? Data(contentsOf: url),
                  let song = try? JSONDecoder().decode(Song.self, from: data) else { return nil }
            return song
        }.sorted { $0.title < $1.title }
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
        rebuildDownloadedSongs()
    }
}
