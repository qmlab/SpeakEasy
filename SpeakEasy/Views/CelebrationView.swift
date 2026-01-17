//
//  CelebrationView.swift
//  SpeakEasy
//

import SwiftUI

struct CelebrationView: View {
    @State private var stars: [CelebrationStar] = []
    @State private var showText = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ForEach(stars) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: star.size))
                    .foregroundColor(star.color)
                    .position(star.position)
                    .opacity(star.opacity)
                    .rotationEffect(.degrees(star.rotation))
            }
            
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 20)
                    .scaleEffect(showText ? 1.2 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showText)
                
                Text("Great Job!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .purple, radius: 10)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showText)
                
                Text("You learned a new word!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showText ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: showText)
            }
        }
        .onAppear {
            createStars()
            showText = true
            animateStars()
        }
    }
    
    private func createStars() {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        stars = (0..<30).map { _ in
            CelebrationStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: -50...0)
                ),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 15...35),
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func animateStars() {
        let screenHeight = UIScreen.main.bounds.height
        
        withAnimation(.easeOut(duration: 2)) {
            for i in stars.indices {
                stars[i].position.y += screenHeight + 100
                stars[i].position.x += CGFloat.random(in: -50...50)
                stars[i].rotation += Double.random(in: 180...720)
                stars[i].opacity = 0
            }
        }
    }
}

struct CelebrationStar: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var rotation: Double
}

struct CelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        CelebrationView()
    }
}
