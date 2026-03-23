import SwiftUI

struct CommentsSheet: View {
    @EnvironmentObject var authManager: AuthManager
    let post: Post

    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Theme.accent)
                        Spacer()
                    } else if comments.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.muted.opacity(0.4))
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                            Text("Be the first to reply.")
                                .font(.caption)
                                .foregroundColor(Theme.muted.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        commentsList
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadComments()
            }
        }
    }

    private var commentsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
            .padding(.top, 8)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let url = URL(string: comment.authorAvatar), !comment.authorAvatar.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    commentInitials(comment.authorName)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                commentInitials(comment.authorName)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(comment.authorName.isEmpty ? "Anonymous" : comment.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.foreground)
                    Text(relativeTime(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(Theme.foreground.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func commentInitials(_ name: String) -> some View {
        Circle()
            .fill(Theme.cardHover)
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.accent)
            )
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack(spacing: 12) {
                TextField("", text: $newComment, prompt: Text("Add a comment...").foregroundColor(Theme.muted.opacity(0.6)))
                    .foregroundColor(Theme.foreground)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )

                Button {
                    Task { await sendComment() }
                } label: {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(
                                newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Theme.muted.opacity(0.3)
                                : Theme.accent
                            )
                    }
                }
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bg)
        }
    }

    // MARK: - Helpers

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

    private func loadComments() async {
        guard let postId = post.id else { return }
        do {
            let fetched = try await PostService.getComments(postId: postId)
            withAnimation {
                comments = fetched
                isLoading = false
            }
        } catch {
            isLoading = false
        }
    }

    private func sendComment() async {
        guard let postId = post.id,
              let user = authManager.user else { return }

        let text = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        let commentText = text
        newComment = ""

        do {
            let commentId = try await PostService.addComment(
                postId: postId,
                authorId: user.uid,
                authorName: user.displayName ?? "",
                authorAvatar: user.photoURL?.absoluteString ?? "",
                content: commentText
            )

            let newC = Comment(
                id: commentId,
                postId: postId,
                authorId: user.uid,
                authorName: user.displayName ?? "",
                authorAvatar: user.photoURL?.absoluteString ?? "",
                content: commentText,
                createdAt: Date()
            )

            withAnimation(.spring(response: 0.3)) {
                comments.append(newC)
            }
        } catch {
            newComment = commentText
        }

        isSending = false
    }
}
