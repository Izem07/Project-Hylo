import Foundation

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var downloadedSongIDs: Set<String> = []
    
    init() {
        loadDownloadedIDs()
    }
    
    // Directory where offline tracks are stored securely
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func localFileURL(for songID: String) -> URL {
        return documentsDirectory.appendingPathComponent("\(songID).mp3")
    }
    
    func isDownloaded(songID: String) -> Bool {
        return FileManager.default.fileExists(atPath: localFileURL(for: songID).path)
    }
    
    // Download track from Navidrome server for offline use
    func downloadTrack(song: Song, completion: @escaping (Bool) -> Void) {
        guard let remoteURL = NavidromeService.shared.streamURL(for: song.id) else {
            completion(false)
            return
        }
        
        let destinationURL = localFileURL(for: song.id)
        
        // If already downloaded, skip
        if isDownloaded(songID: song.id) {
            completion(true)
            return
        }
        
        URLSession.shared.downloadTask(with: remoteURL) { location, response, error in
            guard let location = location, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: location, to: destinationURL)
                
                DispatchQueue.main.async {
                    self.downloadedSongIDs.insert(song.id)
                    self.saveDownloadedIDs()
                    completion(true)
                }
            } catch {
                print("Failed to save file offline: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func deleteOfflineTrack(songID: String) {
        let fileURL = localFileURL(for: songID)
        try? FileManager.default.removeItem(at: fileURL)
        downloadedSongIDs.remove(songID)
        saveDownloadedIDs()
    }
    
    private func saveDownloadedIDs() {
        UserDefaults.standard.set(Array(downloadedSongIDs), forKey: "HyloDownloadedSongs")
    }
    
    private func loadDownloadedIDs() {
        if let saved = UserDefaults.standard.array(forKey: "HyloDownloadedSongs") as? [String] {
            downloadedSongIDs = Set(saved)
        }
    }
}
