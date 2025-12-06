import SwiftUI

// 새 카운터 추가 화면 뷰
// 특정 카테고리에 새로운 카운터 항목을 추가합니다.
struct AddCounterView: View {
    @Binding var isPresented: Bool // 뷰 표시 여부 바인딩
    let categoryId: UUID // 카운터가 추가될 카테고리의 ID
    
    @EnvironmentObject var store: TallyStore
    
    // 입력 상태 변수
    @State private var name: String = ""
    @State private var initialCount: Double = 0.0 // 초기 시작 값

    // 해당 카테고리의 소수점 허용 여부 확인
    var allowDecimals: Bool {
        store.categories.first(where: { $0.id == categoryId })?.allowDecimals ?? false
    }

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
                            let delta = allowDecimals ? 0.1 : 1.0
                            if initialCount > 0 { initialCount -= delta }
                            if initialCount < 0 { initialCount = 0 } // 음수 방지 (초기값은 보통 0 이상)
                            // 소수점 보정
                            initialCount = (initialCount * 10).rounded() / 10
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                        }

                        Spacer()

                        // 현재 설정된 초기 값 표시
                        Text(allowDecimals ? String(format: "%.1f", initialCount) : String(format: "%.0f", initialCount))
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        // 증가 버튼
                        Button(action: {
                            let delta = allowDecimals ? 0.1 : 1.0
                            initialCount += delta
                            // 소수점 보정
                            initialCount = (initialCount * 10).rounded() / 10
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
