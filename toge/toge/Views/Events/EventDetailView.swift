import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    let event: CarEvent

    @State private var isAttending = false
    @State private var attendees: [EventAttendee] = []
    @State private var isLoading = false
    @State private var showAllAttendees = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    heroImage

                    VStack(alignment: .leading, spacing: 20) {
                        // Category badge
                        Text(event.category.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accentSoft)
                            .clipShape(Capsule())

                        // Title
                        Text(event.title)
                            .font(.title2.bold())
                            .foregroundColor(Theme.foreground)

                        // Description
                        if !event.description.isEmpty {
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(Theme.muted)
                                .lineSpacing(4)
                        }

                        // Info cards
                        VStack(spacing: 12) {
                            infoRow(icon: "calendar", label: "Date", value: event.date)
                            infoRow(icon: "clock", label: "Time", value: event.time)
                            infoRow(icon: "mappin.and.ellipse", label: "Location", value: event.location)
                            if !event.address.isEmpty {
                                infoRow(icon: "map", label: "Address", value: event.address)
                            }
                            if let maxAttendees = event.maxAttendees {
                                infoRow(
                                    icon: "person.2",
                                    label: "Capacity",
                                    value: "\(event.attendeeCount) / \(maxAttendees) attending"
                                )
                            } else {
                                infoRow(
                                    icon: "person.2",
                                    label: "Attending",
                                    value: "\(event.attendeeCount) people"
                                )
                            }
                        }
                        .padding(16)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusLg, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )

                        // Organizer
                        organizerSection

                        // RSVP button
                        rsvpButton

                        // Attendees
                        attendeesSection
                    }
                    .padding(16)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadData()
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Group {
            if !event.imageURL.isEmpty {
                AsyncImage(url: URL(string: event.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(height: 220)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Theme.accent.opacity(0.3), Theme.card],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.foreground.opacity(0.2))
            )
    }

    // MARK: - Info Row

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Theme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.foreground)
            }

            Spacer()
        }
    }

    // MARK: - Organizer

    private var organizerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organizer")
                .font(.headline)
                .foregroundColor(Theme.foreground)

            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.cardHover)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(event.organizerName.prefix(1)))
                            .font(.headline.bold())
                            .foregroundColor(Theme.accent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.organizerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.foreground)
                    Text("Event Organizer")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                Spacer()
            }
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - RSVP Button

    private var rsvpButton: some View {
        Button {
            Task { await handleRSVP() }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isAttending ? "checkmark.circle.fill" : "hand.raised.fill")
                    Text(isAttending ? "You're Going!" : "RSVP to This Event")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isAttending ? Theme.success : Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        }
        .disabled(isLoading)
    }

    // MARK: - Attendees

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attendees")
                    .font(.headline)
                    .foregroundColor(Theme.foreground)
                Spacer()
                Text("\(attendees.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.muted)
            }

            if attendees.isEmpty {
                Text("No one has RSVP'd yet. Be the first!")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .padding(.vertical, 12)
            } else {
                let displayedAttendees = showAllAttendees ? attendees : Array(attendees.prefix(6))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
                    ForEach(displayedAttendees) { attendee in
                        VStack(spacing: 6) {
                            if !attendee.userAvatar.isEmpty {
                                AsyncImage(url: URL(string: attendee.userAvatar)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        attendeeInitial(attendee.userName)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                            } else {
                                attendeeInitial(attendee.userName)
                            }

                            Text(attendee.userName)
                                .font(.caption2)
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)
                        }
                    }
                }

                if attendees.count > 6 && !showAllAttendees {
                    Button {
                        showAllAttendees = true
                    } label: {
                        Text("Show all \(attendees.count) attendees")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func attendeeInitial(_ name: String) -> some View {
        Circle()
            .fill(Theme.cardHover)
            .frame(width: 48, height: 48)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.accent)
            )
    }

    // MARK: - Actions

    private func loadData() async {
        guard let eventId = event.id else { return }
        do {
            attendees = try await EventService.getAttendees(eventId: eventId)
            if let userId = authManager.user?.uid {
                isAttending = try await EventService.isUserAttending(eventId: eventId, userId: userId)
            }
        } catch {
            // silently fail
        }
    }

    private func handleRSVP() async {
        guard let eventId = event.id,
              let user = authManager.user else { return }
        isLoading = true
        do {
            try await EventService.toggleRSVP(
                eventId: eventId,
                userId: user.uid,
                userName: user.displayName ?? "User",
                userAvatar: user.photoURL?.absoluteString ?? "",
                isAttending: isAttending
            )
            isAttending.toggle()
            attendees = try await EventService.getAttendees(eventId: eventId)
        } catch {
            // silently fail
        }
        isLoading = false
    }
}
