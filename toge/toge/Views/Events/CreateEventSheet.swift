import SwiftUI

struct CreateEventSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var onCreated: () -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var location = ""
    @State private var address = ""
    @State private var selectedCategory = "Meet"
    @State private var maxAttendeesText = ""
    @State private var isCreating = false
    @State private var error: String?

    private let categories = ["Meet", "Cruise", "Track Day", "Show", "Drift", "Rally", "Workshop"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Event Title")
                            TogeTextField(placeholder: "Weekend Canyon Run", text: $title, icon: "calendar")
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Description")
                            TextEditor(text: $description)
                                .foregroundColor(Theme.foreground)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }

                        // Date & Time
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                fieldLabel("Date")
                                DatePicker("", selection: $eventDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Theme.accent)
                                    .colorScheme(.dark)
                                    .padding(12)
                                    .background(Theme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                fieldLabel("Time")
                                DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Theme.accent)
                                    .colorScheme(.dark)
                                    .padding(12)
                                    .background(Theme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Location Name")
                            TogeTextField(placeholder: "Mulholland Drive", text: $location, icon: "mappin.and.ellipse")
                        }

                        // Address
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Address")
                            TogeTextField(placeholder: "Full address", text: $address, icon: "map")
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Category")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button {
                                            selectedCategory = cat
                                        } label: {
                                            Text(cat)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(selectedCategory == cat ? .white : Theme.muted)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedCategory == cat ? Theme.accent : Theme.card)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(selectedCategory == cat ? Color.clear : Theme.border, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        // Max Attendees
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("Max Attendees (optional)")
                            TogeTextField(placeholder: "No limit", text: $maxAttendeesText, icon: "person.2")
                                .keyboardType(.numberPad)
                        }

                        // Error
                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                        }

                        // Create Button
                        Button {
                            Task { await createEvent() }
                        } label: {
                            HStack(spacing: 8) {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Event")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isFormValid ? Theme.accent : Theme.accent.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(!isFormValid || isCreating)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Event")
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

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundColor(Theme.muted)
    }

    private func createEvent() async {
        guard let user = authManager.user else { return }
        isCreating = true
        error = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let maxAttendees = Int(maxAttendeesText)

        do {
            _ = try await EventService.createEvent(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                date: dateFormatter.string(from: eventDate),
                time: timeFormatter.string(from: eventTime),
                location: location.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                category: selectedCategory,
                imageURL: "",
                organizerId: user.uid,
                organizerName: user.displayName ?? "User",
                maxAttendees: maxAttendees
            )
            onCreated()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isCreating = false
    }
}
