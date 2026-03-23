import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Feed")
                }
                .tag(0)

            ExploreTabView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)

            GarageView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "car.fill" : "car")
                    Text("Garage")
                }
                .tag(2)

            ChatListView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("Chat")
                }
                .tag(3)

            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(Theme.accent)
    }
}
