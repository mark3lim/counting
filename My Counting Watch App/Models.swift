
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
import Observation

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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
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

@Observable
class AppState {
    // 카테고리 목록
    private let saveKey = "watch_saved_categories"
    
    // Flag to prevent infinite sync loops
    private var isRemoteUpdate = false
    
    // 초기화
    init() {
        load()
        
        // Handle incoming data from iOS
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] receivedCategories in
            guard let self = self else { return }
            self.applyRemoteUpdate(receivedCategories)
        }
    }
    
    // 카테고리 목록 변경 시 처리
    // Observation 매크로로 인해 프로퍼티 변경 시 UI 업데이트됨
    var categories: [TallyCategory] = [] {
        didSet {
            // 변경사항 영구 저장
            save()
            
            if !isRemoteUpdate {
                print("Sending update to iOS")
                ConnectivityProvider.shared.send(categories: categories)
            }
        }
    }
    
    private func applyRemoteUpdate(_ newCategories: [TallyCategory]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isRemoteUpdate = true
            self.categories = newCategories
            self.isRemoteUpdate = false
        }
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
            categories[catIndex].updatedAt = Date() // 수정 시간 갱신
        }
    }
    
    // 카테고리 전체 업데이트 메서드 (Deprecated - use mergeCategories)
    func updateCategories(_ newCategories: [TallyCategory], isRemote: Bool = false) {
       // 호환성을 위해 남겨두거나 삭제
    }
}
