import SwiftUI

struct CommunityDetailView: View {
    let community: Community
    @EnvironmentObject private var authManager: AuthManager
    @State private var posts: [CommunityPost] = []
    @State private var isMember = false
    @State private var isLoadingMembership = true
    @State private var isLoadingPosts = true
    @State private var isJoining = false
    @State private var showCreatePost = false
    @State private var selectedPost: CommunityPost?

    private var currentUserId: String { authManager.user?.uid ?? "" }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    communityHeader
                    postsFeed
                }
            }
        }
        .navigationTitle(community.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if isMember {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CommunityCreatePostSheet(community: community) {
                loadPosts()
            }
        }
        .sheet(item: $selectedPost) { post in
            CommunityCommentsSheet(community: community, post: post)
        }
        .task {
            await loadAll()
        }
    }

    // MARK: - Header

    private var communityHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            RoundedRectangle(cornerRadius: Theme.radiusXl, style: .continuous)
                .fill(Theme.accentSoft)
                .frame(width: 72, height: 72)
                .overlay(
                    Text(String(community.name.prefix(1)).uppercased())
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.accent)
                )

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(community.name)
                        .font(.title2.bold())
                        .foregroundColor(Theme.foreground)

                    Image(systemName: community.type.icon)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                if !community.description.isEmpty {
                    Text(community.description)
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            // Stats
            HStack(spacing: 24) {
                StatPill(icon: "person.2", value: "\(community.memberCount)", label: "Members")
                StatPill(icon: "text.bubble", value: "\(community.postCount)", label: "Posts")

                if !community.category.isEmpty {
                    StatPill(icon: "tag", value: community.category, label: "Category")
                }
            }

            // Join / Leave
            if !isLoadingMembership {
                Button {
                    toggleMembership()
                } label: {
                    HStack(spacing: 8) {
                        if isJoining {
                            ProgressView()
                                .tint(isMember ? Theme.foreground : .white)
                                .scaleEffect(0.8)
                        }
                        Text(isMember ? "Leave Community" : "Join Community")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(isMember ? Theme.foreground : .white)
                    .background(isMember ? Theme.card : Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                            .stroke(isMember ? Theme.border : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(isJoining || community.ownerId == currentUserId)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.card)
    }

    // MARK: - Posts Feed

    private var postsFeed: some View {
        LazyVStack(spacing: 12) {
            if isLoadingPosts {
                ProgressView()
                    .tint(Theme.accent)
                    .padding(.top, 40)
            } else if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.muted.opacity(0.25))
                    Text("No posts yet")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)

                    if isMember {
                        Text("Be the first to post something")
                            .font(.caption)
                            .foregroundColor(Theme.muted.opacity(0.7))
                    }
                }
                .padding(.top, 40)
            } else {
                ForEach(posts) { post in
                    PostCard(post: post, currentUserId: currentUserId, communityId: community.id ?? "") {
                        selectedPost = post
                    } onLike: {
                        toggleLike(post: post)
                    }
                }
            }
        }
        .padding(16)
    }

    // MARK: - Data Loading

    private func loadAll() async {
        guard let communityId = community.id else { return }

        async let memberCheck: () = checkMembership(communityId: communityId)
        async let postsLoad: () = loadPostsAsync(communityId: communityId)

        _ = await (memberCheck, postsLoad)
    }

    private func checkMembership(communityId: String) async {
        do {
            let result = try await CommunityService.shared.isMember(communityId: communityId, userId: currentUserId)
            await MainActor.run {
                isMember = result
                isLoadingMembership = false
            }
        } catch {
            await MainActor.run { isLoadingMembership = false }
        }
    }

    private func loadPostsAsync(communityId: String) async {
        do {
            let result = try await CommunityService.shared.getPosts(communityId: communityId)
            await MainActor.run {
                posts = result
                isLoadingPosts = false
            }
        } catch {
            await MainActor.run { isLoadingPosts = false }
        }
    }

    private func loadPosts() {
        guard let communityId = community.id else { return }
        Task {
            do {
                let result = try await CommunityService.shared.getPosts(communityId: communityId)
                posts = result
            } catch {}
        }
    }

    private func toggleMembership() {
        guard let communityId = community.id else { return }
        isJoining = true

        Task {
            do {
                if isMember {
                    try await CommunityService.shared.leaveCommunity(communityId: communityId, userId: currentUserId)
                } else {
                    try await CommunityService.shared.joinCommunity(communityId: communityId, userId: currentUserId)
                }
                withAnimation { isMember.toggle() }
            } catch {}
            isJoining = false
        }
    }

    private func toggleLike(post: CommunityPost) {
        guard let communityId = community.id, let postId = post.id else { return }
        Task {
            do {
                let liked = try await CommunityService.shared.toggleLike(communityId: communityId, postId: postId, userId: currentUserId)
                if let idx = posts.firstIndex(where: { $0.id == postId }) {
                    posts[idx].likes += liked ? 1 : -1
                }
            } catch {}
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.subheadline.bold())
            }
            .foregroundColor(Theme.foreground)

            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
    }
}

// MARK: - Post Card

private struct PostCard: View {
    let post: CommunityPost
    let currentUserId: String
    let communityId: String
    let onComment: () -> Void
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack(spacing: 10) {
                Circle()
                    .fill(Theme.cardHover)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(post.authorName.prefix(1)).uppercased())
                            .font(.caption.bold())
                            .foregroundColor(Theme.accent)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorName)
                        .font(.caption.bold())
                        .foregroundColor(Theme.foreground)

                    if let date = post.createdAt {
                        Text(date.relativeFormatted)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                }

                Spacer()

                // Post type badge
                HStack(spacing: 4) {
                    Image(systemName: post.type.icon)
                    Text(post.type.label)
                }
                .font(.caption2.bold())
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.accentSoft)
                .clipShape(Capsule())
            }

            // Title
            Text(post.title)
                .font(.subheadline.bold())
                .foregroundColor(Theme.foreground)

            // Content
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .lineLimit(4)
            }

            // Tags
            if !post.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(post.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(Theme.accent.opacity(0.8))
                    }
                }
            }

            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    Label("\(post.likes)", systemImage: "heart")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                Button(action: onComment) {
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                Spacer()

                if post.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Create Post Sheet

private struct CommunityCreatePostSheet: View {
    let community: Community
    let onCreated: () -> Void
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var postType: CommunityPost.PostType = .discussion
    @State private var tagsText = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Post type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.caption.bold())
                                .foregroundColor(Theme.muted)

                            Picker("Type", selection: $postType) {
                                ForEach(CommunityPost.PostType.allCases, id: \.self) { type in
                                    Label(type.label, systemImage: type.icon).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.accent)
                        }

                        TogeTextField(placeholder: "Post title", text: $title)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.caption.bold())
                                .foregroundColor(Theme.muted)

                            TextEditor(text: $content)
                                .font(.body)
                                .foregroundColor(Theme.foreground)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }

                        TogeTextField(placeholder: "Tags (comma separated)", text: $tagsText, icon: "tag")

                        Button {
                            createPost()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                }
                                Text("Post")
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .background(title.isEmpty ? Theme.muted.opacity(0.3) : Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(title.isEmpty || isCreating)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
        }
    }

    private func createPost() {
        guard let communityId = community.id, let user = authManager.user else { return }
        isCreating = true
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        Task {
            do {
                _ = try await CommunityService.shared.createPost(
                    communityId: communityId,
                    authorId: user.uid,
                    authorName: user.displayName ?? "User",
                    authorAvatar: user.photoURL?.absoluteString ?? "",
                    type: postType,
                    title: title,
                    content: content,
                    tags: tags
                )
                onCreated()
                dismiss()
            } catch {
                isCreating = false
            }
        }
    }
}

// MARK: - Comments Sheet

private struct CommunityCommentsSheet: View {
    let community: Community
    let post: CommunityPost
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [Comment] = []
    @State private var commentText = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Post preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text(post.title)
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.foreground)
                        Text(post.content)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.card)

                    Divider().overlay(Theme.border)

                    // Comments
                    if isLoading {
                        Spacer()
                        ProgressView().tint(Theme.accent)
                        Spacer()
                    } else if comments.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.muted.opacity(0.25))
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                            .padding(16)
                        }
                    }

                    Divider().overlay(Theme.border)

                    // Input
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $commentText)
                            .font(.body)
                            .foregroundColor(Theme.foreground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                        Button {
                            sendComment()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.muted.opacity(0.3) : Theme.accent)
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .task { loadComments() }
        }
    }

    private func loadComments() {
        guard let communityId = community.id, let postId = post.id else { return }
        Task {
            do {
                comments = try await CommunityService.shared.getComments(communityId: communityId, postId: postId)
            } catch {}
            isLoading = false
        }
    }

    private func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let communityId = community.id, let postId = post.id, let user = authManager.user else { return }
        commentText = ""
        isSending = true

        Task {
            do {
                try await CommunityService.shared.addComment(
                    communityId: communityId,
                    postId: postId,
                    authorId: user.uid,
                    authorName: user.displayName ?? "User",
                    authorAvatar: user.photoURL?.absoluteString ?? "",
                    content: text
                )
                loadComments()
            } catch {}
            isSending = false
        }
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.cardHover)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.authorName.prefix(1)).uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(Theme.accent)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.caption.bold())
                        .foregroundColor(Theme.foreground)

                    if let date = comment.createdAt {
                        Text(date.relativeFormatted)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(Theme.foreground.opacity(0.9))
            }

            Spacer()
        }
    }
}
