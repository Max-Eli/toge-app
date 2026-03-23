import SwiftUI
import PhotosUI

struct CreatePostSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var onPostCreated: () -> Void

    @State private var content = ""
    @State private var carName = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isPosting = false
    @State private var error: String?

    private var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPosting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's happening?")
                                .font(.subheadline.weight(.medium))
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

                        // Car name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tag your car (optional)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Theme.muted)

                            HStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                                    .frame(width: 20)

                                TextField("", text: $carName, prompt: Text("e.g. '95 Supra RZ").foregroundColor(Theme.muted.opacity(0.6)))
                                    .foregroundColor(Theme.foreground)
                                    .font(.body)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                        }

                        // Photos section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Photos")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Theme.muted)
                                Spacer()
                                PhotosPicker(
                                    selection: $selectedItems,
                                    maxSelectionCount: 6,
                                    matching: .images
                                ) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                        Text("Add Photos")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Theme.accent)
                                }
                            }

                            if !selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(selectedImages.indices, id: \.self) { index in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: selectedImages[index])
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 110, height: 110)
                                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                                            .stroke(Theme.border, lineWidth: 1)
                                                    )

                                                Button {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        selectedImages.remove(at: index)
                                                        if index < selectedItems.count {
                                                            selectedItems.remove(at: index)
                                                        }
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 24, height: 24)
                                                        .background(Circle().fill(Color.black.opacity(0.7)))
                                                }
                                                .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                        // Error
                        if let error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.destructive)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.destructive)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.destructive.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createPost() }
                    } label: {
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canPost ? Theme.accent : Theme.muted.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    .disabled(!canPost)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task { await loadImages(from: newItems) }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        await MainActor.run {
            selectedImages = images
        }
    }

    private func createPost() async {
        guard let user = authManager.user else { return }
        isPosting = true
        error = nil

        do {
            _ = try await PostService.createPost(
                authorId: user.uid,
                authorName: user.displayName ?? "",
                authorAvatar: user.photoURL?.absoluteString ?? "",
                carName: carName.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                images: selectedImages
            )
            await MainActor.run {
                onPostCreated()
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isPosting = false
            }
        }
    }
}
