import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    @State private var searchQuery = ""
    @State private var selectedCategory = "All"
    @State private var showCreateListing = false

    private let categories = ["All", "Engine", "Suspension", "Wheels & Tires", "Exterior", "Interior", "Electronics", "Other"]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var filteredListings: [Listing] {
        var result = listings
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.description.localizedCaseInsensitiveContains(searchQuery) ||
                $0.carFitment.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Theme.accent)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Search
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.muted)
                            TextField("", text: $searchQuery, prompt: Text("Search parts...").foregroundColor(Theme.muted.opacity(0.6)))
                                .foregroundColor(Theme.foreground)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                        .padding(.horizontal, 16)

                        // Categories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button { selectedCategory = cat } label: {
                                        Text(cat)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == cat ? Theme.accent : Theme.card)
                                            .foregroundColor(selectedCategory == cat ? .white : Theme.muted)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(selectedCategory == cat ? Color.clear : Theme.border, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Listings Grid
                        if filteredListings.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "cart")
                                    .font(.system(size: 48))
                                    .foregroundColor(Theme.muted.opacity(0.3))
                                Text("No listings yet")
                                    .font(.headline)
                                    .foregroundColor(Theme.foreground)
                                Text("Be the first to list a part")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredListings) { listing in
                                    NavigationLink {
                                        ListingDetailView(listing: listing)
                                            .environmentObject(authManager)
                                    } label: {
                                        listingCard(listing)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showCreateListing = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .shadow(color: Theme.accent.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Marketplace")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreateListing) {
            CreateListingSheet { loadData() }
                .environmentObject(authManager)
        }
        .task { loadData() }
    }

    private func listingCard(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstImage = listing.images.first, !firstImage.isEmpty {
                AsyncImage(url: URL(string: firstImage)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Theme.cardHover)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous)
                    .fill(Theme.cardHover)
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundColor(Theme.muted))
            }

            Text(listing.title)
                .font(.caption.bold())
                .foregroundColor(Theme.foreground)
                .lineLimit(2)

            Text("$\(Int(listing.price))")
                .font(.subheadline.bold())
                .foregroundColor(Theme.accent)

            HStack(spacing: 4) {
                Text(listing.condition)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentSoft)
                    .foregroundColor(Theme.accent)
                    .clipShape(Capsule())

                if listing.status == "sold" {
                    Text("SOLD")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.destructive.opacity(0.15))
                        .foregroundColor(Theme.destructive)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func loadData() {
        Task {
            isLoading = true
            do {
                listings = try await MarketplaceService.getListings()
            } catch {
                print("Marketplace load error: \(error)")
            }
            isLoading = false
        }
    }
}
