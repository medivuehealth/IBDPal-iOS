import SwiftUI

struct MicronutrientSummaryView: View {
    let userData: UserData?
    let journalEntries: [JournalEntry]
    
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    @State private var dailyIntake: DailyMicronutrientIntake?
    @State private var micronutrientAnalysis: IBDMicronutrientAnalysis?
    @State private var isLoading = true
    @State private var calculatedMicronutrients: [String: Double] = [:]
    @State private var foodList: [String] = []
    @State private var servingSizeInfo: [String: String] = [:]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Calculated Micronutrients Summary
                        if !calculatedMicronutrients.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("7 Day Daily Averages")
                                    .font(.headline)
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
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                        
                        // Food Sources with Serving Sizes
                        if !foodList.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last 7 Day Food Portion Sizes")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(foodList.enumerated()), id: \.offset) { index, food in
                                        HStack {
                                            Text(food)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if let servingSize = servingSizeInfo[food] {
                                                Text(servingSize)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                        
                        // Medical Disclaimer Banner at bottom
                        MedicalDisclaimerBanner()
                            .padding(.horizontal)
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
                        
                        // Medical Disclaimer Banner at bottom
                        MedicalDisclaimerBanner()
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("7-Day Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                loadMicronutrientData()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadMicronutrientData() {
        guard let userData = userData else {
            isLoading = false
            return
        }
        
        // Process foods and calculate micronutrients from the passed journal entries
        var allFoods: [String] = []
        var servingInfo: [String: String] = [:]
        for entry in journalEntries {
            if let meals = entry.meals {
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
                
                // Store the original dailyIntakeResult
                self.dailyIntake = dailyIntakeResult
                self.micronutrientAnalysis = analysis
                
                // Extract calculated micronutrients for display - convert to daily averages
                let intake = dailyIntakeResult.totalIntake
                
                // Calculate unique days from journal entries
                let uniqueDays = Set(journalEntries.map { entry in
                    let entryDate = Date.fromISOString(entry.entry_date)
                    let calendar = Calendar.current
                    return calendar.startOfDay(for: entryDate)
                }).count
                let daysCount = max(1, uniqueDays)
                
                self.calculatedMicronutrients = [
                    "Vitamin A": intake.vitaminA / Double(daysCount),
                    "Vitamin C": intake.vitaminC / Double(daysCount),
                    "Iron": intake.iron / Double(daysCount),
                    "Potassium": intake.potassium / Double(daysCount),
                    "Vitamin B12": intake.vitaminB12 / Double(daysCount),
                    "Vitamin B9": intake.vitaminB9 / Double(daysCount),
                    "Zinc": intake.zinc / Double(daysCount),
                    "Calcium": intake.calcium / Double(daysCount),
                    "Vitamin D": intake.vitaminD / Double(daysCount),
                    "Magnesium": intake.magnesium / Double(daysCount)
                ]
                
            } catch {
                print("❌ [MicronutrientSummaryView] Failed to fetch profile: \(error)")
                
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
                
                // Calculate unique days from journal entries
                let uniqueDays = Set(journalEntries.map { entry in
                    let entryDate = Date.fromISOString(entry.entry_date)
                    let calendar = Calendar.current
                    return calendar.startOfDay(for: entryDate)
                }).count
                let daysCount = max(1, uniqueDays)
                
                self.calculatedMicronutrients = [
                    "Vitamin A": intake.vitaminA / Double(daysCount),
                    "Vitamin C": intake.vitaminC / Double(daysCount),
                    "Iron": intake.iron / Double(daysCount),
                    "Potassium": intake.potassium / Double(daysCount),
                    "Vitamin B12": intake.vitaminB12 / Double(daysCount),
                    "Vitamin B9": intake.vitaminB9 / Double(daysCount),
                    "Zinc": intake.zinc / Double(daysCount),
                    "Calcium": intake.calcium / Double(daysCount),
                    "Vitamin D": intake.vitaminD / Double(daysCount),
                    "Magnesium": intake.magnesium / Double(daysCount)
                ]
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
            print("🔍 [MicronutrientSummaryView] Profile HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
            return response.data
        } catch {
            print("❌ [MicronutrientSummaryView] Profile decode error: \(error)")
            return nil
        }
    }
    
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
            return .orange
        }
    }
}





