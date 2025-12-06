
import SwiftUI
import Observation

// MARK: - Models

struct CounterItem: Identifiable, Codable, Hashable {
    let id: Int
    var name: String
    var count: Int
}

struct CategoryItem: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let colorName: String // storing color as string for simplicity in model
    let iconName: String
    var counters: [CounterItem]
    
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "cyan": return .cyan
        case "orange": return .orange
        case "amber": return .brown // closest standard color, or .orange
        default: return .gray
        }
    }
}

// MARK: - App State

@Observable
class AppState {
    var categories: [CategoryItem] = [
        CategoryItem(id: 1, name: "운동", colorName: "blue", iconName: "dumbbell.fill", counters: [
            CounterItem(id: 101, name: "푸쉬업", count: 15),
            CounterItem(id: 102, name: "스쿼트", count: 30)
        ]),
        CategoryItem(id: 2, name: "수분 섭취", colorName: "cyan", iconName: "drop.fill", counters: [
            CounterItem(id: 201, name: "물 (잔)", count: 3)
        ]),
        CategoryItem(id: 3, name: "독서", colorName: "orange", iconName: "book.fill", counters: [
            CounterItem(id: 301, name: "읽은 페이지", count: 42)
        ]),
        CategoryItem(id: 4, name: "카페인", colorName: "amber", iconName: "cup.and.saucer.fill", counters: [
            CounterItem(id: 401, name: "커피", count: 2)
        ])
    ]
    
    // Helper to update count directly
    func updateCount(categoryId: Int, counterId: Int, delta: Int) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            let newCount = categories[catIndex].counters[ctrIndex].count + delta
            categories[catIndex].counters[ctrIndex].count = max(0, newCount)
        }
    }
    
    func resetCount(categoryId: Int, counterId: Int) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            categories[catIndex].counters[ctrIndex].count = 0
        }
    }
}
