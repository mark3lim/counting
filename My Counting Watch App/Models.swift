
import SwiftUI
import Observation

// MARK: - Shared Models (Matching iOS App)

struct TallyCounter: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var count: Double
}

struct TallyCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorName: String
    var iconName: String
    var counters: [TallyCounter]
    var allowNegative: Bool = false
    var allowDecimals: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }
    
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// MARK: - App State

@Observable
class AppState {
    var categories: [TallyCategory] = [] {
        didSet {
            if !isRemoteUpdate {
                ConnectivityProvider.shared.send(categories: categories)
            }
        }
    }
    
    private var isRemoteUpdate = false
    
    init() {
        // Initial setup
        // Try to request data or wait for sync?
        // Since we don't persist in Watch explicitly in this snippet (maybe we should?), we start empty or wait.
        // But for prototype, let's keep the dummy data ONLY if no data received yet?
        // Actually, better to start empty and request data, or start with dummy.
        // Let's start with dummy but if sync happens it will overwrite.
        
       categories = [
            TallyCategory(name: "운동", colorName: "bg-blue-600", iconName: "dumbbell", counters: [
                TallyCounter(name: "푸쉬업", count: 15),
                TallyCounter(name: "스쿼트", count: 30)
            ]),
            TallyCategory(name: "수분", colorName: "bg-cyan-500", iconName: "droplet", counters: [
                TallyCounter(name: "물 (잔)", count: 3)
            ])
        ]
        
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] newCategories in
            DispatchQueue.main.async {
                self?.isRemoteUpdate = true
                self?.categories = newCategories
                self?.isRemoteUpdate = false
            }
        }
    }
    
    func updateCount(categoryId: UUID, counterId: UUID, delta: Double) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            var newCount = categories[catIndex].counters[ctrIndex].count + delta
            if !categories[catIndex].allowNegative && newCount < 0 { newCount = 0 }
            
            // Round to 1 decimal place
            newCount = (newCount * 10).rounded() / 10
            
            categories[catIndex].counters[ctrIndex].count = newCount
        }
    }
    
    func updateCategories(_ newCategories: [TallyCategory]) {
        self.categories = newCategories
    }
}
