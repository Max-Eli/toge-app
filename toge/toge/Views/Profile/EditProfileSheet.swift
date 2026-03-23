import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    var profile: UserProfile?
    var onSave: () -> Void

    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Photo Picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else if let url = profile?.profileImageURL, !url.isEmpty {
                                AsyncImage(url: URL(string: url)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    placeholderCircle
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                            } else {
                                placeholderCircle
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    photoData = data
                                }
                            }
                        }

                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(Theme.muted)

                        VStack(spacing: 16) {
                            TogeTextField(placeholder: "Display Name", text: $displayName, icon: "person")
                            TogeTextField(placeholder: "Username", text: $username, icon: "at")
                            TogeTextField(placeholder: "Bio", text: $bio, icon: "text.quote")
                            TogeTextField(placeholder: "Location", text: $location, icon: "mappin")
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(Theme.accent)
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                displayName = profile?.displayName ?? ""
                username = profile?.username ?? ""
                bio = profile?.bio ?? ""
                location = profile?.location ?? ""
            }
        }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Theme.card)
            .frame(width: 90, height: 90)
            .overlay(
                Image(systemName: "camera")
                    .font(.title2)
                    .foregroundColor(Theme.muted)
            )
    }

    private func save() async {
        guard let uid = authManager.user?.uid else { return }
        isSaving = true
        do {
            var profileImageURL: String?
            if let photoData {
                profileImageURL = try await StorageService.uploadImage(data: photoData, path: "users/\(uid)/profile")
            }

            var data: [String: Any] = [
                "displayName": displayName,
                "username": username,
                "bio": bio,
                "location": location,
            ]
            if let profileImageURL {
                data["profileImageURL"] = profileImageURL
            }

            try await UserService.updateUserProfile(uid: uid, data: data)
            onSave()
            dismiss()
        } catch {
            print("Save profile error: \(error)")
        }
        isSaving = false
    }
}
