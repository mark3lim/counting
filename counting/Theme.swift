import SwiftUI

// 앱의 디자인 시스템 및 테마 관리 구조체
// 색상 팔레트와 아이콘 매핑 정보를 제공합니다.
struct AppTheme {
    // 사용 가능한 모든 색상 이름 목록
    // Tailwind CSS 스타일의 이름을 사용합니다.
    static let allColorNames = [
        "bg-red-600", "bg-orange-500", "bg-yellow-500", "bg-green-600", "bg-mint-500", "bg-teal-500",
        "bg-cyan-500", "bg-blue-600", "bg-indigo-600", "bg-purple-600", "bg-pink-500", "bg-brown-600",
        "bg-gray-600", "bg-black"
    ]

    // 사용 가능한 모든 아이콘 이름 목록 (SF Symbols)
    // 카테고리별로 분류되어 있습니다.
    static let allIconNames = [
        // 기본 아이콘
        "list.bullet", "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        // 활동/운동
        "figure.walk", "figure.run", "dumbbell.fill", "sportscourt.fill", "bicycle",
        // 음식/음료
        "cup.and.saucer.fill", "wineglass.fill", "fork.knife", "carrot.fill", "drop.fill",
        // 사물
        "book.fill", "gift.fill", "cart.fill", "creditcard.fill", "gamecontroller.fill",
        "headphones", "camera.fill", "briefcase.fill", "envelope.fill", "gearshape.fill",
        // 자연
        "leaf.fill", "pawprint.fill", "sun.max.fill", "moon.fill", "cloud.rain.fill",
        // 여행/교통
        "airplane", "car.fill", "bus.fill", "tram.fill", "map.fill",
        // 기술/기기
        "desktopcomputer", "laptopcomputer", "iphone", "applewatch", "wifi",
        // 기타
        "person.fill", "person.2.fill", "house.fill", "building.2.fill", "music.note"
    ]
    
    // 색상 이름을 받아 실제 SwiftUI Color 객체를 반환하는 헬퍼 메서드
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
        
        // 이전 버전 호환성을 위한 매핑
        case "bg-amber-700": return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "bg-emerald-500": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "bg-rose-500": return Color(red: 1.0, green: 0.3, blue: 0.5)
            
        default: return Color.gray
        }
    }
    
    // 아이콘 이름을 받아 실제 SF Symbol 이름을 반환하는 헬퍼 메서드
    static func getIcon(for name: String) -> String {
        switch name {
        // 이전 버전의 레거시 아이콘 이름을 SF Symbol로 매핑
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
            // 레거시 이름이 아니면 유효한 SF Symbol 이름으로 간주하고 그대로 반환
            return name.isEmpty ? "star.fill" : name
        }
    }
}
