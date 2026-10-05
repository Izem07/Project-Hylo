import SwiftUI

struct OfflineView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {

                    // Status banner
                    HStack(spacing: 12) {
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "bolt.horizontal.slash.fill")
                            .foregroundColor(hyloYellow)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(networkMonitor.isConnected ? "Online — Offline Tracks" : "Offline Mode Active")
                                .font(.headline).fontWeight(.bold).foregroundColor(.white)
                            Text("Only downloaded audio files are stored locally.")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Count badge
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Cached Tracks")
                                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            Text("\(offlineManager.downloadedSongs.count) audio files on device")
                                .font(.caption2).foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(hyloYellow).font(.title3)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Track list
                    if offlineManager.downloadedSongs.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.slash")
                                .font(.system(size: 48)).foregroundColor(.gray)
                            Text("No offline tracks yet")
                                .font(.headline).foregroundColor(.white)
                            Text("Browse the Library, then tap the download button on any track.")
                                .font(.caption).foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List {
                            ForEach(offlineManager.downloadedSongs) { song in
                                SongRow(song: song, queue: offlineManager.downloadedSongs, playerViewModel: playerViewModel)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            offlineManager.deleteDownload(songID: song.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
