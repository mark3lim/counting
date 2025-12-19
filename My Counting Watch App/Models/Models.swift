
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
    
    // Shared formatter for consistency and performance
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    var createdAt: String = TallyCategory.iso8601Formatter.string(from: Date())
    var updatedAt: String = TallyCategory.iso8601Formatter.string(from: Date())
    
    // 테마 색상 반환
    var color: Color {
        return AppTheme.getColor(for: colorName)
    }
    
    // 아이콘 이름 반환
    var icon: String {
        return AppTheme.getIcon(for: iconName)
    }
}

// MARK: - 앱 상태 관리 (AppState)

// MARK: - 앱 상태 관리 (AppState)

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
        load()
        
        // Handle incoming data from iOS
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] receivedCategories in
            guard let self = self else { return }
            self.applyRemoteUpdate(receivedCategories)
        }
        
        // Request latest data ONLY ONCE per app session
        if !Self.hasRequestedInitialData {
            Self.hasRequestedInitialData = true
            isLoading = true
            ConnectivityProvider.shared.requestInitialData()
            
            // Set a timeout to turn off loading if not reachable
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isLoading = false
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
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TallyCategory].self, from: data) {
            self.categories = decoded
        } else {
            self.categories = []
        }
    }
    
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
            
            categories[catIndex].counters[ctrIndex].count = newCount
            categories[catIndex].counters[ctrIndex].count = newCount
            categories[catIndex].updatedAt = TallyCategory.iso8601Formatter.string(from: Date()) // 수정 시간 갱신
            
            // Only send update to iOS when user manually changes count
            ConnectivityProvider.shared.send(categories: categories)
        }
    }
    func resetCount(categoryId: UUID, counterId: UUID) {
        if let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
           let ctrIndex = categories[catIndex].counters.firstIndex(where: { $0.id == counterId }) {
            
            categories[catIndex].counters[ctrIndex].count = 0.0
            categories[catIndex].counters[ctrIndex].count = 0.0
            categories[catIndex].updatedAt = TallyCategory.iso8601Formatter.string(from: Date())
            
            // Manual Send
            ConnectivityProvider.shared.send(categories: categories)
        }
    }
    // 카테고리 전체 업데이트 메서드 (Deprecated - use mergeCategories)
    func updateCategories(_ newCategories: [TallyCategory], isRemote: Bool = false) {
       // 호환성을 위해 남겨두거나 삭제
    }
}
