import SwiftUI

struct ExploreTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var posts: [Post] = []
    @State private var communities: [Community] = []
    @State private var searchQuery = ""
    @State private var isLoading = true

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]

    private var postsWithImages: [Post] {
        posts.filter { !$0.images.isEmpty }
    }

    private var filteredPosts: [Post] {
        guard !searchQuery.isEmpty else { return postsWithImages }
        return postsWithImages.filter {
            $0.content.localizedCaseInsensitiveContains(searchQuery) ||
            $0.authorName.localizedCaseInsensitiveContains(searchQuery) ||
            $0.carName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Theme.accent)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.muted)
                                TextField("", text: $searchQuery, prompt: Text("Search posts, users, cars...").foregroundColor(Theme.muted.opacity(0.6)))
                                    .foregroundColor(Theme.foreground)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                            .padding(.horizontal, 16)

                            // Trending Communities
                            if !communities.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Trending Communities")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Theme.muted)
                                        .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(communities.prefix(6)) { community in
                                                NavigationLink {
                                                    CommunityDetailView(communityId: community.id ?? "")
                                                        .environmentObject(authManager)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Circle()
                                                            .fill(Theme.accentSoft)
                                                            .frame(width: 36, height: 36)
                                                            .overlay(
                                                                Text(String(community.name.prefix(1)))
                                                                    .font(.caption.bold())
                                                                    .foregroundColor(Theme.accent)
                                                            )

                                                        Text(community.name)
                                                            .font(.caption.bold())
                                                            .foregroundColor(Theme.foreground)
                                                            .lineLimit(1)

                                                        Text("\(community.memberCount) members")
                                                            .font(.caption2)
                                                            .foregroundColor(Theme.muted)
                                                    }
                                                    .frame(width: 110)
                                                    .padding(12)
                                                    .background(Theme.card)
                                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // Photo Grid
                            if filteredPosts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(Theme.muted.opacity(0.3))
                                    Text("Nothing to explore yet")
                                        .font(.headline)
                                        .foregroundColor(Theme.foreground)
                                    Text("Posts with photos will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.muted)
                                }
                                .padding(.top, 60)
                            } else {
                                LazyVGrid(columns: columns, spacing: 4) {
                                    ForEach(filteredPosts) { post in
                                        AsyncImage(url: URL(string: post.images.first ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Rectangle().fill(Theme.card)
                                        }
                                        .frame(minHeight: 150, maxHeight: 200)
                                        .clipped()
                                        .overlay(alignment: .bottomLeading) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(post.authorName)
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.white)
                                                if !post.carName.isEmpty {
                                                    Text(post.carName)
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            .padding(8)
                                            .background(.black.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            .padding(6)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }

                            Spacer().frame(height: 80)
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            async let p = PostService.getFeedPosts(limit: 30)
            async let c = CommunityService.shared.getCommunities()
            posts = try await p
            communities = try await c
        } catch {
            print("Explore load error: \(error)")
        }
        isLoading = false
    }
}
