
import SwiftUI
import WatchKit

struct CounterView: View {
    @EnvironmentObject var appState: AppState
    
    let categoryId: UUID
    @State private var currentCounterId: UUID
    let color: Color
    
    // 애니메이션 방향 제어를 위한 상태
    @State private var slideEdge: Edge = .trailing
    
    init(categoryId: UUID, counterId: UUID, color: Color) {
        self.categoryId = categoryId
        self._currentCounterId = State(initialValue: counterId)
        self.color = color
    }
    
    // Computed property lookup
    var counter: TallyCounter? {
        if let cat = appState.categories.first(where: { $0.id == categoryId }),
           let ctr = cat.counters.first(where: { $0.id == currentCounterId }) {
            return ctr
        }
        return nil
    }
    
    // 애니메이션 및 알림 상태
    @State private var scale: CGFloat = 1.0
    @State private var showingResetAlert = false
    
    // 토스트 상태
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            // 배경 / 전체 터치 영역
            Color.black.ignoresSafeArea()
            
            if let counter = counter {
                VStack {
                    // 상단: 카운터 이름
                    Text(counter.name)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .padding(.top, 2)
                    
                    Spacer()
                    
                    // 중앙: 큰 숫자 표시
                    let displayString = counter.count.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", counter.count) : String(format: "%.1f", counter.count)
                    
                    Text(displayString)
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundStyle(appState.categories.first(where: { $0.id == categoryId })?.color ?? color)
                        .scaleEffect(scale) // 탭 시 커지는 애니메이션 효과
                        .shadow(radius: 5)
                        .onTapGesture {
                            increment()
                        }
                    
                    // 탭 안내 문구
                    Text("tap_to_count".localized.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                        .allowsHitTesting(false) // 터치 이벤트를 배경으로 전달
                    
                    Spacer()
                    
                    // 하단 컨트롤: 초기화 및 감소 버튼
                    VStack(spacing: 8) {
                        HStack {
                            // 초기화 버튼
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            // 감소 버튼
                            Button(action: {
                                decrement()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.gray)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 페이지 인디케이터 (Dots)
                        if let category = appState.categories.first(where: { $0.id == categoryId }) {
                            HStack(spacing: 5) {
                                ForEach(category.counters, id: \.id) { counter in
                                    Circle()
                                        .fill(counter.id == currentCounterId ? Color.white : Color.gray.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                        .animation(.easeInOut, value: currentCounterId)
                                }
                            }
                            .padding(.bottom, 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                .id(currentCounterId) // 뷰 식별을 위한 ID 설정 (전환 애니메이션용)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge),
                    removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentCounterId)
                
                .contentShape(Rectangle()) // 빈 영역도 터치 가능하도록 설정
                .onTapGesture {
                    increment()
                }
                // 초기화 확인 알림
                .alert("reset_data".localized, isPresented: $showingResetAlert) {
                    Button("cancel".localized, role: .cancel) { }
                    Button("reset_data".localized, role: .destructive) {
                        appState.resetCount(categoryId: categoryId, counterId: currentCounterId)
                    }
                } message: {
                    Text("reset_counter_msg".localized)
                }
            } else {
                Text("Counter deleted")
                    .foregroundStyle(.gray)
            }
            
            // 토스트 뷰
            if showToast {
                ToastView(message: toastMessage) // 기본 하단 패딩 20
                    .zIndex(2)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    // 수평 스와이프인지 확인
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 {
                            // 왼쪽 스와이프 -> 다음 항목
                            switchCounter(direction: 1)
                        } else {
                            // 오른쪽 스와이프 -> 이전 항목
                            switchCounter(direction: -1)
                        }
                    }
                }
        )
    }
    
    // 카운터 전환 함수 (무한 순환)
    private func switchCounter(direction: Int) {
        guard let category = appState.categories.first(where: { $0.id == categoryId }),
              !category.counters.isEmpty,
              let currentIndex = category.counters.firstIndex(where: { $0.id == currentCounterId }) else {
            return
        }
        
        let totalCount = category.counters.count
        // 다음 인덱스 계산 (무한 루프)
        let nextIndex = (currentIndex + direction + totalCount) % totalCount
        
        // 애니메이션 방향 설정
        slideEdge = direction > 0 ? .trailing : .leading
        
        // ID 업데이트
        withAnimation {
            currentCounterId = category.counters[nextIndex].id
        }
    }
    
    // 카운트 증가 및 애니메이션
    private func increment() {
        guard let counter = counter else { return }
        
        // 최대값 제한 체크
        if abs(counter.count + 1) > AppConstants.maxValue {
            WKInterfaceDevice.current().play(.failure)
            showLimitToast()
            return
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.2
        }
        // Use AppState to update and trigger sync
        appState.updateCount(categoryId: categoryId, counterId: currentCounterId, delta: 1)
        
        // 애니메이션 복귀
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            withAnimation {
                scale = 1.0
            }
        }
    }
    
    // 카운트 감소 (0 미만 방지 로직 포함)
    private func decrement() {
        guard let counter = counter else { return }
        
        // 최대값 제한 체크 (음수 방향도 제한이 필요하다면 여기서 체크, 보통은 0 제한이 우선)
        // 여기서는 논리적으로 -maxValue 도달 가능성을 열어두되, 보통 0이 하한선.
        // 하지만 updateCount 내에서 allowNegative 체크를 하므로, 여기서는 maxValue만 체크.
        // (단, 감소해서 -9999999가 될 수도 있으므로 체크)
        if abs(counter.count - 1) > AppConstants.maxValue {
            WKInterfaceDevice.current().play(.failure)
            showLimitToast()
            return
        }
        
        appState.updateCount(categoryId: categoryId, counterId: currentCounterId, delta: -1)
    }
    
    // 토스트 표시 헬퍼
    private func showLimitToast() {
        toastMessage = "max_value_reached".localized
        withAnimation { showToast = true }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showToast = false }
        }
    }
}
