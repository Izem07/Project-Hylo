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
                    AsyncImage(url: NavidromeService.shared.coverArtURL(for: playerViewModel.currentSong?.coverArtID, size: 600)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        default:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(16)
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
                        set: { playerViewModel.seek(to: $0) }
                    ), in: 0...1)
                    .accentColor(hyloYellow)

                    HStack {
                        Text(formatSeconds(playerViewModel.currentTime))
                        Spacer()
                        Text(formatSeconds(playerViewModel.duration))
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

                    Button(action: { playerViewModel.skipBack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Previous track")

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

                    Button(action: { playerViewModel.skipForward() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Next track")

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

    private func formatSeconds(_ s: Double) -> String {
        guard s.isFinite && s > 0 else { return "0:00" }
        let t = Int(s)
        return "\(t / 60):\(String(format: "%02d", t % 60))"
    }
}
