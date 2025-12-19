
import SwiftUI
import LocalAuthentication

// 앱 설정 화면 뷰
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 사용자 설정을 유지하기 위한 @AppStorage 변수들
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    
    // 데이터 초기화 경고창 표시 여부 상태
    @State private var showingResetAlert = false
    
    // 로컬라이제이션 매니저 관찰 (언어 변경 시 리프레시)
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        List {
            // 섹션 1: 언어 설정
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
            
            // 섹션 2: 피드백 및 소리 설정
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
            
            // 섹션 3: 보안 설정
            LockSettingsView()
            
            // 섹션 4: 데이터 관리
            Section {
                Button(action: {
                    showingResetAlert = true
                }) {
                    Text("reset_data".localized)
                        .foregroundColor(.red)
                }
            } header: {
                Text("data_management".localized)
            }
        }
        .navigationTitle("") // 시스템 타이틀 제거
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 시스템 뒤로가기 버튼 숨김
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("settings".localized)
                    .font(.system(size: 20, weight: .bold)) // 폰트 크기 1.2배 키움
                    .foregroundColor(.primary)
            }
        }
        .alert("reset_data".localized, isPresented: $showingResetAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("delete".localized, role: .destructive) {
                // 데이터 초기화
                NotificationCenter.default.post(name: NSNotification.Name("ResetAllData"), object: nil)
            }
        } message: {
            Text("reset_warning".localized)
        }
    }
}

// 보안 설정 섹션 뷰
struct LockSettingsView: View {
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("useFaceID") private var useFaceID = false
    
    @State private var showingPinSetup = false
    @State private var showingBiometryError = false
    @State private var biometryErrorType = ""
    
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        Section(header: Text("security".localized),
                footer: Text("lock_description".localized).padding(.top, 4)) {
            
            // 잠금 활성화 토글
            Toggle("enable_lock".localized, isOn: $isLockEnabled)
            
            if isLockEnabled {
                // FaceID 설정
                Toggle("use_face_id".localized, isOn: $useFaceID)
                
                // 암호 변경 버튼
                Button(action: {
                    showingPinSetup = true
                }) {
                    HStack {
                        Text("change_pin".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPinSetup) {
            PinSetupView(isPresented: $showingPinSetup, isLockEnabled: $isLockEnabled)
        }
        .onChange(of: isLockEnabled) { _, newValue in
            if newValue {
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
    
    func checkBiometryAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "use_face_id".localized
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if !success {
                        useFaceID = false
                        if let error = authenticationError as? LAError {
                             biometryErrorType = getErrorMessage(error: error)
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
    
    func getErrorMessage(error: LAError) -> String {
        return error.localizedDescription
    }
}
