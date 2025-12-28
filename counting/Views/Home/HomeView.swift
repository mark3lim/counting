//
//  HomeView.swift
//  counting
//
//  메인 홈 화면 뷰
//  사용자가 등록한 카테고리 목록을 보여주고, 설정 화면이나 카테고리 추가 화면으로 이동할 수 있습니다.
//

import SwiftUI
import UIKit

struct HomeView: View {
    // MARK: - Properties
    
    @EnvironmentObject var store: TallyStore
    @ObservedObject var l10n = LocalizationManager.shared
    
    // Sheet 상태
    @State private var showingAddCategory = false
    
    // 삭제 관련 상태
    @State private var categoryToDelete: TallyCategory?
    @State private var showingDeleteOption = false
    @State private var activeAlert: ActiveAlert?
    @State private var deletingCategoryId: UUID?
    
    // 편집 모드 상태
    @State private var isEditing = false
    @State private var selectedCategories = Set<UUID>()
    
    // 동기화 상태
    @State private var isSyncing = false
    @State private var syncResult: SyncResult = .none
    
    // MARK: - Types
    
    enum SyncResult {
        case none, success, failure
    }

    enum ActiveAlert: Identifiable {
        case delete, deleteSelected, forceSync
        
        var id: String {
            switch self {
            case .delete: return "delete"
            case .deleteSelected: return "deleteSelected"
            case .forceSync: return "forceSync"
            }
        }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                ambientOrbs
                mainContent
            }
            .toolbar { toolbarContent }
            .toolbarBackground(.visible, for: .bottomBar)
            .navigationTitle("home_tab".localized) // Set title for back button menu in pushed views
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(isPresented: $showingAddCategory)
            }
            .confirmationDialog(
                "category_options".localized,
                isPresented: $showingDeleteOption,
                titleVisibility: .visible
            ) {
                Button("delete_category".localized, role: .destructive) {
                    activeAlert = .delete
                }
                Button("cancel".localized, role: .cancel) {}
            }
            .alert(item: $activeAlert) { alertType in
                alertForType(alertType)
            }
        }
    }
    
    // MARK: - Background Views
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [ColorSet.bgGradientStart, ColorSet.bgGradientEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var ambientOrbs: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(ColorSet.orb1.opacity(0.4))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -150)
                
                Circle()
                    .fill(ColorSet.orb2.opacity(0.4))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height / 3)
                
                Circle()
                    .fill(ColorSet.orb3.opacity(0.4))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: 50, y: geometry.size.height - 200)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    headerSection
                    subtitleSection
                    categoryGrid
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("my_counters".localized)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.8))
            
            Spacer()
            
            editButton
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var editButton: some View {
        Group {
            if isEditing {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isEditing = false
                        selectedCategories.removeAll()
                    }
                } label: {
                    headerActionButtonImage(systemName: "xmark")
                }
                .accessibilityLabel("done".localized)
                .transition(.scale.combined(with: .opacity))
            } else {
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditing = true
                        }
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    NavigationLink {
                        RandomTeamView()
                    } label: {
                        Label("random_team".localized, systemImage: "dice.fill")
                    }
                } label: {
                    headerActionButtonImage(systemName: "ellipsis")
                }
                .accessibilityLabel("options".localized)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func headerActionButtonImage(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .bold))
            .symbolVariant(.fill)
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(isEditing ? Color.primary : Color.primary.opacity(0.8))
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                    .blendMode(.overlay)
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isEditing ? 1.05 : 1.0)
    }
    
    private var subtitleSection: some View {
        Text("home_greeting_subtitle".localized)
            .font(.subheadline)
            .foregroundStyle(Color.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(store.categories.sorted(by: { $0.createdAt > $1.createdAt })) { category in
                categoryCell(for: category)
            }
        }
        .padding()
        .padding(.bottom, 100)
    }
    
    @ViewBuilder
    private func categoryCell(for category: TallyCategory) -> some View {
        if isEditing {
            editingCategoryCell(for: category)
        } else {
            normalCategoryCell(for: category)
        }
    }
    
    private func editingCategoryCell(for category: TallyCategory) -> some View {
        TallyCategoryCard(category: category)
            .overlay(selectionOverlay(for: category))
            .onTapGesture {
                toggleSelection(for: category.id)
            }
            .scaleEffect(0.95)
    }
    
    private func normalCategoryCell(for category: TallyCategory) -> some View {
        NavigationLink(destination: TallyCategoryDetailView(categoryId: category.id)) {
            TallyCategoryCard(category: category)
                .scaleEffect(deletingCategoryId == category.id ? 0.01 : 1.0)
                .opacity(deletingCategoryId == category.id ? 0.0 : 1.0)
                .animation(.spring(response: 0.33, dampingFraction: 0.6), value: deletingCategoryId)
                .allowsHitTesting(deletingCategoryId != category.id)
                .onLongPressGesture(minimumDuration: 1.0) {
                    categoryToDelete = category
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showingDeleteOption = true
                }
        }
    }
    
    private func selectionOverlay(for category: TallyCategory) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(selectedCategories.contains(category.id) ? Color.accentColor.opacity(0.2) : Color.clear)
            
            VStack {
                HStack {
                    Image(systemName: selectedCategories.contains(category.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(selectedCategories.contains(category.id) ? Color.accentColor : Color.gray)
                        .background(Circle().fill(Color.white).padding(2))
                        .padding(12)
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedCategories.contains(id) {
            selectedCategories.remove(id)
        } else {
            selectedCategories.insert(id)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if isEditing {
                editingToolbar
            } else {
                normalToolbar
            }
        }
    }
    
    @ViewBuilder
    private var editingToolbar: some View {
        Spacer()
        Button {
            if !selectedCategories.isEmpty {
                activeAlert = .deleteSelected
            }
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("delete".localized)
                if !selectedCategories.isEmpty {
                    Text("(\(selectedCategories.count))")
                }
            }
            .font(.headline)
            .foregroundStyle(selectedCategories.isEmpty ? Color.secondary : Color.red)
        }
        .disabled(selectedCategories.isEmpty)
        Spacer()
    }
    
    @ViewBuilder
    private var normalToolbar: some View {
        NavigationLink(destination: SettingsView()) {
            Label("settings".localized, systemImage: "gearshape")
                .labelStyle(.iconOnly)
        }
        
        NavigationLink {
            ReceiveDataView()
        } label: {
            Label("import".localized, systemImage: "square.and.arrow.down")
                .labelStyle(.iconOnly)
        }
        
        syncButton
        
        Button { showingAddCategory = true } label: {
            Label("add".localized, systemImage: "plus.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.blue)
        }
    }
    
    private var syncButton: some View {
        Button { activeAlert = .forceSync } label: {
            ZStack {
                if syncResult == .success {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.green)
                        .transition(.scale.combined(with: .opacity))
                } else if syncResult == .failure {
                    Image(systemName: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(Color.red)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .rotationEffect(.degrees(isSyncing ? 360 : 0))
                        .animation(
                            isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isSyncing
                        )
                }
            }
        }
        .disabled(isSyncing || syncResult != .none)
    }
    
    // MARK: - Alerts
    
    private func alertForType(_ type: ActiveAlert) -> Alert {
        switch type {
        case .delete:
            return deleteAlert
        case .deleteSelected:
            return deleteSelectedAlert
        case .forceSync:
            return syncAlert
        }
    }
    
    private var deleteAlert: Alert {
        Alert(
            title: Text("delete_category_confirmation".localized),
            message: Text("irreversible_action".localized),
            primaryButton: .destructive(Text("delete".localized)) {
                performDelete()
            },
            secondaryButton: .cancel(Text("cancel".localized))
        )
    }
    
    private var deleteSelectedAlert: Alert {
        Alert(
            title: Text("delete_selected_title".localized),
            message: Text(String(format: "delete_selected_message".localized, selectedCategories.count)),
            primaryButton: .destructive(Text("delete".localized)) {
                withAnimation {
                    store.deleteCategories(ids: selectedCategories)
                    selectedCategories.removeAll()
                    isEditing = false
                }
            },
            secondaryButton: .cancel(Text("cancel".localized))
        )
    }
    
    private var syncAlert: Alert {
        Alert(
            title: Text("sync_confirmation_title".localized),
            message: Text("sync_confirmation_message".localized),
            primaryButton: .default(Text("sync_now".localized)) {
                performSync()
            },
            secondaryButton: .cancel(Text("cancel".localized))
        )
    }
    
    // MARK: - Actions
    
    private func performDelete() {
        guard let category = categoryToDelete else { return }
        
        deletingCategoryId = category.id
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
            withAnimation(.easeOut(duration: 0.2)) {
                store.deleteCategory(categoryId: category.id)
            }
            deletingCategoryId = nil
            categoryToDelete = nil
        }
    }
    
    private func performSync() {
        isSyncing = true
        let startTime = Date()
        
        ConnectivityProvider.shared.send(categories: store.categories) { success in
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, 1.0 - elapsedTime)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                isSyncing = false
                withAnimation {
                    syncResult = success ? .success : .failure
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        syncResult = .none
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(TallyStore.shared)
}
