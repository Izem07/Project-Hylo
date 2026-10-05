import SwiftUI

struct ConnectView: View {
    @StateObject private var navidrome = NavidromeService.shared
    @State private var allowInsecureHTTP: Bool = UserDefaults.standard.bool(forKey: "hylo_insecure")
    @State private var isTestingConnection = false
    @State private var connectionResult: ConnectionResult? = nil

    let hyloYellow = Color(red: 0.98, green: 0.8, blue: 0.1)

    enum ConnectionResult {
        case success, failure(String)

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .success: return .green
            case .failure: return .red
            }
        }
        var message: String {
            switch self {
            case .success: return "Connected successfully!"
            case .failure(let msg): return msg
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Branding
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hylo")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Your music server, built for the drive.")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Connect to Navidrome for albums, playlists, search, favorites, offline listening, and full queue control.")
                        .font(.subheadline).foregroundColor(.gray)
                        .padding(.top, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Albums", "Playlists", "Favorites", "Offline", "Queue"], id: \.self) {
                                CapsulePill(title: $0)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)

                // Form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Connect")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)

                    // Server URL
                    formField(label: "SERVER URL", hint: "Use a full URL or hostname. Defaults to HTTPS when no scheme is provided.") {
                        TextField("music.example.com or http://192.168.1.x:4533", text: $navidrome.serverURL)
                            .fieldStyle()
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }

                    // Insecure HTTP toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow Insecure HTTP")
                                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            Text("Only enable for a trusted local, LAN, or Tailscale server.")
                                .font(.caption2).foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $allowInsecureHTTP)
                            .labelsHidden()
                            .tint(hyloYellow)
                            .onChange(of: allowInsecureHTTP) { val in
                                UserDefaults.standard.set(val, forKey: "hylo_insecure")
                            }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)

                    // Username
                    formField(label: "USERNAME", hint: nil) {
                        TextField("Username", text: $navidrome.username)
                            .fieldStyle()
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    // Password
                    formField(label: "PASSWORD", hint: nil) {
                        SecureField("Password", text: $navidrome.password)
                            .fieldStyle()
                    }

                    // Connection result banner
                    if let result = connectionResult {
                        HStack(spacing: 10) {
                            Image(systemName: result.icon)
                                .foregroundColor(result.color)
                            Text(result.message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(result.color.opacity(0.15))
                        .cornerRadius(12)
                    }

                    // Connect button
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView().tint(.black)
                            } else {
                                Text("Connect to Server")
                                    .font(.headline).foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hyloYellow)
                        .cornerRadius(14)
                    }
                    .disabled(isTestingConnection || navidrome.serverURL.isEmpty || navidrome.username.isEmpty)
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Test connection

    private func testConnection() {
        isTestingConnection = true
        connectionResult = nil
        NavidromeService.shared.testConnection { success, message in
            self.isTestingConnection = false
            if success {
                self.connectionResult = .success
            } else {
                self.connectionResult = .failure(message ?? "Connection failed.")
            }
        }
    }

    // MARK: - Form field builder

    @ViewBuilder
    private func formField<Content: View>(label: String, hint: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption2).fontWeight(.bold).foregroundColor(.gray)
            content()
            if let hint = hint {
                Text(hint).font(.caption2).foregroundColor(.gray)
            }
        }
    }
}

// MARK: - CapsulePill

struct CapsulePill: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
    }
}

// MARK: - TextField style helper

private extension View {
    func fieldStyle() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}
