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
    
    private static let cloudinaryBaseURL = "https://res.cloudinary.com/dgpir7tqk/image/upload"
    
    private static let knownObjects: Set<String> = [
        "apple", "ball", "banana", "car", "cat", "chair", "dog", "hand", "shirt", "teddy_bear", "tree"
    ]
    
    var body: some View {
        if let url = directCloudinaryURL {
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
            fallbackImage
        }
    }
    
    private var directCloudinaryURL: URL? {
        let normalizedName = objectName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        guard Self.knownObjects.contains(normalizedName) else {
            return nil
        }
        
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
