import SwiftUI

// 앱 설정 화면 뷰
// 햅틱, 사운드, 보안 설정, 데이터 관리 등의 기능을 제공합니다.
struct SettingsView: View {
    // 사용자 설정을 유지하기 위한 @AppStorage 변수들
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("isLockEnabled") private var isLockEnabled = false // 앱 잠금 사용 여부
    @AppStorage("useFaceID") private var useFaceID = false        // FaceID 사용 여부
    
    // 데이터 초기화 경고창 표시 여부 상태
    @State private var showResetAlert = false
    
    // 데이터 저장소 및 화면 전환 관리
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // 배경색 설정 (시스템 기본 회색)
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                
                // 헤더 바 (뒤로가기 버튼 포함)
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                         HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                            Text("홈")
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding()
                
                // 설정 타이틀
                Text("설정")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 섹션 1: 피드백 및 소리 설정
                            VStack(alignment: .leading, spacing: 8) {
                                Text("피드백 및 소리")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .padding(.leading, 8)
                                
                                VStack(spacing: 0) {
                                    // 햅틱 피드백 토글
                                    ToggleRow(icon: "iphone.radiowaves.left.and.right", iconColor: .blue, title: "햅틱 피드백", isOn: $hapticFeedbackEnabled)
                                        .onChange(of: hapticFeedbackEnabled) { _, newValue in
                                            // 설정 변경 시 테스트 햅틱 반응 발생
                                            if newValue {
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            }
                                        }
                                    Divider().padding(.leading, 56)
                                    // 사운드 효과 토글
                                    ToggleRow(icon: "speaker.wave.2.fill", iconColor: .indigo, title: "사운드 효과", isOn: $soundEffectsEnabled)
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                            
                            // 섹션 2: 보안 설정 (앱 잠금)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("보안")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .padding(.leading, 8)
                                
                                // 잠금 설정 상세 화면으로 이동하는 내비게이션 링크
                                NavigationLink(destination: LockSettingsView(isLockEnabled: $isLockEnabled, useFaceID: $useFaceID)) {
                                    HStack {
                                        IconView(icon: "lock.fill", color: .gray)
                                        Text("앱 잠금")
                                            .font(.body)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(isLockEnabled ? "켬" : "끔")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(.systemGray3))
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                            }
                            
                            // 섹션 3: 데이터 관리
                            VStack(alignment: .leading, spacing: 8) {
                                Text("데이터 관리")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .padding(.leading, 8)
                                
                                VStack(spacing: 0) {
                                    // 데이터 내보내기 버튼 (미구현)
                                    Button(action: {
                                        // Export Action
                                    }) {
                                        HStack {
                                            IconView(icon: "square.and.arrow.up", color: .green)
                                            Text("CSV로 내보내기")
                                                .font(.body)
                                                .foregroundColor(.black)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(.systemGray3))
                                        }
                                        .padding()
                                    }
                                    
                                    Divider().padding(.leading, 56)
                                    
                                    // 모든 데이터 삭제 버튼
                                    Button(action: {
                                        showResetAlert = true
                                    }) {
                                        HStack {
                                            IconView(icon: "trash.fill", color: .red)
                                            Text("모든 데이터 초기화")
                                                .font(.body)
                                                .foregroundColor(.red)
                                            Spacer()
                                        }
                                        .padding()
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                            
                            Spacer()
                            
                            // 앱 정보 및 저작권 표시
                            VStack(spacing: 4) {
                                Text("Counting v1.0.0")
                                Text("Created by MarkLim")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        // 데이터 초기화 확인 알림
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("모든 데이터 초기화"),
                message: Text("정말로 모든 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                primaryButton: .destructive(Text("삭제")) {
                    store.resetAllData()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }
}

// 잠금 설정 상세 화면 뷰
struct LockSettingsView: View {
    @Binding var isLockEnabled: Bool
    @Binding var useFaceID: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                // 헤더 바
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                            Text("설정")
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding()
                
                Text("앱 잠금")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                VStack(spacing: 0) {
                    // 잠금 활성화 토글
                    Toggle("잠금 활성화", isOn: $isLockEnabled)
                        .padding()
                    
                    // FaceID 설정 (잠금 활성화 시에만 표시)
                    if isLockEnabled {
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Face ID 사용")
                                Text("앱을 열 때 Face ID를 사용합니다.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: $useFaceID)
                                .labelsHidden()
                        }
                        .padding()
                        
                        Divider().padding(.leading, 16)
                        
                        // 암호 변경 버튼
                        Button(action: {
                            showingPinSetup = true
                        }) {
                            HStack {
                                Text("암호 변경")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(.systemGray3))
                            }
                            .padding()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)
                
                Text("앱 잠금을 활성화하면 앱을 실행하거나 백그라운드에서 불러올 때 암호 또는 생체 인증이 필요합니다.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingPinSetup) {
            PinSetupView(isPresented: $showingPinSetup, isLockEnabled: $isLockEnabled)
        }
        .onChange(of: isLockEnabled) { _, newValue in
            if newValue {
                // 잠금을 켰을 때, 저장된 암호가 없거나 재설정을 원하면 설정 화면 띄우기
                // 여기서는 암호가 없으면 설정 화면을 띄우고, 있으면 그냥 켜지게 둠.
                // 만약 사용자가 '활성화 할 때마다' 입력을 원했다면 로직 변경 필요.
                // 일단 '저장된 암호가 없을 때'만 띄우도록 함.
                if KeychainHelper.shared.readPin() == nil {
                    // 잠시 토글을 끄고 설정 화면에서 완료 시 켜도록 함 (애니메이션 문제 방지)
                    isLockEnabled = false
                    showingPinSetup = true
                }
            }
        }
    }
    
    @State private var showingPinSetup = false
}

// 설정 목록에서 사용되는 토글 행 컴포넌트
struct ToggleRow: View {
    let icon: String // 아이콘 SF Symbol 이름
    let iconColor: Color // 아이콘 색상
    let title: String // 메뉴 제목
    @Binding var isOn: Bool // 토글 상태 바인딩
    
    var body: some View {
        HStack {
            IconView(icon: icon, color: iconColor)
            Text(title)
                .font(.body)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

// 설정 목록에서 사용되는 아이콘 뷰
struct IconView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .frame(width: 30, height: 30)
            .background(color.opacity(0.15))
            .cornerRadius(8)
            .padding(.trailing, 8)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
