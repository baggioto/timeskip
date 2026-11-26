import SwiftUI
import TMDBKit

/// Grid cell: poster, title, year and rating (Figma: PosterCard).
public struct PosterCard: View {
    let title: Title
    let isSaved: Bool

    public init(title: Title, isSaved: Bool = false) {
        self.title = title
        self.isSaved = isSaved
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RemoteImage(url: TMDBImage.url(title.posterPath, size: .poster))
                .aspectRatio(2 / 3, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(alignment: .topTrailing) {
                    if isSaved { SavedBadge() }
                }

            Text(title.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            MetaLine(title: title)
        }
        .accessibilityElement(children: .combine)
    }
}

/// List row: thumbnail, title and meta (Figma: ListRow).
public struct TitleRow: View {
    let title: Title
    let isSaved: Bool

    public init(title: Title, isSaved: Bool = false) {
        self.title = title
        self.isSaved = isSaved
    }

    public var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: TMDBImage.url(title.posterPath, size: .thumbnail))
                .frame(width: 54, height: 81)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(title.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                MetaLine(title: title, showsType: true)
                if !title.overview.isEmpty {
                    Text(title.overview)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            if isSaved {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel(Text("In watchlist", bundle: .module))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// "2024 · ★ 7.8" (optionally prefixed with Movie / Series).
public struct MetaLine: View {
    let title: Title
    let showsType: Bool

    public init(title: Title, showsType: Bool = false) {
        self.title = title
        self.showsType = showsType
    }

    public var body: some View {
        HStack(spacing: 4) {
            if showsType {
                Text(title.mediaType.label)
                if title.year != nil || title.rating != nil { Text("·") }
            }
            if let year = title.year {
                Text(year)
            }
            if let rating = title.rating {
                if title.year != nil { Text("·") }
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(rating)
                    .accessibilityLabel(Text("rated \(rating)", bundle: .module))
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.textMuted)
        .lineLimit(1)
    }
}

struct SavedBadge: View {
    var body: some View {
        Image(systemName: "bookmark.fill")
            .font(.caption)
            .foregroundStyle(Theme.onAccent)
            .padding(6)
            .background(Theme.accent, in: .circle)
            .padding(6)
            .accessibilityLabel(Text("In watchlist", bundle: .module))
    }
}

public struct Chip: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.raised, in: .capsule)
    }
}

/// A slim notice above content, e.g. "Offline · showing saved results".
public struct Banner: View {
    let text: String
    let systemImage: String

    public init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        Label(text, systemImage: systemImage)
            .font(.footnote.weight(.medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 10))
    }
}

/// Full-screen error with a retry button (Figma: offline error).
public struct ErrorStateView: View {
    let error: APIError
    let retry: () async -> Void

    public init(error: APIError, retry: @escaping () async -> Void) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: error.systemImage)
        } description: {
            Text(error.message)
        } actions: {
            if error != .missingToken {
                Button {
                    Task { await retry() }
                } label: {
                    Text("Try again", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundStyle(Theme.onAccent)
            }
        }
    }
}
