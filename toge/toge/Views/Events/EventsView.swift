import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var events: [CarEvent] = []
    @State private var isLoading = false
    @State private var selectedCategory = "All"
    @State private var showCreateSheet = false
    @State private var attendingEventIds: Set<String> = []

    private let categories = ["All", "Meet", "Cruise", "Track Day", "Show", "Drift", "Rally", "Workshop"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if isLoading && events.isEmpty {
                    ProgressView()
                        .tint(Theme.accent)
                } else if events.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            categoryChips
                                .padding(.bottom, 16)

                            LazyVStack(spacing: 12) {
                                ForEach(events) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        eventCard(event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Events")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateEventSheet(onCreated: {
                    Task { await loadEvents() }
                })
            }
            .task {
                await loadEvents()
            }
            .refreshable {
                await loadEvents()
            }
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        Task { await loadEvents() }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedCategory == category ? .white : Theme.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category
                                    ? Theme.accent
                                    : Theme.card
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCategory == category ? Color.clear : Theme.border,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Event Card

    private func eventCard(_ event: CarEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event image
            if !event.imageURL.isEmpty {
                AsyncImage(url: URL(string: event.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure:
                        eventImagePlaceholder
                    default:
                        eventImagePlaceholder
                            .overlay(ProgressView().tint(Theme.muted))
                    }
                }
                .frame(height: 160)
                .clipped()
            } else {
                eventImagePlaceholder
                    .frame(height: 160)
            }

            VStack(alignment: .leading, spacing: 10) {
                // Category badge
                Text(event.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accentSoft)
                    .clipShape(Capsule())

                // Title
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(Theme.foreground)
                    .lineLimit(2)

                // Date & time
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(event.date)
                    Text("·")
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(event.time)
                }
                .font(.subheadline)
                .foregroundColor(Theme.muted)

                // Location
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text(event.location)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(Theme.muted)

                Divider()
                    .background(Theme.border)

                // Bottom row: organizer, attendees, RSVP
                HStack {
                    // Organizer
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.cardHover)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(event.organizerName.prefix(1)))
                                    .font(.caption2.bold())
                                    .foregroundColor(Theme.accent)
                            )
                        Text(event.organizerName)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Attendee count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendeeCount)")
                            .font(.caption.weight(.medium))
                        if let max = event.maxAttendees {
                            Text("/ \(max)")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                    }
                    .foregroundColor(Theme.foreground)

                    // RSVP button
                    let isAttending = attendingEventIds.contains(event.id ?? "")
                    Button {
                        Task { await handleRSVP(event: event, isAttending: isAttending) }
                    } label: {
                        Text(isAttending ? "Going" : "RSVP")
                            .font(.caption.weight(.bold))
                            .foregroundColor(isAttending ? Theme.success : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isAttending ? Theme.success.opacity(0.15) : Theme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var eventImagePlaceholder: some View {
        Rectangle()
            .fill(Theme.cardHover)
            .overlay(
                Image(systemName: "flag.checkered")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.muted.opacity(0.3))
            )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            categoryChips

            Spacer()

            Image(systemName: "flag.checkered")
                .font(.system(size: 56))
                .foregroundColor(Theme.muted.opacity(0.3))
            Text("No events yet")
                .font(.title3.bold())
                .foregroundColor(Theme.foreground)
            Text("Be the first to organize a car meet or event.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Event")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 48)
                .padding(.horizontal, 24)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Actions

    private func loadEvents() async {
        isLoading = true
        do {
            if selectedCategory == "All" {
                events = try await EventService.getEvents()
            } else {
                events = try await EventService.getEvents(category: selectedCategory)
            }
            // Check which events user is attending
            if let userId = authManager.user?.uid {
                var attending = Set<String>()
                for event in events {
                    if let eventId = event.id,
                       try await EventService.isUserAttending(eventId: eventId, userId: userId) {
                        attending.insert(eventId)
                    }
                }
                attendingEventIds = attending
            }
        } catch {
            // silently fail
        }
        isLoading = false
    }

    private func handleRSVP(event: CarEvent, isAttending: Bool) async {
        guard let eventId = event.id,
              let user = authManager.user else { return }
        do {
            try await EventService.toggleRSVP(
                eventId: eventId,
                userId: user.uid,
                userName: user.displayName ?? "User",
                userAvatar: user.photoURL?.absoluteString ?? "",
                isAttending: isAttending
            )
            if isAttending {
                attendingEventIds.remove(eventId)
            } else {
                attendingEventIds.insert(eventId)
            }
            await loadEvents()
        } catch {
            // silently fail
        }
    }
}
