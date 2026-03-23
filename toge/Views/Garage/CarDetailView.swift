import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let car: CarBuild
    var onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private var isOwner: Bool {
        authManager.user?.uid == car.ownerId
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage
                    carInfoSection
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Car", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.foreground)
                    }
                }
            }
        }
        .alert("Delete Car", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if let carId = car.id {
                        try? await CarService.deleteCar(carId)
                        onDelete()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this car? This action cannot be undone.")
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = URL(string: car.coverPhoto), !car.coverPhoto.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        heroPlaceholder
                    }
                }
            } else {
                heroPlaceholder
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Theme.bg.opacity(0.8), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )

            // Title overlay
            VStack(alignment: .leading, spacing: 6) {
                if !car.nickname.isEmpty {
                    Text("\"\(car.nickname)\"")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Theme.accent)
                }
                Text(car.displayTitle)
                    .font(.title.weight(.heavy))
                    .foregroundColor(Theme.foreground)

                if !car.trim.isEmpty {
                    Text(car.trim)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(20)
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var heroPlaceholder: some View {
        ZStack {
            Theme.card
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.muted.opacity(0.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Car Info Section

    private var carInfoSection: some View {
        VStack(spacing: 20) {
            // Description
            if !car.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("About")
                    Text(car.description)
                        .font(.body)
                        .foregroundColor(Theme.foreground.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
            }

            // Specs grid
            specsGrid
                .padding(.horizontal, 20)

            // Photo gallery
            if car.photos.count > 1 {
                photoGallery
            }

            // Mods list
            if !car.mods.isEmpty {
                modsSection
                    .padding(.horizontal, 20)
            }

            Spacer().frame(height: 40)
        }
        .padding(.top, 4)
    }

    // MARK: - Specs Grid

    private var specsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Specifications")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                specCard(icon: "calendar", label: "Year", value: car.year)
                specCard(icon: "building.2", label: "Make", value: car.make)
                specCard(icon: "car", label: "Model", value: car.model)
                specCard(icon: "sparkle", label: "Trim", value: car.trim)
                specCard(icon: "engine.combustion", label: "Engine", value: car.engine)
                specCard(icon: "bolt.fill", label: "Horsepower", value: car.horsepower.isEmpty ? "--" : "\(car.horsepower) HP")
                specCard(icon: "arrow.triangle.2.circlepath", label: "Torque", value: car.torque.isEmpty ? "--" : "\(car.torque) lb-ft")
                specCard(icon: "gearshape.2", label: "Drivetrain", value: car.drivetrain)
                specCard(icon: "gearshift.layout.sixspeed", label: "Transmission", value: car.transmission)
                specCard(icon: "scalemass", label: "Weight", value: car.weight.isEmpty ? "--" : "\(car.weight) lbs")
            }
        }
    }

    private func specCard(icon: String, label: String, value: String) -> some View {
        let displayValue = value.isEmpty ? "--" : value

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.muted)
            }

            Text(displayValue)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Photo Gallery

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Gallery")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(car.photos, id: \.self) { urlStr in
                        AsyncImage(url: URL(string: urlStr)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Theme.cardHover
                                    .overlay(ProgressView().tint(Theme.muted))
                            }
                        }
                        .frame(width: 200, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Mods Section

    private var modsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Modifications")

            let grouped = Dictionary(grouping: car.mods, by: { $0.category })
            let sortedCategories = grouped.keys.sorted()

            ForEach(sortedCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.accent)

                    ForEach(grouped[category] ?? []) { mod in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 6, height: 6)
                            Text(mod.name)
                                .font(.subheadline)
                                .foregroundColor(Theme.foreground.opacity(0.9))
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundColor(Theme.foreground)
    }
}
