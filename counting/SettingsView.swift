import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("screenAlwaysOn") private var screenAlwaysOn = false
    @AppStorage("isLockEnabled") private var isLockEnabled = false
    @AppStorage("useFaceID") private var useFaceID = false
    @State private var showResetAlert = false
    
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
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
                
                Text("설정")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Section 1: Feedback & Sound
                        VStack(alignment: .leading, spacing: 8) {
                            Text("피드백 및 소리")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                ToggleRow(icon: "iphone.radiowaves.left.and.right", iconColor: .blue, title: "햅틱 피드백", isOn: $hapticFeedbackEnabled)
                                Divider().padding(.leading, 56)
                                ToggleRow(icon: "speaker.wave.2.fill", iconColor: .indigo, title: "사운드 효과", isOn: $soundEffectsEnabled)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        
                        // Section 2: Screen Settings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("화면 설정")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                ToggleRow(icon: "sun.max.fill", iconColor: .orange, title: "화면 켜짐 유지", isOn: $screenAlwaysOn)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        
                        // Section 3: Security
                        VStack(alignment: .leading, spacing: 8) {
                            Text("보안")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                                .padding(.leading, 8)
                            
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
                        
                        // Section 4: Data Management
                        VStack(alignment: .leading, spacing: 8) {
                            Text("데이터 관리")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
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
                        
                        VStack(spacing: 4) {
                            Text("Counting v1.0.0")
                            Text("Designed by MarkLim")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
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

struct LockSettingsView: View {
    @Binding var isLockEnabled: Bool
    @Binding var useFaceID: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                // Header
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
                    Toggle("잠금 활성화", isOn: $isLockEnabled)
                        .padding()
                    
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
    }
}

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
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
