import Combine
import SwiftUI

// 단일 카운터 모델
// 각 카운터의 고유 ID, 이름, 현재 카운트 값을 저장합니다.
struct TallyCounter: Identifiable, Codable {
    var id: UUID = UUID() // 고유 식별자
    var name: String      // 카운터 이름 (예: "푸쉬업", "물 마시기")
    var count: Int        // 현재 카운트 값
}

// 카테고리 모델
// 카운터들을 그룹화하는 카테고리입니다.
struct TallyCategory: Identifiable, Codable {
    var id: UUID = UUID()           // 고유 식별자
    var name: String                // 카테고리 이름 (예: "운동")
    var colorName: String           // 테마 색상 이름 (예: "bg-blue-600")
    var iconName: String            // 아이콘 이름 (SF Symbols 또는 Lucide)
    var counters: [TallyCounter]    // 이 카테고리에 포함된 카운터 목록
    var createdAt: Date = Date()    // 생성일
    var updatedAt: Date = Date()    // 수정일

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

    // UserDefaults에 저장할 때 사용할 키
    private let saveKey = "tally_categories_data"

    // 초기화 시 데이터를 로드합니다.
    init() {
        load()
    }

    // 데이터를 UserDefaults에 JSON 형태로 인코딩하여 저장합니다.
    private func save() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

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
    func addCategory(name: String, colorName: String, iconName: String) {
        let newCategory = TallyCategory(
            name: name,
            colorName: colorName,
            iconName: iconName,
            counters: []
        )
        categories.append(newCategory)
    }

    // 기존 카테고리 정보를 수정하는 메서드
    func updateCategory(category: TallyCategory, name: String, colorName: String, iconName: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].name = name
            categories[index].colorName = colorName
            categories[index].iconName = iconName
            categories[index].updatedAt = Date()
        }
    }

    // 카테고리를 삭제하는 메서드
    func deleteCategory(categoryId: UUID) {
        categories.removeAll { $0.id == categoryId }
    }

    // 특정 카테고리에 새로운 카운터를 추가하는 메서드
    func addCounter(to categoryId: UUID, name: String, initialCount: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let newCounter = TallyCounter(name: name, count: initialCount)
        categories[index].counters.append(newCounter)
    }

    // 카운터를 삭제하는 메서드
    func deleteCounter(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[catIndex].counters.removeAll { $0.id == counterId }
    }

    // 특정 카운터의 숫자를 증가시키거나 감소시키는 메서드
    func updateCount(categoryId: UUID, counterId: UUID, delta: Int) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        var count = categories[catIndex].counters[counterIndex].count + delta
        if count < 0 { count = 0 } // 카운터가 음수가 되지 않도록 방지
        categories[catIndex].counters[counterIndex].count = count
    }

    // 카운터의 이름을 변경하는 메서드
    func renameCounter(categoryId: UUID, counterId: UUID, newName: String) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].name = newName
    }

    // 카운터의 숫자를 0으로 초기화하는 메서드
    func resetCount(categoryId: UUID, counterId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
            let counterIndex = categories[catIndex].counters.firstIndex(where: {
                $0.id == counterId
            })
        else { return }

        categories[catIndex].counters[counterIndex].count = 0
    }

    // 모든 데이터를 삭제하고 초기화하는 메서드 (설정 화면에서 사용됨)
    func resetAllData() {
        categories = []
    }
}
