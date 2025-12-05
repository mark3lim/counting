import SwiftUI

struct AppTheme {
    static let allColorNames = [
        "bg-red-600", "bg-orange-500", "bg-yellow-500", "bg-green-600", "bg-mint-500", "bg-teal-500",
        "bg-cyan-500", "bg-blue-600", "bg-indigo-600", "bg-purple-600", "bg-pink-500", "bg-brown-600",
        "bg-gray-600", "bg-black"
    ]

    static let allIconNames = [
        // Basic
        "list.bullet", "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        // Activities
        "figure.walk", "figure.run", "dumbbell.fill", "sportscourt.fill", "bicycle",
        // Food & Drink
        "cup.and.saucer.fill", "wineglass.fill", "fork.knife", "carrot.fill", "drop.fill",
        // Objects
        "book.fill", "gift.fill", "cart.fill", "creditcard.fill", "gamecontroller.fill",
        "headphones", "camera.fill", "briefcase.fill", "envelope.fill", "gearshape.fill",
        // Nature
        "leaf.fill", "pawprint.fill", "sun.max.fill", "moon.fill", "cloud.rain.fill",
        // Travel
        "airplane", "car.fill", "bus.fill", "tram.fill", "map.fill",
        // Tech
        "desktopcomputer", "laptopcomputer", "iphone", "applewatch", "wifi",
        // Misc
        "person.fill", "person.2.fill", "house.fill", "building.2.fill", "music.note"
    ]
    
    static func getColor(for name: String) -> Color {
        switch name {
        case "bg-red-600": return Color(red: 1.0, green: 0.4, blue: 0.4)
        case "bg-orange-500": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "bg-yellow-500": return Color(red: 1.0, green: 0.8, blue: 0.0)
        case "bg-green-600": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "bg-mint-500": return Color(red: 0.0, green: 0.9, blue: 0.7)
        case "bg-teal-500": return Color(red: 0.0, green: 0.7, blue: 0.7)
        case "bg-cyan-500": return Color(red: 0.0, green: 0.8, blue: 1.0)
        case "bg-blue-600": return Color(red: 0.2, green: 0.5, blue: 1.0)
        case "bg-indigo-600": return Color(red: 0.4, green: 0.3, blue: 1.0)
        case "bg-purple-600": return Color(red: 0.7, green: 0.3, blue: 0.9)
        case "bg-pink-500": return Color(red: 1.0, green: 0.3, blue: 0.7)
        case "bg-brown-600": return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "bg-gray-600": return Color(red: 0.5, green: 0.5, blue: 0.55)
        case "bg-black": return Color(red: 0.1, green: 0.1, blue: 0.15)
        
        // Legacy mappings
        case "bg-amber-700": return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "bg-emerald-500": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "bg-rose-500": return Color(red: 1.0, green: 0.3, blue: 0.5)
            
        default: return Color.gray
        }
    }
    
    static func getIcon(for name: String) -> String {
        switch name {
        // Legacy mappings
        case "dumbbell": return "dumbbell.fill"
        case "droplet": return "drop.fill"
        case "book": return "book.fill"
        case "coffee": return "cup.and.saucer.fill"
        case "list": return "list.bullet"
        case "star": return "star.fill"
        case "heart": return "heart.fill"
        case "flame": return "flame.fill"
        case "bolt": return "bolt.fill"
        case "briefcase": return "briefcase.fill"
        case "cart": return "cart.fill"
        case "gift": return "gift.fill"
        case "gamecontroller": return "gamecontroller.fill"
        case "headphones": return "headphones"
        case "camera": return "camera.fill"
        default: 
            // If not a legacy name, assume it's a valid SF Symbol name
            return name.isEmpty ? "star.fill" : name
        }
    }
}
