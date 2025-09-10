import SwiftUI
import Foundation
import Combine

struct HomeView: View {
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    
    @State private var journalEntries: [JournalEntry] = []
    @State private var nutritionAnalysis = NutritionAnalysis()
    @State private var loadingNutrition = false
    @State private var showingMicronutrientAnalysis = false
    
    let userData: UserData?
    @ObservedObject var dataRefreshManager: DataRefreshManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Welcome Header - at the very top
                    welcomeHeader
                    
                    // 2. Micronutrient Analysis Card
                    MicronutrientAnalysisCard(userData: userData) {
                        showingMicronutrientAnalysis = true
                    }
                    
                    // 3. Original Comprehensive Nutrition Analysis Section
                    if loadingNutrition {
                        ProgressView("Analyzing nutrition data...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        // Nutrition Deficiencies Analysis
                        NutritionDeficienciesCard(analysis: nutritionAnalysis)
                        
                        // Dietician Recommendations
                        DieticianRecommendationsCard(analysis: nutritionAnalysis)
                        
                        // Nutrition Insights Tab
                        NutritionInsightsCard(analysis: nutritionAnalysis)
                    }
                    
                    // Quick Stats Grid - Now includes both Nutrition and Flare Risk
                    quickStatsGrid
                    
                    // Recent Reminders
                    recentReminders
                    
                    Spacer(minLength: 100)
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
            .onChange(of: dataRefreshManager.refreshTrigger) {
                // Refresh data when refresh trigger changes
                print("🏠 [HomeView] Refresh triggered - reloading data")
                loadData()
            }
            .sheet(isPresented: $showingMicronutrientAnalysis) {
                IBDNutritionAnalysisView(
                    userData: userData,
                    journalEntries: journalEntries
                )
                .onAppear {
                    print("🔍 [HomeView DEBUG] IBDNutritionAnalysisView sheet opened with \(journalEntries.count) journal entries")
                }
                .onDisappear {
                    // Refresh data when micronutrient analysis is closed
                    dataRefreshManager.refreshData()
                }
            }
        }
    }
    
    // MARK: - Welcome Header
    @ViewBuilder
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title2)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Text(userData?.name ?? "User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                }
                
                Spacer()
                
                // Profile picture placeholder
                Circle()
                    .fill(Color.ibdAccent)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(userData?.name?.first ?? "U"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            
            Text("How are you feeling today?")
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Stats Grid
    @ViewBuilder
    private var quickStatsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Nutrition Score
                StatCard(
                    title: "Nutrition Score",
                    value: "\(nutritionAnalysis.overallScore)",
                    subtitle: "/100",
                    icon: "leaf.fill",
                    color: nutritionAnalysis.overallScore >= 70 ? .green : nutritionAnalysis.overallScore >= 50 ? .orange : .red
                )
                
                // Flare Risk
                StatCard(
                    title: "Flare Risk",
                    value: "Low",
                    subtitle: "Risk",
                    icon: "heart.fill",
                    color: .green
                )
                
                // Daily Meals
                StatCard(
                    title: "Meals Today",
                    value: "\(getTodaysMealCount())",
                    subtitle: "meals",
                    icon: "fork.knife",
                    color: .blue
                )
                
                // Symptoms
                StatCard(
                    title: "Symptoms",
                    value: "\(getTodaysSymptomCount())",
                    subtitle: "reported",
                    icon: "exclamationmark.triangle.fill",
                    color: getTodaysSymptomCount() == 0 ? .green : .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Recent Reminders
    @ViewBuilder
    private var recentReminders: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(getRecentReminders(), id: \.id) { reminder in
                    ReminderCard(reminder: reminder)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        Task {
            await loadJournalEntries()
            await loadNutritionAnalysis()
        }
    }
    
    private func loadJournalEntries() async {
        guard let userData = userData else { 
            print("🔍 [HomeView DEBUG] No userData available for loading journal entries")
            return 
        }
        
        print("🔍 [HomeView DEBUG] Starting to load journal entries for user: \(userData.id)")
        
        do {
            let entries = try await networkManager.fetchJournalEntries(userId: userData.id)
            print("🔍 [HomeView DEBUG] Successfully loaded \(entries.count) journal entries")
            await MainActor.run {
                self.journalEntries = entries
                print("🔍 [HomeView DEBUG] Updated HomeView journalEntries to \(self.journalEntries.count) entries")
            }
        } catch {
            print("❌ [HomeView] Failed to load journal entries: \(error)")
        }
    }
    
    private func loadNutritionAnalysis() async {
        await MainActor.run {
            loadingNutrition = true
        }
        
        // Simulate analysis loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            // Generate realistic nutrition analysis
            nutritionAnalysis = generateNutritionAnalysis()
            loadingNutrition = false
        }
    }
    
    private func refreshData() {
        dataRefreshManager.refreshData()
    }
    
    // MARK: - Helper Functions
    private func getTodaysMealCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return journalEntries.filter { entry in
            Calendar.current.isDate(Date.fromISOString(entry.entry_date), inSameDayAs: today)
        }.flatMap { (entry: JournalEntry) in entry.meals ?? [] }.count
    }
    
    private func getTodaysSymptomCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return journalEntries.filter { entry in
            Calendar.current.isDate(Date.fromISOString(entry.entry_date), inSameDayAs: today)
        }.flatMap { $0.symptoms ?? [] }.count
    }
    
    private func getRecentReminders() -> [Reminder] {
        return [
            Reminder(
                id: UUID(),
                title: "Log your meals",
                message: "Track your nutrition for better IBD management",
                type: .info,
                priority: .medium,
                date: Date()
            ),
            Reminder(
                id: UUID(),
                title: "Take your medication",
                message: "Don't forget your daily medication",
                type: .warning,
                priority: .high,
                date: Date().addingTimeInterval(-3600)
            )
        ]
    }
    
    private func generateNutritionAnalysis() -> NutritionAnalysis {
        var analysis = NutritionAnalysis()
        
        // Calculate averages from journal entries
        let recentEntries = journalEntries.prefix(7)
        let mealsWithNutrition = recentEntries.flatMap { (entry: JournalEntry) in entry.meals ?? [] }.compactMap { (meal: Meal) in 
    CalculatedNutrition(
        detectedFoods: [meal.description],
        totalCalories: Double(meal.calories ?? 0),
        totalProtein: Double(meal.protein ?? 0),
        totalCarbs: Double(meal.carbs ?? 0),
        totalFiber: Double(meal.fiber ?? 0),
        totalFat: Double(meal.fat ?? 0)
    )
}
        
        if !mealsWithNutrition.isEmpty {
            analysis.avgCalories = mealsWithNutrition.map { $0.totalCalories }.reduce(0, +) / Double(mealsWithNutrition.count)
            analysis.avgProtein = mealsWithNutrition.map { $0.totalProtein }.reduce(0, +) / Double(mealsWithNutrition.count)
            analysis.avgCarbs = mealsWithNutrition.map { $0.totalCarbs }.reduce(0, +) / Double(mealsWithNutrition.count)
            analysis.avgFiber = mealsWithNutrition.map { $0.totalFiber }.reduce(0, +) / Double(mealsWithNutrition.count)
            analysis.avgFat = mealsWithNutrition.map { $0.totalFat }.reduce(0, +) / Double(mealsWithNutrition.count)
            analysis.daysWithMeals = Set(recentEntries.map { Calendar.current.startOfDay(for: Date.fromISOString($0.entry_date)) }).count
        }
        
        // Generate deficiencies based on averages
        analysis.deficiencies = generateDeficiencies(from: analysis)
        analysis.recommendations = generateRecommendations(from: analysis)
        analysis.overallScore = calculateOverallScore(from: analysis)
        analysis.foodPatterns = generateFoodPatterns()
        analysis.lowNutritionFoods = generateLowNutritionFoods()
        analysis.enhancementRecommendations = generateEnhancementRecommendations()
        
        return analysis
    }
    
    private func generateDeficiencies(from analysis: NutritionAnalysis) -> [NutritionDeficiency] {
        var deficiencies: [NutritionDeficiency] = []
        
        if analysis.avgProtein < 50 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Protein",
                currentLevel: analysis.avgProtein,
                recommendedLevel: 80.0,
                percentage: (analysis.avgProtein / 80.0) * 100,
                severity: analysis.avgProtein < 30 ? .severe : .moderate
            ))
        }
        
        if analysis.avgFiber < 20 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Fiber",
                currentLevel: analysis.avgFiber,
                recommendedLevel: 25.0,
                percentage: (analysis.avgFiber / 25.0) * 100,
                severity: analysis.avgFiber < 10 ? .severe : .moderate
            ))
        }
        
        if analysis.avgCalories < 1500 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Calories",
                currentLevel: analysis.avgCalories,
                recommendedLevel: 2000.0,
                percentage: (analysis.avgCalories / 2000.0) * 100,
                severity: analysis.avgCalories < 1200 ? .severe : .moderate
            ))
        }
        
        return deficiencies
    }
    
    private func generateRecommendations(from analysis: NutritionAnalysis) -> [String] {
        var recommendations: [String] = []
        
        if analysis.avgProtein < 50 {
            recommendations.append("Increase protein intake with lean meats, fish, or plant-based sources")
        }
        
        if analysis.avgFiber < 20 {
            recommendations.append("Add more fiber-rich foods like oats, bananas, and cooked vegetables")
        }
        
        if analysis.avgCalories < 1500 {
            recommendations.append("Consider increasing calorie intake with healthy fats and complex carbs")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Keep up the great work with your nutrition!")
        }
        
        return recommendations
    }
    
    private func calculateOverallScore(from analysis: NutritionAnalysis) -> Int {
        var score = 100
        
        // Deduct points for deficiencies
        for deficiency in analysis.deficiencies {
            switch deficiency.severity {
            case .mild:
                score -= 10
            case .moderate:
                score -= 20
            case .severe:
                score -= 30
            case .critical:
                score -= 40
            }
        }
        
        // Bonus for good nutrition
        if analysis.avgProtein >= 60 && analysis.avgFiber >= 20 && analysis.avgCalories >= 1500 {
            score += 10
        }
        
        return max(0, min(100, score))
    }
    
    private func generateFoodPatterns() -> [NutritionFoodPattern] {
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
            )
        ]
    }
    
    private func generateEnhancementRecommendations() -> [EnhancementRecommendation] {
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
            )
        ]
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(12)
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.type.icon)
                .foregroundColor(reminder.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(reminder.message)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(reminder.priority.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(reminder.priority.color)
                
                Text(reminder.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Original Nutrition Analysis Cards

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
                .foregroundColor(deficiency.severity.colorValue)
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
                Text(deficiency.severity.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(deficiency.severity.colorValue)
                
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

// MARK: - Supporting Components

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
    var foodPatterns: [NutritionFoodPattern] = []
    var lowNutritionFoods: [LowNutritionFood] = []
    var enhancementRecommendations: [EnhancementRecommendation] = []
}

struct NutritionDeficiency: Identifiable {
    let id = UUID()
    let nutrient: String
    let currentLevel: Double
    let recommendedLevel: Double
    let percentage: Double
    let severity: DeficiencySeverity
}

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

struct SuggestedFood {
    let name: String
    let benefit: String
    let color: Color
}

struct Reminder: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let type: ReminderType
    let priority: ReminderPriority
    let date: Date
}

enum ReminderType {
    case warning
    case info
    case success
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warning: return .orange
        case .info: return .blue
        case .success: return .green
        }
    }
}

enum ReminderPriority {
    case high
    case medium
    case low
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

enum MealStatus {
    case completed
    case pending
    case missed
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .pending: return .orange
        case .missed: return .red
        }
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

// MARK: - Date Extension
extension Date {
    static func fromISOString(_ isoString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: isoString) ?? Date()
    }
}
