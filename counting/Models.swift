import Combine
import SwiftUI

struct TallyCounter: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var count: Int
}

struct TallyCategory: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var colorName: String  // Store the Tailwind class name or similar identifier
    var iconName: String  // Store the Lucide icon name or SF Symbol name
    var counters: [TallyCounter]

    // Helper to get SwiftUI Color from the stored string
    var color: Color {
        switch colorName {
        case "bg-blue-600": return Color.blue
        case "bg-cyan-500": return Color.cyan
        case "bg-orange-500": return Color.orange
        case "bg-amber-700": return Color.brown
        case "bg-purple-600": return Color.purple
        case "bg-pink-500": return Color.pink
        case "bg-emerald-500": return Color.green
        case "bg-indigo-600": return Color.indigo
        case "bg-rose-500": return Color.red
        default: return Color.gray
        }
    }

    // Helper to get SF Symbol from the stored string
    var icon: String {
        switch iconName {
        case "dumbbell": return "dumbbell.fill"
        case "droplet": return "drop.fill"
        case "book": return "book.fill"
        case "coffee": return "cup.and.saucer.fill"
        case "list": return "list.bullet"
        default: return "star.fill"
        }
    }
}

class TallyStore: ObservableObject {
    @Published var categories: [TallyCategory] = [
        TallyCategory(
            name: "운동", colorName: "bg-blue-600", iconName: "dumbbell",
            counters: [
                TallyCounter(name: "푸쉬업", count: 15),
                TallyCounter(name: "스쿼트", count: 30),
            ]),
        TallyCategory(
            name: "수분 섭취", colorName: "bg-cyan-500", iconName: "droplet",
            counters: [
                TallyCounter(name: "물 (잔)", count: 3)
            ]),
        TallyCategory(
            name: "독서", colorName: "bg-orange-500", iconName: "book",
            counters: [
                TallyCounter(name: "읽은 페이지", count: 42)
            ]),
        TallyCategory(
            name: "카페인", colorName: "bg-amber-700", iconName: "coffee",
            counters: [
                TallyCounter(name: "커피", count: 2)
            ]),
    ]

    func addCategory(name: String) {
        let colors = [
            "bg-purple-600", "bg-pink-500", "bg-emerald-500", "bg-indigo-600", "bg-rose-500",
        ]
        let randomColor = colors.randomElement() ?? "bg-gray-500"

        let newCategory = TallyCategory(
            name: name,
            colorName: randomColor,
            iconName: "list",  // Default icon
            counters: [TallyCounter(name: "기본 카운터", count: 0)]
        )
        categories.append(newCategory)
    }

    func addCounter(to categoryId: UUID, name: String, initialCount: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let newCounter = TallyCounter(name: name, count: initialCount)
        categories[index].counters.append(newCounter)
    }

    func updateCount(categoryId: UUID, counterId: UUID, delta: Int) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        var count = categories[catIndex].counters[counterIndex].count + delta
        if count < 0 { count = 0 }
        categories[catIndex].counters[counterIndex].count = count
    }

    func resetCount(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].count = 0
    }
}
