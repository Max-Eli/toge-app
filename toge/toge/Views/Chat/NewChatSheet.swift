import SwiftUI
import FirebaseFirestore

struct NewChatSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [UserResult] = []
    @State private var isSearching = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.muted)

                        TextField("", text: $searchText, prompt: Text("Search by name or email").foregroundColor(Theme.muted.opacity(0.6)))
                            .foregroundColor(Theme.foreground)
                            .font(.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { searchUsers() }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.destructive)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if isSearching {
                        Spacer()
                        ProgressView()
                            .tint(Theme.accent)
                        Spacer()
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.muted.opacity(0.3))
                            Text("No users found")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                        }
                        Spacer()
                    } else if searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.muted.opacity(0.3))
                            Text("Search for a user to start chatting")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(searchResults) { user in
                                    UserRow(user: user) {
                                        startChat(with: user)
                                    }
                                }
                            }
                            .padding(.top, 12)
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(ProgressView().tint(Theme.accent))
                }
            }
        }
    }

    // MARK: - Search

    private func searchUsers() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil

        Task {
            do {
                let currentUid = authManager.user?.uid ?? ""

                // Search by displayName
                let snap = try await db.collection("users")
                    .whereField("displayName", isGreaterThanOrEqualTo: query)
                    .whereField("displayName", isLessThanOrEqualTo: query + "\u{f8ff}")
                    .limit(to: 20)
                    .getDocuments()

                let results = snap.documents.compactMap { doc -> UserResult? in
                    let data = doc.data()
                    let uid = doc.documentID
                    guard uid != currentUid else { return nil }
                    return UserResult(
                        id: uid,
                        displayName: data["displayName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageURL: data["profileImageURL"] as? String ?? ""
                    )
                }

                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed. Try again."
                    isSearching = false
                }
            }
        }
    }

    // MARK: - Create Chat

    private func startChat(with user: UserResult) {
        guard let currentUser = authManager.user else { return }
        isCreating = true

        Task {
            do {
                _ = try await ChatService.shared.createDM(
                    userId: currentUser.uid,
                    userName: currentUser.displayName ?? "User",
                    otherUserId: user.id,
                    otherUserName: user.displayName
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create chat."
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Models

private struct UserResult: Identifiable {
    let id: String
    let displayName: String
    let email: String
    let profileImageURL: String
}

// MARK: - User Row

private struct UserRow: View {
    let user: UserResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Theme.card)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(String(user.displayName.prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundColor(Theme.accent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.foreground)

                    if !user.email.isEmpty {
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.muted.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
