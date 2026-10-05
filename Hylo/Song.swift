import Foundation

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: String
    let coverArtID: String?
    var isLiked: Bool
}
