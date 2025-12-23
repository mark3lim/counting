import Combine
import SwiftUI

// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
struct TallyCounter: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID() // 고유 식별자
    var name: String      // 카운터 이름 (예: "푸쉬업", "물 마시기")
    var count: Double     // 현재 카운트 값
}

// 카테고리 모델
// 카운터들을 그룹화하는 카테고리입니다.
struct TallyCategory: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()           // 고유 식별자
    var name: String                // 카테고리 이름 (예: "운동")
    var colorName: String           // 테마 색상 이름 (예: "bg-blue-600")
    var iconName: String            // 아이콘 이름 (SF Symbols 또는 Lucide)
    var counters: [TallyCounter]    // 이 카테고리에 포함된 카운터 목록
    var allowNegative: Bool = false // 음수 사용 허용 여부
    var allowDecimals: Bool = false // 소수점 사용 허용 여부
    var createdAt: String = ""      // 생성일
    var updatedAt: String = ""      // 수정일
    
    // CodingKeys to exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, name, colorName, iconName, counters, allowNegative, allowDecimals, createdAt, updatedAt
    }
    
    // Custom init to set timestamps
    init(id: UUID = UUID(), name: String, colorName: String, iconName: String, 
         counters: [TallyCounter], allowNegative: Bool = false, allowDecimals: Bool = false,
         createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.iconName = iconName
        self.counters = counters
        self.allowNegative = allowNegative
        self.allowDecimals = allowDecimals
        let now = ISO8601DateFormatter().string(from: Date())
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }
    
    // Explicit nonisolated Codable implementation for Swift 6 compatibility
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.colorName = try container.decode(String.self, forKey: .colorName)
        self.iconName = try container.decode(String.self, forKey: .iconName)
        self.counters = try container.decode([TallyCounter].self, forKey: .counters)
        self.allowNegative = try container.decodeIfPresent(Bool.self, forKey: .allowNegative) ?? false
        self.allowDecimals = try container.decodeIfPresent(Bool.self, forKey: .allowDecimals) ?? false
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(counters, forKey: .counters)
        try container.encode(allowNegative, forKey: .allowNegative)
        try container.encode(allowDecimals, forKey: .allowDecimals)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - TallyCategory UI Extensions (MainActor)
// 연산 프로퍼티를 별도 extension으로 분리하여 Sendable 준수 유지
extension TallyCategory {
    // colorName 문자열을 SwiftUI Color 객체로 변환하는 연산 프로퍼티
    @MainActor
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }

    // iconName 문자열을 SF Symbol 이름으로 변환하는 연산 프로퍼티
    @MainActor
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// 데이터 저장소 클래스 (ViewModel)
// 앱의 모든 데이터를 관리하고 UserDefaults에 영구 저장합니다.
@MainActor
class TallyStore: ObservableObject {
    // 카테고리 목록을 저장하는 배열
    // 변경될 때마다 save() 메서드가 호출되어 자동으로 저장됩니다.
    @Published var categories: [TallyCategory] = [] {
        didSet {
             save()
        }
    }
    
    private func applyRemoteUpdate(_ newCategories: [TallyCategory]) {
        // ConnectivityProvider already dispatches to Main, but explicit check doesn't hurt or relies on MainActor isolation
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
        // MainActor context에서 동기적으로 로드 (init은 암시적으로 isolated 될 수 있음)
        // load() 및 setup을 수행
        // 주의: init 내부에서 self 캡처 시 비동기 처리 주의
        
        // Load data synchronously
        if let data = UserDefaults.standard.data(forKey: "saved_categories"),
           let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
            self.categories = decoded
        } else {
            self.categories = []
        }
        
        // Setup Callbacks
        // ConnectivityProvider 콜백은 백그라운드 스레드에서 올 수 있으므로 Task { @MainActor }로 감싸서 처리
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] receivedCategories in
            Task { @MainActor [weak self] in
                self?.applyRemoteUpdate(receivedCategories)
            }
        }
        
        ConnectivityProvider.shared.onRequestData = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                ConnectivityProvider.shared.send(categories: self.categories)
            }
        }
        
        // 데이터 초기화 알림 수신
        NotificationCenter.default.addObserver(self, selector: #selector(handleResetAllData), name: NSNotification.Name("ResetAllData"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleResetAllData() {
        Task { @MainActor [weak self] in
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
    
    // addCategory, importCategory 등 모든 메서드는 @MainActor 클래스 내부에 있으므로
    // 기본적으로 Main thread에서 실행됨을 보장받습니다.

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
    
    // 카운터 값을 직접 설정하는 메서드
    func updateExplicitCount(categoryId: UUID, counterId: UUID, newCount: Double) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        var count = newCount
        if !categories[catIndex].allowNegative && count < 0 {
            count = 0
        }
        
        // 소수점 첫째 자리까지만 유지 (반올림)
        count = (count * 10).rounded() / 10
        
        categories[catIndex].counters[counterIndex].count = count
        // 데이터가 변경되었으므로 카테고리 수정 시간 갱신
        categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
        
        // Manual Send triggered by user action
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
