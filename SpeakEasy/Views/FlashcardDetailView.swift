//
//  FlashcardDetailView.swift
//  SpeakEasy
//

import SwiftUI

struct FlashcardDetailView: View {
    let object: ObjectItem
    @ObservedObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 30) {
                closeButton
                
                Spacer()
                
                flashcardContent
                
                Spacer()
                
                actionButtons
                
                Spacer()
            }
            .padding()
            
            if showConfetti {
                ConfettiView()
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [object.color.opacity(0.3), object.color.opacity(0.1), Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
    }
    
    private var flashcardContent: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.2))
                    .frame(width: 220, height: 220)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                RemoteImageView(
                    objectName: object.name,
                    imageType: .flashcard,
                    fallbackIcon: iconForObject(object),
                    iconColor: object.color,
                    size: 180
                )
                .clipShape(Circle())
                .scaleEffect(speechService.isSpeaking ? 1.1 : 1.0)
                .animation(.spring(), value: speechService.isSpeaking)
            }
            .onAppear {
                isAnimating = true
            }
            
            Text(object.name)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(object.color)
                .shadow(color: object.color.opacity(0.3), radius: 5)
            
            if progressManager.isLearned(object) {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.title)
                    }
                }
                
                Text("You learned this!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.green)
            } else {
                let practiceCount = progressManager.practiceCountFor(object)
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < practiceCount ? "star.fill" : "star")
                            .foregroundColor(index < practiceCount ? .yellow : .gray.opacity(0.3))
                            .font(.title)
                    }
                }
                
                Text("Practice \(3 - practiceCount) more time\(3 - practiceCount == 1 ? "" : "s")!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.white)
                .shadow(color: object.color.opacity(0.3), radius: 20)
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                speechService.speak(object.name)
                progressManager.incrementPractice(for: object)
                
                if progressManager.isLearned(object) {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showConfetti = false
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title2)
                    Text("Say It!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    Capsule()
                        .fill(object.color)
                        .shadow(color: object.color.opacity(0.5), radius: 10)
                )
            }
            .scaleEffect(speechService.isSpeaking ? 0.95 : 1.0)
            .animation(.spring(), value: speechService.isSpeaking)
        }
    }
    
    private func iconForObject(_ object: ObjectItem) -> String {
        switch object.name.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "bird": return "bird.fill"
        case "fish": return "fish.fill"
        case "rabbit": return "hare.fill"
        case "horse": return "hare.fill"
        case "cow": return "tortoise.fill"
        case "pig": return "hare.fill"
        case "duck": return "bird.fill"
        case "elephant": return "tortoise.fill"
        case "apple": return "apple.logo"
        case "banana": return "leaf.fill"
        case "orange": return "circle.fill"
        case "milk": return "drop.fill"
        case "bread": return "square.fill"
        case "cookie": return "circle.fill"
        case "water": return "drop.fill"
        case "juice": return "cup.and.saucer.fill"
        case "carrot": return "leaf.fill"
        case "grapes": return "circle.grid.2x2.fill"
        case "ball": return "circle.fill"
        case "teddy bear": return "teddybear.fill"
        case "blocks": return "square.stack.3d.up.fill"
        case "doll": return "person.fill"
        case "car toy": return "car.fill"
        case "puzzle": return "puzzlepiece.fill"
        case "crayons": return "pencil"
        case "book": return "book.fill"
        case "chair": return "chair.fill"
        case "table": return "rectangle.fill"
        case "bed": return "bed.double.fill"
        case "door": return "door.left.hand.closed"
        case "window": return "window.vertical.closed"
        case "lamp": return "lamp.desk.fill"
        case "cup": return "cup.and.saucer.fill"
        case "spoon": return "fork.knife"
        case "plate": return "circle"
        case "tv": return "tv.fill"
        case "tree": return "tree.fill"
        case "flower": return "camera.macro"
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "star": return "star.fill"
        case "cloud": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "grass": return "leaf.fill"
        case "car": return "car.fill"
        case "bus": return "bus.fill"
        case "train": return "tram.fill"
        case "airplane": return "airplane"
        case "boat": return "ferry.fill"
        case "bicycle": return "bicycle"
        case "hand": return "hand.raised.fill"
        case "foot": return "figure.walk"
        case "eye": return "eye.fill"
        case "ear": return "ear.fill"
        case "nose": return "nose.fill"
        case "mouth": return "mouth.fill"
        case "head": return "person.fill"
        case "arm": return "figure.arms.open"
        case "leg": return "figure.walk"
        case "shirt": return "tshirt.fill"
        case "pants": return "figure.stand"
        case "shoes": return "shoe.fill"
        case "hat": return "hat.widebrim.fill"
        case "socks": return "shoe.fill"
        case "jacket": return "tshirt.fill"
        default: return "photo.fill"
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 8...15),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 2)) {
            for i in particles.indices {
                particles[i].position.y += CGFloat.random(in: 400...800)
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

struct StarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    let starSize: CGFloat
    let filledColor: Color
    let emptyColor: Color
    
    init(rating: Double, starSize: CGFloat = 24, filledColor: Color = .yellow, emptyColor: Color = .gray.opacity(0.3)) {
        self.rating = rating
        self.starSize = starSize
        self.filledColor = filledColor
        self.emptyColor = emptyColor
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxRating, id: \.self) { index in
                starView(for: index)
            }
        }
    }
    
    @ViewBuilder
    private func starView(for index: Int) -> some View {
        let fillAmount = min(max(rating - Double(index), 0), 1)
        
        GeometryReader { geometry in
            ZStack {
                Image(systemName: "star.fill")
                    .foregroundColor(emptyColor)
                
                Image(systemName: "star.fill")
                    .foregroundColor(filledColor)
                    .mask(
                        Rectangle()
                            .size(width: geometry.size.width * fillAmount, height: geometry.size.height)
                    )
            }
        }
        .frame(width: starSize, height: starSize)
    }
}

struct APIFlashcardDetailView: View {
    let object: ObjectListResponse
    @ObservedObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    @State private var showConfetti = false
    @State private var currentRating: Double = 0.0
    @State private var showRatingResult = false
    @State private var recognizedText: String = ""
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 30) {
                closeButton
                
                Spacer()
                
                flashcardContent
                
                Spacer()
                
                actionButtons
                
                Spacer()
            }
            .padding()
            
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            currentRating = progressManager.lastRatingForId(object.id)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [object.color.opacity(0.3), object.color.opacity(0.1), Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
    }
    
    private var flashcardContent: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.2))
                    .frame(width: 220, height: 220)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                RemoteImageView(
                    objectName: object.name,
                    imageType: .flashcard,
                    fallbackIcon: iconForObject(object.name),
                    iconColor: object.color,
                    size: 180,
                    directURL: object.flashcardUrl
                )
                .clipShape(Circle())
                .scaleEffect(speechService.isSpeaking || speechService.isListening ? 1.1 : 1.0)
                .animation(.spring(), value: speechService.isSpeaking)
                .animation(.spring(), value: speechService.isListening)
            }
            .onAppear {
                isAnimating = true
            }
            
            Text(object.name)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(object.color)
                .shadow(color: object.color.opacity(0.3), radius: 5)
            
            StarRatingView(rating: currentRating, starSize: 32, filledColor: .yellow, emptyColor: .gray.opacity(0.3))
            
            if showRatingResult {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f / 5.0 stars", currentRating))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ratingColor)
                    
                    if !recognizedText.isEmpty {
                        Text("You said: \"\(recognizedText)\"")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Text(ratingMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(ratingColor)
                }
            } else if progressManager.isLearnedById(object.id) {
                Text("You learned this!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.green)
            } else {
                Text("Tap 'Say It!' and speak the word")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.white)
                .shadow(color: object.color.opacity(0.3), radius: 20)
        )
    }
    
    private var ratingColor: Color {
        if currentRating >= 4.0 {
            return .green
        } else if currentRating >= 2.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var ratingMessage: String {
        if currentRating >= 4.5 {
            return "Perfect!"
        } else if currentRating >= 4.0 {
            return "Excellent!"
        } else if currentRating >= 3.0 {
            return "Good job! Keep practicing!"
        } else if currentRating >= 2.0 {
            return "Nice try! Try again!"
        } else if currentRating > 0 {
            return "Keep trying!"
        } else {
            return "Tap 'Say It!' to start"
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                if speechService.isListening {
                    speechService.stopListening()
                } else {
                    speechService.speak(object.name)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        speechService.startListening(targetWord: object.name) { rating in
                            self.currentRating = rating
                            self.recognizedText = speechService.recognizedText
                            self.showRatingResult = true
                            
                            progressManager.recordRating(id: object.id, name: object.name, rating: rating)
                            
                            if rating >= 4.0 {
                                showConfetti = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showConfetti = false
                                }
                            }
                        }
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: speechService.isListening ? "mic.fill" : "speaker.wave.3.fill")
                        .font(.title2)
                    Text(speechService.isListening ? "Listening..." : "Say It!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    Capsule()
                        .fill(speechService.isListening ? Color.red : object.color)
                        .shadow(color: (speechService.isListening ? Color.red : object.color).opacity(0.5), radius: 10)
                )
            }
            .scaleEffect(speechService.isSpeaking || speechService.isListening ? 0.95 : 1.0)
            .animation(.spring(), value: speechService.isSpeaking)
            .animation(.spring(), value: speechService.isListening)
            .disabled(speechService.isSpeaking)
            
            if showRatingResult {
                Button(action: {
                    showRatingResult = false
                    currentRating = 0
                    recognizedText = ""
                }) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(object.color)
                }
            }
        }
    }
    
    private func iconForObject(_ name: String) -> String {
        switch name.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "bird": return "bird.fill"
        case "fish": return "fish.fill"
        case "rabbit": return "hare.fill"
        case "horse": return "hare.fill"
        case "cow": return "tortoise.fill"
        case "pig": return "hare.fill"
        case "duck": return "bird.fill"
        case "elephant": return "tortoise.fill"
        case "apple": return "apple.logo"
        case "banana": return "leaf.fill"
        case "orange": return "circle.fill"
        case "milk": return "drop.fill"
        case "bread": return "square.fill"
        case "cookie": return "circle.fill"
        case "water": return "drop.fill"
        case "juice": return "cup.and.saucer.fill"
        case "carrot": return "leaf.fill"
        case "grapes": return "circle.grid.2x2.fill"
        case "mushroom": return "leaf.fill"
        case "tomato": return "circle.fill"
        case "ball": return "circle.fill"
        case "teddy bear": return "teddybear.fill"
        case "blocks": return "square.stack.3d.up.fill"
        case "doll": return "person.fill"
        case "car toy": return "car.fill"
        case "puzzle": return "puzzlepiece.fill"
        case "crayons": return "pencil"
        case "book": return "book.fill"
        case "yo yo": return "circle.fill"
        case "chair": return "chair.fill"
        case "table": return "rectangle.fill"
        case "bed": return "bed.double.fill"
        case "door": return "door.left.hand.closed"
        case "window": return "window.vertical.closed"
        case "lamp": return "lamp.desk.fill"
        case "cup": return "cup.and.saucer.fill"
        case "spoon": return "fork.knife"
        case "plate": return "circle"
        case "tv": return "tv.fill"
        case "mirror": return "rectangle.portrait.fill"
        case "tree": return "tree.fill"
        case "flower": return "camera.macro"
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "star": return "star.fill"
        case "cloud": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "grass": return "leaf.fill"
        case "rock": return "mountain.2.fill"
        case "car": return "car.fill"
        case "bus": return "bus.fill"
        case "train": return "tram.fill"
        case "airplane": return "airplane"
        case "boat": return "ferry.fill"
        case "bicycle": return "bicycle"
        case "motorcycle": return "bicycle"
        case "hand": return "hand.raised.fill"
        case "foot": return "figure.walk"
        case "eye": return "eye.fill"
        case "ear": return "ear.fill"
        case "nose": return "nose.fill"
        case "mouth": return "mouth.fill"
        case "head": return "person.fill"
        case "arm": return "figure.arms.open"
        case "leg": return "figure.walk"
        case "shirt": return "tshirt.fill"
        case "pants": return "figure.stand"
        case "shoes": return "shoe.fill"
        case "hat": return "hat.widebrim.fill"
        case "socks": return "shoe.fill"
        case "jacket": return "tshirt.fill"
        case "gloves": return "hand.raised.fill"
        default: return "photo.fill"
        }
    }
}

struct FlashcardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available - requires API data")
            .environmentObject(ProgressManager())
    }
}
