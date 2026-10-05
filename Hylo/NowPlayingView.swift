import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Hylo Brand Color
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)
    
    var body: some View {
        ZStack {
            // Dark Background
            Color(red: 0.08, green: 0.08, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: - Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Now Playing")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Options action
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Album Art
                ZStack(alignment: .bottomTrailing) {
                    // Placeholder for actual album art (using a gradient block)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.0, contentMode: .fit)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    // Show Lyrics Button Overlay
                    Button(action: {
                        // Show lyrics action
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.bubble.fill")
                            Text("Show Lyrics")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    .padding(12)
                }
                .padding(.horizontal, 24)
                
                // MARK: - Track Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playerViewModel.currentSong?.title ?? "Feel Good Inc.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(playerViewModel.currentSong?.artist ?? "Gorillaz")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(hyloYellow) // Hylo Brand Color
                        
                        Text(playerViewModel.currentSong?.album ?? "Unknown Album")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Like Button
                    Button(action: { playerViewModel.toggleLike() }) {
                        Image(systemName: playerViewModel.isLiked ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(playerViewModel.isLiked ? hyloYellow : .white)
                    }
                }
                .padding(.horizontal, 24)
                
                // MARK: - Scrubber
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { playerViewModel.playbackProgress },
                        set: { _ in }
                    ), in: 0...1)
                    .accentColor(hyloYellow)
                    
                    HStack {
                        Text(formatTime(progress: playerViewModel.playbackProgress, total: 223))
                        Spacer()
                        Text("3:43")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .fontDesign(.monospaced)
                }
                .padding(.horizontal, 24)
                
                // MARK: - Playback Controls
                HStack(spacing: 28) {
                    Button(action: {}) {
                        Image(systemName: "repeat")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // Large Hylo-Yellow Play/Pause Button
                    Button(action: { playerViewModel.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(hyloYellow)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.black) // Black icon for contrast on yellow
                        }
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // MARK: - Bottom Bar (Up Next)
                HStack {
                    Text("Up Next")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                        Text("2 tracks")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
        }
    }
    
    private func formatTime(progress: Double, total: Double) -> String {
        let currentSeconds = Int(progress * total)
        let minutes = currentSeconds / 60
        let seconds = currentSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
