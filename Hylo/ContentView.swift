import SwiftUI

struct ContentView: View {
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var navidrome = NavidromeService.shared

    @State private var searchQuery = ""
    @State private var searchResults: [Song] = []
    @State private var isSearching = false
    @State private var showNowPlaying = false

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                // MARK: - Search Tab
                NavigationView {
                    VStack(spacing: 0) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Search your Navidrome library…", text: $searchQuery)
                                .foregroundColor(.white)
                                .submitLabel(.search)
                                .onSubmit {
                                    isSearching = true
                                    navidrome.search(query: searchQuery) { results in
                                        searchResults = results
                                        isSearching = false
                                    }
                                }
                            if isSearching {
                                ProgressView().tint(.yellow)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if searchResults.isEmpty && !searchQuery.isEmpty && !isSearching {
                            Spacer()
                            Text("No results for "\(searchQuery)"")
                                .foregroundColor(.gray)
                            Spacer()
                        } else {
                            List(searchResults) { song in
                                SongRow(song: song, playerVM: playerVM, offlineManager: offlineManager)
                                    .listRowBackground(Color.black)
                            }
                            .listStyle(.plain)
                        }
                    }
                    .background(Color.black.ignoresSafeArea())
                    .navigationTitle("Search")
                }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

                // MARK: - Offline Tab
                OfflineView(playerViewModel: playerVM)
                    .tabItem { Label("Offline", systemImage: "arrow.down.circle.fill") }

                // MARK: - Settings Tab
                NavigationView {
                    Form {
                        Section(header: Text("Navidrome Server").foregroundColor(hyloYellow)) {
                            TextField("Server URL", text: $navidrome.serverURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            TextField("Username", text: $navidrome.username)
                                .autocapitalization(.none)
                            SecureField("Password", text: $navidrome.password)
                        }

                        Section(header: Text("About").foregroundColor(hyloYellow)) {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0").foregroundColor(.gray)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black.ignoresSafeArea())
                    .navigationTitle("Settings")
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .accentColor(hyloYellow)
            .preferredColorScheme(.dark)

            // MARK: - Mini Now Playing bar
            if let song = playerVM.currentSong {
                Button(action: { showNowPlaying = true }) {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(song.artist)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: { playerVM.togglePlayPause() }) {
                            Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(hyloYellow)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 56) // clear tab bar
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showNowPlaying) {
                    NowPlayingView(playerViewModel: playerVM)
                }
            }
        }
    }
}

// MARK: - Reusable Song Row

struct SongRow: View {
    let song: Song
    @ObservedObject var playerVM: PlayerViewModel
    @ObservedObject var offlineManager: OfflineManager

    var body: some View {
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
                offlineManager.downloadTrack(song: song) { _ in }
            }) {
                Image(systemName: offlineManager.isDownloaded(songID: song.id)
                      ? "checkmark.circle.fill"
                      : "arrow.down.circle")
                    .foregroundColor(Color(red: 0.98, green: 0.8, blue: 0.1))
            }
            .buttonStyle(.plain)

            Button(action: { playerVM.play(song: song) }) {
                Image(systemName: "play.fill")
                    .foregroundColor(Color(red: 0.98, green: 0.8, blue: 0.1))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
