
//
//  Models.swift
//  My Counting Watch App
//
//  Created by MARKLIM on 2025-12-07.
//
//  데이터 모델 및 앱 상태(AppState)를 정의하는 파일입니다.
//  iOS 앱과 동일한 구조체를 사용하여 데이터를 동기화합니다.
//

import SwiftUI
import Combine

// MARK: - 공유 모델 (iOS 앱과 동일)

// MARK: - 공유 모델 (iOS 앱과 동일)

struct TallyCounter: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var count: Double
}


struct TallyCategory: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var colorName: String
    var iconName: String
    var counters: [TallyCounter]
    var allowNegative: Bool = false
    var allowDecimals: Bool = false
    
    var createdAt: String = ""
    var updatedAt: String = ""
    
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
extension TallyCategory {
    // 테마 색상 반환
    @MainActor
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }
    
    // 아이콘 이름 반환
    @MainActor
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// MARK: - 앱 상태 관리 (AppState)

@MainActor
class AppState: ObservableObject {
    // 카테고리 목록
    private let saveKey = "watch_saved_categories"
    
    // Flag to prevent infinite sync loops
    private var isRemoteUpdate = false
    
    @Published var isLoading = false
    
    // Flag to prevent multiple initial requests
    private static var hasRequestedInitialData = false
    
    // 초기화
    init() {
        // 동기적으로 로드
        if let data = UserDefaults.standard.data(forKey: "watch_saved_categories"),
           let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
            self.categories = decoded
        } else {
            self.categories = []
        }
        
        // Handle incoming data from iOS
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] receivedCategories in
            Task { @MainActor [weak self] in
                self?.applyRemoteUpdate(receivedCategories)
            }
        }
        
        // Request latest data ONLY ONCE per app session
        if !Self.hasRequestedInitialData {
            Self.hasRequestedInitialData = true
            isLoading = true
            ConnectivityProvider.shared.requestInitialData()
            
            // Set a timeout to turn off loading if not reachable
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                // Check if self still exists and needed
                self.isLoading = false
            }
        }
    }
    
    // 카테고리 목록 변경 시 처리
    @Published var categories: [TallyCategory] = [] {
        didSet {
            // 변경사항 영구 저장
            save()
        }
    }
    
    private func applyRemoteUpdate(_ newCategories: [TallyCategory]) {
        // ConnectivityProvider already dispatches to Main
        // Loop Prevention
        self.isRemoteUpdate = true
        defer { self.isRemoteUpdate = false }
        
        // Watch Logic: Full Sync from iOS
        self.categories = newCategories
        self.isLoading = false
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // load() removed from init to avoid double loading or async issues, logic moved to init
    
    // MARK: - Merge Logic
    
    // 특정 카운터 값 업데이트 메서드
    func updateCount(categoryId: UUID, counterId: UUID, delta: Double) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            var newCount = categories[catIndex].counters[ctrIndex].count + delta
            
            // 음수 허용 여부 체크
            if !categories[catIndex].allowNegative && newCount < 0 { newCount = 0 }
            
            // 소수점 첫째 자리 반올림
            newCount = (newCount * 10).rounded() / 10
            
            // 최대값 제한
            if abs(newCount) > AppConstants.maxValue { return }
            
            categories[catIndex].counters[ctrIndex].count = newCount
            categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date()) // 수정 시간 갱신
            
            // Only send update to iOS when user manually changes count
            ConnectivityProvider.shared.send(categories: categories)
        }
    }
    func resetCount(categoryId: UUID, counterId: UUID) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            categories[catIndex].counters[ctrIndex].count = 0.0
            categories[catIndex].updatedAt = ISO8601DateFormatter().string(from: Date())
            
            // Manual Send
            ConnectivityProvider.shared.send(categories: categories)
        }
    }
    // 카테고리 전체 업데이트 메서드 (Deprecated - use mergeCategories)
    func updateCategories(_ newCategories: [TallyCategory], isRemote: Bool = false) {
       // 호환성을 위해 남겨두거나 삭제
    }
}
