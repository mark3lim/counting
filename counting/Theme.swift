import SwiftUI

// 앱의 디자인 시스템 및 테마 관리 구조체
// 색상 팔레트와 아이콘 매핑 정보를 제공합니다.
struct AppTheme {
    // 사용 가능한 모든 색상 이름 목록
    // Tailwind CSS 스타일의 이름을 사용합니다.
    static let allColorNames = [
        "bg-red-400", "bg-orange-400", "bg-yellow-400", "bg-green-500", "bg-mint-400", "bg-teal-400",
        "bg-cyan-400", "bg-blue-500", "bg-indigo-500", "bg-purple-500", "bg-pink-400", "bg-brown-500",
        "bg-gray-500", "bg-slate-700",
        "bg-coral-400", "bg-lavender-400", "bg-peach-400", "bg-sky-400", "bg-lemon-400", "bg-lilac-400", "bg-salmon-400"
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
        case "bg-red-600", "bg-red-400": return Color(red: 1.0, green: 0.5, blue: 0.5) // Lighter Red
        case "bg-orange-500", "bg-orange-400": return Color(red: 1.0, green: 0.7, blue: 0.4) // Lighter Orange
        case "bg-yellow-500", "bg-yellow-400": return Color(red: 1.0, green: 0.85, blue: 0.2) // Lighter Yellow
        case "bg-green-600", "bg-green-500": return Color(red: 0.3, green: 0.85, blue: 0.5) // Lighter Green
        case "bg-mint-500", "bg-mint-400": return Color(red: 0.2, green: 0.95, blue: 0.8) // Lighter Mint
        case "bg-teal-500", "bg-teal-400": return Color(red: 0.2, green: 0.8, blue: 0.8) // Lighter Teal
        case "bg-cyan-500", "bg-cyan-400": return Color(red: 0.2, green: 0.9, blue: 1.0) // Lighter Cyan
        case "bg-blue-600", "bg-blue-500": return Color(red: 0.3, green: 0.6, blue: 1.0) // Lighter Blue
        case "bg-indigo-600", "bg-indigo-500": return Color(red: 0.5, green: 0.4, blue: 1.0) // Lighter Indigo
        case "bg-purple-600", "bg-purple-500": return Color(red: 0.8, green: 0.4, blue: 1.0) // Lighter Purple
        case "bg-pink-500", "bg-pink-400": return Color(red: 1.0, green: 0.4, blue: 0.8) // Lighter Pink
        case "bg-brown-600", "bg-brown-500": return Color(red: 0.7, green: 0.5, blue: 0.4) // Lighter Brown
        case "bg-gray-600", "bg-gray-500": return Color(red: 0.6, green: 0.6, blue: 0.65) // Lighter Gray
        case "bg-black", "bg-slate-700": return Color(red: 0.2, green: 0.25, blue: 0.35) // Slate Blue-ish Black
        
        // New Pastel Colors
        case "bg-coral-400": return Color(red: 1.0, green: 0.6, blue: 0.5)
        case "bg-lavender-400": return Color(red: 0.7, green: 0.6, blue: 1.0)
        case "bg-peach-400": return Color(red: 1.0, green: 0.75, blue: 0.6)
        case "bg-sky-400": return Color(red: 0.5, green: 0.8, blue: 1.0)
        case "bg-lemon-400": return Color(red: 1.0, green: 0.95, blue: 0.4)
        case "bg-lilac-400": return Color(red: 0.8, green: 0.6, blue: 1.0)
        case "bg-salmon-400": return Color(red: 1.0, green: 0.5, blue: 0.4)
        
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

// 다크 모드와 라이트 모드를 지원하는 색상 세트
struct ColorSet {
    // 배경 그라데이션 시작 색상
    static var bgGradientStart: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(hex: "0f172a") : UIColor(hex: "f5f7fa")
        })
    }
    
    // 배경 그라데이션 끝 색상
    static var bgGradientEnd: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(hex: "1e293b") : UIColor(hex: "c3cfe2")
        })
    }
    
    // Ambient Orb 1 (보라 계열)
    static var orb1: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(hex: "4c1d95") : UIColor(hex: "a18cd1")
        })
    }
    
    // Ambient Orb 2 (분홍 계열)
    static var orb2: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(hex: "831843") : UIColor(hex: "fbc2eb")
        })
    }
    
    // Ambient Orb 3 (청록 계열)
    static var orb3: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(hex: "134e4a") : UIColor(hex: "8fd3f4")
        })
    }
    
    // 주요 텍스트 색상
    static var primaryText: Color {
        Color.primary
    }
    
    // 보조 텍스트 색상
    static var secondaryText: Color {
        Color.secondary
    }
}

// UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
