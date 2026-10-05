import Foundation
import CryptoKit

class NavidromeService: ObservableObject {
    static let shared = NavidromeService()

    @Published var serverURL: String = UserDefaults.standard.string(forKey: "hylo_url") ?? "" {
        didSet { UserDefaults.standard.set(serverURL, forKey: "hylo_url") }
    }
    @Published var username: String = UserDefaults.standard.string(forKey: "hylo_user") ?? "" {
        didSet { UserDefaults.standard.set(username, forKey: "hylo_user") }
    }
    @Published var password: String = UserDefaults.standard.string(forKey: "hylo_pass") ?? "" {
        didSet { UserDefaults.standard.set(password, forKey: "hylo_pass") }
    }

    // Fresh salt + MD5 token on every call (Subsonic auth spec)
    private var authParameters: String {
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        let tokenInput = password + salt
        let token = Insecure.MD5.hash(data: Data(tokenInput.utf8))
            .map { String(format: "%02hhx", $0) }
            .joined()
        return "u=\(username)&t=\(token)&s=\(salt)&v=1.16.1&c=Hylo&f=json"
    }

    var baseURL: String {
        var url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/") { url = String(url.dropLast()) }
        // Default to https if no scheme provided
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            url = "https://" + url
        }
        return url
    }

    // MARK: - URL helpers

    func streamURL(for songID: String) -> URL? {
        URL(string: "\(baseURL)/rest/stream.view?id=\(songID)&\(authParameters)")
    }

    func coverArtURL(for coverID: String?, size: Int = 300) -> URL? {
        guard let id = coverID, !id.isEmpty else { return nil }
        return URL(string: "\(baseURL)/rest/getCoverArt.view?id=\(id)&size=\(size)&\(authParameters)")
    }

    // MARK: - Albums (live query)

    func fetchAlbums(completion: @escaping ([Album]) -> Void) {
        guard !baseURL.isEmpty,
              let url = URL(string: "\(baseURL)/rest/getAlbumList2.view?type=alphabeticalByName&size=100&\(authParameters)") else {
            completion([]); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(AlbumListResponse.self, from: data)
                let albums = decoded.subsonicResponse.albumList2?.album ?? []
                DispatchQueue.main.async { completion(albums) }
            } catch {
                print("Album parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Tracks for an album (live query)

    func fetchTracks(forAlbumID albumID: String, completion: @escaping ([Song]) -> Void) {
        guard !baseURL.isEmpty,
              let url = URL(string: "\(baseURL)/rest/getAlbum.view?id=\(albumID)&\(authParameters)") else {
            completion([]); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(AlbumDetailResponse.self, from: data)
                let songs = (decoded.subsonicResponse.album?.song ?? []).map { Self.mapSong($0) }
                DispatchQueue.main.async { completion(songs) }
            } catch {
                print("Track parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Playlists (live query)

    func fetchPlaylists(completion: @escaping ([Playlist]) -> Void) {
        guard !baseURL.isEmpty,
              let url = URL(string: "\(baseURL)/rest/getPlaylists.view?\(authParameters)") else {
            completion([]); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
                let playlists = decoded.subsonicResponse.playlists?.playlist ?? []
                DispatchQueue.main.async { completion(playlists) }
            } catch {
                print("Playlists parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Tracks for a playlist (live query)

    func fetchPlaylistTracks(playlistID: String, completion: @escaping ([Song]) -> Void) {
        guard !baseURL.isEmpty,
              let url = URL(string: "\(baseURL)/rest/getPlaylist.view?id=\(playlistID)&\(authParameters)") else {
            completion([]); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PlaylistDetailResponse.self, from: data)
                let songs = (decoded.subsonicResponse.playlist?.entry ?? []).map { Self.mapSong($0) }
                DispatchQueue.main.async { completion(songs) }
            } catch {
                print("Playlist tracks parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Search

    func search(query: String, completion: @escaping ([Song]) -> Void) {
        guard !baseURL.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rest/search3.view?query=\(encoded)&\(authParameters)") else {
            completion([]); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(SubsonicResponse.self, from: data)
                let songs = (decoded.subsonicResponse.searchResult3?.song ?? []).map { Self.mapSong($0) }
                DispatchQueue.main.async { completion(songs) }
            } catch {
                print("Search parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Star / Unstar

    func setStarred(songID: String, starred: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        let endpoint = starred ? "star.view" : "unstar.view"
        guard let url = URL(string: "\(baseURL)/rest/\(endpoint)?id=\(songID)&\(authParameters)") else {
            completion(false); return
        }
        URLSession.shared.dataTask(with: url) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }

    // MARK: - Connection test

    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/rest/ping.view?\(authParameters)") else {
            completion(false, "Invalid server URL."); return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription); return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let root = json["subsonic-response"] as? [String: Any] else {
                    completion(false, "Unexpected server response."); return
                }
                if let errorObj = root["error"] as? [String: Any],
                   let code = errorObj["code"] as? Int, code == 40 || code == 41 {
                    completion(false, "Authentication failed — check your credentials.")
                } else if root["status"] as? String == "ok" {
                    completion(true, nil)
                } else {
                    completion(false, "Server returned an error.")
                }
            }
        }.resume()
    }

    // MARK: - Helpers

    static func mapSong(_ s: SubsonicSong) -> Song {
        Song(
            id: s.id,
            title: s.title,
            artist: s.artist ?? "Unknown Artist",
            album: s.album ?? "Unknown Album",
            duration: formatDuration(s.duration),
            coverArtID: s.coverArt,
            isLiked: s.starred != nil
        )
    }

    static func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
