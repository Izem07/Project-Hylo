import SwiftUI

struct LibraryView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your library, ready to go.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Quick Picks Section
                    Text("Quick Picks")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Liked Songs Card
                            Button(action: {
                                let mockSong = Song(id: "1", title: "Feel Good Inc.", artist: "Gorillaz", album: "Demon Days", duration: "3:43", isLiked: true)
                                playerViewModel.play(song: mockSong)
                            }) {
                                VStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 140, height: 140)
                                        .overlay(Image(systemName: "heart.fill").font(.largeTitle).foregroundColor(hyloYellow))
                                    
                                    Text("Liked Songs")
                                        .font(.subheadline).bold().foregroundColor(.white)
                                    Text("7 favorites ready")
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            
                            // Recently Played Card
                            VStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 140, height: 140)
                                    .overlay(Image(systemName: "clock.fill").font(.largeTitle).foregroundColor(.gray))
                                
                                Text("Recently Played")
                                    .font(.subheadline).bold().foregroundColor(.white)
                                Text("2 tracks")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Server Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(networkMonitor.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(networkMonitor.isConnected ? "Connected to server" : "Server unreachable")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
