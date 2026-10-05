import SwiftUI

// MARK: - Library root (Albums + Playlists)

struct LibraryView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var navidrome = NavidromeService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    @State private var albums: [Album] = []
    @State private var playlists: [Playlist] = []
    @State private var selectedTab: LibraryTab = .albums
    @State private var isLoading = false

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    enum LibraryTab { case albums, playlists }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(.white)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(networkMonitor.isConnected ? Color.green : Color.red)
                                .frame(width: 7, height: 7)
                            Text(networkMonitor.isConnected ? "Live from server" : "Server unreachable")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // Segment picker
                    HStack(spacing: 0) {
                        tabButton("Albums", tab: .albums)
                        tabButton("Playlists", tab: .playlists)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    if isLoading {
                        Spacer()
                        ProgressView().tint(hyloYellow).frame(maxWidth: .infinity)
                        Spacer()
                    } else if selectedTab == .albums {
                        albumGrid
                    } else {
                        playlistList
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadContent() }
            .onChange(of: selectedTab) { _ in loadContent() }
        }
    }

    // MARK: - Album grid

    private var albumGrid: some View {
        ScrollView {
            if albums.isEmpty {
                emptyState(icon: "square.stack.fill", message: "No albums found.\nMake sure your server URL and credentials are set in Settings.")
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(albums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album, playerViewModel: playerViewModel)) {
                            AlbumCell(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Playlist list

    private var playlistList: some View {
        ScrollView {
            if playlists.isEmpty {
                emptyState(icon: "music.note.list", message: "No playlists found on your server.")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, playerViewModel: playerViewModel)) {
                            PlaylistRow(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func tabButton(_ label: String, tab: LibraryTab) -> some View {
        Button(action: { selectedTab = tab }) {
            Text(label)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(selectedTab == tab ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == tab ? hyloYellow : Color.white.opacity(0.1))
                .cornerRadius(10)
        }
        .padding(2)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44)).foregroundColor(.gray)
            Text(message)
                .font(.subheadline).foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func loadContent() {
        guard networkMonitor.isConnected else { return }
        isLoading = true
        if selectedTab == .albums {
            navidrome.fetchAlbums { fetched in
                albums = fetched
                isLoading = false
            }
        } else {
            navidrome.fetchPlaylists { fetched in
                playlists = fetched
                isLoading = false
            }
        }
    }
}

// MARK: - Album cell

struct AlbumCell: View {
    let album: Album
    @StateObject private var navidrome = NavidromeService.shared
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: navidrome.coverArtURL(for: album.coverArt)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Image(systemName: "music.note").foregroundColor(.gray).font(.largeTitle))
                }
            }
            .frame(height: 160)
            .clipped()
            .cornerRadius(10)

            Text(album.name)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(.white).lineLimit(1)
            Text(album.artist ?? "")
                .font(.caption).foregroundColor(.gray).lineLimit(1)
        }
    }
}

// MARK: - Album detail

struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var navidrome = NavidromeService.shared
    @StateObject private var offlineManager = OfflineManager.shared

    @State private var songs: [Song] = []
    @State private var isLoading = true

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()

            if isLoading {
                ProgressView().tint(hyloYellow)
            } else {
                List {
                    // Album header
                    Section {
                        HStack(spacing: 16) {
                            AsyncImage(url: navidrome.coverArtURL(for: album.coverArt, size: 120)) { phase in
                                switch phase {
                                case .success(let image): image.resizable().scaledToFill()
                                default: Rectangle().fill(Color.white.opacity(0.1))
                                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                                }
                            }
                            .frame(width: 80, height: 80).cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(album.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                                Text(album.artist ?? "").font(.subheadline).foregroundColor(.gray)
                                Text("\(songs.count) tracks")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }

                    // Track list
                    ForEach(songs) { song in
                        SongRow(song: song, queue: songs, playerViewModel: playerViewModel)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            navidrome.fetchTracks(forAlbumID: album.id) { fetched in
                songs = fetched
                isLoading = false
            }
        }
    }
}

// MARK: - Playlist row

struct PlaylistRow: View {
    let playlist: Playlist
    @StateObject private var navidrome = NavidromeService.shared
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: navidrome.coverArtURL(for: playlist.coverArt, size: 80)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: Rectangle().fill(Color.white.opacity(0.08))
                    .overlay(Image(systemName: "music.note.list").foregroundColor(.gray))
                }
            }
            .frame(width: 52, height: 52).cornerRadius(8)

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white).lineLimit(1)
                Text("\(playlist.songCount) songs")
                    .font(.caption).foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption).foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Playlist detail

struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var navidrome = NavidromeService.shared

    @State private var songs: [Song] = []
    @State private var isLoading = true

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()

            if isLoading {
                ProgressView().tint(hyloYellow)
            } else if songs.isEmpty {
                Text("This playlist is empty.").foregroundColor(.gray)
            } else {
                List(songs) { song in
                    SongRow(song: song, queue: songs, playerViewModel: playerViewModel)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            navidrome.fetchPlaylistTracks(playlistID: playlist.id) { fetched in
                songs = fetched
                isLoading = false
            }
        }
    }
}

// MARK: - Shared song row

struct SongRow: View {
    let song: Song
    let queue: [Song]
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var navidrome = NavidromeService.shared
    @StateObject private var offlineManager = OfflineManager.shared

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    init(song: Song, queue: [Song] = [], playerViewModel: PlayerViewModel) {
        self.song = song
        self.queue = queue
        self.playerViewModel = playerViewModel
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: navidrome.coverArtURL(for: song.coverArtID, size: 60)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: Rectangle().fill(Color.white.opacity(0.08))
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray).font(.caption))
                }
            }
            .frame(width: 44, height: 44).cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white).lineLimit(1)
                Text(song.artist)
                    .font(.caption).foregroundColor(.gray).lineLimit(1)
            }

            Spacer()

            Text(song.duration)
                .font(.caption2).foregroundColor(.gray).monospacedDigit()

            // Download / cached indicator
            Button(action: {
                offlineManager.download(song: song) { _ in }
            }) {
                Image(systemName: offlineManager.isDownloaded(songID: song.id)
                    ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundColor(offlineManager.isDownloaded(songID: song.id) ? hyloYellow : .gray)
            }
            .accessibilityLabel(offlineManager.isDownloaded(songID: song.id) ? "Downloaded" : "Download")
            .buttonStyle(.plain)

            // Play
            Button(action: { playerViewModel.play(song: song, queue: queue.isEmpty ? [song] : queue) }) {
                Image(systemName: "play.fill").foregroundColor(hyloYellow)
            }
            .accessibilityLabel("Play \(song.title)")
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color(red: 0.08, green: 0.08, blue: 0.08))
    }
}
