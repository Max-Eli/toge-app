import SwiftUI

struct VideosView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var videos: [Video] = []
    @State private var isLoading = true
    @State private var selectedCategory = "All"
    @State private var selectedVideo: Video?

    private let categories = ["All", "Engine", "Suspension", "Exterior", "Interior", "Maintenance", "Other"]

    private var filteredVideos: [Video] {
        if selectedCategory == "All" { return videos }
        return videos.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Theme.accent)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Category Filter
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

                        if filteredVideos.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "play.rectangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(Theme.muted.opacity(0.3))
                                Text("No videos yet")
                                    .font(.headline)
                                    .foregroundColor(Theme.foreground)
                                Text("How-to videos will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.muted)
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredVideos) { video in
                                    Button {
                                        selectedVideo = video
                                        Task { try? await VideoService.incrementViews(videoId: video.id ?? "") }
                                    } label: {
                                        videoCard(video)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }
        }
        .navigationTitle("Videos")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedVideo) { video in
            VideoPlayerSheet(video: video)
        }
        .task { loadData() }
    }

    private func videoCard(_ video: Video) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                if !video.thumbnailURL.isEmpty {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Theme.cardHover)
                    }
                } else {
                    Rectangle().fill(Theme.cardHover)
                }

                // Play overlay
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )

                // Duration badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(video.duration)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(8)
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.foreground)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(video.authorName)
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    Text("•")
                        .foregroundColor(Theme.muted)

                    Text("\(video.views) views")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                HStack(spacing: 6) {
                    Text(video.category)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentSoft)
                        .foregroundColor(Theme.accent)
                        .clipShape(Capsule())

                    Text(video.difficulty)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(video.difficulty).opacity(0.15))
                        .foregroundColor(difficultyColor(video.difficulty))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Beginner": return Theme.success
        case "Intermediate": return .orange
        case "Advanced": return Theme.destructive
        default: return Theme.muted
        }
    }

    private func loadData() {
        Task {
            isLoading = true
            do {
                videos = try await VideoService.getVideos()
            } catch {
                print("Videos load error: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Video Player Sheet
struct VideoPlayerSheet: View {
    let video: Video
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let url = URL(string: video.videoURL) {
                        Link(destination: url) {
                            VStack(spacing: 12) {
                                if !video.thumbnailURL.isEmpty {
                                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Theme.cardHover)
                                    }
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                                    .overlay(
                                        Circle()
                                            .fill(.black.opacity(0.5))
                                            .frame(width: 60, height: 60)
                                            .overlay(Image(systemName: "play.fill").foregroundColor(.white).font(.title2))
                                    )
                                }

                                Text("Tap to watch on YouTube")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.accent)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.title3.bold())
                            .foregroundColor(Theme.foreground)

                        Text(video.authorName)
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)

                        Text(video.description)
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                            .padding(.top, 4)

                        HStack(spacing: 16) {
                            Label("\(video.views) views", systemImage: "eye")
                            Label(video.duration, systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .navigationTitle("Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.muted)
                    }
                }
            }
        }
    }
}
