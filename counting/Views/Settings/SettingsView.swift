
import SwiftUI
import LocalAuthentication

// 앱 설정 화면 뷰
struct SettingsView: View {
    
    // 사용자 설정을 유지하기 위한 @AppStorage 변수들
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("useThousandSeparator") private var useThousandSeparator = false // 1000 단위 구분 기호
    
    // 데이터 초기화 경고창 표시 여부 상태
    @State private var showingResetAlert = false
    
    // PIN 설정 화면 표시 여부 및 로직 상태
    @State private var showingPinSetup = false
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("useFaceID") private var useFaceID = false
    
    // 생체 인증 에러 상태
    @State private var showingBiometryError = false
    @State private var biometryErrorType = ""
    
    // 로컬라이제이션 매니저 관찰
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        List {
            languageSection
            displaySection
            feedbackSection
            LockSettingsView(showingPinSetup: $showingPinSetup)
            dataManagementSection
            appInfoSection
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("settings".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        // 모달 및 알림 처리 (상위 뷰에서 통합 관리)
        .fullScreenCover(isPresented: $showingPinSetup) {
            PinSetupView(isPresented: $showingPinSetup, isLockEnabled: $isLockEnabled)
        }
        .alert("reset_data".localized, isPresented: $showingResetAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("delete".localized, role: .destructive) {
                NotificationCenter.default.post(name: NSNotification.Name("ResetAllData"), object: nil)
            }
        } message: {
            Text("reset_warning".localized)
        }
        // 보안 설정 로직 처리
        .onChange(of: isLockEnabled) { _, newValue in
            if newValue {
                // 잠금을 켰는데 PIN이 없으면 설정 화면으로 이동
                if KeychainHelper.shared.readPin() == nil {
                    isLockEnabled = false
                    showingPinSetup = true
                }
            }
        }
        .onChange(of: useFaceID) { _, newValue in
            if newValue {
                checkBiometryAvailability()
            }
        }
        .alert("biometry_error".localized, isPresented: $showingBiometryError) {
            Button("confirm".localized) { }
        } message: {
            Text(biometryErrorType)
        }
    }
    
    // MARK: - Subviews
    
    private var languageSection: some View {
        Section {
            Picker("language".localized, selection: $l10n.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("language".localized)
        }
    }
    
    private var displaySection: some View {
        Section {
            Toggle("use_thousand_separator".localized, isOn: $useThousandSeparator)
        } header: {
            Text("display".localized)
        }
    }
    
    private var feedbackSection: some View {
        Section {
            Toggle("haptic_feedback".localized, isOn: $hapticFeedbackEnabled)
                .onChange(of: hapticFeedbackEnabled) { _, newValue in
                    if newValue {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
            Toggle("sound_effects".localized, isOn: $soundEffectsEnabled)
        } header: {
            Text("feedback".localized)
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            Button(action: {
                showingResetAlert = true
            }) {
                Text("reset_data".localized)
                .foregroundStyle(.red)
            }
        } header: {
            Text("data_management".localized)
        }
    }
    
    private var appInfoSection: some View {
        Section {
            NavigationLink(destination: AppInfoView()) {
                HStack {
                    Text("app_info".localized)
                        .foregroundStyle(.primary)
                }
            }
        } header: {
            Text("app_info".localized)
        }
    }
    
    // 생체 인증 가능 여부 확인 (Swift 6 Concurrency 적용)
    func checkBiometryAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "use_face_id".localized
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                Task { @MainActor in
                    if !success {
                        useFaceID = false
                        if let error = authenticationError as? LAError {
                             biometryErrorType = error.localizedDescription
                        } else {
                            biometryErrorType = "Authentication failed"
                        }
                        showingBiometryError = true
                    }
                }
            }
        } else {
            useFaceID = false
            biometryErrorType = error?.localizedDescription ?? "Face ID not available"
            showingBiometryError = true
        }
    }
}

// 보안 설정 섹션 뷰 (순수 UI 컴포넌트)
struct LockSettingsView: View {
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("useFaceID") private var useFaceID = false
    @AppStorage("lockTimeout") private var lockTimeout = 0
    
    @Binding var showingPinSetup: Bool
    
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        Section(header: Text("security".localized),
                footer: Text("lock_description".localized).padding(.top, 4)) {
            
            // 잠금 활성화 토글
            Toggle("enable_lock".localized, isOn: $isLockEnabled)
            
            if isLockEnabled {
                // FaceID 설정
                Toggle("use_face_id".localized, isOn: $useFaceID)
                
                // 잠금 시간 설정
                Picker("lock_timeout".localized, selection: $lockTimeout) {
                    Text("timeout_immediate".localized).tag(0)
                    Text("timeout_10s".localized).tag(10)
                    Text("timeout_30s".localized).tag(30)
                    Text("timeout_1m".localized).tag(60)
                    Text("timeout_5m".localized).tag(300)
                    Text("timeout_10m".localized).tag(600)
                    Text("timeout_30m".localized).tag(1800)
                    Text("timeout_1h".localized).tag(3600)
                }
                
                // 암호 변경 버튼
                Button(action: {
                    showingPinSetup = true
                }) {
                    HStack {
                        Text("change_pin".localized)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(.systemGray3))
                    }
                }
            }
        }
    }
}
