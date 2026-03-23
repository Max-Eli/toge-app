import SwiftUI
import PhotosUI

struct CreateListingSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    var onCreated: () -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var condition = "Used"
    @State private var category = "Other"
    @State private var carFitment = ""
    @State private var location = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataList: [Data] = []
    @State private var isSubmitting = false

    private let conditions = ["New", "Like New", "Used", "Fair"]
    private let categories = ["Engine", "Suspension", "Wheels & Tires", "Exterior", "Interior", "Electronics", "Other"]

    private var canSubmit: Bool {
        !title.isEmpty && !description.isEmpty && !price.isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Photos
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                            if photoDataList.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.title)
                                        .foregroundColor(Theme.muted)
                                    Text("Add Photos (up to 5)")
                                        .font(.caption)
                                        .foregroundColor(Theme.muted)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(photoDataList.enumerated()), id: \.offset) { _, data in
                                            if let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedPhotos) { _, newValue in
                            Task {
                                photoDataList = []
                                for item in newValue {
                                    if let data = try? await item.loadTransferable(type: Data.self) {
                                        photoDataList.append(data)
                                    }
                                }
                            }
                        }

                        // Form Fields
                        VStack(spacing: 16) {
                            TogeTextField(placeholder: "Title", text: $title, icon: "tag")
                            TogeTextField(placeholder: "Price", text: $price, icon: "dollarsign")
                                .keyboardType(.decimalPad)
                            TogeTextField(placeholder: "Car Fitment (e.g. 2020 Supra)", text: $carFitment, icon: "car")
                            TogeTextField(placeholder: "Location", text: $location, icon: "mappin")

                            // Description
                            TextEditor(text: $description)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(Theme.foreground)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                                .overlay(alignment: .topLeading) {
                                    if description.isEmpty {
                                        Text("Description")
                                            .foregroundColor(Theme.muted.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }

                            // Condition Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Condition")
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                HStack(spacing: 8) {
                                    ForEach(conditions, id: \.self) { c in
                                        Button { condition = c } label: {
                                            Text(c)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(condition == c ? Theme.accent : Theme.card)
                                                .foregroundColor(condition == c ? .white : Theme.muted)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(condition == c ? Color.clear : Theme.border, lineWidth: 1))
                                        }
                                    }
                                }
                            }

                            // Category Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(categories, id: \.self) { cat in
                                            Button { category = cat } label: {
                                                Text(cat)
                                                    .font(.caption.bold())
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(category == cat ? Theme.accent : Theme.card)
                                                    .foregroundColor(category == cat ? .white : Theme.muted)
                                                    .clipShape(Capsule())
                                                    .overlay(Capsule().stroke(category == cat ? Color.clear : Theme.border, lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Submit
                        Button {
                            Task { await createListing() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                }
                                Text("Create Listing")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canSubmit ? Theme.accent : Theme.accent.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(!canSubmit)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Listing")
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

    private func createListing() async {
        guard let user = authManager.user else { return }
        isSubmitting = true
        do {
            _ = try await MarketplaceService.createListing(
                sellerId: user.uid,
                sellerName: user.displayName ?? "User",
                sellerAvatar: user.photoURL?.absoluteString ?? "",
                title: title,
                description: description,
                price: Double(price) ?? 0,
                condition: condition,
                category: category,
                carFitment: carFitment,
                location: location,
                imageData: photoDataList
            )
            onCreated()
            dismiss()
        } catch {
            print("Create listing error: \(error)")
        }
        isSubmitting = false
    }
}
