
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
    // 변경 시(didSet) iPhone으로 데이터를 전송하여 동기화합니다.
    // 동기화 상태 표시를 위한 플래그
    var isSyncing = false
    
    // 원격 업데이트 중 무한 루프 방지 및 save 호출 제어
    private var isRemoteUpdate = false
    private let saveKey = "watch_tally_categories_data"

    init() {
        // 1. 로컬 저장 데이터 로드 (Persistence)
        load()
        
        // 2. ConnectivityProvider로부터 데이터 수신 시 처리
        ConnectivityProvider.shared.onReceiveCategories = { [weak self] newCategories in
            DispatchQueue.main.async {
                self?.isSyncing = true
                self?.isRemoteUpdate = true
                self?.mergeCategories(newCategories)
                self?.isRemoteUpdate = false
                
                // 잠시 후 동기화 표시 끔
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.isSyncing = false
                }
            }
        }
        
        ConnectivityProvider.shared.onReset = { [weak self] in
            DispatchQueue.main.async {
                self?.isRemoteUpdate = true
                self?.categories = [] // 전체 초기화
                self?.isRemoteUpdate = false
                self?.save()
            }
        }
        
        // 3. 초기 데이터 요청 (iPhone에 최신 데이터 요청)
        // Watch는 항상 iPhone 데이터를 최신으로 간주하려 시도
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ConnectivityProvider.shared.requestData()
        }
    }
    
    // 카테고리 목록 변경 시 처리
    // Observation 매크로로 인해 프로퍼티 변경 시 UI 업데이트됨
    var categories: [TallyCategory] = [] {
        didSet {
            // 변경사항 영구 저장
            save()
            
            // 사용자가 직접 변경한 경우(Remote Update가 아님)에만 iPhone으로 전송
            if !isRemoteUpdate {
                ConnectivityProvider.shared.send(categories: categories)
            }
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
            // 로드 시에는 전송하지 않도록 플래그 설정
            isRemoteUpdate = true
            self.categories = decoded
            isRemoteUpdate = false
        } else {
            self.categories = []
        }
    }
    
    // MARK: - Merge Logic
    
    private func mergeCategories(_ remoteCategories: [TallyCategory]) {
        // hasChanges 변수는 categories가 변경될 때 didSet이 트리거 되므로 불필요하여 제거됨.
        
        // 1. 들어온 데이터가 비어있다면?
        if remoteCategories.isEmpty {
            // iPhone에 데이터가 하나도 없다는 뜻일 수 있음.
            // 하지만 Watch에 데이터가 있다면? 실수로 지워지는 것 방지.
            // 사용자 시나리오: iPhone 앱 재설치 -> iPhone 빔 -> Watch 데이터 살아있어야 함 -> Watch가 iPhone에 쏴줘야 함.
            if !categories.isEmpty {
                // 내 데이터가 있으므로, 오히려 iPhone으로 보내줘야 함.
                // receive 핸들러 안이므로 send 호출은 init의 requestData 응답이거나 send에 대한 ack일 수 있음.
                // 여기서는 로컬 데이터를 유지하고 아무것도 안함 (내 데이터가 더 소중함).
                // 추후 내가 변경하면 그때 send 로 전송될 것임.
                return
            }
        }
        
        // 2. 병합 수행 (iPhone 데이터 우선 반영)
        // 로컬(Watch) 데이터를 순회하며 업데이트하거나, 새로운 항목 추가
        
        // 2-1. Remote 데이터를 로컬에 반영 (업데이트 및 추가)
        for remoteCat in remoteCategories {
            if let localIndex = categories.firstIndex(where: { $0.id == remoteCat.id }) {
                // 타임스탬프 비교: Remote가 더 최신이거나 같으면 업데이트
                 if remoteCat.updatedAt >= categories[localIndex].updatedAt {
                     if categories[localIndex] != remoteCat {
                         categories[localIndex] = remoteCat
                     }
                 }
            } else {
                // 로컬에 없는 카테고리 추가
                categories.append(remoteCat)
            }
        }
        
        // 2-2. (선택) iPhone에서 삭제된 항목 처리?
        // "Sync" 관점에서는 iPhone에 없는 항목은 Watch에서도 지워져야 함.
        // 하지만 "Merge / Last Write" 관점에서는 조심스러움.
        // 안전하게 가기 위해: iPhone에서 온 리스트에 포함되지 않은 로컬 카테고리는 삭제 (단, 2-1 과정을 거친 후)
        // *주의*: 만약 네트워크 오류로 일부만 왔다면? -> JSON 전체가 오므로 그럴 일 없음.
        // *전략 수정*: iPhone이 Master Source of Truth이므로, iPhone 목록에 없는 것은 Watch에서 삭제하는 것이 맞음.
        // (단, Watch에서 오프라인 생성한게 있다면? -> 현재 UI상 불가능)
        
        let remoteIds = Set(remoteCategories.map { $0.id })
        let categoriesToDelete = categories.filter { !remoteIds.contains($0.id) }
        
        if !categoriesToDelete.isEmpty {
            categories.removeAll { !remoteIds.contains($0.id) }
        }
        
        // 변경 없음 상태여도, 만약 로드가 처음이라면 UI 리프레시 필요할 수 있으나 @Observable이 처리함
    }
    
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
