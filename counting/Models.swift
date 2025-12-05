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
        return AppTheme.getColor(for: colorName)
    }

    // Helper to get SF Symbol from the stored string
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

class TallyStore: ObservableObject {
    @Published var categories: [TallyCategory] = [] {
        didSet {
            save()
        }
    }

    private let saveKey = "tally_categories_data"

    init() {
        load()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
            self.categories = decoded
            return
        }

        // Default data for first run
        self.categories = [
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
    }

    func addCategory(name: String, colorName: String, iconName: String) {
        let newCategory = TallyCategory(
            name: name,
            colorName: colorName,
            iconName: iconName,
            counters: [TallyCounter(name: "기본 카운터", count: 0)]
        )
        categories.append(newCategory)
    }

    func updateCategory(category: TallyCategory, name: String, colorName: String, iconName: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].name = name
            categories[index].colorName = colorName
            categories[index].iconName = iconName
        }
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

    func renameCounter(categoryId: UUID, counterId: UUID, newName: String) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].name = newName
    }

    func resetCount(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].count = 0
    }

    func resetAllData() {
        categories = []
    }
}
