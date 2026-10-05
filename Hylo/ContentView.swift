import SwiftUI

struct ContentView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingNowPlaying = false
    
    // Hylo Brand Color
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Connection Lost Banner
                if !networkMonitor.isConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("No connection — Offline mode active")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(hyloYellow)
                }
                
                TabView {
                    // 1. Library View
                    LibraryView(playerViewModel: playerViewModel)
                        .tabItem {
                            Label("Library", systemImage: "music.note.list")
                        }
                    
                    // 2. Offline View
                    OfflineView(playerViewModel: playerViewModel)
                        .tabItem {
                            Label("Offline", systemImage: "arrow.down.circle.fill")
                        }
                }
                .accentColor(hyloYellow)
            }
            
            // Persistent Mini-Player Overlay
            if playerViewModel.currentSong != nil {
                MiniPlayerView(playerViewModel: playerViewModel)
                    .onTapGesture {
                        showingNowPlaying = true
                    }
                    .padding(.bottom, 49) // Offset to sit just above the TabBar
            }
        }
        // Now Playing Modal Sheet
        .sheet(isPresented: $showingNowPlaying) {
            NowPlayingView(playerViewModel: playerViewModel)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mini Player View Component
struct MiniPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)
    
    var body: some View {
        HStack {
            // Tiny artwork placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(hyloYellow.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "music.note").foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(playerViewModel.currentSong?.title ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(playerViewModel.currentSong?.artist ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(hyloYellow)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Like Button
            Button(action: { playerViewModel.toggleLike() }) {
                Image(systemName: playerViewModel.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(playerViewModel.isLiked ? hyloYellow : .white)
                    .padding(.trailing, 8)
            }
            
            // Play/Pause Button
            Button(action: { playerViewModel.togglePlayPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // Glassmorphism background for the mini-player
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
}
