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
                VStack(spacing: 24) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Analyzing nutrition...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Processing your micronutrient data")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                            .foregroundColor(.red)
                            
                            Text("Analysis Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    } else if let analysis = micronutrientAnalysis {
                        analysisContent(analysis)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No Analysis Available")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Unable to generate micronutrient analysis")
                                .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("Micronutrient Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
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
        VStack(spacing: 24) {
            overallStatusSection(analysis)
            summaryMetricsSection(analysis)
            ibdSpecificNutrientsSection(analysis)
            recommendationsSection(analysis)
            foodMicronutrientsSection()
        }
    }
    
    @ViewBuilder
    private func overallStatusSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Overall Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Status cards removed - only showing summary metrics below
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func summaryMetricsSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary metrics
            HStack(spacing: 12) {
                StatusMetricCard(
                    title: "Deficiencies",
                    count: analysis.deficiencies.count,
                    color: analysis.deficiencies.isEmpty ? .green : .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatusMetricCard(
                    title: "Excesses",
                    count: analysis.excesses.count,
                    color: analysis.excesses.isEmpty ? .green : .orange,
                    icon: "arrow.up.circle.fill"
                )
                
                StatusMetricCard(
                    title: "Optimal",
                    count: countOptimalNutrients(analysis),
                    color: .blue,
                    icon: "checkmark.circle.fill"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func ibdSpecificNutrientsSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("IBD-Specific Nutrients")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                IBDNutrientCard(
                    name: "Vitamin D",
                    status: analysis.ibdSpecificNutrients.vitaminD.status,
                    value: analysis.ibdSpecificNutrients.vitaminD.currentIntake,
                    target: analysis.ibdSpecificNutrients.vitaminD.requiredIntake,
                    unit: "IU"
                )
                
                IBDNutrientCard(
                    name: "Vitamin B12",
                    status: analysis.ibdSpecificNutrients.vitaminB12.status,
                    value: analysis.ibdSpecificNutrients.vitaminB12.currentIntake,
                    target: analysis.ibdSpecificNutrients.vitaminB12.requiredIntake,
                    unit: "mcg"
                )
                
                IBDNutrientCard(
                    name: "Iron",
                    status: analysis.ibdSpecificNutrients.iron.status,
                    value: analysis.ibdSpecificNutrients.iron.currentIntake,
                    target: analysis.ibdSpecificNutrients.iron.requiredIntake,
                    unit: "mg"
                )
                
                IBDNutrientCard(
                    name: "Calcium",
                    status: analysis.ibdSpecificNutrients.calcium.status,
                    value: analysis.ibdSpecificNutrients.calcium.currentIntake,
                    target: analysis.ibdSpecificNutrients.calcium.requiredIntake,
                    unit: "mg"
                )
                
                IBDNutrientCard(
                    name: "Zinc",
                    status: analysis.ibdSpecificNutrients.zinc.status,
                    value: analysis.ibdSpecificNutrients.zinc.currentIntake,
                    target: analysis.ibdSpecificNutrients.zinc.requiredIntake,
                    unit: "mg"
                )
                
                IBDNutrientCard(
                    name: "Omega-3",
                    status: analysis.ibdSpecificNutrients.omega3.status,
                    value: analysis.ibdSpecificNutrients.omega3.currentIntake,
                    target: analysis.ibdSpecificNutrients.omega3.requiredIntake,
                    unit: "mg"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func foodMicronutrientsSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Food Micronutrients")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Last 7 Days")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if foodMicronutrients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Food Data Available")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This could mean:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• No journal entries in the last 7 days")
                            Text("• Journal entries don't contain meal data")
                            Text("• Food micronutrient calculation failed")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(foodMicronutrients.enumerated()), id: \.offset) { index, foodData in
                        FoodMicronutrientCard(
                            foodName: foodData.0, 
                            micronutrients: foodData.1,
                            servingSize: nil // TODO: Pass serving size from calculation
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func recommendationsSection(_ analysis: IBDMicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if analysis.recommendations.immediateActions.isEmpty {
                // No recommendations - show success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("No Immediate Actions Needed")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your current nutrition status doesn't require immediate intervention. Continue following your current dietary plan.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Show recommendations with professional cards
                LazyVStack(spacing: 12) {
                    ForEach(analysis.recommendations.immediateActions, id: \.nutrient) { action in
                        RecommendationCard(action: action)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
    
    private func getScoreLevel(_ analysis: IBDMicronutrientAnalysis) -> Int {
        let score = calculateIBDScore(analysis)
        switch score {
        case "Excellent":
            return 5
        case "Good":
            return 4
        case "Fair":
            return 3
        default:
            return 2
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
            
            // Fetch journal entries from the last 7 days
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            print("🔍 [IBDNutritionAnalysisView] Date range: \(startDateString) to \(endDateString)")
            
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
    let servingSize: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Food header
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text(foodName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let servingSize = servingSize {
                    Text(servingSize)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Micronutrients grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MicronutrientValueItem: View {
    let name: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Card Components

struct StatusMetricCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DeficiencyCard: View {
    let deficiency: MicronutrientDeficiency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: severityIcon(deficiency.severity))
                    .font(.title3)
                    .foregroundColor(severityColor(deficiency.severity))
                
                Text(deficiency.nutrient)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deficiency.severity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor(deficiency.severity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(severityColor(deficiency.severity).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(severityColor(deficiency.severity).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func severityIcon(_ severity: DeficiencySeverity) -> String {
        switch severity {
        case .mild:
            return "exclamationmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle.fill"
        case .severe:
            return "exclamationmark.octagon.fill"
        case .critical:
            return "xmark.octagon.fill"
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
}

struct ExcessCard: View {
    let excess: MicronutrientExcess
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: severityIcon(excess.severity))
                    .font(.title3)
                    .foregroundColor(severityColor(excess.severity))
                
                Text(excess.nutrient)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(excess.severity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor(excess.severity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(severityColor(excess.severity).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(severityColor(excess.severity).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func severityIcon(_ severity: ExcessSeverity) -> String {
        switch severity {
        case .mild:
            return "arrow.up.circle.fill"
        case .moderate:
            return "arrow.up.triangle.fill"
        case .severe:
            return "arrow.up.octagon.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
    
    private func severityColor(_ severity: ExcessSeverity) -> Color {
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
}

struct IBDNutrientCard: View {
    let name: String
    let status: NutrientStatusLevel
    let value: Double
    let target: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: statusIcon(status))
                    .font(.caption)
                    .foregroundColor(statusColor(status))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(String(format: "%.1f", value)) \(unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("of \(String(format: "%.1f", target)) \(unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                ProgressView(value: value, total: target)
                    .progressViewStyle(LinearProgressViewStyle(tint: statusColor(status)))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor(status).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(statusColor(status).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func statusIcon(_ status: NutrientStatusLevel) -> String {
        switch status {
        case .optimal:
            return "checkmark.circle.fill"
        case .deficient:
            return "exclamationmark.triangle.fill"
        case .suboptimal:
            return "exclamationmark.circle.fill"
        case .adequate:
            return "checkmark.circle"
        case .excessive:
            return "arrow.up.circle.fill"
        }
    }
    
    private func statusColor(_ status: NutrientStatusLevel) -> Color {
        switch status {
        case .optimal:
            return .green
        case .deficient:
            return .red
        case .suboptimal:
            return .orange
        case .adequate:
            return .blue
        case .excessive:
            return .orange
        }
    }
}

struct RecommendationCard: View {
    let action: MicronutrientAction
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Priority indicator
            VStack {
                Image(systemName: priorityIcon(action.priority))
                    .font(.title3)
                    .foregroundColor(priorityColor(action.priority))
                
                Text(priorityText(action.priority))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(priorityColor(action.priority))
            }
            .frame(width: 60)
            
            // Action content
            VStack(alignment: .leading, spacing: 8) {
                Text(action.action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(action.timeframe)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(action.nutrient)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(priorityColor(action.priority).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(priorityColor(action.priority).opacity(0.3), lineWidth: 1)
                )
        )
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
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private func priorityText(_ priority: ActionPriority) -> String {
        switch priority {
        case .critical:
            return "Critical"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        }
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
