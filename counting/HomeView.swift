import SwiftUI
import UIKit

// 메인 홈 화면 뷰
// 사용자가 등록한 카테고리 목록을 보여주고, 설정 화면이나 카테고리 추가 화면으로 이동할 수 있습니다.
struct HomeView: View {
    // 앱의 데이터 저장소를 환경 객체로 가져옵니다.
    @EnvironmentObject var store: TallyStore
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 카테고리 추가 시트 표시 여부를 제어하는 상태 변수
    @State private var showingAddCategory = false
    
    // 삭제 관련 상태 변수
    @State private var categoryToDelete: TallyCategory?
    @State private var showingDeleteOption = false
    @State private var showingDeleteConfirmation = false
    @State private var deletingCategoryId: UUID? // 삭제 애니메이션 중인 카테고리 ID 추적

    // 그리드 레이아웃 설정 (2열 그리드)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // 배경색 설정 (연한 회색)
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // 헤더 영역
                    VStack {
                        Text("my_counters".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("home_greeting_subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // 카테고리 목록 그리드 (스크롤 가능)
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            // 생성일 순으로 정렬하여 표시 (최신순)
                            ForEach(store.categories.sorted(by: { $0.createdAt > $1.createdAt })) { category in
                                NavigationLink(
                                    destination: TallyCategoryDetailView(categoryId: category.id)
                                ) {
                                    // 각 카테고리를 카드 형태로 표시하는 뷰
                                    TallyCategoryCard(category: category)
                                        // 수동 애니메이션 적용: 삭제 중이면 축소 및 투명화
                                        .scaleEffect(deletingCategoryId == category.id ? 0.01 : 1.0)
                                        .opacity(deletingCategoryId == category.id ? 0.0 : 1.0)
                                        .animation(.spring(response: 0.33, dampingFraction: 0.6), value: deletingCategoryId)
                                        .allowsHitTesting(deletingCategoryId != category.id)
                                        .onLongPressGesture(minimumDuration: 1.0) {
                                            self.categoryToDelete = category
                                            // 햅틱 피드백 발생
                                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                                            generator.impactOccurred()
                                            self.showingDeleteOption = true
                                        }
                                }
                            }
                        }
                        .padding()
                    }

                }
            }
            .overlay(
                // 하단 탭 바 (Liquid Glass 디자인)
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        
                        // 1. 홈 버튼
                        Button(action: {
                            // 현재 홈이므로 액션 없음 (또는 최상단 스크롤 등)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 20))
                                Text("home_tab".localized)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.black.opacity(0.8))
                            .frame(width: 100, height: 60)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        // 2. 추가 버튼 (중앙 Liquid Sphere)
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            ZStack {
                                // 메인 그라디언트 배경
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "4FacFe"), Color(hex: "00F2Fe")]), // 공백 제거
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(hex: "4FacFe").opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                // 상단 빛 반사 (Glossy Effect)
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.1)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 58, height: 58)
                                
                                // 아이콘
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        }
                        // .offset(y: -20) 제거하여 다른 버튼과 높이 맞춤
                        .padding(.horizontal, 20) // 양옆 버튼과의 간격 넓힘
                        
                        Spacer()
                        
                        // 3. 설정 버튼
                        NavigationLink(destination: SettingsView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                Text("settings".localized)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.black.opacity(0.8))
                            .frame(width: 100, height: 60)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12) // 내부 여백
                    .background(
                        // 독(Dock) 배경 Glass Effect (타원형)
                        ZStack {
                            MaterialEffect(style: .systemUltraThinMaterial) // UIKit Blur Helper
                                .clipShape(Capsule())
                            
                            // 테두리
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20) // 화면 양옆에서 띄우기
                    .padding(.bottom, 20) // 조금 더 아래로 위치 조정
                }
                .edgesIgnoringSafeArea(.bottom)
            , alignment: .bottom)
            .navigationBarHidden(true) // 기본 내비게이션 바 숨김
            // 카테고리 추가 모달 시트
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(isPresented: $showingAddCategory)
            }
            // 1단계: 삭제 옵션 표시 (삭제 버튼)
            .confirmationDialog("category_options".localized, isPresented: $showingDeleteOption, titleVisibility: .visible) {
                Button("delete_category".localized, role: .destructive) {
                    self.showingDeleteConfirmation = true
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text(categoryToDelete?.name ?? "selected_category".localized)
            }
            // 2단계: 최종 삭제 확인 경고창
            .alert("delete_category_confirmation".localized, isPresented: $showingDeleteConfirmation) {
                Button("delete".localized, role: .destructive) {
                    if let category = categoryToDelete {
                        // 1. 먼저 시각적 축소 애니메이션 실행
                        deletingCategoryId = category.id
                        
                        // 2. 애니메이션이 끝날 때쯤 실제 데이터 삭제
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                store.deleteCategory(categoryId: category.id)
                            }
                            deletingCategoryId = nil
                            categoryToDelete = nil
                        }
                    }
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text("irreversible_action".localized)
            }
        }
    }
}

// 카테고리 카드 뷰
// 개별 카테고리의 정보를 카드 형태로 시각화하여 보여줍니다.
struct TallyCategoryCard: View {
    let category: TallyCategory

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 카테고리 고유 색상 배경
            category.color

            // 광택 효과를 위한 그라디언트 오버레이
            LinearGradient(
                gradient: Gradient(colors: [
                    .white.opacity(0.4),
                    .white.opacity(0.1),
                    .clear,
                    .black.opacity(0.1)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // 빛 반사(Shine) 효과
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }

            // 카드 내용 (아이콘, 이름, 항목 수)
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    // 카테고리 아이콘 표시
                    Image(systemName: category.icon)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 2)
                }

                Spacer()

                // 카테고리 이름
                Text(category.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                // 포함된 카운터 개수 표시
                Text("\(category.counters.count)" + "items_count_suffix".localized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Material.regularMaterial) // 배경 설정을 변경하려면 이 부분을 수정하세요 (예: Color.black.opacity(0.3) 등)
                    .foregroundColor(.black.opacity(0.75))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .padding()
        }
        .frame(height: 160)
        .cornerRadius(24) // 둥근 모서리
        .shadow(color: category.color.opacity(0.4), radius: 8, x: 0, y: 8) // 그림자 효과
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1) // 테두리 효과
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TallyStore())
    }
}

// MARK: - Helper Structs

// SwiftUI에서 사용할 수 있는 간단한 Blur View (Material 호환성)
struct MaterialEffect: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// 특정 모서리만 둥글게 만들기 위한 Shape
struct CustomCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
