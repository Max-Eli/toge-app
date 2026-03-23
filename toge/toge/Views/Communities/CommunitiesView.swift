import SwiftUI

struct CommunitiesView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var communities: [Community] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showCreateSheet = false

    private var filteredCommunities: [Community] {
        guard !searchText.isEmpty else { return communities }
        return communities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                } else if communities.isEmpty {
                    emptyState
                } else {
                    communitiesList
                }
            }
            .navigationTitle("Communities")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search communities")
            .sheet(isPresented: $showCreateSheet) {
                CreateCommunitySheet {
                    loadCommunities()
                }
            }
            .task { loadCommunities() }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 56))
                .foregroundColor(Theme.muted.opacity(0.25))

            Text("No communities yet")
                .font(.title3.bold())
                .foregroundColor(Theme.foreground)

            Text("Be the first to create a community\nfor car enthusiasts")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)

            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Community")
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

    // MARK: - Communities List

    private var communitiesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCommunities) { community in
                    NavigationLink(destination: CommunityDetailView(community: community)) {
                        CommunityCard(community: community)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func loadCommunities() {
        Task {
            do {
                let result = try await CommunityService.shared.getCommunities()
                withAnimation(.easeInOut(duration: 0.2)) {
                    communities = result
                    isLoading = false
                }
            } catch {
                isLoading = false
            }
        }
    }
}

// MARK: - Community Card

private struct CommunityCard: View {
    let community: Community

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(community.name.prefix(1)).uppercased())
                            .font(.title3.bold())
                            .foregroundColor(Theme.accent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(community.name)
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.foreground)
                            .lineLimit(1)

                        Image(systemName: community.type.icon)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }

                    HStack(spacing: 12) {
                        Label("\(community.memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(Theme.muted)

                        Label("\(community.postCount)", systemImage: "text.bubble")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                }

                Spacer()

                // Category Badge
                if !community.category.isEmpty {
                    Text(community.category)
                        .font(.caption2.bold())
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.accentSoft)
                        .clipShape(Capsule())
                }
            }

            // Description
            if !community.description.isEmpty {
                Text(community.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
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
