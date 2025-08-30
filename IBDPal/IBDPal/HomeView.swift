import SwiftUI
import Charts

struct HomeView: View {
    let userData: UserData?
    
    @State private var isLoading = true
    @State private var reminders: [Reminder] = []
    @State private var nutritionAnalysis = NutritionAnalysis()
    @State private var flareRiskData = FlareRiskData()
    @State private var loadingNutrition = true
    @State private var loadingFlareRisk = true
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Text("Here's your IBD care summary")
                            .font(.subheadline)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Nutrition Deficiencies Analysis
                    if loadingNutrition {
                        ProgressView("Analyzing nutrition data...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        NutritionDeficienciesCard(analysis: nutritionAnalysis)
                    }
                    
                    // Dietician Recommendations
                    if !loadingNutrition {
                        DieticianRecommendationsCard(analysis: nutritionAnalysis)
                    }
                    
                    // Nutrition Insights Tab
                    if !loadingNutrition {
                        NutritionInsightsCard(analysis: nutritionAnalysis)
                    }
                    
                    // Flare Risk Indicator
                    if loadingFlareRisk {
                        ProgressView("Calculating flare risk...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        FlareRiskCard(data: flareRiskData)
                    }
                    
                    // Reminders
                    if !reminders.isEmpty {
                        RemindersSection(reminders: reminders)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationTitle("IBDPal")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("🏠 [HomeView] View appeared - THIS SHOULD BE VISIBLE IN XCODE")
                print("🏠 [HomeView] User data: \(userData?.email ?? "nil")")
                loadData()
            }
        }
    }
    
    private func loadData() {
        loadNutritionAnalysis()
        loadFlareRiskData()
    }
    

    

    
    private func loadNutritionAnalysis() {
        guard let userData = userData else { return }
        
        loadingNutrition = true
        print("🥗 [HomeView] Starting nutrition analysis for user: \(userData.email)")
        
        // For now, generate sample data based on the backfilled entries
        // In the future, this would be an API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadingNutrition = false
            
            // Generate realistic nutrition data based on our backfilled entries
            let sampleAnalysis = self.generateSampleNutritionAnalysis()
            self.nutritionAnalysis = sampleAnalysis
            
            print("🥗 [HomeView] Generated nutrition analysis - Calories: \(sampleAnalysis.avgCalories), Protein: \(sampleAnalysis.avgProtein), Fiber: \(sampleAnalysis.avgFiber)")
        }
    }
    
    private func generateSampleNutritionAnalysis() -> NutritionAnalysis {
        // Generate realistic data based on our backfilled entries
        let avgCalories = Double.random(in: 1600...2200)
        let avgProtein = Double.random(in: 60...100)
        let avgCarbs = Double.random(in: 150...250)
        let avgFiber = Double.random(in: 12...28)
        let avgFat = Double.random(in: 50...80)
        let daysWithMeals = Int.random(in: 5...7)
        
        // Calculate deficiencies based on IBD targets
        let ibdTargets = IBDTargets()
        var deficiencies: [NutritionDeficiency] = []
        
        if avgProtein < Double(ibdTargets.proteinTarget) * 0.9 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Protein",
                currentLevel: avgProtein,
                recommendedLevel: Double(ibdTargets.proteinTarget),
                severity: avgProtein < Double(ibdTargets.proteinTarget) * 0.7 ? .high : .moderate,
                impact: "Protein helps with healing and muscle maintenance",
                foodSources: ["Chicken breast", "Salmon", "Greek yogurt", "Eggs", "Tofu"]
            ))
        }
        
        if avgFiber < Double(ibdTargets.fiberTarget) * 0.8 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Fiber",
                currentLevel: avgFiber,
                recommendedLevel: Double(ibdTargets.fiberTarget),
                severity: avgFiber < Double(ibdTargets.fiberTarget) * 0.6 ? .high : .moderate,
                impact: "Fiber helps with digestive health and regularity",
                foodSources: ["Oatmeal", "Bananas", "Sweet potatoes", "Quinoa", "Spinach"]
            ))
        }
        
        if avgCalories < Double(ibdTargets.calorieTarget) * 0.9 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Calories",
                currentLevel: avgCalories,
                recommendedLevel: Double(ibdTargets.calorieTarget),
                severity: avgCalories < Double(ibdTargets.calorieTarget) * 0.8 ? .high : .moderate,
                impact: "Adequate calories are needed for energy and healing",
                foodSources: ["Nuts", "Avocado", "Olive oil", "Whole grains", "Lean meats"]
            ))
        }
        
        // Generate personalized recommendations
        var recommendations: [String] = []
        
        if avgProtein < Double(ibdTargets.proteinTarget) * 0.9 {
            recommendations.append("Add lean protein sources like chicken breast or salmon to your meals")
        }
        
        if avgFiber < Double(ibdTargets.fiberTarget) * 0.8 {
            recommendations.append("Gradually increase soluble fiber intake with oatmeal and bananas")
        }
        
        if avgCalories < Double(ibdTargets.calorieTarget) * 0.9 {
            recommendations.append("Consider adding healthy snacks between meals to increase calorie intake")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Maintain your current nutrition balance - you're doing great!")
        }
        
        // Calculate overall score
        let proteinScore = min(avgProtein / Double(ibdTargets.proteinTarget), 1.0) * 100
        let fiberScore = min(avgFiber / Double(ibdTargets.fiberTarget), 1.0) * 100
        let calorieScore = min(avgCalories / Double(ibdTargets.calorieTarget), 1.0) * 100
        let overallScore = Int((proteinScore + fiberScore + calorieScore) / 3)
        
        // Generate food patterns based on our backfilled data
        let foodPatterns = generateFoodPatterns()
        
        // Generate low nutrition foods
        let lowNutritionFoods = generateLowNutritionFoods()
        
        // Generate enhancement recommendations
        let enhancementRecommendations = generateEnhancementRecommendations()
        
        return NutritionAnalysis(
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFiber: avgFiber,
            avgFat: avgFat,
            daysWithMeals: daysWithMeals,
            deficiencies: deficiencies,
            recommendations: recommendations,
            overallScore: overallScore,
            lastUpdated: Date(),
            foodPatterns: foodPatterns,
            lowNutritionFoods: lowNutritionFoods,
            enhancementRecommendations: enhancementRecommendations
        )
    }
    
    private func loadFlareRiskData() {
        guard let userData = userData else { return }
        
        loadingFlareRisk = true
        
        // For now, generate sample flare risk data
        // In the future, this would be an API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadingFlareRisk = false
            
            // Generate realistic flare risk data
            let sampleFlareData = self.generateSampleFlareRiskData()
            self.flareRiskData = sampleFlareData
            
            print("🔥 [HomeView] Generated flare risk data - Risk Level: \(sampleFlareData.currentRisk.rawValue)")
        }
    }
    
    private func generateSampleFlareRiskData() -> FlareRiskData {
        // Generate realistic flare risk based on our backfilled data patterns
        let riskLevels: [FlareRiskLevel] = [.low, .moderate, .high, .veryHigh]
        let currentRisk = riskLevels.randomElement() ?? .low
        
        // Generate trend data for the last 30 days
        var trend: [FlareRiskPoint] = []
        let calendar = Calendar.current
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // Create realistic trend with some variation
            let baseScore: Double
            switch currentRisk {
            case .low: baseScore = Double.random(in: 10...30)
            case .moderate: baseScore = Double.random(in: 30...50)
            case .high: baseScore = Double.random(in: 50...70)
            case .veryHigh: baseScore = Double.random(in: 70...90)
            }
            
            let variation = Double.random(in: -10...10)
            let score = max(0, min(100, baseScore + variation))
            
            let trendRiskLevel: FlareRiskLevel
            if score < 25 { trendRiskLevel = .low }
            else if score < 50 { trendRiskLevel = .moderate }
            else if score < 75 { trendRiskLevel = .high }
            else { trendRiskLevel = .veryHigh }
            
            trend.append(FlareRiskPoint(
                date: date,
                riskLevel: trendRiskLevel,
                score: score
            ))
        }
        
        // Generate risk factors based on current risk level
        var factors: [FlareRiskFactor] = []
        
        switch currentRisk {
        case .low:
            factors = [
                FlareRiskFactor(factor: "Good medication adherence", impact: 0.2, description: "Consistent medication use"),
                FlareRiskFactor(factor: "Balanced nutrition", impact: 0.15, description: "Meeting nutritional needs"),
                FlareRiskFactor(factor: "Low stress levels", impact: 0.1, description: "Stress management")
            ]
        case .moderate:
            factors = [
                FlareRiskFactor(factor: "Inconsistent medication", impact: 0.4, description: "Missing some doses"),
                FlareRiskFactor(factor: "Dietary triggers", impact: 0.3, description: "Some foods causing issues"),
                FlareRiskFactor(factor: "Moderate stress", impact: 0.2, description: "Elevated stress levels")
            ]
        case .high:
            factors = [
                FlareRiskFactor(factor: "Poor medication adherence", impact: 0.6, description: "Frequently missing medication"),
                FlareRiskFactor(factor: "High stress levels", impact: 0.5, description: "Significant stress"),
                FlareRiskFactor(factor: "Poor sleep quality", impact: 0.4, description: "Inadequate sleep"),
                FlareRiskFactor(factor: "Dietary issues", impact: 0.3, description: "Trigger foods consumed")
            ]
        case .veryHigh:
            factors = [
                FlareRiskFactor(factor: "Severe medication non-adherence", impact: 0.8, description: "Not taking medication regularly"),
                FlareRiskFactor(factor: "Very high stress", impact: 0.7, description: "Extreme stress levels"),
                FlareRiskFactor(factor: "Poor sleep", impact: 0.6, description: "Chronic sleep issues"),
                FlareRiskFactor(factor: "Multiple trigger foods", impact: 0.5, description: "Consuming many trigger foods"),
                FlareRiskFactor(factor: "Recent flare", impact: 0.4, description: "Recent flare episode")
            ]
        }
        
        return FlareRiskData(
            currentRisk: currentRisk,
            trend: trend,
            factors: factors,
            lastUpdated: Date()
        )
    }
    

    
    private func generateReminders(from entries: [[String: Any]]) -> [Reminder] {
        var reminders: [Reminder] = []
        
        if entries.isEmpty {
            reminders.append(Reminder(
                id: "weekly-log",
                type: .warning,
                title: "Weekly Log Missing",
                message: "You haven't logged anything in the past 7 days. Regular tracking helps identify patterns.",
                action: "Add Entry",
                icon: "plus.circle",
                priority: .high
            ))
        }
        
        return reminders
    }
    

    
    private func generateFoodPatterns() -> [NutritionFoodPattern] {
        // Based on our backfilled data, generate realistic food patterns
        let commonFoods = [
            NutritionFoodPattern(name: "Chicken Breast", frequency: 5, nutritionScore: 85, calories: 165, protein: 31.0, fiber: 0.0, mealType: "Dinner"),
            NutritionFoodPattern(name: "White Rice", frequency: 4, nutritionScore: 45, calories: 130, protein: 2.7, fiber: 0.4, mealType: "Lunch"),
            NutritionFoodPattern(name: "Bananas", frequency: 6, nutritionScore: 75, calories: 105, protein: 1.3, fiber: 3.1, mealType: "Snack"),
            NutritionFoodPattern(name: "Greek Yogurt", frequency: 4, nutritionScore: 80, calories: 130, protein: 23.0, fiber: 0.0, mealType: "Breakfast"),
            NutritionFoodPattern(name: "Bread", frequency: 3, nutritionScore: 40, calories: 80, protein: 3.0, fiber: 1.0, mealType: "Breakfast"),
            NutritionFoodPattern(name: "Salmon", frequency: 2, nutritionScore: 90, calories: 208, protein: 25.0, fiber: 0.0, mealType: "Dinner")
        ]
        
        return commonFoods.sorted { $0.frequency > $1.frequency }
    }
    
    private func generateLowNutritionFoods() -> [LowNutritionFood] {
        // Identify foods that are eaten frequently but lack nutrition
        return [
            LowNutritionFood(
                name: "White Rice",
                frequency: 4,
                missingNutrients: ["Fiber", "Protein", "Vitamins"],
                currentNutrition: ["calories": 130, "protein": 2.7, "fiber": 0.4],
                suggestedEnhancements: ["Add vegetables", "Mix with quinoa", "Add beans"]
            ),
            LowNutritionFood(
                name: "Bread",
                frequency: 3,
                missingNutrients: ["Fiber", "Protein"],
                currentNutrition: ["calories": 80, "protein": 3.0, "fiber": 1.0],
                suggestedEnhancements: ["Use whole grain bread", "Add avocado", "Add lean protein"]
            ),
            LowNutritionFood(
                name: "Crackers",
                frequency: 2,
                missingNutrients: ["Protein", "Fiber", "Vitamins"],
                currentNutrition: ["calories": 120, "protein": 2.0, "fiber": 0.5],
                suggestedEnhancements: ["Add hummus", "Add cheese", "Add vegetables"]
            )
        ]
    }
    
    private func generateEnhancementRecommendations() -> [EnhancementRecommendation] {
        // Generate specific recommendations for enhancing common foods
        return [
            EnhancementRecommendation(
                title: "Enhance White Rice",
                description: "Add quinoa and vegetables to increase protein and fiber content",
                impact: "High",
                targetFood: "White Rice",
                suggestedAdditions: ["Quinoa", "Broccoli", "Carrots", "Chickpeas"],
                expectedNutritionGain: ["protein": 8.0, "fiber": 5.0, "vitamins": 15.0]
            ),
            EnhancementRecommendation(
                title: "Improve Bread Nutrition",
                description: "Switch to whole grain bread and add healthy toppings",
                impact: "Medium",
                targetFood: "Bread",
                suggestedAdditions: ["Avocado", "Turkey", "Spinach", "Tomatoes"],
                expectedNutritionGain: ["protein": 12.0, "fiber": 3.0, "healthy_fats": 8.0]
            ),
            EnhancementRecommendation(
                title: "Boost Greek Yogurt",
                description: "Add berries and nuts for extra fiber and healthy fats",
                impact: "High",
                targetFood: "Greek Yogurt",
                suggestedAdditions: ["Berries", "Almonds", "Chia Seeds", "Honey"],
                expectedNutritionGain: ["fiber": 4.0, "healthy_fats": 6.0, "antioxidants": 10.0]
            ),
            EnhancementRecommendation(
                title: "Enhance Chicken Meals",
                description: "Add vegetables and healthy grains for balanced nutrition",
                impact: "Medium",
                targetFood: "Chicken Breast",
                suggestedAdditions: ["Sweet Potato", "Broccoli", "Brown Rice", "Olive Oil"],
                expectedNutritionGain: ["fiber": 6.0, "vitamins": 20.0, "healthy_fats": 4.0]
            )
        ]
    }
}

// MARK: - Helper Functions
func getSuggestedFoods(for analysis: NutritionAnalysis) -> [SuggestedFood] {
    var foods: [SuggestedFood] = []
    
    // Add foods based on deficiencies
    for deficiency in analysis.deficiencies {
        switch deficiency.nutrient.lowercased() {
        case "protein":
            foods.append(SuggestedFood(name: "Salmon", benefit: "Protein", color: .blue))
            foods.append(SuggestedFood(name: "Chicken", benefit: "Protein", color: .blue))
            foods.append(SuggestedFood(name: "Greek Yogurt", benefit: "Protein", color: .purple))
        case "fiber":
            foods.append(SuggestedFood(name: "Oatmeal", benefit: "Fiber", color: .green))
            foods.append(SuggestedFood(name: "Bananas", benefit: "Fiber", color: .yellow))
            foods.append(SuggestedFood(name: "Quinoa", benefit: "Fiber", color: .green))
        case "calories":
            foods.append(SuggestedFood(name: "Avocado", benefit: "Healthy Fats", color: .green))
            foods.append(SuggestedFood(name: "Nuts", benefit: "Calories", color: .brown))
            foods.append(SuggestedFood(name: "Olive Oil", benefit: "Healthy Fats", color: .green))
        default:
            break
        }
    }
    
    // Add general IBD-friendly foods if no specific deficiencies
    if foods.isEmpty {
        foods = [
            SuggestedFood(name: "Salmon", benefit: "Omega-3", color: .blue),
            SuggestedFood(name: "Quinoa", benefit: "Protein", color: .green),
            SuggestedFood(name: "Spinach", benefit: "Iron", color: .green),
            SuggestedFood(name: "Greek Yogurt", benefit: "Probiotics", color: .purple)
        ]
    }
    
    return foods
}

// MARK: - Data Models



struct NutritionAnalysis {
    var avgCalories: Double = 0
    var avgProtein: Double = 0
    var avgCarbs: Double = 0
    var avgFiber: Double = 0
    var avgFat: Double = 0
    var daysWithMeals: Int = 0
    var deficiencies: [NutritionDeficiency] = []
    var recommendations: [String] = []
    var overallScore: Int = 0
    var lastUpdated: Date = Date()
    
    // New fields for nutrition insights
    var foodPatterns: [NutritionFoodPattern] = []
    var lowNutritionFoods: [LowNutritionFood] = []
    var enhancementRecommendations: [EnhancementRecommendation] = []
    
    static func from(dictionary: [String: Any]) -> NutritionAnalysis {
        var analysis = NutritionAnalysis()
        
        // Parse average nutrition values - handle both string and double values
        if let caloriesString = dictionary["avg_calories"] as? String {
            analysis.avgCalories = Double(caloriesString) ?? 0
        } else {
            analysis.avgCalories = dictionary["avg_calories"] as? Double ?? 0
        }
        
        if let proteinString = dictionary["avg_protein"] as? String {
            analysis.avgProtein = Double(proteinString) ?? 0
        } else {
            analysis.avgProtein = dictionary["avg_protein"] as? Double ?? 0
        }
        
        if let carbsString = dictionary["avg_carbs"] as? String {
            analysis.avgCarbs = Double(carbsString) ?? 0
        } else {
            analysis.avgCarbs = dictionary["avg_carbs"] as? Double ?? 0
        }
        
        if let fiberString = dictionary["avg_fiber"] as? String {
            analysis.avgFiber = Double(fiberString) ?? 0
        } else {
            analysis.avgFiber = dictionary["avg_fiber"] as? Double ?? 0
        }
        
        if let fatString = dictionary["avg_fat"] as? String {
            analysis.avgFat = Double(fatString) ?? 0
        } else {
            analysis.avgFat = dictionary["avg_fat"] as? Double ?? 0
        }
        
        if let daysString = dictionary["days_with_meals"] as? String {
            analysis.daysWithMeals = Int(daysString) ?? 0
        } else {
            analysis.daysWithMeals = dictionary["days_with_meals"] as? Int ?? 0
        }
        
        print("🥗 [NutritionAnalysis] Parsed values - Calories: \(analysis.avgCalories), Protein: \(analysis.avgProtein), Fiber: \(analysis.avgFiber)")
        
        if let deficienciesData = dictionary["deficiencies"] as? [[String: Any]] {
            analysis.deficiencies = deficienciesData.compactMap { NutritionDeficiency.from(dictionary: $0) }
        }
        
        if let recommendations = dictionary["recommendations"] as? [String] {
            analysis.recommendations = recommendations
        }
        
        if let score = dictionary["overall_score"] as? Int {
            analysis.overallScore = score
        }
        
        if let updatedString = dictionary["last_updated"] as? String {
            let formatter = ISO8601DateFormatter()
            analysis.lastUpdated = formatter.date(from: updatedString) ?? Date()
        }
        
        return analysis
    }
}

struct NutritionDeficiency: Identifiable {
    let id = UUID()
    let nutrient: String
    let currentLevel: Double
    let recommendedLevel: Double
    let severity: DeficiencySeverity
    let impact: String
    let foodSources: [String]
    
    var percentage: Double {
        guard recommendedLevel > 0 else { return 0 }
        return (currentLevel / recommendedLevel) * 100
    }
    
    static func from(dictionary: [String: Any]) -> NutritionDeficiency? {
        guard let nutrient = dictionary["nutrient"] as? String,
              let severityString = dictionary["severity"] as? String,
              let impact = dictionary["impact"] as? String,
              let foodSources = dictionary["food_sources"] as? [String] else {
            return nil
        }
        
        // Parse current_level - handle both string and double
        let currentLevel: Double
        if let currentLevelString = dictionary["current_level"] as? String {
            currentLevel = Double(currentLevelString) ?? 0
        } else {
            currentLevel = dictionary["current_level"] as? Double ?? 0
        }
        
        // Parse recommended_level - handle both string and double
        let recommendedLevel: Double
        if let recommendedLevelString = dictionary["recommended_level"] as? String {
            recommendedLevel = Double(recommendedLevelString) ?? 0
        } else {
            recommendedLevel = dictionary["recommended_level"] as? Double ?? 0
        }
        
        let severity = DeficiencySeverity(rawValue: severityString) ?? .moderate
        
        return NutritionDeficiency(
            nutrient: nutrient,
            currentLevel: currentLevel,
            recommendedLevel: recommendedLevel,
            severity: severity,
            impact: impact,
            foodSources: foodSources
        )
    }
}

enum DeficiencySeverity: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "exclamationmark.triangle"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct FlareRiskData {
    var currentRisk: FlareRiskLevel = .low
    var trend: [FlareRiskPoint] = []
    var factors: [FlareRiskFactor] = []
    var lastUpdated: Date = Date()
    
    static func from(dictionary: [String: Any]) -> FlareRiskData {
        var data = FlareRiskData()
        
        if let riskString = dictionary["current_risk"] as? String {
            data.currentRisk = FlareRiskLevel(rawValue: riskString) ?? .low
        }
        
        if let trendData = dictionary["trend"] as? [[String: Any]] {
            data.trend = trendData.compactMap { FlareRiskPoint.from(dictionary: $0) }
        }
        
        if let factorsData = dictionary["factors"] as? [[String: Any]] {
            data.factors = factorsData.compactMap { FlareRiskFactor.from(dictionary: $0) }
        }
        
        if let updatedString = dictionary["last_updated"] as? String {
            let formatter = ISO8601DateFormatter()
            data.lastUpdated = formatter.date(from: updatedString) ?? Date()
        }
        
        return data
    }
}

struct FlareRiskPoint: Identifiable {
    let id = UUID()
    let date: Date
    let riskLevel: FlareRiskLevel
    let score: Double
    
    static func from(dictionary: [String: Any]) -> FlareRiskPoint? {
        guard let dateString = dictionary["date"] as? String,
              let riskString = dictionary["risk_level"] as? String,
              let score = dictionary["score"] as? Double else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: dateString) ?? Date()
        let riskLevel = FlareRiskLevel(rawValue: riskString) ?? .low
        
        return FlareRiskPoint(date: date, riskLevel: riskLevel, score: score)
    }
}

struct FlareRiskFactor: Identifiable {
    let id = UUID()
    let factor: String
    let impact: Double
    let description: String
    
    static func from(dictionary: [String: Any]) -> FlareRiskFactor? {
        guard let factor = dictionary["factor"] as? String,
              let impact = dictionary["impact"] as? Double,
              let description = dictionary["description"] as? String else {
            return nil
        }
        
        return FlareRiskFactor(factor: factor, impact: impact, description: description)
    }
}

enum FlareRiskLevel: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle"
        case .moderate: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        case .veryHigh: return "xmark.octagon"
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .veryHigh: return "Very High Risk"
        }
    }
}

struct Reminder: Identifiable {
    let id: String
    let type: ReminderType
    let title: String
    let message: String
    let action: String
    let icon: String
    let priority: ReminderPriority
}

struct SuggestedFood {
    let name: String
    let benefit: String
    let color: Color
}

// MARK: - Nutrition Insights Data Models
struct NutritionFoodPattern: Identifiable {
    let id = UUID()
    let name: String
    let frequency: Int
    let nutritionScore: Int
    let calories: Int
    let protein: Double
    let fiber: Double
    let mealType: String
}

struct LowNutritionFood: Identifiable {
    let id = UUID()
    let name: String
    let frequency: Int
    let missingNutrients: [String]
    let currentNutrition: [String: Double]
    let suggestedEnhancements: [String]
}

struct EnhancementRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let impact: String
    let targetFood: String
    let suggestedAdditions: [String]
    let expectedNutritionGain: [String: Double]
}

enum ReminderType {
    case warning
    case info
    case success
}

enum ReminderPriority {
    case high
    case medium
    case low
}

// MARK: - View Components





struct NutritionDeficienciesCard: View {
    let analysis: NutritionAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.ibdNutritionColor)
                Text("Nutrition Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text("Score: \(analysis.overallScore)/100")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(analysis.overallScore >= 70 ? .green : analysis.overallScore >= 50 ? .orange : .red)
            }
            
            // Nutrition Summary Section
            if analysis.daysWithMeals > 0 {
                VStack(spacing: 12) {
                    Text("7-Day Average")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    HStack(spacing: 20) {
                        NutritionValueCard(
                            title: "Calories",
                            value: "\(Int(analysis.avgCalories))",
                            unit: "kcal",
                            color: .orange
                        )
                        
                        NutritionValueCard(
                            title: "Protein",
                            value: "\(Int(analysis.avgProtein))",
                            unit: "g",
                            color: .blue
                        )
                        
                        NutritionValueCard(
                            title: "Fiber",
                            value: "\(Int(analysis.avgFiber))",
                            unit: "g",
                            color: .green
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            if analysis.deficiencies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Great nutrition balance!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Your nutrition intake meets IBD recommendations")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(analysis.deficiencies.prefix(3)) { deficiency in
                        DeficiencyRow(deficiency: deficiency)
                    }
                    
                    if analysis.deficiencies.count > 3 {
                        Button("View all \(analysis.deficiencies.count) deficiencies") {
                            // Navigate to detailed view
                        }
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                    }
                }
            }
            
            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    ForEach(analysis.recommendations.prefix(2), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.ibdAccent)
                                .padding(.top, 2)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.ibdSecondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NutritionValueCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.ibdSecondaryText)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.ibdSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DeficiencyRow: View {
    let deficiency: NutritionDeficiency
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: deficiency.severity.icon)
                .foregroundColor(deficiency.severity.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deficiency.nutrient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Text("\(Int(deficiency.percentage))% of recommended")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(deficiency.severity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(deficiency.severity.color)
                
                Text("\(Int(deficiency.currentLevel))g")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

struct FlareRiskCard: View {
    let data: FlareRiskData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(data.currentRisk.color)
                Text("Flare Risk Indicator")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text(data.currentRisk.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(data.currentRisk.color)
            }
            
            // Risk Trend Chart
            if !data.trend.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("3-Month Trend")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Chart(data.trend) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Risk", point.score)
                        )
                        .foregroundStyle(data.currentRisk.color)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Risk", point.score)
                        )
                        .foregroundStyle(data.currentRisk.color.opacity(0.1))
                    }
                    .frame(height: 100)
                    .chartYScale(domain: 0...100)
                }
            }
            
            // Risk Factors
            if !data.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contributing Factors")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    ForEach(data.factors.prefix(3)) { factor in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(factor.impact > 0.7 ? .red : factor.impact > 0.4 ? .orange : .yellow)
                                .frame(width: 8, height: 8)
                            
                            Text(factor.factor)
                                .font(.caption)
                                .foregroundColor(.ibdPrimaryText)
                            
                            Spacer()
                            
                            Text("\(Int(factor.impact * 100))%")
                                .font(.caption)
                                .foregroundColor(.ibdSecondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RemindersSection: View {
    let reminders: [Reminder]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
                .padding(.horizontal)
            
            ForEach(reminders) { reminder in
                ReminderCard(reminder: reminder)
            }
        }
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.icon)
                .foregroundColor(reminder.type == .warning ? .ibdWarning : .ibdInfo)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(reminder.message)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(reminder.action) {
                // Handle action
            }
            .font(.caption)
            .foregroundColor(.ibdPrimary)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Nutrition Insights Card
struct NutritionInsightsCard: View {
    let analysis: NutritionAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.ibdAccent)
                Text("Nutrition Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                Spacer()
            }
            
            // Most Common Foods
            VStack(alignment: .leading, spacing: 12) {
                Text("My Most Common Foods")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                ForEach(analysis.foodPatterns.prefix(3), id: \.name) { food in
                    CommonFoodRow(food: food)
                }
            }
            
            // Low Nutrition Foods
            if !analysis.lowNutritionFoods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Changes to My Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    ForEach(analysis.lowNutritionFoods.prefix(2), id: \.name) { food in
                        LowNutritionFoodRow(food: food)
                    }
                }
            }
            
            // Enhancement Recommendations
            if !analysis.enhancementRecommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggestions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    ForEach(analysis.enhancementRecommendations.prefix(3), id: \.id) { recommendation in
                        EnhancementRecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Dietician Recommendations Card
struct DieticianRecommendationsCard: View {
    let analysis: NutritionAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.ibdAccent)
                Text("Dietician Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                Spacer()
            }
            
            // Immediate Actions
            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Immediate Actions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    ForEach(analysis.recommendations.prefix(3), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.ibdWarning)
                                .padding(.top, 2)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.ibdSecondaryText)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            
            // Weekly Goals
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Goals")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                VStack(spacing: 8) {
                    let ibdTargets = IBDTargets()
                    
                    WeeklyGoalRow(
                        title: "Protein Intake",
                        target: "\(ibdTargets.proteinTarget)g",
                        current: "\(Int(analysis.avgProtein))g",
                        progress: min(analysis.avgProtein / Double(ibdTargets.proteinTarget), 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Fiber Intake",
                        target: "\(ibdTargets.fiberTarget)g",
                        current: "\(Int(analysis.avgFiber))g",
                        progress: min(analysis.avgFiber / Double(ibdTargets.fiberTarget), 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Calorie Balance",
                        target: "\(ibdTargets.calorieTarget) kcal",
                        current: "\(Int(analysis.avgCalories)) kcal",
                        progress: min(analysis.avgCalories / Double(ibdTargets.calorieTarget), 1.0)
                    )
                }
            }
            
            // Food Suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended Foods")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    // Dynamic food suggestions based on deficiencies
                    let suggestedFoods = getSuggestedFoods(for: analysis)
                    
                    ForEach(suggestedFoods.prefix(4), id: \.name) { food in
                        FoodSuggestionItem(name: food.name, benefit: food.benefit, color: food.color)
                    }
                }
            }
            
            // Meal Timing
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Timing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack(spacing: 16) {
                    let currentTime = Date()
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: currentTime)
                    
                    MealTimingItem(
                        time: "8:00 AM",
                        meal: "Breakfast",
                        status: hour < 8 ? .pending : hour < 12 ? .completed : .missed
                    )
                    MealTimingItem(
                        time: "12:00 PM",
                        meal: "Lunch",
                        status: hour < 12 ? .pending : hour < 18 ? .completed : .missed
                    )
                    MealTimingItem(
                        time: "6:00 PM",
                        meal: "Dinner",
                        status: hour < 18 ? .pending : .completed
                    )
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Components for Dietician Recommendations
struct WeeklyGoalRow: View {
    let title: String
    let target: String
    let current: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text("\(current) / \(target)")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress >= 0.8 ? .green : progress >= 0.6 ? .orange : .red))
        }
    }
}

struct FoodSuggestionItem: View {
    let name: String
    let benefit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.ibdPrimaryText)
            
            Text(benefit)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MealTimingItem: View {
    let time: String
    let meal: String
    let status: MealStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Text(time)
                .font(.caption2)
                .foregroundColor(.ibdSecondaryText)
            
            Text(meal)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.ibdPrimaryText)
            
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Nutrition Insights Components
struct CommonFoodRow: View {
    let food: NutritionFoodPattern
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .foregroundColor(.ibdNutritionColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Text("Eaten \(food.frequency) times this week")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(food.nutritionScore)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(food.nutritionScore >= 70 ? .green : food.nutritionScore >= 50 ? .orange : .red)
                
                Text("Nutrition")
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

struct LowNutritionFoodRow: View {
    let food: LowNutritionFood
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.ibdWarning)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Text("Low in \(food.missingNutrients.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(food.frequency)x/week")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdSecondaryText)
                
                Text("Frequency")
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

struct EnhancementRecommendationRow: View {
    let recommendation: EnhancementRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.ibdAccent)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(recommendation.impact)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(recommendation.impact == "High" ? .green : recommendation.impact == "Medium" ? .orange : .red)
                
                Text("Impact")
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

enum MealStatus {
    case completed
    case pending
    case missed
    
    var color: Color {
        switch self {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .missed:
            return .red
        }
    }
}



#Preview {
    HomeView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
} 