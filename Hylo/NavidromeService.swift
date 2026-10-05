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

    private var authParameters: String {
        let salt = String(Int.random(in: 100000...999999))
        let tokenInput = password + salt
        let token = Insecure.MD5.hash(data: Data(tokenInput.utf8))
            .map { String(format: "%02hhx", $0) }
            .joined()
        return "u=\(username)&t=\(token)&s=\(salt)&v=1.16.1&c=Hylo"
    }

    private var baseURL: String {
        var url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/") { url = String(url.dropLast()) }
        return url
    }

    // MARK: - Stream URL

    func streamURL(for songID: String) -> URL? {
        return URL(string: "\(baseURL)/rest/stream.view?id=\(songID)&\(authParameters)")
    }

    // MARK: - Search

    func search(query: String, completion: @escaping ([Song]) -> Void) {
        guard !baseURL.isEmpty,
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rest/search3.view?query=\(encodedQuery)&\(authParameters)&f=json") else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SubsonicResponse.self, from: data)
                let results = decoded.subsonicResponse.searchResult3?.song ?? []
                let mapped = results.map { item in
                    Song(
                        id: item.id,
                        title: item.title,
                        artist: item.artist ?? "Unknown Artist",
                        album: item.album ?? "Unknown Album",
                        duration: Self.formatDuration(item.duration),
                        isLiked: item.starred != nil
                    )
                }
                DispatchQueue.main.async { completion(mapped) }
            } catch {
                print("Navidrome search parse error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    // MARK: - Star / Unstar

    func setStarred(songID: String, starred: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        let endpoint = starred ? "star.view" : "unstar.view"
        guard let url = URL(string: "\(baseURL)/rest/\(endpoint)?id=\(songID)&\(authParameters)&f=json") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }

    // MARK: - Helpers

    private static func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
