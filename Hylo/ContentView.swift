import SwiftUI

struct ContentView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingNowPlaying = false

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {

                // Offline / no-connection banner
                if !networkMonitor.isConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash").font(.caption)
                        Text("No connection — Offline mode active")
                            .font(.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(hyloYellow)
                }

                TabView {
                    // 1. Library (live albums + playlists)
                    LibraryView(playerViewModel: playerViewModel)
                        .tabItem { Label("Library", systemImage: "music.note.list") }

                    // 2. Offline cached tracks
                    OfflineView(playerViewModel: playerViewModel)
                        .tabItem { Label("Offline", systemImage: "arrow.down.circle.fill") }

                    // 3. Settings / Connect
                    NavigationView {
                        ConnectView()
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .accentColor(hyloYellow)
            }

            // Mini-player floats above the tab bar
            if playerViewModel.currentSong != nil {
                MiniPlayerView(playerViewModel: playerViewModel)
                    .onTapGesture { showingNowPlaying = true }
                    .padding(.bottom, 49) // sits just above the tab bar
            }
        }
        .sheet(isPresented: $showingNowPlaying) {
            NowPlayingView(playerViewModel: playerViewModel)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mini player bar

struct MiniPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var navidrome = NavidromeService.shared

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        HStack(spacing: 12) {
            // Album art thumbnail
            AsyncImage(url: navidrome.coverArtURL(for: playerViewModel.currentSong?.coverArtID, size: 80)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(hyloYellow.opacity(0.3))
                        .overlay(Image(systemName: "music.note").foregroundColor(.white))
                }
            }
            .frame(width: 40, height: 40)
            .cornerRadius(6)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(playerViewModel.currentSong?.title ?? "")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(.white).lineLimit(1)
                Text(playerViewModel.currentSong?.artist ?? "")
                    .font(.caption).foregroundColor(hyloYellow).lineLimit(1)
            }

            Spacer()

            Button(action: { playerViewModel.toggleLike() }) {
                Image(systemName: playerViewModel.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(playerViewModel.isLiked ? hyloYellow : .white)
            }
            .accessibilityLabel(playerViewModel.isLiked ? "Unlike" : "Like")

            Button(action: { playerViewModel.togglePlayPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2).foregroundColor(.white)
            }
            .accessibilityLabel(playerViewModel.isPlaying ? "Pause" : "Play")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
}
