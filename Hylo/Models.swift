import Foundation

// MARK: - Shared Song model lives in Song.swift

// MARK: - Search response

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
    let coverArt: String?
    let starred: String?
}

// MARK: - Album list response

struct AlbumListResponse: Codable {
    let subsonicResponse: SubsonicAlbumListBody
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicAlbumListBody: Codable {
    let status: String
    let albumList2: AlbumList2?
}

struct AlbumList2: Codable {
    let album: [Album]?
}

struct Album: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let artist: String?
    let coverArt: String?
    let songCount: Int?
}

// MARK: - Album detail response

struct AlbumDetailResponse: Codable {
    let subsonicResponse: SubsonicAlbumDetailBody
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicAlbumDetailBody: Codable {
    let status: String
    let album: AlbumDetail?
}

struct AlbumDetail: Codable {
    let song: [SubsonicSong]?
}

// MARK: - Playlists response

struct PlaylistsResponse: Codable {
    let subsonicResponse: SubsonicPlaylistsBody
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicPlaylistsBody: Codable {
    let status: String
    let playlists: PlaylistsWrapper?
}

struct PlaylistsWrapper: Codable {
    let playlist: [Playlist]?
}

struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let songCount: Int
    let coverArt: String?
}

// MARK: - Playlist detail response

struct PlaylistDetailResponse: Codable {
    let subsonicResponse: SubsonicPlaylistDetailBody
    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicPlaylistDetailBody: Codable {
    let status: String
    let playlist: PlaylistDetail?
}

struct PlaylistDetail: Codable {
    let entry: [SubsonicSong]?
}
