//
//  RemoteImageView.swift
//  SpeakEasy
//

import SwiftUI

struct RemoteImageView: View {
    let objectName: String
    let imageType: ImageType
    let fallbackIcon: String
    let iconColor: Color
    let size: CGFloat
    var directURL: String? = nil

    @ObservedObject private var photoCache = RealPhotoURLCache.shared

    private static let cloudinaryBaseURL = "https://res.cloudinary.com/dgpir7tqk/image/upload"

    /// Normalized asset name used for both xcasset lookup and backend URL construction.
    private var normalizedName: String {
        objectName.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    var body: some View {
        // 1. Try bundled xcasset first (no network needed)
        if let uiImage = UIImage(named: normalizedName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 16 : 8))
        } else if let url = resolvedImageURL {
            // 2. Fall back to remote image (real photo or Cloudinary SVG)
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 16 : 8))
                case .failure:
                    // If we were showing a real photo, try Cloudinary SVG fallback
                    if url != cloudinarySVGURL {
                        AsyncImage(url: cloudinarySVGURL) { svgPhase in
                            switch svgPhase {
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size, height: size)
                                    .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 16 : 8))
                            default:
                                fallbackImage
                            }
                        }
                    } else {
                        fallbackImage
                    }
                @unknown default:
                    fallbackImage
                }
            }
        } else {
            // 3. SF Symbol fallback
            fallbackImage
        }
    }

    /// The primary URL to try: real photo first, then Cloudinary SVG.
    private var resolvedImageURL: URL? {
        // Direct URL takes priority (e.g. full https:// URL from backend)
        if let directURL = directURL,
           let url = URL(string: directURL),
           url.scheme != nil {
            return url
        }
        // Try real photo URL from observed cache (reactive — view refreshes when cache loads)
        if let urlString = photoCache.photoURL(for: normalizedName),
           let url = URL(string: urlString) {
            return url
        }
        // Fall back to Cloudinary SVG
        return cloudinarySVGURL
    }

    /// Original Cloudinary SVG URL (PNG-rendered).
    private var cloudinarySVGURL: URL? {
        let urlString = "\(Self.cloudinaryBaseURL)/f_png/risingstar/task_images/\(normalizedName)"
        return URL(string: urlString)
    }

    private var fallbackImage: some View {
        Image(systemName: fallbackIcon)
            .font(.system(size: size * 0.5))
            .foregroundColor(iconColor)
            .frame(width: size, height: size)
    }
}

/// Caches real photo URLs fetched from the backend via AdaptiveAPIService.
@MainActor
class RealPhotoURLCache: ObservableObject {
    static let shared = RealPhotoURLCache()

    @Published private var photoURLs: [String: String] = [:]
    private var isLoaded = false
    private var isLoading = false
    private var failureCount = 0
    private var lastFailureDate: Date?
    private let maxRetries = 3
    private let api = AdaptiveAPIService()

    func photoURL(for name: String) -> String? {
        if !isLoaded && !isLoading && canRetry {
            isLoading = true
            Task { await loadPhotoURLs() }
        }
        return photoURLs[name]
    }

    private var canRetry: Bool {
        if failureCount >= maxRetries { return false }
        if let last = lastFailureDate {
            let backoff = pow(2.0, Double(failureCount))
            return Date().timeIntervalSince(last) >= backoff
        }
        return true
    }

    private func loadPhotoURLs() async {
        do {
            photoURLs = try await api.getPhotoURLs()
            isLoaded = true
        } catch {
            failureCount += 1
            lastFailureDate = Date()
            print("[RealPhotoURLCache] Failed to load photo URLs (attempt \(failureCount)): \(error)")
        }
        isLoading = false
    }
}

struct RemoteImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RemoteImageView(
                objectName: "Apple",
                imageType: .thumbnail,
                fallbackIcon: "apple.logo",
                iconColor: .red,
                size: 80
            )

            RemoteImageView(
                objectName: "Dog",
                imageType: .flashcard,
                fallbackIcon: "dog.fill",
                iconColor: .orange,
                size: 150
            )
        }
    }
}
