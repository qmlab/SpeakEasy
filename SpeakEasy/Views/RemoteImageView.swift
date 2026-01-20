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
    
    @State private var imageURL: String?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString), !loadFailed {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                fallbackImage
            }
        }
        .task {
            await loadImageURL()
        }
    }
    
    private var fallbackImage: some View {
        Image(systemName: fallbackIcon)
            .font(.system(size: size * 0.5))
            .foregroundColor(iconColor)
            .frame(width: size, height: size)
    }
    
    private func loadImageURL() async {
        do {
            let objects = try await APIService.shared.getObjects()
            if let matchingObject = objects.first(where: { $0.name.lowercased() == objectName.lowercased() }) {
                let images = try await APIService.shared.getObjectImages(objectId: matchingObject.id, imageType: imageType)
                if let firstImage = images.first {
                    await MainActor.run {
                        self.imageURL = firstImage.imageUrl
                        self.isLoading = false
                    }
                    return
                }
            }
            await MainActor.run {
                self.isLoading = false
                self.loadFailed = true
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.loadFailed = true
            }
        }
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
