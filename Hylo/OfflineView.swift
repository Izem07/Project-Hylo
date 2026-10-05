import SwiftUI

struct OfflineView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var offlineManager = OfflineManager.shared

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {

                // Status banner
                HStack(spacing: 12) {
                    Image(systemName: "bolt.horizontal.slash.fill")
                        .foregroundColor(hyloYellow)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline Mode Active")
                            .font(.headline).fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("No server connection required to listen.")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)

                // Storage info
                HStack {
                    VStack(alignment: .leading) {
                        Text("Downloaded Tracks")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("\(offlineManager.downloadedSongs.count) tracks cached locally")
                            .font(.caption2).foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(hyloYellow)
                        .font(.title3)
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
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No offline tracks yet")
                            .font(.headline).foregroundColor(.white)
                        Text("Search for songs and tap the download button to save them for offline listening.")
                            .font(.caption).foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List {
                        ForEach(offlineManager.downloadedSongs) { song in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(song.title)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text("\(song.artist) • \(song.album)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(song.duration)
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                                    .monospacedDigit()

                                Button(action: {
                                    offlineManager.deleteOfflineTrack(songID: song.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    playerViewModel.play(song: song)
                                }) {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(hyloYellow)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.black)
                        }
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
