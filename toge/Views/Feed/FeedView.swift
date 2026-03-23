import SwiftUI
import PhotosUI

// MARK: - Relative Time Formatter
private func relativeTime(from date: Date?) -> String {
    guard let date else { return "" }
    let interval = Date().timeIntervalSince(date)
    let seconds = Int(interval)
    if seconds < 60 { return "now" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m ago" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h ago" }
    let days = hours / 24
    if days < 30 { return "\(days)d ago" }
    let months = days / 30
    if months < 12 { return "\(months)mo ago" }
    return "\(days / 365)y ago"
}

// MARK: - Feed View

struct FeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var posts: [Post] = []
    @State private var likedPostIds: Set<String> = []
    @State private var isLoading = true
    @State private var showCreatePost = false
    @State private var selectedPostForComments: Post?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if posts.isEmpty {
                    emptyState
                } else {
                    feedList
                }

                // Floating create button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreatePost = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Theme.accent)
                                        .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreatePost) {
                CreatePostSheet(onPostCreated: {
                    Task { await loadPosts() }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedPostForComments) { post in
                CommentsSheet(post: post)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await loadPosts()
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.2)
            Text("Loading feed...")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 80, height: 80)
                Image(systemName: "text.bubble")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.accent)
            }

            VStack(spacing: 8) {
                Text("No Posts Yet")
                    .font(.title3.bold())
                    .foregroundColor(Theme.foreground)
                Text("Be the first to share your build\nwith the community.")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
            }

            Button {
                showCreatePost = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Post")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 48)
                .padding(.horizontal, 28)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(posts) { post in
                    PostCard(
                        post: post,
                        isLiked: likedPostIds.contains(post.id ?? ""),
                        onLike: { await toggleLike(post) },
                        onComment: { selectedPostForComments = post }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80)
        }
        .refreshable {
            await loadPosts()
        }
    }

    // MARK: - Data Loading

    private func loadPosts() async {
        do {
            let fetched = try await PostService.getFeedPosts()
            withAnimation(.easeInOut(duration: 0.3)) {
                posts = fetched
                isLoading = false
            }

            // Check liked status for each post
            if let userId = authManager.user?.uid {
                var liked = Set<String>()
                for post in fetched {
                    if let postId = post.id,
                       try await PostService.hasUserLiked(postId: postId, userId: userId) {
                        liked.insert(postId)
                    }
                }
                withAnimation { likedPostIds = liked }
            }
        } catch {
            isLoading = false
        }
    }

    private func toggleLike(_ post: Post) async {
        guard let postId = post.id, let userId = authManager.user?.uid else { return }

        // Optimistic UI update
        let wasLiked = likedPostIds.contains(postId)
        withAnimation(.spring(response: 0.3)) {
            if wasLiked {
                likedPostIds.remove(postId)
            } else {
                likedPostIds.insert(postId)
            }

            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likes += wasLiked ? -1 : 1
            }
        }

        do {
            _ = try await PostService.toggleLike(postId: postId, userId: userId)
        } catch {
            // Revert on failure
            withAnimation {
                if wasLiked {
                    likedPostIds.insert(postId)
                } else {
                    likedPostIds.remove(postId)
                }
                if let index = posts.firstIndex(where: { $0.id == postId }) {
                    posts[index].likes += wasLiked ? 1 : -1
                }
            }
        }
    }
}

// MARK: - Post Card

private struct PostCard: View {
    let post: Post
    let isLiked: Bool
    let onLike: () async -> Void
    let onComment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                avatarView
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName.isEmpty ? "Anonymous" : post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.foreground)

                    HStack(spacing: 6) {
                        if !post.carName.isEmpty {
                            Text(post.carName)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        }
                        Text(relativeTime(from: post.createdAt))
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                }
                Spacer()
            }
            .padding(16)

            // Content
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.body)
                    .foregroundColor(Theme.foreground.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.bottom, post.images.isEmpty ? 16 : 12)
            }

            // Image grid
            if !post.images.isEmpty {
                imageGrid
                    .padding(.bottom, 4)
            }

            // Actions bar
            HStack(spacing: 0) {
                // Like button
                Button {
                    Task { await onLike() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.body)
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                        Text("\(post.likes)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .contentShape(Rectangle())

                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1, height: 20)

                // Comment button
                Button(action: onComment) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.body)
                            .foregroundColor(Theme.muted)
                        Text("\(post.commentCount)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .contentShape(Rectangle())
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var avatarView: some View {
        if let url = URL(string: post.authorAvatar), !post.authorAvatar.isEmpty {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsAvatar
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(Theme.cardHover)
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(post.authorName.prefix(1)).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundColor(Theme.accent)
            )
    }

    @ViewBuilder
    private var imageGrid: some View {
        let imageURLs = post.images
        if imageURLs.count == 1 {
            singleImage(imageURLs[0])
        } else if imageURLs.count == 2 {
            HStack(spacing: 2) {
                gridImage(imageURLs[0])
                gridImage(imageURLs[1])
            }
            .frame(height: 220)
        } else if imageURLs.count == 3 {
            HStack(spacing: 2) {
                gridImage(imageURLs[0])
                    .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    gridImage(imageURLs[1])
                    gridImage(imageURLs[2])
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 220)
        } else if imageURLs.count >= 4 {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    gridImage(imageURLs[0])
                    gridImage(imageURLs[1])
                }
                HStack(spacing: 2) {
                    gridImage(imageURLs[2])
                    ZStack {
                        gridImage(imageURLs[3])
                        if imageURLs.count > 4 {
                            Color.black.opacity(0.5)
                            Text("+\(imageURLs.count - 4)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(height: 280)
        }
    }

    private func singleImage(_ urlStr: String) -> some View {
        AsyncImage(url: URL(string: urlStr)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                imagePlaceholder
            default:
                imagePlaceholder
                    .overlay(ProgressView().tint(Theme.muted))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipped()
    }

    private func gridImage(_ urlStr: String) -> some View {
        AsyncImage(url: URL(string: urlStr)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                imagePlaceholder
            default:
                imagePlaceholder
                    .overlay(ProgressView().tint(Theme.muted))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Theme.cardHover)
    }
}
