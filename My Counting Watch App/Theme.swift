
import SwiftUI

struct AppTheme {
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
        case "bg-amber-700": return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "bg-emerald-500": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "bg-rose-500": return Color(red: 1.0, green: 0.3, blue: 0.5)
        default: return Color.gray
        }
    }
    
    static func getIcon(for name: String) -> String {
        switch name {
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
        default: return name.isEmpty ? "star.fill" : name
        }
    }
}
