
//
//  Theme.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  앱 테마 관련 헬퍼 구조체입니다.
//  색상 이름 및 아이콘 이름 문자열을 SwiftUI Color 및 시스템 이미지 이름으로 변환합니다.
//

import SwiftUI

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
    
    // 색상 이름 문자열을 SwiftUI Color로 변환
    static func getColor(for name: String) -> Color {
        switch name {
        case "bg-red-600": return Color(red: 0.87, green: 0.27, blue: 0.27) // Tailwind red-600
        case "bg-red-400": return Color(red: 0.98, green: 0.55, blue: 0.55) // Tailwind red-400 (lighter)
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
        
        case "bg-amber-700": return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "bg-emerald-500": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "bg-rose-500": return Color(red: 1.0, green: 0.3, blue: 0.5)
        default: return Color.gray
        }
    }
    
    // 아이콘 이름 문자열을 SF Symbol 이름으로 변환
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
        case "house": return "house.fill"
        case "person": return "person.fill"
        case "music": return "music.note"
        case "leaf": return "leaf.fill"
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "car": return "car.fill"
        case "phone": return "iphone"
        case "watch": return "applewatch"
        case "creditcard": return "creditcard.fill"
        case "pawprint": return "pawprint.fill"
        default: return name.isEmpty ? "star.fill" : name
        }
    }
}
