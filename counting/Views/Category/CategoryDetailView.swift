import SwiftUI
import CoreImage.CIFilterBuiltins

// 카테고리 상세 화면 뷰
// 특정 카테고리에 포함된 카운터 목록을 보여주고 관리합니다.
struct TallyCategoryDetailView: View {
    let categoryId: UUID
    @EnvironmentObject var store: TallyStore
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var l10n = LocalizationManager.shared
    
    // 모달 시트 표시 상태
    @State private var showingAddCounter = false
    @State private var showingEditCategory = false
    @State private var showingResetAlert = false
    @State private var showingBluetoothShare = false
    
    // 빠른 카운팅 모드 활성화 여부
    @State private var isQuickCountMode = false
    
    // 카운터 선택 상태 (상세 카운팅 화면 전환용)
    @State private var selectedCounterId: UUID? = nil

    // 현재 카테고리 데이터 조회 (실시간 업데이트 반영)
    var liveCategory: TallyCategory? {
        store.categories.first(where: { $0.id == categoryId })
    }

    var body: some View {
        if let category = liveCategory {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [ColorSet.bgGradientStart, ColorSet.bgGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // 커스텀 내비게이션 바
                    HStack {
                        // 뒤로가기 버튼
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.primary)
                                .padding()
                        }
                        // 카테고리 아이콘 및 이름
                        Image(systemName: category.icon)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(category.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        
                        // 카테고리 편집 버튼
                        // 카테고리 메뉴 버튼 (햄버거 아이콘)
                        Menu {
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                Label("reset_action".localized, systemImage: "arrow.counterclockwise")
                            }
                            
                            Button(action: {
                                showingEditCategory = true
                            }) {
                                Label("edit".localized, systemImage: "pencil")
                            }
                            
                            Button(action: {
                                showingBluetoothShare = true
                            }) {
                                Label("share".localized, systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            // SF Symbol 아이콘 사용 (SwiftUI 스타일 적용)
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary.opacity(0.8))
                                .padding(10)
                            .background(
                                ZStack {
                                    // Native SwiftUI Material (iOS 15+)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                    
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.2),
                                            .white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                                .clipShape(Circle())
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .padding(.trailing)
                        }
                    }
                    .padding(.top, 10)
                    
                    // 빠른 카운팅 모드 토글 (헤더 아래)
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: isQuickCountMode ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(isQuickCountMode ? .yellow : .gray)
                            Text("quick_count_mode".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(isQuickCountMode ? Color.primary : Color.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isQuickCountMode)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.gray.opacity(0.1)),
                        alignment: .bottom
                    )
                    .padding(.bottom, 6)

                    // 카운터 목록 리스트 (스와이프 삭제 지원)
                    List {
                        // 각 카운터를 리스트 형태로 표시
                        ForEach(category.counters, id: \.id) { tallyCounter in
                            Group {
                                if isQuickCountMode {
                                    // 빠른 카운팅 모드: +/- 버튼이 있는 행
                                    TallyCounterRow(
                                        counter: tallyCounter,
                                        isQuickCountMode: true,
                                        allowDecimals: category.allowDecimals, // 소수점 허용 여부 전달
                                        onIncrement: {
                                            let delta = category.allowDecimals ? 0.1 : 1.0
                                            store.updateCount(categoryId: category.id, counterId: tallyCounter.id, delta: delta)
                                        },
                                        onDecrement: {
                                            let delta = category.allowDecimals ? -0.1 : -1.0
                                            store.updateCount(categoryId: category.id, counterId: tallyCounter.id, delta: delta)
                                        }
                                    )
                                } else {
                                    // 일반 모드: 상세 화면으로 이동하는 버튼
                                    Button(action: {
                                        // 카운터 선택 시 애니메이션과 함께 상세 화면으로 전환
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            selectedCounterId = tallyCounter.id
                                        }
                                    }) {
                                        TallyCounterRow(counter: tallyCounter, isQuickCountMode: false, allowDecimals: category.allowDecimals)
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete(perform: deleteCounter)

                        // 새 카운터 추가 버튼
                        Button(action: {
                            showingAddCounter = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("add_counter".localized)
                            }
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(.gray.opacity(0.5))
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .blur(radius: selectedCounterId != nil ? 5 : 0) // 상세 화면 표시 중일 때 배경 블러 처리
                .navigationBarHidden(true)
                // 카운터 추가 시트
                .sheet(isPresented: $showingAddCounter) {
                    AddCounterView(isPresented: $showingAddCounter, categoryId: category.id)
                }
                // 카테고리 편집 시트 (AddCategoryView 재사용)
                .sheet(isPresented: $showingEditCategory) {
                    AddCategoryView(isPresented: $showingEditCategory, editingCategory: category)
                }
                // 초기화 확인 알림
                .alert(isPresented: $showingResetAlert) {
                    Alert(
                        title: Text("reset_action".localized),
                        message: Text("reset_counter_msg".localized),
                        primaryButton: .destructive(Text("reset_action".localized)) {
                            store.resetCategoryCounters(categoryId: category.id)
                        },
                        secondaryButton: .cancel(Text("cancel".localized))
                    )
                }
                // 블루투스 공유 시트
                .sheet(isPresented: $showingBluetoothShare) {
                    BluetoothDeviceListView(category: category)
                }

                // 커스텀 화면 전환 오버레이 (개별 카운터 상세 화면)
                if let counterId = selectedCounterId {
                    TallyCounterView(
                        categoryId: category.id,
                        counterId: counterId,
                        onDismiss: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCounterId = nil
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }

        } else {
            // 카테고리 데이터를 찾을 수 없을 때의 폴백 화면
            VStack {
                Spacer()
                Text("category_not_found".localized)
                    .font(.headline)
                    .foregroundStyle(.gray)
                Button("go_back".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    // 카운터 삭제 처리 함수
    private func deleteCounter(at offsets: IndexSet) {
        if let category = liveCategory {
            offsets.forEach { index in
                let counter = category.counters[index]
                store.deleteCounter(categoryId: category.id, counterId: counter.id)
            }
        }
    }
}

// 카운터 목록의 개별 행 뷰
struct TallyCounterRow: View {
    let counter: TallyCounter
    var isQuickCountMode: Bool = false
    var allowDecimals: Bool = false // 소수점 표시 여부
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(counter.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                // 모드에 따라 하단 텍스트 변경 또는 숨김
                if !isQuickCountMode {
                    Text("tap_to_view_detail".localized)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
            
            if isQuickCountMode {
                // 빠른 카운팅 모드 컨트롤
                HStack(spacing: 12) {
                    Button(action: {
                        onDecrement?()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle()) // 리스트 선택 간섭 방지
                    
                    Text(allowDecimals ? String(format: "%.1f", counter.count) : String(format: "%.0f", counter.count))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 40)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        onIncrement?()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle()) // 리스트 선택 간섭 방지
                }
                .padding(4)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
            } else {
                // 일반 모드: 현재 카운트 숫자 표시
                Text(allowDecimals ? String(format: "%.1f", counter.count) : String(format: "%.0f", counter.count))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        // 배경색: Quick Mode일 때는 시스템 배경(테두리 느낌), 일반 모드일 때는 연한 Material로 구분
        .background(isQuickCountMode ? Color(.secondarySystemBackground) : Color(.tertiarySystemFill))
        .cornerRadius(24)
        // Quick Mode일 때 그림자 및 테두리 추가
        .shadow(color: isQuickCountMode ? Color.black.opacity(0.05) : Color.clear, radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isQuickCountMode ? Color.gray.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// QR Code View
struct QRCodeView: View {
    let category: TallyCategory
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ZStack {
                // Screen Background
                category.color.opacity(0.2).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text(category.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if let qrImage = generateQRCode(from: category) {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    } else {
                        Text("qr_generation_failed".localized)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("qr_scan_instruction".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationBarTitle("qr_share".localized, displayMode: .inline)
            .navigationBarItems(trailing: Button("close".localized) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    func generateQRCode(from category: TallyCategory) -> UIImage? {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(category),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        let data = Data(jsonString.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            // Scale up the image for better quality
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
