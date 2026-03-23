import SwiftUI
import FirebaseFirestore

struct ChatListView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var channels: [ChatChannel] = []
    @State private var listener: ListenerRegistration?
    @State private var searchText = ""
    @State private var showNewChat = false
    @State private var isLoading = true

    private var filteredChannels: [ChatChannel] {
        guard !searchText.isEmpty else { return channels }
        let currentUserId = authManager.user?.uid ?? ""
        return channels.filter {
            $0.displayName(currentUserId: currentUserId)
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                } else if channels.isEmpty {
                    emptyState
                } else {
                    channelsList
                }
            }
            .navigationTitle("Messages")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search conversations")
            .sheet(isPresented: $showNewChat) {
                NewChatSheet()
            }
            .onAppear { startListening() }
            .onDisappear { stopListening() }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundColor(Theme.muted.opacity(0.25))

            Text("No conversations yet")
                .font(.title3.bold())
                .foregroundColor(Theme.foreground)

            Text("Start a chat with someone from the community")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showNewChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("New Message")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Channels List

    private var channelsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredChannels) { channel in
                    NavigationLink(destination: ChatView(channel: channel)) {
                        ChannelRow(channel: channel, currentUserId: authManager.user?.uid ?? "")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Listener

    private func startListening() {
        guard let userId = authManager.user?.uid else { return }
        listener = ChatService.shared.subscribeToChannels(userId: userId) { updated in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.channels = updated
                self.isLoading = false
            }
        }
    }

    private func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Channel Row

private struct ChannelRow: View {
    let channel: ChatChannel
    let currentUserId: String

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(channel.type == .group ? Theme.accentSoft : Theme.card)
                    .frame(width: 52, height: 52)

                if channel.type == .group {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.accent)
                } else {
                    Text(avatarInitial)
                        .font(.title3.bold())
                        .foregroundColor(Theme.accent)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(channel.displayName(currentUserId: currentUserId))
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.foreground)
                        .lineLimit(1)

                    Spacer()

                    if let date = channel.lastMessageAt {
                        Text(date.relativeFormatted)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                }

                HStack(spacing: 6) {
                    if channel.type == .group {
                        Image(systemName: "person.3")
                            .font(.caption2)
                            .foregroundColor(Theme.muted.opacity(0.6))
                    }

                    Text(channel.lastMessage.isEmpty ? "No messages yet" : channel.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bg)
        .contentShape(Rectangle())
    }

    private var avatarInitial: String {
        String(channel.displayName(currentUserId: currentUserId).prefix(1)).uppercased()
    }
}

// MARK: - Relative Date Formatting

extension Date {
    var relativeFormatted: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }

        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDate(self, equalTo: now, toGranularity: .year) ? "MMM d" : "MMM d, yy"
        return formatter.string(from: self)
    }
}
