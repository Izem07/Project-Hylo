import Foundation

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()

    @Published var downloadedSongs: [Song] = []

    private let metadataKey = "hylo_offline_metadata"

    init() {
        loadMetadata()
    }

    // MARK: - File Paths

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func localFileURL(for songID: String) -> URL {
        documentsDirectory.appendingPathComponent("\(songID).mp3")
    }

    // MARK: - Status

    func isDownloaded(songID: String) -> Bool {
        FileManager.default.fileExists(atPath: localFileURL(for: songID).path)
    }

    // MARK: - Download

    func downloadTrack(song: Song, completion: @escaping (Bool) -> Void) {
        guard let remoteURL = NavidromeService.shared.streamURL(for: song.id) else {
            completion(false)
            return
        }

        let destination = localFileURL(for: song.id)

        if isDownloaded(songID: song.id) {
            completion(true)
            return
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
                    if !self.downloadedSongs.contains(where: { $0.id == song.id }) {
                        self.downloadedSongs.append(song)
                        self.saveMetadata()
                    }
                    completion(true)
                }
            } catch {
                print("Offline save failed: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    // MARK: - Delete

    func deleteOfflineTrack(songID: String) {
        let fileURL = localFileURL(for: songID)
        try? FileManager.default.removeItem(at: fileURL)
        downloadedSongs.removeAll { $0.id == songID }
        saveMetadata()
    }

    // MARK: - Persistence

    private func saveMetadata() {
        if let encoded = try? JSONEncoder().encode(downloadedSongs) {
            UserDefaults.standard.set(encoded, forKey: metadataKey)
        }
    }

    private func loadMetadata() {
        if let data = UserDefaults.standard.data(forKey: metadataKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            downloadedSongs = decoded
        }
    }
}
