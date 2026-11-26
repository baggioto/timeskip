import SwiftUI
import TMDBKit

/// `AsyncImage` has no disk cache and refetches when cells are recycled; this view goes through `ImageCache`.
public struct RemoteImage: View {
    let url: URL?
    let placeholderSymbol: String

    public init(url: URL?, placeholderSymbol: String = "film") {
        self.url = url
        self.placeholderSymbol = placeholderSymbol
    }

    @State private var image: UIImage?
    @State private var failed = false

    public var body: some View {
        // The color takes exactly the size it's offered; the image sits in an overlay so `scaledToFill`
        // can't grow the layout (in a ZStack it widened its parent past the screen and clipped text).
        Theme.raised
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else if failed || url == nil {
                    Image(systemName: placeholderSymbol)
                        .font(.title2)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .clipped()
            .task(id: url) {
                image = nil
                failed = false
                guard let url else { return }
                do {
                    let loaded = try await ImageCache.shared.image(for: url)
                    withAnimation(.easeOut(duration: 0.2)) { image = loaded }
                } catch {
                    // A cancelled load just means the cell scrolled away.
                    if !Task.isCancelled { failed = true }
                }
            }
            .accessibilityHidden(true)
    }
}
