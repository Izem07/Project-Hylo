import Foundation

struct Song: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let isLiked: Bool
}
