import SwiftUI
import PhotosUI

struct AddCarSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var onCarAdded: () -> Void

    // Car fields
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var trim = ""
    @State private var nickname = ""
    @State private var carDescription = ""
    @State private var engine = ""
    @State private var horsepower = ""
    @State private var torque = ""
    @State private var drivetrain = ""
    @State private var transmission = ""
    @State private var weight = ""

    // Mods
    @State private var mods: [CarMod] = []
    @State private var newModName = ""
    @State private var newModCategory = "Engine"

    // Photos
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    // State
    @State private var isSaving = false
    @State private var error: String?

    private let modCategories = [
        "Engine", "Exhaust", "Intake", "Turbo/Supercharger",
        "Suspension", "Brakes", "Wheels/Tires", "Exterior",
        "Interior", "Electronics", "Drivetrain", "Other"
    ]

    private var canSave: Bool {
        !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        basicInfoSection
                        specsSection
                        modsSection
                        photosSection

                        if let error {
                            errorBanner(error)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveCar() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canSave ? Theme.accent : Theme.muted.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task { await loadImages(from: newItems) }
            }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Basic Info", icon: "car.fill")

            fieldRow(label: "Year", text: $year, placeholder: "2024")
            fieldRow(label: "Make *", text: $make, placeholder: "Toyota")
            fieldRow(label: "Model *", text: $model, placeholder: "Supra")
            fieldRow(label: "Trim", text: $trim, placeholder: "RZ")
            fieldRow(label: "Nickname", text: $nickname, placeholder: "Give it a name")

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.muted)

                TextEditor(text: $carDescription)
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
        }
    }

    // MARK: - Specs

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Specifications", icon: "wrench.and.screwdriver")

            fieldRow(label: "Engine", text: $engine, placeholder: "2JZ-GTE")
            fieldRow(label: "Horsepower", text: $horsepower, placeholder: "320")
            fieldRow(label: "Torque (lb-ft)", text: $torque, placeholder: "315")
            fieldRow(label: "Drivetrain", text: $drivetrain, placeholder: "RWD")
            fieldRow(label: "Transmission", text: $transmission, placeholder: "6-Speed Manual")
            fieldRow(label: "Weight (lbs)", text: $weight, placeholder: "3400")
        }
    }

    // MARK: - Mods

    private var modsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Modifications", icon: "gearshape.2")

            // Existing mods
            if !mods.isEmpty {
                VStack(spacing: 6) {
                    ForEach(mods) { mod in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mod.name)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.foreground)
                                Text(mod.category)
                                    .font(.caption)
                                    .foregroundColor(Theme.accent)
                            }
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    mods.removeAll { $0.id == mod.id }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Theme.muted.opacity(0.5))
                            }
                        }
                        .padding(12)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    }
                }
            }

            // Add mod
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("", text: $newModName, prompt: Text("Mod name").foregroundColor(Theme.muted.opacity(0.6)))
                        .foregroundColor(Theme.foreground)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }

                HStack(spacing: 10) {
                    Menu {
                        ForEach(modCategories, id: \.self) { cat in
                            Button(cat) { newModCategory = cat }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(newModCategory)
                                .font(.subheadline)
                                .foregroundColor(Theme.foreground)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    }

                    Button {
                        addMod()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    }
                    .disabled(newModName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Photos", icon: "photo.on.rectangle.angled")
                Spacer()
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.accent)
                }
            }

            if selectedImages.isEmpty {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.muted.opacity(0.4))
                        Text("Tap to add photos")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                            .stroke(Theme.border.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    )
                }
            } else {
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

                                // First photo badge
                                if index == 0 {
                                    Text("Cover")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.accent)
                                        .clipShape(Capsule())
                                        .offset(x: -6, y: 6)
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedImages.remove(at: index)
                                        if index < selectedItems.count {
                                            selectedItems.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
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
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Theme.accent)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundColor(Theme.foreground)
        }
    }

    private func fieldRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.muted)

            TextField("", text: text, prompt: Text(placeholder).foregroundColor(Theme.muted.opacity(0.5)))
                .foregroundColor(Theme.foreground)
                .font(.body)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.destructive)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.destructive)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.destructive.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
    }

    private func addMod() {
        let name = newModName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        withAnimation(.spring(response: 0.3)) {
            mods.append(CarMod(name: name, category: newModCategory))
            newModName = ""
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

    private func saveCar() async {
        guard let userId = authManager.user?.uid else { return }
        isSaving = true
        error = nil

        do {
            _ = try await CarService.addCar(
                ownerId: userId,
                year: year.trimmingCharacters(in: .whitespacesAndNewlines),
                make: make.trimmingCharacters(in: .whitespacesAndNewlines),
                model: model.trimmingCharacters(in: .whitespacesAndNewlines),
                trim: trim.trimmingCharacters(in: .whitespacesAndNewlines),
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                description: carDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                horsepower: horsepower.trimmingCharacters(in: .whitespacesAndNewlines),
                torque: torque.trimmingCharacters(in: .whitespacesAndNewlines),
                engine: engine.trimmingCharacters(in: .whitespacesAndNewlines),
                drivetrain: drivetrain.trimmingCharacters(in: .whitespacesAndNewlines),
                transmission: transmission.trimmingCharacters(in: .whitespacesAndNewlines),
                weight: weight.trimmingCharacters(in: .whitespacesAndNewlines),
                mods: mods,
                photos: selectedImages
            )
            await MainActor.run {
                onCarAdded()
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}
