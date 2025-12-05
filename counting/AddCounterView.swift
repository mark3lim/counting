import SwiftUI

// 새 카운터 추가 화면 뷰
// 특정 카테고리에 새로운 카운터 항목을 추가합니다.
struct AddCounterView: View {
    @Binding var isPresented: Bool // 뷰 표시 여부 바인딩
    let categoryId: UUID // 카운터가 추가될 카테고리의 ID
    
    @EnvironmentObject var store: TallyStore
    
    // 입력 상태 변수
    @State private var name: String = ""
    @State private var initialCount: Int = 0 // 초기 시작 값

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 카운터 이름 입력 섹션
                VStack(alignment: .leading) {
                    Text("이름")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.gray)
                        TextField("예: 턱걸이, 물 한 잔", text: $name)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                // 초기 값 설정 섹션
                VStack(alignment: .leading) {
                    Text("초기 시작 값 (선택)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    HStack {
                        // 감소 버튼
                        Button(action: {
                            if initialCount > 0 { initialCount -= 1 }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                        }

                        Spacer()

                        // 현재 설정된 초기 값 표시
                        Text("\(initialCount)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        // 증가 버튼
                        Button(action: {
                            initialCount += 1
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                        }
                    }
                }

                // 추가하기 버튼
                Button(action: {
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty {
                        store.addCounter(
                            to: categoryId, name: trimmedName, initialCount: initialCount)
                        isPresented = false
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("추가하기")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1.0) // 이름 입력 전까진 비활성화

                Spacer()
            }
            .padding()
            .navigationTitle("새 카운터 추가")
            .navigationBarItems(
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                })
        }
    }
}
