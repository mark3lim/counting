import SwiftUI

// 새 카운터 추가 화면 뷰
// 특정 카테고리에 새로운 카운터 항목을 추가합니다.
struct AddCounterView: View {
    @Binding var isPresented: Bool // 뷰 표시 여부 바인딩
    let categoryId: UUID // 카운터가 추가될 카테고리의 ID
    
    @EnvironmentObject var store: TallyStore
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 입력 상태 변수
    @State private var name: String = ""
    @State private var initialCount: Double = 0.0 // 초기 시작 값
    
    // Focus state management
    @FocusState private var isNameFocused: Bool
    
    // Alert state
    @State private var showingLimitAlert = false
    private let maxValue: Double = AppConstants.maxValue
    
    // Check if category allows decimals
    var allowDecimals: Bool {
        store.categories.first(where: { $0.id == categoryId })?.allowDecimals ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Counter Name Section
                    nameInputSection

                    // Initial Value Section
                    countInputSection

                    // Add Button
                    addButton
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, 10)
            }
            .navigationTitle("add_counter".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarCloseButton }
            .alert("notice".localized, isPresented: $showingLimitAlert) {
                Button("confirm".localized, role: .cancel) { }
            } message: {
                Text("value_exceeded".localized)
            }
        }
        .onAppear {
            setFocusWithDelay()
        }
        .withLock()
    }
    
    // MARK: - Subviews (Extracted for cleaner body)
    
    private var nameInputSection: some View {
        VStack(alignment: .leading) {
            Text("counter_name".localized)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.gray)

            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(.gray)
                TextField("counter_placeholder".localized, text: $name)
                    .focused($isNameFocused)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var countInputSection: some View {
        VStack(alignment: .leading) {
            Text("initial_value".localized)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.gray)

            HStack {
                decreaseButton
                Spacer()
                countTextField
                Spacer()
                increaseButton
            }
        }
    }
    
    private var countTextField: some View {
        TextField("", value: $initialCount, format: .number)
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .frame(maxWidth: 150)
            .onChange(of: initialCount) { _, newValue in
                validateLimit(newValue: newValue)
            }
    }
    
    private var decreaseButton: some View {
        Button(action: decreaseCount) {
            Image(systemName: "minus")
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .foregroundStyle(.black)
        }
    }
    
    private var increaseButton: some View {
        Button(action: increaseCount) {
            Image(systemName: "plus")
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .foregroundStyle(.black)
        }
    }
    
    private var addButton: some View {
        Button(action: addCounter) {
            HStack {
                Image(systemName: "plus.circle")
                Text("add_action".localized)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
    }
    
    private var toolbarCloseButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.gray)
            }
        }
    }
    
    // MARK: - Actions
    
    private func decreaseCount() {
        var newValue = initialCount
        let delta = allowDecimals ? 0.1 : 1.0
        newValue -= delta
        newValue = roundValue(newValue)
        
        // Negative Check based on category settings
        if let category = store.categories.first(where: { $0.id == categoryId }), !category.allowNegative {
             if newValue < 0 { newValue = 0 }
        }
        
        if abs(newValue) > maxValue {
            showingLimitAlert = true
            return
        }
        initialCount = newValue
    }
    
    private func increaseCount() {
        var newValue = initialCount
        let delta = allowDecimals ? 0.1 : 1.0
        newValue += delta
        newValue = roundValue(newValue)
        
        if abs(newValue) > maxValue {
            showingLimitAlert = true
            return
        }
        initialCount = newValue
    }
    
    private func validateLimit(newValue: Double) {
        if abs(newValue) > maxValue {
            // Restore within limit
            initialCount = newValue > 0 ? maxValue : -maxValue
            showingLimitAlert = true
        }
    }
    
    private func addCounter() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            store.addCounter(to: categoryId, name: trimmedName, initialCount: initialCount)
            isPresented = false
        }
    }
    
    private func roundValue(_ value: Double) -> Double {
        return (value * 10).rounded() / 10
    }
    
    // Swift 6 Concurrency: Use Task and MainActor instead of DispatchQueue
    private func setFocusWithDelay() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            isNameFocused = true
        }
    }
}
