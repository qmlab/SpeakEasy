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

    private static let backendBaseURL = "https://risingstar-backend-zclkfobb.fly.dev"

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
                .clipped()
        } else if let url = remoteImageURL {
            // 2. Fall back to backend /task-images/ endpoint
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
                        .clipped()
                case .failure:
                    fallbackImage
                @unknown default:
                    fallbackImage
                }
            }
        } else {
            // 3. SF Symbol fallback
            fallbackImage
        }
    }

    private var remoteImageURL: URL? {
        // Direct URL takes priority (e.g. full https:// URL from backend)
        if let directURL = directURL,
           let url = URL(string: directURL),
           url.scheme != nil {
            return url
        }
        // Construct backend task-images URL
        let urlString = "\(Self.backendBaseURL)/task-images/\(normalizedName).svg"
        return URL(string: urlString)
    }

    private var fallbackImage: some View {
        Image(systemName: fallbackIcon)
            .font(.system(size: size * 0.5))
            .foregroundColor(iconColor)
            .frame(width: size, height: size)
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
