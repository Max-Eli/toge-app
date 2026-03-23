import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var profile: UserProfile?
    @State private var cars: [CarBuild] = []
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var showEditProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Theme.accent)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            profileHeader

                            // Stats
                            statsRow

                            // Quick Actions
                            quickActions

                            // My Cars
                            if !cars.isEmpty {
                                carsSection
                            }

                            // Recent Posts
                            if !posts.isEmpty {
                                postsSection
                            }

                            // Sign Out
                            signOutButton

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarRight) {
                    Button { showEditProfile = true } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Theme.foreground)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(profile: profile) { loadData() }
                    .environmentObject(authManager)
            }
            .task { loadData() }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let url = profile?.profileImageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialCircle
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
            } else {
                initialCircle
            }

            VStack(spacing: 4) {
                Text(profile?.displayName ?? authManager.user?.displayName ?? "User")
                    .font(.title2.bold())
                    .foregroundColor(Theme.foreground)

                if let username = profile?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(Theme.accent)
                }

                Text(profile?.email ?? authManager.user?.email ?? "")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }

            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let location = profile?.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(Theme.muted)
            }
        }
    }

    private var initialCircle: some View {
        Circle()
            .fill(Theme.card)
            .frame(width: 90, height: 90)
            .overlay(
                Text(String(profile?.displayName.prefix(1) ?? authManager.user?.displayName?.prefix(1) ?? "?"))
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.accent)
            )
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(cars.count)", label: "Cars")
            Divider().frame(height: 30).background(Theme.border)
            statItem(value: "\(posts.count)", label: "Posts")
        }
        .padding(.vertical, 16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous).stroke(Theme.border, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(Theme.foreground)
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink { CommunitiesView().environmentObject(authManager) } label: {
                    quickActionButton(icon: "person.3", label: "Communities")
                }
                NavigationLink { EventsView().environmentObject(authManager) } label: {
                    quickActionButton(icon: "calendar", label: "Events")
                }
                NavigationLink { MarketplaceView().environmentObject(authManager) } label: {
                    quickActionButton(icon: "cart", label: "Marketplace")
                }
                NavigationLink { VideosView().environmentObject(authManager) } label: {
                    quickActionButton(icon: "play.rectangle", label: "Videos")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func quickActionButton(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.accent)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
        .frame(width: 80, height: 70)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private var carsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Cars")
                .font(.headline)
                .foregroundColor(Theme.foreground)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cars) { car in
                        VStack(alignment: .leading, spacing: 8) {
                            if !car.coverPhoto.isEmpty {
                                AsyncImage(url: URL(string: car.coverPhoto)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Theme.cardHover)
                                }
                                .frame(width: 160, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                                    .fill(Theme.cardHover)
                                    .frame(width: 160, height: 100)
                                    .overlay(Image(systemName: "car.fill").foregroundColor(Theme.muted))
                            }

                            Text(car.nickname.isEmpty ? "\(car.year) \(car.make) \(car.model)" : car.nickname)
                                .font(.caption.bold())
                                .foregroundColor(Theme.foreground)
                                .lineLimit(1)

                            Text("\(car.year) \(car.make) \(car.model)")
                                .font(.caption2)
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Posts")
                .font(.headline)
                .foregroundColor(Theme.foreground)
                .padding(.horizontal, 16)

            ForEach(posts.prefix(3)) { post in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundColor(Theme.foreground)
                        .lineLimit(3)

                    HStack(spacing: 12) {
                        Label("\(post.likes)", systemImage: "heart")
                        Label("\(post.commentCount)", systemImage: "bubble.right")
                    }
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                .padding(.horizontal, 16)
            }
        }
    }

    private var signOutButton: some View {
        Button {
            authManager.signOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.destructive.opacity(0.15))
            .foregroundColor(Theme.destructive)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        }
        .padding(.horizontal, 16)
    }

    private func loadData() {
        guard let uid = authManager.user?.uid else { return }
        Task {
            isLoading = true
            do {
                async let p = UserService.getUserProfile(uid: uid)
                async let c = CarService.getUserCars(userId: uid)
                async let po = PostService.getFeedPosts(limit: 10)
                profile = try await p
                cars = try await c
                let allPosts = try await po
                posts = allPosts.filter { $0.authorId == uid }
            } catch {
                print("Profile load error: \(error)")
            }
            isLoading = false
        }
    }
}
