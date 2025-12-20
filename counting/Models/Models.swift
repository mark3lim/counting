import Combine
import SwiftUI

// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
struct TallyCounter: Identifiable, Codable, Hashable {
    var id: UUID = UUID() // 고유 식별자
    var name: String      // 카운터 이름 (예: "푸쉬업", "물 마시기")
    var count: Double     // 현재 카운트 값
}

// 카테고리 모델
// 카운터들을 그룹화하는 카테고리입니다.
struct TallyCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()           // 고유 식별자
    var name: String                // 카테고리 이름 (예: "운동")
    var colorName: String           // 테마 색상 이름 (예: "bg-blue-600")
    var iconName: String            // 아이콘 이름 (SF Symbols 또는 Lucide)
    var counters: [TallyCounter]    // 이 카테고리에 포함된 카운터 목록
    var allowNegative: Bool = false // 음수 사용 허용 여부
    var allowDecimals: Bool = false // 소수점 사용 허용 여부
    var createdAt: String = ISO8601DateFormatter().string(from: Date())    // 생성일
    var updatedAt: String = ISO8601DateFormatter().string(from: Date())    // 수정일

    // colorName 문자열을 SwiftUI Color 객체로 변환하는 연산 프로퍼티
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }

    // iconName 문자열을 SF Symbol 이름으로 변환하는 연산 프로퍼티
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// 데이터 저장소 클래스 (ViewModel)
// 앱의 모든 데이터를 관리하고 UserDefaults에 영구 저장합니다.
class TallyStore: ObservableObject {
    // 카테고리 목록을 저장하는 배열
    // 변경될 때마다 save() 메서드가 호출되어 자동으로 저장됩니다.
    @Published var categories: [TallyCategory] = [] {
        didSet {
             save()
        }
    }
    
    private func applyRemoteUpdate(_ newCategories: [TallyCategory]) {
        // ConnectivityProvider already dispatches to Main
        guard !isRemoteUpdate else { return }
        
        // Loop Prevention
        self.isRemoteUpdate = true
        defer { self.isRemoteUpdate = false }
        
        // Merge Logic: Update ONLY counts from Watch, preserve other metadata
        for remoteCat in newCategories {
            if let localCatIndex = self.categories.firstIndex(where: { $0.id == remoteCat.id }) {
                for remoteCounter in remoteCat.counters {
                    if let localCounterIndex = self.categories[localCatIndex].counters.firstIndex(where: { $0.id == remoteCounter.id }) {
                         // Only update if value changed to avoid unnecessary churn
                         if self.categories[localCatIndex].counters[localCounterIndex].count != remoteCounter.count {
                             self.categories[localCatIndex].counters[localCounterIndex].count = remoteCounter.count
                         }
                    }
                }
                // Update timestamp 
                self.categories[localCatIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
            }
        }
    }

    // Singleton instance
    static let shared = TallyStore()
    
    // UserDefaults key
    private let saveKey = "saved_categories"
    
    // Flag to prevent infinite sync loops
    private var isRemoteUpdate = false
    
    // 초기화 시 데이터를 로드합니다.
    init() {
        load()
        
        // 앱 시작 시 Watch로 데이터 전송 시도
        // Proactive sync removed to prevent overwriting Watch data on launch
        
        // Handle incoming data from Watch
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] receivedCategories in
            guard let self = self else { return }
            self.applyRemoteUpdate(receivedCategories)
        }
        
        ConnectivityProvider.shared.onRequestData = { [weak self] in
            guard let self = self else { return }
            ConnectivityProvider.shared.send(categories: self.categories)
        }
        
        // 데이터 초기화 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(handleResetAllData), name: NSNotification.Name("ResetAllData"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleResetAllData() {
        DispatchQueue.main.async { [weak self] in
            self?.resetAllData()
        }
    }
    
    // 데이터를 UserDefaults에 JSON 형태로 인코딩하여 저장합니다.
    private func save() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    // areContentsEqual removed
    
    // UserDefaults에서 데이터를 로드하여 디코딩합니다.
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
            self.categories = decoded
            return
        }

        // 저장된 데이터가 없을 경우 빈 배열로 초기화합니다.
        self.categories = []
    }

    // 새로운 카테고리를 추가하는 메서드
    func addCategory(name: String, colorName: String, iconName: String, allowNegative: Bool, allowDecimals: Bool) {
        let newCategory = TallyCategory(
            name: name,
            colorName: colorName,
            iconName: iconName,
            counters: [],
            allowNegative: allowNegative,
            allowDecimals: allowDecimals
        )
        categories.append(newCategory)
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 외부에서 가져온 카테고리(카운터 포함)를 추가하는 메서드
    func importCategory(_ category: TallyCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 기존 카테고리 정보를 수정하는 메서드
    func updateCategory(category: TallyCategory, name: String, colorName: String, iconName: String, allowNegative: Bool, allowDecimals: Bool) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].name = name
            categories[index].colorName = colorName
            categories[index].iconName = iconName
            categories[index].allowNegative = allowNegative
            categories[index].allowDecimals = allowDecimals
            categories[index].updatedAt = ISO8601DateFormatter().string(from: Date())
            ConnectivityProvider.shared.send(categories: categories)
        }
    }

    // 카테고리를 삭제하는 메서드
    func deleteCategory(categoryId: UUID) {
        categories.removeAll { $0.id == categoryId }
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 여러 카테고리를 한 번에 삭제하는 메서드
    func deleteCategories(ids: Set<UUID>) {
        categories.removeAll { ids.contains($0.id) }
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 특정 카테고리에 새로운 카운터를 추가하는 메서드
    func addCounter(to categoryId: UUID, name: String, initialCount: Double) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let newCounter = TallyCounter(name: name, count: initialCount)
        categories[index].counters.append(newCounter)
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 카운터를 삭제하는 메서드
    func deleteCounter(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[catIndex].counters.removeAll { $0.id == counterId }
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 특정 카운터의 숫자를 증가시키거나 감소시키는 메서드
    func updateCount(categoryId: UUID, counterId: UUID, delta: Double) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        var count = categories[catIndex].counters[counterIndex].count + delta
        if !categories[catIndex].allowNegative && count < 0 { 
            count = 0 
        } // 음수 비허용 시 0 미만 방지
        
        // 소수점 첫째 자리까지만 유지 (반올림)
        count = (count * 10).rounded() / 10
        
        categories[catIndex].counters[counterIndex].count = count
        // 데이터가 변경되었으므로 카테고리 수정 시간 갱신
        categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
        
        // Manual Send triggered by user action
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 카운터의 이름을 변경하는 메서드
    func renameCounter(categoryId: UUID, counterId: UUID, newName: String) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].name = newName
        categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 카운터의 숫자를 0으로 초기화하는 메서드
    func resetCount(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].count = 0.0
        categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
        
        // Manual Send triggered by user action
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 특정 카테고리의 모든 카운터를 0으로 초기화하는 메서드
    func resetCategoryCounters(categoryId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }

        for i in 0..<categories[catIndex].counters.count {
            categories[catIndex].counters[i].count = 0.0
        }
        categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
        
        ConnectivityProvider.shared.send(categories: categories)
    }

    // 모든 데이터를 삭제하고 초기화하는 메서드 (설정 화면에서 사용됨)
    func resetAllData() {
        categories = []
        ConnectivityProvider.shared.send(categories: categories)
    }
    

}
