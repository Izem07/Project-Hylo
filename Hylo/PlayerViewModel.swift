import Foundation
import AVFoundation
import MediaPlayer
import UIKit

class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var isLiked: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    @Published var playbackError: String? = nil

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?

    private var queue: [Song] = []
    private var queueIndex: Int = 0

    init() {
        setupAudioSession()
        setupRemoteCommands()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    func play(song: Song, queue: [Song] = []) {
        self.currentSong = song
        self.isLiked = song.isLiked
        self.playbackError = nil

        if !queue.isEmpty {
            self.queue = queue
            self.queueIndex = queue.firstIndex(where: { $0.id == song.id }) ?? 0
        }

        let playbackURL: URL?

        // Check if track is cached locally for offline listening
        if OfflineManager.shared.isDownloaded(songID: song.id) {
            playbackURL = OfflineManager.shared.localFileURL(for: song.id)
            print("Playing from Offline Storage: \(song.title)")
        } else if NetworkMonitor.shared.isConnected {
            // Stream from server only if connected
            playbackURL = NavidromeService.shared.streamURL(for: song.id)
            print("Streaming from Navidrome Server: \(song.title)")
        } else {
            // No connection and not cached — show error
            playbackError = "No connection. Download this track for offline listening."
            print("Cannot play \(song.title) — offline and not cached")
            return
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
        updateNowPlayingInfo(song: song)
    }

    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
        updatePlaybackState()
    }

    func toggleLike() {
        isLiked.toggle()
        guard let song = currentSong else { return }
        // Call Navidrome star/unstar API endpoint
        NavidromeService.shared.setStarred(songID: song.id, starred: isLiked)
    }

    // MARK: - Seek

    func seek(to progress: Double) {
        guard let duration = audioPlayer?.currentItem?.duration else { return }
        let seconds = progress * duration.seconds
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        audioPlayer?.seek(to: time)
    }

    // MARK: - Queue / Skip

    func skipForward() {
        guard queueIndex + 1 < queue.count else { return }
        queueIndex += 1
        play(song: queue[queueIndex], queue: queue)
    }

    func skipBack() {
        if currentTime > 3 {
            seek(to: 0)
        } else if queueIndex > 0 {
            queueIndex -= 1
            play(song: queue[queueIndex], queue: queue)
        } else {
            seek(to: 0)
        }
    }

    private func setupPeriodicObserver() {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            self.duration = self.audioPlayer?.currentItem?.duration.seconds ?? 0
            self.playbackProgress = self.duration > 0 ? self.currentTime / self.duration : 0

            // MARK: - Task 11: Lock screen elapsed time
            if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime
                info[MPMediaItemPropertyPlaybackDuration] = self.duration
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    // MARK: - Lock Screen & Background Audio Support

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBack()
            return .success
        }
    }

    private func updateNowPlayingInfo(song: Song) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.album

        // Push metadata to the iOS Lock Screen
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // Fetch and set cover art asynchronously
        if let artURL = NavidromeService.shared.coverArtURL(for: song.coverArtID, size: 600) {
            URLSession.shared.dataTask(with: artURL) { data, _, _ in
                guard let data = data, let uiImage = UIImage(data: data) else { return }
                let artwork = MPMediaItemArtwork(boundsSize: uiImage.size) { _ in uiImage }
                DispatchQueue.main.async {
                    if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                        info[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                    }
                }
            }.resume()
        }
    }

    private func updatePlaybackState() {
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
}
