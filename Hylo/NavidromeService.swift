import Foundation

class NavidromeService {
    static let shared = NavidromeService()
    
    private let serverURL = "https://your-navidrome-server.com"
    private let authParameters = "u=username&p=password&v=1.16.1&c=Hylo&f=json"
    
    // MARK: - Stream URL
    func streamURL(for songID: String) -> URL? {
        return URL(string: "\(serverURL)/rest/stream?id=\(songID)&\(authParameters)")
    }
    
    // MARK: - Star / Like Track Endpoint
    func setStarred(songID: String, starred: Bool) {
        let actionEndpoint = starred ? "star.view" : "unstar.view"
        guard let url = URL(string: "\(serverURL)/rest/\(actionEndpoint)?id=\(songID)&\(authParameters)") else { return }
        
        URLSession.shared.dataTask(with: url).resume()
    }
}
