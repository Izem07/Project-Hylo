import Foundation
import AVFoundation

class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var isLiked: Bool = false

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?

    // MARK: - Playback

    func play(song: Song) {
        self.currentSong = song
        self.isLiked = song.isLiked

        let url: URL?
        if OfflineManager.shared.isDownloaded(songID: song.id) {
            url = OfflineManager.shared.localFileURL(for: song.id)
            print("Playing from offline storage: \(song.title)")
        } else {
            url = NavidromeService.shared.streamURL(for: song.id)
            print("Streaming from Navidrome: \(song.title)")
        }

        guard let playbackURL = url else { return }

        let playerItem = AVPlayerItem(url: playbackURL)
        if audioPlayer == nil {
            audioPlayer = AVPlayer(playerItem: playerItem)
        } else {
            audioPlayer?.replaceCurrentItem(with: playerItem)
        }

        audioPlayer?.play()
        isPlaying = true
        setupPeriodicObserver()
    }

    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }

    // MARK: - Like

    func toggleLike() {
        isLiked.toggle()
        guard let song = currentSong else { return }
        NavidromeService.shared.setStarred(songID: song.id, starred: isLiked)
    }

    // MARK: - Progress Observer

    private func setupPeriodicObserver() {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.audioPlayer?.currentItem?.duration.seconds,
                  duration > 0, !duration.isNaN else { return }
            self.playbackProgress = time.seconds / duration
        }
    }
}
