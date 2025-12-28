
import SwiftUI
import AudioToolbox

// 개별 카운터 화면 뷰
// 숫자를 세고, 리셋하고, 화면 켜짐 유지 등의 기능을 제공합니다.
struct TallyCounterView: View {
    let categoryId: UUID
    let counterId: UUID
    var onDismiss: (() -> Void)? = nil
    
    // 데이터 저장소 및 화면 전환 모드
    @EnvironmentObject var store: TallyStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject var l10n = LocalizationManager.shared

    // 애니메이션 및 시각 효과를 위한 상태 변수들
    @State private var scale: CGFloat = 1.0
    @State private var ripples: [Ripple] = []

    // 팝업 및 알림 상태 변수들
    @State private var showingRenamePopup = false
    @State private var showingResetAlert = false
    @State private var renameText = ""
    @State private var editingCount: Double = 0.0

    // 화면 항상 켜짐 기능 관련 상태
    @State private var isScreenAlwaysOn = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 사용자 설정 (햅틱, 사운드, 화면 표시)
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("useThousandSeparator") private var useThousandSeparator = false

    // 터치 시 발생하는 물결 효과(Ripple) 모델 구조체
    struct Ripple: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat = 0
        var opacity: Double = 0.4
    }

    // 현재 카테고리 데이터 조회
    var category: TallyCategory? {
        store.categories.first(where: { $0.id == categoryId })
    }

    // 현재 카운터 데이터 조회
    var counter: TallyCounter? {
        category?.counters.first(where: { $0.id == counterId })
    }

    var body: some View {
        if let category = category, let counter = counter {
            ZStack {
                // 배경색: 카테고리의 대표 색상을 전체 화면에 적용
                category.color.ignoresSafeArea(.all)

                // 메인 터치 영역 (컨트롤 버튼 뒤에 위치)
                GeometryReader { geometry in
                    ZStack {
                        // 1. 물결 효과 배경 (터치 간섭 방지)
                        Color.clear
                            .allowsHitTesting(false)
                        
                        // 2. 물결 효과 렌더링
                        ForEach(ripples) { ripple in
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 100, height: 100)
                                .scaleEffect(ripple.scale)
                                .opacity(ripple.opacity)
                                .position(x: ripple.x, y: ripple.y)
                        }

                        // 3. 중앙 텍스트 정보 (숫자 및 안내 문구)
                        VStack {
                            Text(counter.count, format: .number
                                .precision(.fractionLength(category.allowDecimals ? 1 : 0))
                                .grouping(useThousandSeparator ? .automatic : .never))
                                .font(.system(size: 140, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 10)
                                .scaleEffect(scale) // 숫자 튕김 애니메이션 적용
                                .lineLimit(1) // 한 줄 고정
                                .minimumScaleFactor(0.1) // 화면 폭에 맞춰 10%까지 축소하여 한 줄에 표시
                                .padding(.horizontal)

                            Text("tap_to_count".localized.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .padding(.top, 100) // 상단 헤더 영역 침범 방지
                        .allowsHitTesting(false) // 텍스트 위를 터치해도 카운트되도록 터치 이벤트 통과

                        // 4. 실제 터치 감지 영역 (화면 상단 50%)
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(height: geometry.size.height * 0.5)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("CounterArea"))
                                    .onEnded { value in
                                        // 터치 발생 시 카운트 증가 함수 호출
                                        triggerIncrement(location: value.location)
                                    }
                            )
                    }
                    .coordinateSpace(name: "CounterArea")
                }
                .ignoresSafeArea()
                .toolbar {
                    // Central Title (Category + Counter Name)
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(category.name)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Text(counter.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Edit (Rename) Button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            renameText = counter.name
                            editingCount = counter.count
                            showingRenamePopup = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar) // Transparent background
                // Force back button color to white
                .toolbarColorScheme(.dark, for: .navigationBar)

                // 하단 컨트롤 버튼 영역
                VStack {
                    Spacer()
                    HStack {
                        // 화면 항상 켜기/끄기 버튼
                        Button(action: {
                            isScreenAlwaysOn.toggle()
                            UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
                            
                            // 토스트 메시지 내용 설정
                            toastMessage = isScreenAlwaysOn ? "screen_always_on".localized : "screen_always_off".localized
                            
                            // 토스트 메시지 표시 애니메이션
                            withAnimation {
                                showToast = true
                            }
                            
                            // 3초 후 토스트 메시지 숨김 (Swift 6 Concurrency)
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(3))
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }) {
                            Image(systemName: isScreenAlwaysOn ? "lightbulb.circle.fill" : "lightbulb.circle")
                                .font(.system(size: 34))
                                .foregroundStyle(isScreenAlwaysOn ? .yellow : .white)
                                .frame(width: 100, height: 60)
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))

                        // 초기화 버튼
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 34))
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(width: 100, height: 60)
                        }
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.3))

                        // 감소 버튼
                        Button(action: {
                            let delta = category.allowDecimals ? -0.1 : -1.0
                            store.updateCount(categoryId: categoryId, counterId: counterId, delta: delta)
                            if hapticFeedbackEnabled {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                            if soundEffectsEnabled {
                                AudioServicesPlaySystemSound(1103)
                            }
                        }) {
                            Image(systemName: "minus.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .frame(width: 100, height: 60)
                        }
                    }
                    .background(Material.ultraThinMaterial) // 반투명 배경 재질
                    .cornerRadius(40)
                    .shadow(radius: 10)
                    .padding(.bottom, 40)
                    // 초기화 확인 알림창
                    .alert(isPresented: $showingResetAlert) {
                        Alert(
                            title: Text("reset_counter_title".localized),
                            message: Text("reset_counter_message".localized),
                            primaryButton: .destructive(Text("reset_action".localized)) {
                                store.resetCount(categoryId: categoryId, counterId: counterId)
                            },
                            secondaryButton: .cancel(Text("cancel".localized))
                        )
                    }
            }
            
            }
            // Standard back swipe is automatically handled by NavigationStack
            .blur(radius: showingRenamePopup ? 5 : 0) // 팝업 시 배경 블러 처리
            .onDisappear {
                // 화면을 벗어날 때 화면 켜짐 유지 기능 해제
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .alert("edit_counter".localized, isPresented: $showingRenamePopup) {
                TextField("counter_name_label".localized, text: $renameText)
                TextField("count".localized, value: $editingCount, format: .number)
                    .keyboardType(.numbersAndPunctuation)
                
                Button("cancel".localized, role: .cancel) { }
                Button("confirm".localized) {
                    if !renameText.isEmpty {
                        if abs(editingCount) > maxValue {
                            toastMessage = "max_value_reached".localized
                             withAnimation { showToast = true }
                             Task { @MainActor in
                                 try? await Task.sleep(for: .seconds(2))
                                 withAnimation { showToast = false }
                             }
                        } else {
                            store.renameCounter(categoryId: categoryId, counterId: counterId, newName: renameText)
                            store.updateExplicitCount(categoryId: categoryId, counterId: counterId, newCount: editingCount)
                        }
                    }
                }
            } message: {
                Text("") // Optional message
            }
            
            // 토스트 메시지 (화면 켜짐 설정 알림)
            if showToast {
                ToastView(message: toastMessage, bottomPadding: 120)
                    .zIndex(3)
            }
        } else {
            // 데이터가 없을 경우 표시되는 폴백 뷰 (안전 장치)
            Color.black.ignoresSafeArea()
                .onAppear {
                    dismiss()
                }
        }
    }

    // 최대 카운트 제한 (AddCounterView와 동일)
    private let maxValue: Double = AppConstants.maxValue

    // 카운트 증가 및 효과 발생 함수
    func triggerIncrement(location: CGPoint) {
        guard let category = category, let counter = counter else { return }
        
        let delta = category.allowDecimals ? 0.1 : 1.0
        let newCount = counter.count + delta
        
        // 제한 값 체크
        if abs(newCount) > maxValue {
            // 제한 도달 시 에러 햅틱 피드백
            if hapticFeedbackEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            
            // 토스트 메시지 표시
            toastMessage = "max_value_reached".localized
            withAnimation {
                showToast = true
            }
            
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showToast = false
                }
            }
            return
        }
        
        store.updateCount(categoryId: categoryId, counterId: counterId, delta: delta)
        
        // 햅틱 피드백
        if hapticFeedbackEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        // 사운드 재생 (시스템 틱 사운드)
        if soundEffectsEnabled {
            AudioServicesPlaySystemSound(1104)
        }

        // 숫자 튕김 애니메이션
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0)) {
            scale = 1.15
        }
        
        // Swift 6 Concurrency: Task & MainActor
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation {
                scale = 1.0
            }
        }

        // 물결 효과 생성
        let newRipple = Ripple(x: location.x, y: location.y)
        ripples.append(newRipple)

        // 일정 시간 후 물결 효과 제거 (Swift 6 Concurrency)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples.remove(at: index)
            }
        }
    }
}
