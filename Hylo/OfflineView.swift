import SwiftUI

struct OfflineView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var downloadedSongs: [Song] = [] // Populated from local DB / metadata cache
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header status banner
                HStack(spacing: 12) {
                    Image(systemName: "bolt.horizontal.slash.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline Mode Active")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("No server connection required to listen.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Storage & Downloads Section Banner
                HStack {
                    VStack(alignment: .leading) {
                        Text("Storage & Downloads")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("\(offlineManager.downloadedSongIDs.count) tracks cached locally")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Downloaded Tracks List
                if offlineManager.downloadedSongIDs.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No offline tracks yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Download songs from albums, playlists, or search results to listen anywhere.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List {
                        // Iterate through your cached offline tracks here
                        // Selecting a track immediately plays it locally via the PlayerViewModel
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Offline")
            .navigationBarHidden(true)
        }
    }
}
