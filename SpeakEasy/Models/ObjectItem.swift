//
//  ObjectItem.swift
//  SpeakEasy
//

import Foundation
import SwiftUI

struct ObjectItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: ObjectCategory
    let imageName: String
    let colorHex: String
    
    init(id: UUID = UUID(), name: String, category: ObjectCategory, imageName: String, colorHex: String) {
        self.id = id
        self.name = name
        self.category = category
        self.imageName = imageName
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
}

enum ObjectCategory: String, Codable, CaseIterable {
    case animals = "Animals"
    case food = "Food"
    case toys = "Toys"
    case household = "Household"
    case nature = "Nature"
    case vehicles = "Vehicles"
    case bodyParts = "Body Parts"
    case clothing = "Clothing"
    
    var icon: String {
        switch self {
        case .animals: return "pawprint.fill"
        case .food: return "fork.knife"
        case .toys: return "teddybear.fill"
        case .household: return "house.fill"
        case .nature: return "leaf.fill"
        case .vehicles: return "car.fill"
        case .bodyParts: return "hand.raised.fill"
        case .clothing: return "tshirt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .animals: return .orange
        case .food: return .green
        case .toys: return .purple
        case .household: return .blue
        case .nature: return .mint
        case .vehicles: return .red
        case .bodyParts: return .pink
        case .clothing: return .indigo
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
