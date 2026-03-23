import SwiftUI

struct CreateCommunitySheet: View {
    var onCreated: (() -> Void)? = nil
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var communityType: Community.CommunityType = .public
    @State private var category = ""
    @State private var rulesText = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let categories = ["JDM", "Euro", "American", "Trucks", "Off-Road", "Luxury", "Classic", "EV", "Motorsport", "General"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Community Name")
                            TogeTextField(placeholder: "e.g. R32 GT-R Owners", text: $name)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Description")
                            TextEditor(text: $description)
                                .font(.body)
                                .foregroundColor(Theme.foreground)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Visibility")
                            Picker("Type", selection: $communityType) {
                                ForEach(Community.CommunityType.allCases, id: \.self) { type in
                                    Label(type.label, systemImage: type.icon).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.accent)

                            Text(communityType == .public ? "Anyone can join and view posts" : "Members must be approved to join")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Category")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        CategoryChip(
                                            title: cat,
                                            isSelected: category == cat
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                category = category == cat ? "" : cat
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Rules
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Rules (optional, one per line)")
                            TextEditor(text: $rulesText)
                                .font(.body)
                                .foregroundColor(Theme.foreground)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                        }

                        // Create Button
                        Button {
                            createCommunity()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                }
                                Text("Create Community")
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundColor(.white)
                            .background(isValid ? Theme.accent : Theme.muted.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(!isValid || isCreating)
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Community")
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

    private func createCommunity() {
        guard let user = authManager.user, isValid else { return }
        isCreating = true
        errorMessage = nil

        let rules = rulesText.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        Task {
            do {
                _ = try await CommunityService.shared.createCommunity(
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    type: communityType,
                    category: category,
                    ownerId: user.uid,
                    ownerName: user.displayName ?? "User",
                    rules: rules
                )
                onCreated?()
                dismiss()
            } catch {
                errorMessage = "Failed to create community. Please try again."
                isCreating = false
            }
        }
    }
}

// MARK: - Helpers

private struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(Theme.muted)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : Theme.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accent : Theme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
