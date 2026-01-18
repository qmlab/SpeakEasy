//
//  FlashcardListView.swift
//  SpeakEasy
//

import SwiftUI

struct FlashcardListView: View {
    let category: ObjectCategory
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    @State private var selectedObject: ObjectItem?
    @State private var showFlashcard = false
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var objects: [ObjectItem] {
        ObjectData.objects(for: category)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                categoryHeader
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(objects) { object in
                        ObjectCard(object: object, speechService: speechService)
                            .onTapGesture {
                                selectedObject = object
                                showFlashcard = true
                                speechService.speak(object.name)
                                progressManager.incrementPractice(for: object)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [category.color.opacity(0.1), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(category.rawValue)
        .sheet(isPresented: $showFlashcard) {
            if let object = selectedObject {
                FlashcardDetailView(object: object, speechService: speechService)
            }
        }
    }
    
    private var categoryHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: category.icon)
                    .font(.system(size: 50))
                    .foregroundColor(category.color)
            }
            
            Text(category.rawValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(category.color)
            
            let learnedCount = objects.filter { progressManager.isLearned($0) }.count
            Text("\(learnedCount) of \(objects.count) learned")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            ProgressBar(progress: progressManager.progressForCategory(category), color: category.color)
                .frame(height: 12)
                .padding(.horizontal, 40)
        }
        .padding()
        .onTapGesture {
            speechService.speak(category.rawValue)
        }
    }
}

struct ObjectCard: View {
    let object: ObjectItem
    @ObservedObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(object.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconForObject(object))
                    .font(.system(size: 35))
                    .foregroundColor(object.color)
                
                if progressManager.isLearned(object) {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                                .shadow(color: .orange, radius: 2)
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                    .padding(5)
                }
            }
            
            Text(object.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: object.color.opacity(0.3), radius: 5)
        )
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

struct FlashcardListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FlashcardListView(category: .animals)
                .environmentObject(ProgressManager())
        }
    }
}
