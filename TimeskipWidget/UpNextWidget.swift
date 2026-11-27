import AppGroupKit
import DesignSystem
import SwiftUI
import TMDBKit
import WidgetKit

@main
struct TimeskipWidgetBundle: WidgetBundle {
    var body: some Widget {
        UpNextWidget()
    }
}

/// The next episode of the shows the user is watching, from the snapshot the app writes to the app group.
struct UpNextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpNextWidget", provider: UpNextProvider()) { entry in
            UpNextWidgetView(entry: entry)
                .containerBackground(Theme.background, for: .widget)
        }
        .configurationDisplayName("Up next")
        .description("The next episode of the shows you're watching.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Timeline

nonisolated struct UpNextEntry: TimelineEntry {
    let date: Date
    let items: [UpNextSnapshot.Item]
    /// Poster thumbnails by show id. Widgets can't load images while drawing, so the provider fetches them first.
    let posters: [Int: UIImage]
}

nonisolated struct UpNextProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpNextEntry {
        UpNextEntry(date: .now, items: UpNextSnapshot.placeholder.items, posters: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> Void) {
        let items = UpNextSnapshotStore().read()?.items ?? []
        // The widget gallery shows sample shows when there's nothing to show yet.
        let showSamples = context.isPreview && items.isEmpty
        completion(showSamples ? placeholder(in: context) : UpNextEntry(date: .now, items: items, posters: [:]))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpNextEntry>) -> Void) {
        let items = UpNextSnapshotStore().read()?.items ?? []
        let count = context.family == .systemMedium ? 3 : 1
        let done = UncheckedCompletion(completion)
        Task {
            let posters = await Self.posters(for: Array(items.prefix(count)))
            // The app reloads the widget whenever "Up next" changes, so there's nothing to refresh on a schedule.
            done.call(Timeline(entries: [UpNextEntry(date: .now, items: items, posters: posters)], policy: .never))
        }
    }

    private static func posters(for items: [UpNextSnapshot.Item]) async -> [Int: UIImage] {
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for item in items {
                group.addTask {
                    guard let url = TMDBImage.url(item.posterPath, size: .thumbnail),
                        let (data, _) = try? await URLSession.shared.data(from: url)
                    else { return (item.showID, nil) }
                    return (item.showID, UIImage(data: data))
                }
            }
            var posters: [Int: UIImage] = [:]
            for await (id, image) in group { posters[id] = image }
            return posters
        }
    }
}

/// WidgetKit's completion handlers predate Sendable; it's safe to call this one once from any thread.
private nonisolated struct UncheckedCompletion<Value>: @unchecked Sendable {
    let call: (Value) -> Void
    init(_ call: @escaping (Value) -> Void) { self.call = call }
}

// MARK: - Views

struct UpNextWidgetView: View {
    let entry: UpNextEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.items.isEmpty {
            empty
        } else {
            switch family {
            case .systemMedium: medium
            case .accessoryRectangular: rectangular
            default: small
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Up next", systemImage: "tv")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text("Nothing up next")
                .font(.headline)
                .foregroundStyle(Theme.text)
            if family != .accessoryRectangular {
                Text("Mark an episode as watched to see what's next.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var small: some View {
        let item = entry.items[0]
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Poster(image: entry.posters[item.showID])
                    .frame(width: 36, height: 54)
                Spacer()
                Text("Up next")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            Spacer(minLength: 0)
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Text(code(item))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            ProgressView(value: item.progress)
                .tint(Theme.accent)
        }
        .widgetURL(item.deepLink)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Up next")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            ForEach(entry.items.prefix(3)) { item in
                Link(destination: item.deepLink) {
                    HStack(spacing: 10) {
                        Poster(image: entry.posters[item.showID])
                            .frame(width: 24, height: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Text("\(code(item)) · \(String(localized: "\(item.watched) of \(item.total) episodes"))")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rectangular: some View {
        let item = entry.items[0]
        return VStack(alignment: .leading) {
            Text("Up next")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
            Text(code(item))
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(item.deepLink)
    }

    private func code(_ item: UpNextSnapshot.Item) -> String {
        String(localized: "S\(item.season) · E\(item.episode)")
    }
}

private struct Poster: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Theme.raised.overlay {
                    Image(systemName: "tv").font(.caption).foregroundStyle(Theme.textMuted)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 4))
    }
}

#Preview(as: .systemSmall) {
    UpNextWidget()
} timeline: {
    UpNextEntry(date: .now, items: UpNextSnapshot.placeholder.items, posters: [:])
    UpNextEntry(date: .now, items: [], posters: [:])
}

#Preview(as: .systemMedium) {
    UpNextWidget()
} timeline: {
    UpNextEntry(date: .now, items: UpNextSnapshot.placeholder.items, posters: [:])
}
