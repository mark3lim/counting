
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
        // Start empty and request data from iOS
        categories = []
        
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] newCategories in
            DispatchQueue.main.async {
                self?.isRemoteUpdate = true
                self?.categories = newCategories
                self?.isRemoteUpdate = false
            }
        }
        
        // 데이터 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ConnectivityProvider.shared.requestData()
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
