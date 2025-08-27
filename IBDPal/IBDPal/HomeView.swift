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
        print("🥗 [HomeView] User ID: \(userData.id)")
        print("🥗 [HomeView] API URL: \(apiBaseURL)/journal/nutrition/analysis/\(userData.id)")
        
        guard let url = URL(string: "\(apiBaseURL)/journal/nutrition/analysis/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                loadingNutrition = false
                
                if let error = error {
                    print("🥗 [HomeView] Nutrition analysis error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🥗 [HomeView] Nutrition analysis response status: \(httpResponse.statusCode)")
                }
                
                guard let data = data else { 
                    print("🥗 [HomeView] No data received from nutrition analysis")
                    return 
                }
                
                do {
                    if let analysis = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🥗 [HomeView] Nutrition analysis received: \(analysis)")
                        
                        // Log the specific values we're looking for
                        if let calories = analysis["avg_calories"] {
                            print("🥗 [HomeView] Raw calories value: \(calories) (type: \(type(of: calories)))")
                        }
                        if let protein = analysis["avg_protein"] {
                            print("🥗 [HomeView] Raw protein value: \(protein) (type: \(type(of: protein)))")
                        }
                        if let fiber = analysis["avg_fiber"] {
                            print("🥗 [HomeView] Raw fiber value: \(fiber) (type: \(type(of: fiber)))")
                        }
                        
                        nutritionAnalysis = NutritionAnalysis.from(dictionary: analysis)
                        print("🥗 [HomeView] Nutrition analysis parsed successfully")
                        print("🥗 [HomeView] Final values - Calories: \(nutritionAnalysis.avgCalories), Protein: \(nutritionAnalysis.avgProtein), Fiber: \(nutritionAnalysis.avgFiber)")
                    }
                } catch {
                    print("🥗 [HomeView] Error parsing nutrition analysis: \(error)")
                }
            }
        }.resume()
    }
    
    private func loadFlareRiskData() {
        guard let userData = userData else { return }
        
        loadingFlareRisk = true
        
        guard let url = URL(string: "\(apiBaseURL)/journal/flare-risk/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                loadingFlareRisk = false
                
                guard let data = data else { return }
                
                do {
                    if let flareData = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        flareRiskData = FlareRiskData.from(dictionary: flareData)
                    }
                } catch {
                    print("Error parsing flare risk data: \(error)")
                }
            }
        }.resume()
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
                    WeeklyGoalRow(
                        title: "Protein Intake",
                        target: "84g",
                        current: "\(Int(analysis.avgProtein))g",
                        progress: min(analysis.avgProtein / 84.0, 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Fiber Intake",
                        target: "25g",
                        current: "\(Int(analysis.avgFiber))g",
                        progress: min(analysis.avgFiber / 25.0, 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Calorie Balance",
                        target: "2000 kcal",
                        current: "\(Int(analysis.avgCalories)) kcal",
                        progress: min(analysis.avgCalories / 2000.0, 1.0)
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
                    FoodSuggestionItem(name: "Salmon", benefit: "Omega-3", color: .blue)
                    FoodSuggestionItem(name: "Quinoa", benefit: "Protein", color: .green)
                    FoodSuggestionItem(name: "Spinach", benefit: "Iron", color: .green)
                    FoodSuggestionItem(name: "Greek Yogurt", benefit: "Probiotics", color: .purple)
                }
            }
            
            // Meal Timing
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Timing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack(spacing: 16) {
                    MealTimingItem(time: "8:00 AM", meal: "Breakfast", status: .completed)
                    MealTimingItem(time: "12:00 PM", meal: "Lunch", status: .pending)
                    MealTimingItem(time: "6:00 PM", meal: "Dinner", status: .pending)
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
    HomeView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", token: "token"))
} 