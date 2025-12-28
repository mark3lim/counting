//
//  RandomTeamView.swift
//  counting
//
//  Created by Assistant on 2025/12/25.
//

import SwiftUI

struct RandomTeamView: View {
    // MARK: - Properties
    @StateObject private var viewModel = RandomTeamViewModel()
    @ObservedObject var l10n = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("by_name".localized, systemImage: "text.book.closed.fill", value: .byName) {
                ZStack {
                    // Background for this tab
                    backgroundGradient
                    
                    // Ambient Orbs
                    ambientOrbs
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            byNameView
                            
                            // Result View
                            if !viewModel.teamResult.isEmpty {
                                resultView
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                }
            }
            
            Tab("by_count".localized, systemImage: "person.3.fill", value: .byCount) {
                ZStack {
                    // Background for this tab
                    backgroundGradient
                    
                    // Ambient Orbs
                    ambientOrbs
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            byCountView
                            
                            // Result View
                            if !viewModel.teamResult.isEmpty {
                                resultView
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("random_team".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.resetData()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body.weight(.semibold)) // Dynamic Type compliant
                        .foregroundStyle(Color.primary)
                }
                .accessibilityLabel("Reset")
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.teamResult.isEmpty) // Optional haptic
            }
        }
        .tabViewStyle(.sidebarAdaptable) 
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.teamResult.isEmpty)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [ColorSet.bgGradientStart, ColorSet.bgGradientEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Views
    
    struct NumberInputView: View {
        @Binding var value: Int
        let range: ClosedRange<Int>
        
        @FocusState private var isFocused: Bool
        @State private var text: String = ""
        
        var body: some View {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .foregroundStyle(Color.accentColor)
                .fontWeight(.bold)
                .focused($isFocused)
                // iOS 26 style: Clear button
                .textFieldStyle(.plain) 
                .onAppear {
                    text = "\(value)"
                }
                .onChange(of: value) { _, newValue in
                    // Sync text when value changes externally (e.g. via Stepper)
                    if !isFocused {
                        text = "\(newValue)"
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        text = "" // Clear on focus for "replace" feel
                    } else {
                        // On blur, commit
                        if let newValue = Int(text) {
                            // Clamp value to the valid range
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                        // Restore valid text
                        text = "\(value)"
                    }
                }
                .onSubmit {
                    isFocused = false
                }
        }
    }
    
    private var nameInputHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("input_names".localized)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                TextField("name_placeholder".localized, text: $viewModel.currentNameInput)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onSubmit { viewModel.addName() }
                
                Button {
                    viewModel.addName()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }

    private var nameListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("added_participants".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(viewModel.nameList.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
            }
            
            FlowLayout {
                ForEach(viewModel.nameList, id: \.self) { name in
                    HStack(spacing: 6) {
                        Text(name)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Button {
                            viewModel.removeName(name)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.subheadline)
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var teamCountSection: some View {
        HStack {
            Text("number_of_teams".localized)
                .foregroundStyle(.primary)
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    if viewModel.numberOfTeams > RandomTeamViewModel.teamCountRange.lowerBound {
                        viewModel.numberOfTeams -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(viewModel.numberOfTeams <= RandomTeamViewModel.teamCountRange.lowerBound)
                .sensoryFeedback(.selection, trigger: viewModel.numberOfTeams)
                .opacity(viewModel.isSpecialOptionEnabled && viewModel.specialOptionMode == .distributeByOption ? 0.3 : 1.0)
                
                NumberInputView(value: $viewModel.numberOfTeams, range: RandomTeamViewModel.teamCountRange)
                    .disabled(viewModel.isSpecialOptionEnabled && viewModel.specialOptionMode == .distributeByOption)
                    .opacity(viewModel.isSpecialOptionEnabled && viewModel.specialOptionMode == .distributeByOption ? 0.5 : 1.0)
                
                Button {
                    if viewModel.numberOfTeams < RandomTeamViewModel.teamCountRange.upperBound {
                        viewModel.numberOfTeams += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(viewModel.numberOfTeams >= RandomTeamViewModel.teamCountRange.upperBound)
                .sensoryFeedback(.selection, trigger: viewModel.numberOfTeams)
                .opacity(viewModel.isSpecialOptionEnabled && viewModel.specialOptionMode == .distributeByOption ? 0.3 : 1.0)
            }
        }
        .disabled(viewModel.isSpecialOptionEnabled && viewModel.specialOptionMode == .distributeByOption)
    }

    private var byNameView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Input Card (Names + Team Count)
            VStack(spacing: 24) {
                nameInputHeader
                
                if !viewModel.nameList.isEmpty {
                    nameListSection
                        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                }
                
                Divider()
                
                teamCountSection
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            specialOptionsView
            
            actionButton(title: "shuffle".localized, icon: "shuffle") {
                viewModel.generateTeamsByName()
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.teamResult)
        }
        .sensoryFeedback(.selection, trigger: viewModel.nameList.count)
    }
    
    private var byCountView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Input Card (Total People + Team Count)
            VStack(spacing: 24) {
                // Total People Input
                HStack {
                    Text("total_people".localized)
                        .foregroundStyle(.primary)
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.totalPeople > RandomTeamViewModel.peopleCountRange.lowerBound {
                                viewModel.totalPeople -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 32, height: 32)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .disabled(viewModel.totalPeople <= RandomTeamViewModel.peopleCountRange.lowerBound)
                        .sensoryFeedback(.selection, trigger: viewModel.totalPeople)
                        
                        NumberInputView(value: $viewModel.totalPeople, range: RandomTeamViewModel.peopleCountRange)
                        
                        Button {
                            if viewModel.totalPeople < RandomTeamViewModel.peopleCountRange.upperBound {
                                viewModel.totalPeople += 1
                            }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 32, height: 32)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .disabled(viewModel.totalPeople >= RandomTeamViewModel.peopleCountRange.upperBound)
                        .sensoryFeedback(.selection, trigger: viewModel.totalPeople)
                    }
                }
                
                Divider()
                
                // Reusing the extracted team count section for consistency
                teamCountSection
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            specialOptionsView
            
            actionButton(title: "shuffle".localized, icon: "shuffle") {
                viewModel.generateTeamsByCount()
            }
        }
    }
    
    private var specialOptionsContent: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Mode Selection
            Picker("current_mode".localized, selection: $viewModel.specialOptionMode) {
                Text("option_mode_assign".localized).tag(RandomTeamViewModel.SpecialOptionMode.assignToTeams)
                Text("option_mode_distribute".localized).tag(RandomTeamViewModel.SpecialOptionMode.distributeByOption)
            }
            .pickerStyle(.segmented)
            
            // Option Input Area
            HStack(spacing: 12) {
                TextField("option_placeholder".localized, text: $viewModel.currentOptionInput)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onSubmit { viewModel.addSpecialOption() }
                
                Button {
                    viewModel.addSpecialOption()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(BouncyButtonStyle())
                .sensoryFeedback(.selection, trigger: viewModel.specialOptions.count)
            }
            
            // Added Options List
            if !viewModel.specialOptions.isEmpty {
                specialOptionsList
            }
        }
    }
    
    private var specialOptionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("added_options".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(viewModel.specialOptions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
            }
            
            FlowLayout {
                ForEach(viewModel.specialOptions, id: \.self) { option in
                    HStack(spacing: 6) {
                        Text(option)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Button {
                            viewModel.removeSpecialOption(option)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.subheadline)
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }

            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.primary.opacity(0.03)) // Inner container logic
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var specialOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $viewModel.isSpecialOptionEnabled.animation()) {
                Text("special_options".localized)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            if viewModel.isSpecialOptionEnabled {
                specialOptionsContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isSpecialOptionEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.specialOptions.count)
    }
    
    private var resultView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("team_result".localized)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(0..<viewModel.teamResult.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(teamTitle(for: index))
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                            
                            Spacer()
                        }
                        
                        // Tags layout - using extracted component
                        FlowLayoutWrapper(items: viewModel.teamResult[index])
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private func teamTitle(for index: Int) -> String {
        if viewModel.isSpecialOptionEnabled && index < viewModel.teamLabels.count {
            let label = viewModel.teamLabels[index]
            if !label.isEmpty {
                return label
            }
        }
        return "\("team_default_name".localized) \(index + 1)"
    }
    
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
    }
    
    struct BouncyButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
    
    private var ambientOrbs: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(ColorSet.orb1.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -50, y: -100)
                
                Circle()
                    .fill(ColorSet.orb3.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        RandomTeamView()
    }
}
