import SwiftUI

struct MicronutrientAnalysisCard: View {
    let userData: UserData?
    let onTap: () -> Void
    
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    @State private var dailyIntake: DailyMicronutrientIntake?
    @State private var micronutrientAnalysis: IBDMicronutrientAnalysis?
    @State private var isLoading = true
    @State private var calculatedMicronutrients: [String: Double] = [:]
    @State private var foodList: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "pills.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Micronutrient Analysis")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Last 7 days average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
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
                        color: .blue,
                        icon: "heart.fill"
                    )
                }
                
                // Calculated Micronutrients Summary
                if !calculatedMicronutrients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7-Day Average Micronutrients")
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
                
                // Food Sources
                if !foodList.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Food Sources (\(foodList.count) items)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(foodList.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Key Deficiencies Preview
                if !analysis.deficiencies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Deficiencies")
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        
        // Fetch journal entries from the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userData.id)?startDate=\(startDateString)&endDate=\(endDateString)") else {
            print("❌ [MicronutrientAnalysisCard] Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        print("🌐 [MicronutrientAnalysisCard] Fetching journal entries from: \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ [MicronutrientAnalysisCard] Network error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("❌ [MicronutrientAnalysisCard] No data received")
                    return
                }
                
                do {
                    let journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
                    print("✅ [MicronutrientAnalysisCard] Successfully loaded \(journalEntries.count) journal entries")
                    
                    // Process foods and calculate micronutrients
                    var allFoods: [String] = []
                    var totalMeals = 0
                    for entry in journalEntries {
                        if let meals = entry.meals {
                            totalMeals += meals.count
                            for meal in meals {
                                if !meal.description.isEmpty {
                                    allFoods.append(meal.description)
                                }
                            }
                        }
                    }
                    
                    self.foodList = allFoods
                    
                    // Calculate micronutrient intake from journal entries
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
                    
                    // Analyze deficiencies and excesses
                    let analysis = self.deficiencyAnalyzer.analyzeMicronutrientStatus(
                        dailyIntakeResult.totalIntake,
                        dailyIntakeResult.requirements,
                        [] // No lab results for now
                    )
                    
                    // Store the original dailyIntakeResult (without deficiencies/excesses)
                    self.dailyIntake = dailyIntakeResult
                    self.micronutrientAnalysis = analysis
                    
                    // Extract calculated micronutrients for display
                    let intake = dailyIntakeResult.totalIntake
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
                    
                } catch {
                    print("❌ [MicronutrientAnalysisCard] JSON decode error: \(error)")
                }
            }
        }.resume()
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
        onTap: {}
    )
}
