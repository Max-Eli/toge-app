import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let channel: ChatChannel
    @EnvironmentObject private var authManager: AuthManager
    @State private var messages: [ChatMessage] = []
    @State private var listener: ListenerRegistration?
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool

    private var currentUserId: String { authManager.user?.uid ?? "" }
    private var currentUserName: String { authManager.user?.displayName ?? "User" }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                messagesList

                Divider()
                    .overlay(Theme.border)

                inputBar
            }
        }
        .navigationTitle(channel.displayName(currentUserId: currentUserId))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let showSender = shouldShowSender(at: index)
                        let isCurrentUser = message.senderId == currentUserId

                        MessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            showSender: showSender
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastId = messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $messageText, axis: .vertical)
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
                .lineLimit(1...5)
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(canSend ? Theme.accent : Theme.muted.opacity(0.3))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.bg)
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    // MARK: - Helpers

    private func shouldShowSender(at index: Int) -> Bool {
        let message = messages[index]
        if message.senderId == currentUserId { return false }
        if index == 0 { return true }
        return messages[index - 1].senderId != message.senderId
    }

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let channelId = channel.id else { return }

        messageText = ""
        isSending = true

        Task {
            do {
                try await ChatService.shared.sendMessage(
                    channelId: channelId,
                    senderId: currentUserId,
                    senderName: currentUserName,
                    senderAvatar: authManager.user?.photoURL?.absoluteString ?? "",
                    content: content
                )
            } catch {
                messageText = content // Restore on failure
            }
            isSending = false
        }
    }

    private func startListening() {
        guard let channelId = channel.id else { return }
        listener = ChatService.shared.subscribeToMessages(channelId: channelId) { updated in
            withAnimation(.easeInOut(duration: 0.15)) {
                self.messages = updated
            }
        }
    }

    private func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let showSender: Bool

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
            if showSender {
                Text(message.senderName)
                    .font(.caption.bold())
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
            }

            HStack {
                if isCurrentUser { Spacer(minLength: 60) }

                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(isCurrentUser ? .white : Theme.foreground)

                    if let date = message.createdAt {
                        Text(date.relativeFormatted)
                            .font(.caption2)
                            .foregroundColor(isCurrentUser ? .white.opacity(0.6) : Theme.muted.opacity(0.7))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isCurrentUser ? Theme.accent : Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))

                if !isCurrentUser { Spacer(minLength: 60) }
            }
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
    }
}
