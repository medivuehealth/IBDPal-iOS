import SwiftUI
import Foundation

struct IBDNutritionAnalysisView: View {
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    @State private var micronutrientAnalysis: IBDMicronutrientAnalysis?
    @State private var dailyIntake: DailyMicronutrientIntake?
    @State private var foodMicronutrients: [(String, MicronutrientData)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var userProfile: MicronutrientProfile?
    @Environment(\.dismiss) private var dismiss
    
    let userData: UserData?
    let journalEntries: [JournalEntry]
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Analyzing nutrition...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if let analysis = micronutrientAnalysis {
                        analysisContent(analysis)
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Micronutrient Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAnalysis()
            }
        }
    }
    
    // Break up the analysis content to fix type-checking error
    @ViewBuilder
    private func analysisContent(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(spacing: 20) {
            overallStatusSection(analysis)
            micronutrientStatusSection(analysis)
            foodMicronutrientsSection()
            recommendationsSection(analysis)
        }
    }
    
    @ViewBuilder
    private func overallStatusSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Intake")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(countOptimalNutrients(analysis)) nutrients optimal")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("IBD Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(calculateIBDScore(analysis))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ibdScoreColor(analysis))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func micronutrientStatusSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Micronutrient Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(analysis.deficiencies, id: \.id) { deficiency in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deficiency.nutrient)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(deficiency.severity.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(severityColor(deficiency.severity))
                    }
                    .padding(8)
                    .background(severityColor(deficiency.severity).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func foodMicronutrientsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Micronutrients (Last 7 Days)")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Debug info
            Text("Debug: \(foodMicronutrients.count) foods found")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if foodMicronutrients.isEmpty {
                VStack(spacing: 8) {
                    Text("No food data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This could mean:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• No journal entries in the last 7 days")
                        Text("• Journal entries don't contain meal data")
                        Text("• Food micronutrient calculation failed")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(foodMicronutrients.enumerated()), id: \.offset) { index, foodData in
                        FoodMicronutrientCard(foodName: foodData.0, micronutrients: foodData.1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func recommendationsSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.recommendations.immediateActions, id: \.nutrient) { action in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: priorityIcon(action.priority))
                            .foregroundColor(priorityColor(action.priority))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.action)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(action.timeframe)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func countOptimalNutrients(_ analysis: IBDMicronutrientAnalysis) -> Int {
        let nutrients = [
            analysis.ibdSpecificNutrients.vitaminD,
            analysis.ibdSpecificNutrients.vitaminB12,
            analysis.ibdSpecificNutrients.iron,
            analysis.ibdSpecificNutrients.calcium,
            analysis.ibdSpecificNutrients.zinc,
            analysis.ibdSpecificNutrients.omega3
        ]
        return nutrients.filter { $0.status == .optimal }.count
    }
    
    private func calculateIBDScore(_ analysis: IBDMicronutrientAnalysis) -> String {
        let optimalCount = countOptimalNutrients(analysis)
        let totalCount = 6
        
        let percentage = Double(optimalCount) / Double(totalCount) * 100
        
        switch percentage {
        case 80...100:
            return "Excellent"
        case 60..<80:
            return "Good"
        case 40..<60:
            return "Fair"
        default:
            return "Needs Improvement"
        }
    }
    
    private func ibdScoreColor(_ analysis: IBDMicronutrientAnalysis) -> Color {
        let score = calculateIBDScore(analysis)
        switch score {
        case "Excellent":
            return .green
        case "Good":
            return .blue
        case "Fair":
            return .orange
        default:
            return .red
        }
    }
    
    private func severityColor(_ severity: DeficiencySeverity) -> Color {
        switch severity {
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        case .critical:
            return .red
        }
    }
    
    private func priorityIcon(_ priority: ActionPriority) -> String {
        switch priority {
        case .critical:
            return "exclamationmark.octagon.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "info.circle.fill"
        }
    }
    
    private func priorityColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .critical:
            return .red
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private func loadAnalysis() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First, fetch the user's micronutrient profile
            guard let userId = userData?.id else {
                throw NSError(domain: "No user ID", code: 0)
            }
            
            print("🔍 [DEBUG] Starting nutrition analysis for user: \(userId)")
            
            // Fetch journal entries directly from API (like MicronutrientAnalysisCard does)
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            guard let url = URL(string: "\(apiBaseURL)/journal/entries/\(userId)?startDate=\(startDateString)&endDate=\(endDateString)") else {
                throw NSError(domain: "Invalid URL", code: 0)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
            
            print("🔍 [DEBUG] Fetching journal entries from: \(url)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [DEBUG] Journal entries HTTP Status: \(httpResponse.statusCode)")
            }
            
            let recentEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
            print("🔍 [DEBUG] Successfully loaded \(recentEntries.count) journal entries from API")
            
            // Debug: Print recent entries
            for (index, entry) in recentEntries.enumerated() {
                print("🔍 [DEBUG] Entry \(index + 1): \(entry.entry_date)")
                if let meals = entry.meals {
                    print("🔍 [DEBUG]   Meals count: \(meals.count)")
                    for (mealIndex, meal) in meals.enumerated() {
                        print("🔍 [DEBUG]   Meal \(mealIndex + 1): \(meal.description)")
                    }
                } else {
                    print("🔍 [DEBUG]   No meals in this entry")
                }
            }
            
            let profile = try await fetchMicronutrientProfile(userId: userId)
            
            // Use the fetched profile or create a default one
            let profileToUse = profile ?? MicronutrientProfile(
                userId: userId,
                age: 30,
                weight: 70.0,
                height: 170.0,
                gender: "Unknown",
                diseaseActivity: .remission,
                labResults: [],
                supplements: []
            )
            
            print("🔍 [DEBUG] Using profile: age=\(profileToUse.age), weight=\(profileToUse.weight)")
            print("🔍 [DEBUG] Profile supplements count: \(profileToUse.supplements.count)")
            
            await MainActor.run {
                self.userProfile = profileToUse
            }
            
            // Calculate micronutrient intake from journal entries (use recent entries)
            let dailyIntakeResult = micronutrientCalculator.calculateDailyMicronutrientIntake(
                from: recentEntries,
                userProfile: profileToUse
            )
            
            print("🔍 [DEBUG] Daily intake result food sources count: \(dailyIntakeResult.foodSources.count)")
            print("🔍 [DEBUG] Food sources: \(dailyIntakeResult.foodSources.keys)")
            
            let analysis = deficiencyAnalyzer.analyzeMicronutrientStatus(
                dailyIntakeResult.totalIntake,
                dailyIntakeResult.requirements,
                profileToUse.labResults
            )
            
            // Process food micronutrients
            var foodData: [(String, MicronutrientData)] = []
            for (foodName, micronutrientData) in dailyIntakeResult.foodSources {
                print("🔍 [DEBUG] Processing food: \(foodName)")
                print("🔍 [DEBUG]   Vitamin C: \(micronutrientData.vitaminC) mg")
                print("🔍 [DEBUG]   Iron: \(micronutrientData.iron) mg")
                print("🔍 [DEBUG]   Vitamin D: \(micronutrientData.vitaminD) mcg")
                foodData.append((foodName, micronutrientData))
            }
            
            print("🔍 [DEBUG] Final food data count: \(foodData.count)")
            
            await MainActor.run {
                self.dailyIntake = dailyIntakeResult
                self.micronutrientAnalysis = analysis
                self.foodMicronutrients = foodData
                self.isLoading = false
            }
        } catch {
            print("❌ [ERROR] Nutrition analysis failed: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - API Methods
    
    private func fetchMicronutrientProfile(userId: String) async throws -> MicronutrientProfile? {
        let fullURL = "\(apiBaseURL)/micronutrient/profile"
        
        guard let url = URL(string: fullURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [DEBUG] Micronutrient Profile HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
            return response.data
        } catch {
            print("Decoding error: \(error)")
            // If decoding fails, return nil (no profile exists yet)
            return nil
        }
    }
}

struct FoodMicronutrientCard: View {
    let foodName: String
    let micronutrients: MicronutrientData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(foodName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                MicronutrientValueItem(name: "Vitamin C", value: micronutrients.vitaminC, unit: "mg")
                MicronutrientValueItem(name: "Iron", value: micronutrients.iron, unit: "mg")
                MicronutrientValueItem(name: "Potassium", value: micronutrients.potassium, unit: "mg")
                MicronutrientValueItem(name: "Vitamin B12", value: micronutrients.vitaminB12, unit: "mcg")
                MicronutrientValueItem(name: "Vitamin B9", value: micronutrients.vitaminB9, unit: "mcg")
                MicronutrientValueItem(name: "Zinc", value: micronutrients.zinc, unit: "mg")
                MicronutrientValueItem(name: "Calcium", value: micronutrients.calcium, unit: "mg")
                MicronutrientValueItem(name: "Vitamin D", value: micronutrients.vitaminD, unit: "mcg")
                MicronutrientValueItem(name: "Magnesium", value: micronutrients.magnesium, unit: "mg")
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct MicronutrientValueItem: View {
    let name: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(4)
    }
}

#Preview {
    IBDNutritionAnalysisView(
        userData: UserData(
            id: "sample",
            email: "sample@example.com",
            name: "Sample User",
            phoneNumber: "123-456-7890",
            token: "sample_token"
        ),
        journalEntries: []
    )
}
