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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

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


        // Initialize with empty array if no data found
        self.categories = []
    }

    func addCategory(name: String, colorName: String, iconName: String) {
        let newCategory = TallyCategory(
            name: name,
            colorName: colorName,
            iconName: iconName,
            counters: []
        )
        categories.append(newCategory)
    }

    func updateCategory(category: TallyCategory, name: String, colorName: String, iconName: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].name = name
            categories[index].colorName = colorName
            categories[index].iconName = iconName
            categories[index].updatedAt = Date()
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
