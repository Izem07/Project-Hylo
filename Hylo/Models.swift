import Foundation

// MARK: - Subsonic API Decodable Models

struct SubsonicResponse: Codable {
    let subsonicResponse: SubsonicResponseBody

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicResponseBody: Codable {
    let status: String
    let searchResult3: SearchResult3?
}

struct SearchResult3: Codable {
    let song: [SubsonicSong]?
}

struct SubsonicSong: Codable {
    let id: String
    let title: String
    let artist: String?
    let album: String?
    let duration: Int
    let starred: String?
}
