import SwiftUI

struct ContentView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        TabView {
            // 1. Placeholder for Home View
            VStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.98, green: 0.8, blue: 0.1))
                Text("Home / Library Coming Soon")
                    .font(.headline)
                    .padding()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // 2. Search View Placeholder
            Text("Search Coming Soon")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            // 3. Offline View (The one we built!)
            OfflineView(playerViewModel: playerViewModel)
                .tabItem {
                    Label("Offline", systemImage: "arrow.down.circle.fill")
                }
        }
        // Tint the active tab with the Hylo Yellow brand color
        .accentColor(Color(red: 0.98, green: 0.8, blue: 0.1))
        .preferredColorScheme(.dark) // Force dark mode for the app
    }
}
