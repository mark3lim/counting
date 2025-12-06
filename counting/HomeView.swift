import SwiftUI
import UIKit

// 메인 홈 화면 뷰
// 사용자가 등록한 카테고리 목록을 보여주고, 설정 화면이나 카테고리 추가 화면으로 이동할 수 있습니다.
struct HomeView: View {
    // 앱의 데이터 저장소를 환경 객체로 가져옵니다.
    @EnvironmentObject var store: TallyStore
    
    // 카테고리 추가 시트 표시 여부를 제어하는 상태 변수
    @State private var showingAddCategory = false
    
    // 삭제 관련 상태 변수
    @State private var categoryToDelete: TallyCategory?
    @State private var showingDeleteOption = false
    @State private var showingDeleteConfirmation = false

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
                        Text("나의 카운터")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("오늘도 목표를 달성하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // 카테고리 목록 그리드 (스크롤 가능)
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            // 최신 업데이트 순으로 정렬하여 표시
                            ForEach(store.categories.sorted(by: { $0.updatedAt > $1.updatedAt })) { category in
                                NavigationLink(
                                    destination: TallyCategoryDetailView(categoryId: category.id)
                                ) {
                                    // 각 카테고리를 카드 형태로 표시하는 뷰
                                    TallyCategoryCard(category: category)
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

                    // 하단 탭 바 (커스텀 디자인)
                    HStack {
                        Spacer()
                        // 홈 탭 (현재 화면)
                        VStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 24))
                            Text("홈")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.black)
                        
                        Spacer()
                        
                        // 카테고리 추가 버튼 (중앙 플로팅 버튼)
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.4, green: 0.7, blue: 1.0))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .bold()
                        }
                        
                        Spacer()
                        
                        // 설정 탭 (설정 화면으로 이동)
                        NavigationLink(destination: SettingsView()) {
                            VStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                Text("설정")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    .background(Color.white)
                }
            }
            .navigationBarHidden(true) // 기본 내비게이션 바 숨김
            // 카테고리 추가 모달 시트
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(isPresented: $showingAddCategory)
            }
            // 1단계: 삭제 옵션 표시 (삭제 버튼)
            .confirmationDialog("카테고리 옵션", isPresented: $showingDeleteOption, titleVisibility: .visible) {
                Button("카테고리 삭제", role: .destructive) {
                    self.showingDeleteConfirmation = true
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text(categoryToDelete?.name ?? "선택된 카테고리")
            }
            // 2단계: 최종 삭제 확인 경고창
            .alert("정말 삭제하시겠습니까?", isPresented: $showingDeleteConfirmation) {
                Button("삭제", role: .destructive) {
                    if let category = categoryToDelete {
                        store.deleteCategory(categoryId: category.id)
                        categoryToDelete = nil
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 동작은 되돌릴 수 없습니다.")
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
                Text("\(category.counters.count)개 항목")
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

// 프리뷰
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TallyStore())
    }
}
