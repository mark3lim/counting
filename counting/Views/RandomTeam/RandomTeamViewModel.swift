
import SwiftUI
import Combine

@MainActor
class RandomTeamViewModel: ObservableObject {
    // MARK: - Constants
    static let teamCountRange = 2...100
    static let peopleCountRange = 2...1000
    
    // MARK: - Types
    enum TabSelection: String, CaseIterable, Identifiable {
        case byName
        case byCount
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Special Options Constants
    enum SpecialOptionMode: String, CaseIterable, Identifiable {
        case assignToTeams
        case distributeByOption
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Published Properties
    @Published var selectedTab: TabSelection = .byName {
        didSet {
            // Reset result when tab changes
            if oldValue != selectedTab {
                withAnimation {
                    teamResult = []
                    teamLabels = []
                }
            }
        }
    }
    
    @Published var currentNameInput: String = ""
    @Published var nameList: [String] = []
    @Published var numberOfTeams: Int = 2 {
        didSet {
            if isSpecialOptionEnabled && specialOptionMode == .distributeByOption {
                // In distribute mode, numberOfTeams is locked to options count
                if numberOfTeams != specialOptions.count {
                     // Wait, we should probably prevent editing numberOfTeams in UI instead of forcing here, 
                     // but forcing ensures consistency. 
                     // Actually, if options count is 0, we can't have 0 teams. 
                     // Let's handle this in generate logic or UI disabling.
                }
            } else {
                if numberOfTeams < Self.teamCountRange.lowerBound {
                    numberOfTeams = Self.teamCountRange.lowerBound
                } else if numberOfTeams > Self.teamCountRange.upperBound {
                    numberOfTeams = Self.teamCountRange.upperBound
                }
            }
        }
    }
    
    @Published var totalPeople: Int = 4 {
        didSet {
            if totalPeople < Self.peopleCountRange.lowerBound {
                totalPeople = Self.peopleCountRange.lowerBound
            } else if totalPeople > Self.peopleCountRange.upperBound {
                totalPeople = Self.peopleCountRange.upperBound
            }
        }
    }
    
    // Special Options State
    @Published var isSpecialOptionEnabled: Bool = false {
        didSet {
            if !isSpecialOptionEnabled {
                // Reset team count validation if disabling
                let clamped = min(max(numberOfTeams, Self.teamCountRange.lowerBound), Self.teamCountRange.upperBound)
                if numberOfTeams != clamped { numberOfTeams = clamped }
            } else if specialOptionMode == .distributeByOption {
                numberOfTeams = max(specialOptions.count, Self.teamCountRange.lowerBound)
            }
        }
    }
    @Published var specialOptionMode: SpecialOptionMode = .assignToTeams {
        didSet {
            if isSpecialOptionEnabled && specialOptionMode == .distributeByOption {
                numberOfTeams = max(specialOptions.count, Self.teamCountRange.lowerBound)
            }
        }
    }
    @Published var specialOptions: [String] = [] {
        didSet {
            // If in distribute mode, sync team count
            if isSpecialOptionEnabled && specialOptionMode == .distributeByOption {
                numberOfTeams = max(specialOptions.count, Self.teamCountRange.lowerBound)
            }
        }
    }
    @Published var currentOptionInput: String = ""
    
    @Published var teamResult: [[String]] = []
    @Published var teamLabels: [String] = []
    
    // MARK: - Logic
    
    func addName() {
        let trimmed = currentNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !nameList.contains(trimmed) {
            withAnimation {
                nameList.insert(trimmed, at: 0) // Add to top
            }
        }
        currentNameInput = "" 
    }
    
    func removeName(_ name: String) {
        withAnimation {
            nameList.removeAll { $0 == name }
        }
    }
    
    func addSpecialOption() {
        let trimmed = currentOptionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !specialOptions.contains(trimmed) {
            withAnimation {
                specialOptions.append(trimmed)
            }
        }
        currentOptionInput = ""
    }
    
    func removeSpecialOption(_ option: String) {
        withAnimation {
            specialOptions.removeAll { $0 == option }
        }
    }
    
    func generateTeamsByName() {
        guard !nameList.isEmpty else { return }
        
        let shuffled = nameList.shuffled()
        distributeTeams(items: shuffled)
    }
    
    func generateTeamsByCount() {
        guard totalPeople > 0 else { return }
        
        // Generate numbers 1 to Total
        let numbers = (1...totalPeople).map { String($0) }
        let shuffled = numbers.shuffled()
        distributeTeams(items: shuffled)
    }
    
    func resetData() {
        withAnimation {
            currentNameInput = ""
            nameList = []
            teamResult = []
            teamLabels = []
            numberOfTeams = 2
            totalPeople = 4
            // Reset Special Options
            isSpecialOptionEnabled = false
            specialOptions = []
            currentOptionInput = ""
            specialOptionMode = .assignToTeams
        }
    }
    
    private func distributeTeams(items: [String]) {
        // Determine actual team count and labels
        let finalTeamCount: Int
        var labels: [String] = []
        
        if isSpecialOptionEnabled {
            if specialOptionMode == .distributeByOption {
                // Mode 2: Distribute INTO options
                // If no options, default to 2
                finalTeamCount = max(specialOptions.count, Self.teamCountRange.lowerBound)
                labels = specialOptions
                // Pad if options < 2 (though validation handles)
            } else {
                // Mode 1: Assign Option TO team
                finalTeamCount = numberOfTeams
                // Randomly pick options for teams
                let shuffledOptions = specialOptions.shuffled()
                // If more teams than options, some get empty/nil? Or recycle?
                // User said "Assign randomly matching options count". 
                // Implies if 2 options, 2 teams get them. Others get "Team N".
                // We'll create labels matching team count.
                for i in 0..<finalTeamCount {
                    if i < shuffledOptions.count {
                        labels.append(shuffledOptions[i])
                    } else {
                        labels.append("") // No special option
                    }
                }
                // Shuffle the labels assignments? We shuffled options already. The assignment to team indices 0..N is random enough if options are shuffled.
                // Wait, if options are shuffled, index 0 gets Option A (random). 
                // Then distributing items is round robin.
                // It means "Team 1" (which gets Item 1, Item N+1) gets a random option.
            }
        } else {
            finalTeamCount = numberOfTeams
            labels = [] // Standard "Team N" generation in View or here?
            // Let's populate empty labels and handle "Team N" in View if empty.
        }
        
        var teams: [[String]] = Array(repeating: [], count: finalTeamCount)
        var currentItemIndex = 0
        
        // Simple round-robin distribution
        for item in items {
            teams[currentItemIndex % finalTeamCount].append(item)
            currentItemIndex += 1
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.teamResult = teams
            self.teamLabels = labels
        }
    }
}
