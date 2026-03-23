import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                // Splash / loading
                ZStack {
                    Theme.bg.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("峠")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(Theme.accent)
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
            } else if authManager.isSignedIn {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isSignedIn)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
}
