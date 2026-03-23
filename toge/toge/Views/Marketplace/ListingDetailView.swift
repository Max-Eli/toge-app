import SwiftUI

struct ListingDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let listing: Listing
    @State private var currentImageIndex = 0
    @State private var isSaved = false
    @Environment(\.dismiss) var dismiss

    private var isOwner: Bool {
        authManager.user?.uid == listing.sellerId
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Carousel
                    if !listing.images.isEmpty {
                        TabView(selection: $currentImageIndex) {
                            ForEach(Array(listing.images.enumerated()), id: \.offset) { index, url in
                                AsyncImage(url: URL(string: url)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Theme.cardHover)
                                        .overlay(ProgressView().tint(Theme.accent))
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 300)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        // Title & Price
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.title)
                                    .font(.title2.bold())
                                    .foregroundColor(Theme.foreground)

                                Text("$\(Int(listing.price))")
                                    .font(.title.bold())
                                    .foregroundColor(Theme.accent)
                            }

                            Spacer()

                            if listing.status == "sold" {
                                Text("SOLD")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.destructive.opacity(0.15))
                                    .foregroundColor(Theme.destructive)
                                    .clipShape(Capsule())
                            }
                        }

                        // Badges
                        HStack(spacing: 8) {
                            badge(listing.condition)
                            badge(listing.category)
                        }

                        // Description
                        Text(listing.description)
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)

                        // Car Fitment
                        if !listing.carFitment.isEmpty {
                            infoRow(icon: "car", label: "Fitment", value: listing.carFitment)
                        }

                        // Location
                        if !listing.location.isEmpty {
                            infoRow(icon: "mappin", label: "Location", value: listing.location)
                        }

                        // Seller
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Theme.cardHover)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(listing.sellerName.prefix(1)))
                                        .font(.headline.bold())
                                        .foregroundColor(Theme.accent)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.sellerName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.foreground)
                                Text("Seller")
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))

                        // Actions
                        if isOwner {
                            Button {
                                Task {
                                    try? await MarketplaceService.markAsSold(listingId: listing.id ?? "")
                                    dismiss()
                                }
                            } label: {
                                Text("Mark as Sold")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Theme.success.opacity(0.15))
                                    .foregroundColor(Theme.success)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                            }

                            Button {
                                Task {
                                    try? await MarketplaceService.deleteListing(listingId: listing.id ?? "")
                                    dismiss()
                                }
                            } label: {
                                Text("Delete Listing")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Theme.destructive.opacity(0.15))
                                    .foregroundColor(Theme.destructive)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                            }
                        } else {
                            HStack(spacing: 12) {
                                Button {
                                    guard let uid = authManager.user?.uid else { return }
                                    Task {
                                        if isSaved {
                                            try? await MarketplaceService.unsaveListing(userId: uid, listingId: listing.id ?? "")
                                        } else {
                                            try? await MarketplaceService.saveListing(userId: uid, listingId: listing.id ?? "")
                                        }
                                        isSaved.toggle()
                                    }
                                } label: {
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.title3)
                                        .frame(width: 50, height: 50)
                                        .background(Theme.card)
                                        .foregroundColor(isSaved ? Theme.accent : Theme.muted)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
                                }

                                Button {
                                    // Contact seller - could open chat
                                } label: {
                                    Text("Contact Seller")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Theme.accent)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if let uid = authManager.user?.uid {
                let savedIds = (try? await MarketplaceService.getSavedListingIds(userId: uid)) ?? []
                isSaved = savedIds.contains(listing.id ?? "")
            }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accentSoft)
            .foregroundColor(Theme.accent)
            .clipShape(Capsule())
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Theme.foreground)
            }
        }
    }
}
