import Foundation
import AVFoundation

class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var isLiked: Bool = false
    
    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    
    func play(song: Song) {
        self.currentSong = song
        self.isLiked = song.isLiked
        
        let playbackURL: URL?
        
        // Check if track is cached locally for offline listening
        if OfflineManager.shared.isDownloaded(songID: song.id) {
            playbackURL = OfflineManager.shared.localFileURL(for: song.id)
            print("Playing from Offline Storage: \(song.title)")
        } else {
            // Fallback to live Navidrome server stream
            playbackURL = NavidromeService.shared.streamURL(for: song.id)
            print("Streaming from Navidrome Server: \(song.title)")
        }
        
        guard let url = playbackURL else { return }
        
        let playerItem = AVPlayerItem(url: url)
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
    
    func toggleLike() {
        isLiked.toggle()
        guard let song = currentSong else { return }
        // Call Navidrome star/unstar API endpoint
        NavidromeService.shared.setStarred(songID: song.id, starred: isLiked)
    }
    
    private func setupPeriodicObserver() {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = self.audioPlayer?.currentItem?.duration.seconds, duration > 0 else { return }
            self.playbackProgress = time.seconds / duration
        }
    }
}
