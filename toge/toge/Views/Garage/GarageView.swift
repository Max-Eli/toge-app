import SwiftUI

struct GarageView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var cars: [CarBuild] = []
    @State private var isLoading = true
    @State private var showAddCar = false
    @State private var selectedCar: CarBuild?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if cars.isEmpty {
                    emptyState
                } else {
                    garageGrid
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddCar = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Theme.accent)
                                        .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("My Garage")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedCar) { car in
                CarDetailView(car: car, onDelete: {
                    Task { await loadCars() }
                })
            }
            .sheet(isPresented: $showAddCar) {
                AddCarSheet(onCarAdded: {
                    Task { await loadCars() }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task {
                await loadCars()
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.2)
            Text("Loading garage...")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 80, height: 80)
                Image(systemName: "car.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.accent)
            }

            VStack(spacing: 8) {
                Text("Your Garage is Empty")
                    .font(.title3.bold())
                    .foregroundColor(Theme.foreground)
                Text("Add your first car build\nand start documenting your journey.")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddCar = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Car")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 48)
                .padding(.horizontal, 28)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Grid

    private var garageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cars) { car in
                    CarGridCard(car: car)
                        .onTapGesture {
                            selectedCar = car
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80)
        }
        .refreshable {
            await loadCars()
        }
    }

    private func loadCars() async {
        guard let userId = authManager.user?.uid else {
            isLoading = false
            return
        }
        do {
            let fetched = try await CarService.getUserCars(userId: userId)
            withAnimation(.easeInOut(duration: 0.3)) {
                cars = fetched
                isLoading = false
            }
        } catch {
            isLoading = false
        }
    }
}

// MARK: - Car Grid Card

private struct CarGridCard: View {
    let car: CarBuild

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover photo
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: car.coverPhoto), !car.coverPhoto.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            photoPlaceholder
                        }
                    }
                } else {
                    photoPlaceholder
                }

                // HP badge
                if !car.horsepower.isEmpty {
                    Text("\(car.horsepower) HP")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Theme.accent)
                        )
                        .padding(8)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(car.displayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.foreground)
                    .lineLimit(1)

                if !car.nickname.isEmpty {
                    Text("\"\(car.nickname)\"")
                        .font(.caption2)
                        .foregroundColor(Theme.accent)
                        .lineLimit(1)
                }
            }
            .padding(10)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var photoPlaceholder: some View {
        ZStack {
            Theme.cardHover
            Image(systemName: "car.fill")
                .font(.system(size: 28))
                .foregroundColor(Theme.muted.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Hashable Conformance for NavigationDestination

extension CarBuild: Hashable {
    static func == (lhs: CarBuild, rhs: CarBuild) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
