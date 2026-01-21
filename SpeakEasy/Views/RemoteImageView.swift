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
    
    private static let cloudinaryBaseURL = "https://res.cloudinary.com/dgpir7tqk/image/upload"
    
    var body: some View {
        AsyncImage(url: imageURL) { phase in
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
    }
    
    private var imageURL: URL? {
        if let directURL = directURL, let url = URL(string: directURL) {
            return url
        }
        return constructedCloudinaryURL
    }
    
    private var constructedCloudinaryURL: URL? {
        let normalizedName = objectName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        let folder: String
        switch imageType {
        case .flashcard:
            folder = "flashcards"
        case .findObject:
            folder = "find_object"
        case .thumbnail:
            folder = "thumbnails"
        }
        
        let urlString = "\(Self.cloudinaryBaseURL)/\(folder)/\(normalizedName).png"
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
