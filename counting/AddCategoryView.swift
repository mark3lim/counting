import SwiftUI

// 카테고리 추가 및 수정 화면 뷰
// 새 카테고리를 생성하거나 기존 카테고리를 편집하는 기능을 제공합니다.
struct AddCategoryView: View {
    @Binding var isPresented: Bool // 뷰 표시 여부 바인딩
    var editingCategory: TallyCategory? = nil // 편집 모드일 경우 전달받는 카테고리 객체
    
    @EnvironmentObject var store: TallyStore
    
    // 입력 상태 변수들
    @State private var name: String = ""
    @State private var selectedColor: String = AppTheme.allColorNames.first ?? "bg-blue-600"
    @State private var selectedIcon: String = "list"

    // 컬러/아이콘 그리드 레이아웃 설정
    let columns = [
        GridItem(.adaptive(minimum: 44))
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 카테고리 이름 입력 필드
                Text("카테고리 이름")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)

                TextField("예: 하루 커피 잔 수", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                // 색상 선택 그리드
                Text("색상 선택")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppTheme.allColorNames, id: \.self) { colorName in
                        ZStack {
                            Circle()
                                .fill(AppTheme.getColor(for: colorName))
                                .frame(width: 44, height: 44)
                                .shadow(color: AppTheme.getColor(for: colorName).opacity(0.5), radius: 3, x: 0, y: 3)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedColor = colorName
                                }
                            
                            // 선택된 색상에 체크 표시
                            if selectedColor == colorName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
                
                // 아이콘 선택 그리드
                Text("아이콘 선택")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AppTheme.allIconNames, id: \.self) { iconName in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == iconName ? Color.black : Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: iconName)
                                    .foregroundColor(selectedIcon == iconName ? .white : .gray)
                                    .font(.system(size: 20))
                            }
                            .onTapGesture {
                                selectedIcon = iconName
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxHeight: 200) // 스크롤 뷰 높이 제한

                // 저장/수정 버튼
                Button(action: {
                    if !name.isEmpty {
                        if let category = editingCategory {
                            // 기존 카테고리 업데이트
                            store.updateCategory(category: category, name: name, colorName: selectedColor, iconName: selectedIcon)
                        } else {
                            // 새 카테고리 추가
                            store.addCategory(name: name, colorName: selectedColor, iconName: selectedIcon)
                        }
                        isPresented = false
                    }
                }) {
                    Text(editingCategory != nil ? "수정하기" : "만들기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1.0) // 이름이 비어있으면 비활성화

                Spacer()
            }
            .padding()
            .navigationTitle(editingCategory != nil ? "카테고리 수정" : "새 카테고리")
            .navigationBarItems(
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                })
            .onAppear {
                // 편집 모드일 경우 기존 데이터 불러오기
                if let category = editingCategory {
                    name = category.name
                    selectedColor = category.colorName
                    selectedIcon = category.iconName
                }
            }
        }
    }
}
