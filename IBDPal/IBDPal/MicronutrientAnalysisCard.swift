import SwiftUI

struct MicronutrientAnalysisCard: View {
    let userData: UserData?
    let journalEntries: [JournalEntry]
    let onTap: () -> Void
    
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    @State private var dailyIntake: DailyMicronutrientIntake?
    @State private var micronutrientAnalysis: IBDMicronutrientAnalysis?
    @State private var isLoading = true
    @State private var calculatedMicronutrients: [String: Double] = [:]
    @State private var foodList: [String] = []
    @State private var servingSizeInfo: [String: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Micronutrient Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Last 7 days average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("View Details")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            
            if isLoading {
                ProgressView("Loading micronutrient data...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let analysis = micronutrientAnalysis {
                // Quick Status Overview
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    QuickStatusItem(
                        title: "Deficiencies",
                        count: analysis.deficiencies.count,
                        color: analysis.deficiencies.isEmpty ? .green : .red,
                        icon: "exclamationmark.triangle.fill"
                    )
                    
                    QuickStatusItem(
                        title: "Optimal",
                        count: countOptimalNutrients(analysis),
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                    
                    QuickStatusItem(
                        title: "Excesses",
                        count: analysis.excesses.count,
                        color: analysis.excesses.isEmpty ? .green : .orange,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    QuickStatusItem(
                        title: "IBD Score",
                        value: calculateIBDScore(analysis),
                        color: getIBDScoreColor(analysis),
                        icon: "heart.fill"
                    )
                }
                
                // Key Deficiencies Preview (moved to top)
                if !analysis.deficiencies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IBD-Specific Deficiencies")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(analysis.deficiencies.prefix(3), id: \.id) { deficiency in
                            HStack {
                                Text(deficiency.nutrient)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(deficiency.severity.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("All nutrients optimal!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                // Calculated Micronutrients Summary
                if !calculatedMicronutrients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7 Day Daily Averages")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(Array(calculatedMicronutrients.keys.sorted()), id: \.self) { nutrient in
                                if let value = calculatedMicronutrients[nutrient] {
                                    MicronutrientItem(nutrient: nutrient, value: value)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Food Sources with Serving Sizes
                if !foodList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 7 Day Food Portion Sizes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(foodList, id: \.self) { food in
                                HStack {
                                    Text(food)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let servingSize = servingSizeInfo[food] {
                                        Text(servingSize)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                // No data state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No micronutrient data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Log meals to see analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
        )
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }
        .padding(.horizontal)
        .onAppear {
            loadMicronutrientData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadMicronutrientData() {
        guard let userData = userData else {
            isLoading = false
            return
        }
        
        print("🥗 [MicronutrientAnalysisCard] Loading micronutrient data for user: \(userData.email)")
        print("✅ [MicronutrientAnalysisCard] Using \(journalEntries.count) journal entries from HomeView")
        
        // Process foods and calculate micronutrients from the passed journal entries
        var allFoods: [String] = []
        var servingInfo: [String: String] = [:]
        var totalMeals = 0
        for entry in journalEntries {
            if let meals = entry.meals {
                totalMeals += meals.count
                for meal in meals {
                    if !meal.description.isEmpty {
                        allFoods.append(meal.description)
                        
                        // Capture serving size information
                        var servingText = ""
                        if let servingSize = meal.serving_size, let servingUnit = meal.serving_unit {
                            servingText = "\(servingSize) \(servingUnit)"
                        } else if let servingDescription = meal.serving_description, !servingDescription.isEmpty {
                            servingText = servingDescription
                        } else {
                            // Use fallback serving size from calculation
                            let fallbackSize = self.micronutrientCalculator.parseServingSize(from: meal.description)
                            servingText = "~\(String(format: "%.1f", fallbackSize)) cups (estimated)"
                        }
                        servingInfo[meal.description] = servingText
                    }
                }
            }
        }
        
        self.foodList = allFoods
        self.servingSizeInfo = servingInfo
        print("🍽️ [MicronutrientAnalysisCard] Found \(totalMeals) meals, \(allFoods.count) food items")
        print("🍽️ [MicronutrientAnalysisCard] Food items: \(allFoods.joined(separator: ", "))")
        print("🍽️ [MicronutrientAnalysisCard] Serving sizes: \(servingInfo)")
        
        // Fetch user's actual micronutrient profile
        Task {
            do {
                let profile = try await self.fetchMicronutrientProfile(userId: userData.id)
                
                // Use the fetched profile or create a default one
                let profileToUse = profile ?? MicronutrientProfile(
                    userId: userData.id,
                    age: 30,
                    weight: 70.0,
                    height: 170.0,
                    gender: "male",
                    diseaseActivity: .remission,
                    labResults: [],
                    supplements: []
                )
                            
                // Calculate micronutrient intake from journal entries
                let dailyIntakeResult = self.micronutrientCalculator.calculateDailyMicronutrientIntake(
                    from: journalEntries,
                    userProfile: profileToUse
                )
                
                // Analyze deficiencies and excesses
                let analysis = self.deficiencyAnalyzer.analyzeMicronutrientStatus(
                    dailyIntakeResult.totalIntake,
                    dailyIntakeResult.requirements,
                    profileToUse.labResults
                )
                
                // Store the original dailyIntakeResult (without deficiencies/excesses)
                self.dailyIntake = dailyIntakeResult
                self.micronutrientAnalysis = analysis
                
                // Extract calculated micronutrients for display
                let intake = dailyIntakeResult.totalIntake
                print("🧪 [MicronutrientAnalysisCard] Success calculation - Vitamin C: \(intake.vitaminC), Iron: \(intake.iron)")
                
                self.calculatedMicronutrients = [
                    "Vitamin A": intake.vitaminA,
                    "Vitamin C": intake.vitaminC,
                    "Iron": intake.iron,
                    "Potassium": intake.potassium,
                    "Vitamin B12": intake.vitaminB12,
                    "Vitamin B9": intake.vitaminB9,
                    "Zinc": intake.zinc,
                    "Calcium": intake.calcium,
                    "Vitamin D": intake.vitaminD,
                    "Magnesium": intake.magnesium
                ]
                
                print("✅ [MicronutrientAnalysisCard] Calculated micronutrient intake")
                print("🧪 [MicronutrientAnalysisCard] Micronutrient totals: C=\(intake.vitaminC), Iron=\(intake.iron), K=\(intake.potassium)")
                print("🧪 [MicronutrientAnalysisCard] All micronutrients: \(self.calculatedMicronutrients)")
                print("🧪 [MicronutrientAnalysisCard] Success micronutrients set: \(self.calculatedMicronutrients.count) items")
                
            } catch {
                print("❌ [MicronutrientAnalysisCard] Failed to fetch profile: \(error)")
                
                // Fallback to default profile
                let dailyIntakeResult = self.micronutrientCalculator.calculateDailyMicronutrientIntake(
                    from: journalEntries,
                    userProfile: MicronutrientProfile(
                        userId: userData.id,
                        age: 30,
                        weight: 70.0,
                        height: 170.0,
                        gender: "male",
                        diseaseActivity: .remission,
                        labResults: [],
                        supplements: []
                    )
                )
                
                let analysis = self.deficiencyAnalyzer.analyzeMicronutrientStatus(
                    dailyIntakeResult.totalIntake,
                    dailyIntakeResult.requirements,
                    []
                )
                
                self.dailyIntake = dailyIntakeResult
                self.micronutrientAnalysis = analysis
                
                let intake = dailyIntakeResult.totalIntake
                print("🧪 [MicronutrientAnalysisCard] Fallback calculation - Vitamin C: \(intake.vitaminC), Iron: \(intake.iron)")
                
                self.calculatedMicronutrients = [
                    "Vitamin A": intake.vitaminA,
                    "Vitamin C": intake.vitaminC,
                    "Iron": intake.iron,
                    "Potassium": intake.potassium,
                    "Vitamin B12": intake.vitaminB12,
                    "Vitamin B9": intake.vitaminB9,
                    "Zinc": intake.zinc,
                    "Calcium": intake.calcium,
                    "Vitamin D": intake.vitaminD,
                    "Magnesium": intake.magnesium
                ]
                
                print("🧪 [MicronutrientAnalysisCard] Fallback micronutrients set: \(self.calculatedMicronutrients.count) items")
            }
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    private func fetchMicronutrientProfile(userId: String) async throws -> MicronutrientProfile? {
        let fullURL = "\(AppConfig.apiBaseURL)/micronutrient/profile"
        
        guard let url = URL(string: fullURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [MicronutrientAnalysisCard] Profile HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
            return response.data
        } catch {
            print("❌ [MicronutrientAnalysisCard] Profile decode error: \(error)")
            return nil
        }
    }
    
    private func countOptimalNutrients(_ analysis: IBDMicronutrientAnalysis) -> Int {
        // Count nutrients that are in optimal range
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
            return "Needs Work"
        }
    }
    
    private func getIBDScoreColor(_ analysis: IBDMicronutrientAnalysis) -> Color {
        let optimalCount = countOptimalNutrients(analysis)
        let totalCount = 6
        let percentage = Double(optimalCount) / Double(totalCount) * 100
        
        switch percentage {
        case 80...100:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .orange  // "Needs Work" will be orange
        }
    }
}

struct QuickStatusItem: View {
    let title: String
    let count: Int?
    let value: String?
    let color: Color
    let icon: String
    
    init(title: String, count: Int, color: Color, icon: String) {
        self.title = title
        self.count = count
        self.value = nil
        self.color = color
        self.icon = icon
    }
    
    init(title: String, value: String, color: Color, icon: String) {
        self.title = title
        self.count = nil
        self.value = value
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            if let count = count {
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else if let value = value {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MicronutrientItem: View {
    let nutrient: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(nutrient)
                .font(.caption2)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(formatValue(value, for: nutrient))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func formatValue(_ value: Double, for nutrient: String) -> String {
        let unit = getUnit(for: nutrient)
        return String(format: "%.1f %@", value, unit)
    }
    
    private func getUnit(for nutrient: String) -> String {
        switch nutrient {
        case "Vitamin A", "Vitamin B12", "Vitamin B9", "Vitamin D":
            return "mcg"
        case "Iron", "Zinc", "Magnesium":
            return "mg"
        case "Vitamin C", "Potassium", "Calcium":
            return "mg"
        default:
            return "mg"
        }
    }
}

#Preview {
    MicronutrientAnalysisCard(
        userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"),
        journalEntries: [],
        onTap: {}
    )
}
