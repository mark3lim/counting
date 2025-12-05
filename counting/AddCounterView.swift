import SwiftUI

struct AddCounterView: View {
    @Binding var isPresented: Bool
    let categoryId: UUID
    @EnvironmentObject var store: TallyStore
    @State private var name: String = ""
    @State private var initialCount: Int = 0

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Name Input
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

                // Initial Value Input
                VStack(alignment: .leading) {
                    Text("초기 시작 값 (선택)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    HStack {
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

                        Text("\(initialCount)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

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
                .opacity(name.isEmpty ? 0.5 : 1.0)

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
