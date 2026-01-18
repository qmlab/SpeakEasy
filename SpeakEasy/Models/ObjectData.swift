//
//  ObjectData.swift
//  SpeakEasy
//

import Foundation

struct ObjectData {
    static let allObjects: [ObjectItem] = [
        // Animals
        ObjectItem(name: "Dog", category: .animals, imageName: "dog", colorHex: "FF9500"),
        ObjectItem(name: "Cat", category: .animals, imageName: "cat", colorHex: "FF6B6B"),
        ObjectItem(name: "Bird", category: .animals, imageName: "bird", colorHex: "4ECDC4"),
        ObjectItem(name: "Fish", category: .animals, imageName: "fish", colorHex: "45B7D1"),
        ObjectItem(name: "Rabbit", category: .animals, imageName: "rabbit", colorHex: "DDA0DD"),
        ObjectItem(name: "Horse", category: .animals, imageName: "horse", colorHex: "8B4513"),
        ObjectItem(name: "Cow", category: .animals, imageName: "cow", colorHex: "2C2C2C"),
        ObjectItem(name: "Pig", category: .animals, imageName: "pig", colorHex: "FFB6C1"),
        ObjectItem(name: "Duck", category: .animals, imageName: "duck", colorHex: "FFD700"),
        ObjectItem(name: "Elephant", category: .animals, imageName: "elephant", colorHex: "808080"),
        
        // Food
        ObjectItem(name: "Apple", category: .food, imageName: "apple", colorHex: "FF0000"),
        ObjectItem(name: "Banana", category: .food, imageName: "banana", colorHex: "FFE135"),
        ObjectItem(name: "Orange", category: .food, imageName: "orange", colorHex: "FFA500"),
        ObjectItem(name: "Milk", category: .food, imageName: "milk", colorHex: "FFFAFA"),
        ObjectItem(name: "Bread", category: .food, imageName: "bread", colorHex: "DEB887"),
        ObjectItem(name: "Cookie", category: .food, imageName: "cookie", colorHex: "D2691E"),
        ObjectItem(name: "Water", category: .food, imageName: "water", colorHex: "87CEEB"),
        ObjectItem(name: "Juice", category: .food, imageName: "juice", colorHex: "FFA07A"),
        ObjectItem(name: "Carrot", category: .food, imageName: "carrot", colorHex: "FF7F50"),
        ObjectItem(name: "Grapes", category: .food, imageName: "grapes", colorHex: "6B238E"),
        
        // Toys
        ObjectItem(name: "Ball", category: .toys, imageName: "ball", colorHex: "FF4500"),
        ObjectItem(name: "Teddy Bear", category: .toys, imageName: "teddy", colorHex: "8B4513"),
        ObjectItem(name: "Blocks", category: .toys, imageName: "blocks", colorHex: "FF69B4"),
        ObjectItem(name: "Doll", category: .toys, imageName: "doll", colorHex: "FFB6C1"),
        ObjectItem(name: "Car Toy", category: .toys, imageName: "cartoy", colorHex: "DC143C"),
        ObjectItem(name: "Puzzle", category: .toys, imageName: "puzzle", colorHex: "9370DB"),
        ObjectItem(name: "Crayons", category: .toys, imageName: "crayons", colorHex: "FF6347"),
        ObjectItem(name: "Book", category: .toys, imageName: "book", colorHex: "4169E1"),
        
        // Household
        ObjectItem(name: "Chair", category: .household, imageName: "chair", colorHex: "8B4513"),
        ObjectItem(name: "Table", category: .household, imageName: "table", colorHex: "A0522D"),
        ObjectItem(name: "Bed", category: .household, imageName: "bed", colorHex: "6495ED"),
        ObjectItem(name: "Door", category: .household, imageName: "door", colorHex: "DEB887"),
        ObjectItem(name: "Window", category: .household, imageName: "window", colorHex: "87CEEB"),
        ObjectItem(name: "Lamp", category: .household, imageName: "lamp", colorHex: "FFD700"),
        ObjectItem(name: "Cup", category: .household, imageName: "cup", colorHex: "FF6B6B"),
        ObjectItem(name: "Spoon", category: .household, imageName: "spoon", colorHex: "C0C0C0"),
        ObjectItem(name: "Plate", category: .household, imageName: "plate", colorHex: "FFFAF0"),
        ObjectItem(name: "TV", category: .household, imageName: "tv", colorHex: "2F4F4F"),
        
        // Nature
        ObjectItem(name: "Tree", category: .nature, imageName: "tree", colorHex: "228B22"),
        ObjectItem(name: "Flower", category: .nature, imageName: "flower", colorHex: "FF69B4"),
        ObjectItem(name: "Sun", category: .nature, imageName: "sun", colorHex: "FFD700"),
        ObjectItem(name: "Moon", category: .nature, imageName: "moon", colorHex: "F0E68C"),
        ObjectItem(name: "Star", category: .nature, imageName: "star", colorHex: "FFD700"),
        ObjectItem(name: "Cloud", category: .nature, imageName: "cloud", colorHex: "F0F8FF"),
        ObjectItem(name: "Rain", category: .nature, imageName: "rain", colorHex: "4682B4"),
        ObjectItem(name: "Grass", category: .nature, imageName: "grass", colorHex: "7CFC00"),
        
        // Vehicles
        ObjectItem(name: "Car", category: .vehicles, imageName: "car", colorHex: "FF0000"),
        ObjectItem(name: "Bus", category: .vehicles, imageName: "bus", colorHex: "FFD700"),
        ObjectItem(name: "Train", category: .vehicles, imageName: "train", colorHex: "4169E1"),
        ObjectItem(name: "Airplane", category: .vehicles, imageName: "airplane", colorHex: "87CEEB"),
        ObjectItem(name: "Boat", category: .vehicles, imageName: "boat", colorHex: "1E90FF"),
        ObjectItem(name: "Bicycle", category: .vehicles, imageName: "bicycle", colorHex: "32CD32"),
        
        // Body Parts
        ObjectItem(name: "Hand", category: .bodyParts, imageName: "hand", colorHex: "FFDAB9"),
        ObjectItem(name: "Foot", category: .bodyParts, imageName: "foot", colorHex: "FFDAB9"),
        ObjectItem(name: "Eye", category: .bodyParts, imageName: "eye", colorHex: "4169E1"),
        ObjectItem(name: "Ear", category: .bodyParts, imageName: "ear", colorHex: "FFDAB9"),
        ObjectItem(name: "Nose", category: .bodyParts, imageName: "nose", colorHex: "FFDAB9"),
        ObjectItem(name: "Mouth", category: .bodyParts, imageName: "mouth", colorHex: "FF6B6B"),
        ObjectItem(name: "Head", category: .bodyParts, imageName: "head", colorHex: "FFDAB9"),
        ObjectItem(name: "Arm", category: .bodyParts, imageName: "arm", colorHex: "FFDAB9"),
        ObjectItem(name: "Leg", category: .bodyParts, imageName: "leg", colorHex: "FFDAB9"),
        
        // Clothing
        ObjectItem(name: "Shirt", category: .clothing, imageName: "shirt", colorHex: "4169E1"),
        ObjectItem(name: "Pants", category: .clothing, imageName: "pants", colorHex: "000080"),
        ObjectItem(name: "Shoes", category: .clothing, imageName: "shoes", colorHex: "8B4513"),
        ObjectItem(name: "Hat", category: .clothing, imageName: "hat", colorHex: "FF6347"),
        ObjectItem(name: "Socks", category: .clothing, imageName: "socks", colorHex: "FFFFFF"),
        ObjectItem(name: "Jacket", category: .clothing, imageName: "jacket", colorHex: "2F4F4F"),
    ]
    
    static func objects(for category: ObjectCategory) -> [ObjectItem] {
        allObjects.filter { $0.category == category }
    }
}
