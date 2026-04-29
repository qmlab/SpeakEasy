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
        } else if let directURL = directURL,
                  let url = URL(string: directURL),
                  url.scheme != nil {
            // 2. Direct URL provided (e.g. full https:// URL from backend)
            asyncImageView(url: url)
        } else if let urlString = photoCache.photoURL(for: normalizedName),
                  let url = URL(string: urlString) {
            // 3. Real photo URL from cache
            asyncImageView(url: url)
        } else if !photoCache.isCacheReady {
            // 4. Cache still loading — show spinner, NOT SVG fallback
            ProgressView()
                .frame(width: size, height: size)
        } else if let svgURL = cloudinarySVGURL {
            // 5. Cache loaded but no photo for this item — try Cloudinary SVG
            asyncImageView(url: svgURL)
        } else {
            // 6. SF Symbol fallback
            fallbackImage
        }
    }

    private func asyncImageView(url: URL) -> some View {
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
                if let svgURL = cloudinarySVGURL, url != svgURL {
                    AsyncImage(url: svgURL) { svgPhase in
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
        .id(url)
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
    @Published private(set) var isCacheReady = false
    private var isLoading = false
    private var failureCount = 0
    private var lastFailureDate: Date?
    private let maxRetries = 3
    private let api = AdaptiveAPIService()

    func photoURL(for name: String) -> String? {
        if !isCacheReady && !isLoading && canRetry {
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
            isCacheReady = true
        } catch {
            failureCount += 1
            lastFailureDate = Date()
            print("[RealPhotoURLCache] Failed to load photo URLs (attempt \(failureCount)): \(error)")
            if failureCount >= maxRetries {
                isCacheReady = true
            } else {
                let backoffSeconds = pow(2.0, Double(failureCount))
                isLoading = false
                try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                objectWillChange.send()
                return
            }
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
