import SwiftUI
import Charts

struct HomeView: View {
    let userData: UserData?
    @State private var refreshTrigger: UUID
    
    @State private var isLoading = true
    @State private var reminders: [Reminder] = []
    @State private var nutritionAnalysis = NutritionAnalysis(
        avgCalories: 0, 
        avgProtein: 0, 
        avgCarbs: 0, 
        avgFiber: 0, 
        avgFat: 0, 
        daysWithMeals: 0, 
        deficiencies: [], 
        trends: []
    )
    @State private var flareRiskData = FlareRiskData(
        currentRisk: .moderate,
        trend: .stable,
        factors: [],
        lastUpdated: Date()
    )
    @State private var loadingNutrition = true
    @State private var loadingFlareRisk = true
    @State private var showingMicronutrientAnalysis = false
    @State private var journalEntries: [JournalEntry] = []
    private let apiBaseURL = AppConfig.apiBaseURL
    
    init(userData: UserData?, refreshTrigger: UUID) {
        self.userData = userData
        self._refreshTrigger = State(initialValue: refreshTrigger)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Micronutrient Analysis Card - moved to top
                    MicronutrientAnalysisCard(userData: userData) {
                        showingMicronutrientAnalysis = true
                    }
                    
                    // Welcome Header
                    welcomeHeader
                    
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
            .onChange(of: refreshTrigger) {
                // Refresh data when refresh trigger changes (from tab selection)
                print("🏠 [HomeView] Refresh triggered - reloading data")
                loadData()
            }
            .sheet(isPresented: $showingMicronutrientAnalysis) {
                IBDNutritionAnalysisView(
                    userProfile: MicronutrientProfile(
                        userId: userData?.id ?? "user", 
                        age: 30, 
                        weight: 70.0, 
                        height: 170.0, 
                        gender: "male", 
                        diseaseActivity: .remission, 
                        labResults: [], 
                        supplements: []
                    ), 
                    journalEntries: journalEntries
                )
                .onDisappear {
                    // Refresh data when micronutrient analysis is closed
                    refreshData()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            if let userData = userData {
                Text("Hello, \(userData.name ?? "User")")
                    .font(.subheadline)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var quickStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            nutritionCard
            flareRiskCard
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.ibdAccent)
                Text("Nutrition")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if loadingNutrition {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(nutritionAnalysis.avgCalories)) cal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Avg daily intake")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    if !nutritionAnalysis.deficiencies.isEmpty {
                        Text("\(nutritionAnalysis.deficiencies.count) deficiencies")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var flareRiskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(flareRiskColor(flareRiskData.currentRisk))
                Text("Flare Risk")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if loadingFlareRisk {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flareRiskData.currentRisk.rawValue.capitalized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(flareRiskColor(flareRiskData.currentRisk))
                    
                    Text("Current level")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    if flareRiskData.trend != .stable {
                        Text("Trend: \(flareRiskTrendString(flareRiskData.trend))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var recentReminders: some View {
        if !reminders.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Reminders")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(reminders.prefix(5)) { reminder in
                            ReminderCard(reminder: reminder)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func flareRiskTrendString(_ trend: FlareRiskTrend) -> String {
        switch trend {
        case .improving:
            return "improving"
        case .stable:
            return "stable"
        case .worsening:
            return "worsening"
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadData() {
        loadJournalEntries()
        loadNutritionAnalysis()
        loadFlareRiskData()
    }

    private func refreshData() {
        refreshTrigger = UUID()
    }
    
    private func loadJournalEntries() {
        guard let userData = userData else { return }
        
        print("📖 [HomeView] Loading journal entries for user: \(userData.email)")
        
        // Fetch journal entries from the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userData.id)?startDate=\(startDateString)&endDate=\(endDateString)") else {
            print("❌ [HomeView] Invalid URL for journal entries")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        print("🌐 [HomeView] Fetching journal entries from: \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [HomeView] Network error loading journal entries: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("❌ [HomeView] No data received for journal entries")
                    return
                }
                
                do {
                    let entries = try JSONDecoder().decode([JournalEntry].self, from: data)
                    self.journalEntries = entries
                    print("✅ [HomeView] Successfully loaded \(entries.count) journal entries")
                } catch {
                    print("❌ [HomeView] JSON decode error for journal entries: \(error)")
                }
            }
        }.resume()
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
        // Generate realistic nutrition data
        let avgCalories = Double.random(in: 1600...2200)
        let avgProtein = Double.random(in: 60...100)
        let avgCarbs = Double.random(in: 150...250)
        let avgFiber = Double.random(in: 12...28)
        let avgFat = Double.random(in: 50...80)
        let daysWithMeals = Int.random(in: 5...7)
        
        // Calculate deficiencies based on IBD targets
        let ibdTargets = IBDTargets()
        var deficiencies: [NutritionDeficiency] = []
        
        // Simulate common IBD deficiencies
        if avgFiber < 20 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Fiber",
                currentIntake: avgFiber,
                recommendedIntake: 25.0,
                severity: avgFiber < 15 ? .severe : .moderate,
                impact: "Digestive health and inflammation control"
            ))
        }
        
        if avgProtein < 80 {
            deficiencies.append(NutritionDeficiency(
                nutrient: "Protein",
                currentIntake: avgProtein,
                recommendedIntake: 90.0,
                severity: avgProtein < 60 ? .severe : .moderate,
                impact: "Tissue repair and immune function"
            ))
        }
        
        return NutritionAnalysis(
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFiber: avgFiber,
            avgFat: avgFat,
            daysWithMeals: daysWithMeals,
            deficiencies: deficiencies,
            trends: [
                "Calorie intake has been consistent",
                "Protein levels need improvement",
                "Fiber intake is below recommended levels"
            ]
        )
    }
    
    private func loadFlareRiskData() {
        guard let userData = userData else { return }
        
        loadingFlareRisk = true
        
        // For now, generate sample flare risk data
        // In the future, this would be an API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadingFlareRisk = false
            
            let sampleFlareData = self.generateSampleFlareRiskData()
            self.flareRiskData = sampleFlareData
            
            print("🔥 [HomeView] Generated flare risk data - Risk Level: \(sampleFlareData.currentRisk.rawValue)")
        }
    }
    
    private func generateSampleFlareRiskData() -> FlareRiskData {
        // Generate realistic flare risk data
        let riskLevels: [FlareRiskLevel] = [.low, .moderate, .high]
        let currentRisk = riskLevels.randomElement() ?? .moderate
        
        let trends: [FlareRiskTrend] = [.improving, .stable, .worsening]
        let trend = trends.randomElement() ?? .stable
        
        let factors = [
            FlareRiskFactor(type: "Stress", impact: .moderate, description: "Work-related stress"),
            FlareRiskFactor(type: "Diet", impact: .high, description: "Recent dietary changes"),
            FlareRiskFactor(type: "Sleep", impact: .low, description: "Irregular sleep patterns")
        ]
        
        return FlareRiskData(
            currentRisk: currentRisk,
            trend: trend,
            factors: factors,
            lastUpdated: Date()
        )
    }
    
    private func generateReminders(from entries: [[String: Any]]) -> [Reminder] {
        var reminders: [Reminder] = []
        
        // Generate medication reminders
        reminders.append(Reminder(
            id: UUID().uuidString,
            title: "Take Morning Medication",
            description: "Time for your daily medication",
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .medication,
            priority: .high,
            isCompleted: false
        ))
        
        // Generate meal reminders
        reminders.append(Reminder(
            id: UUID().uuidString,
            title: "Log Lunch",
            description: "Don't forget to log your lunch",
            time: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .meal,
            priority: .medium,
            isCompleted: false
        ))
        
        // Generate hydration reminders
        reminders.append(Reminder(
            id: UUID().uuidString,
            title: "Stay Hydrated",
            description: "Drink water to maintain hydration",
            time: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .hydration,
            priority: .medium,
            isCompleted: false
        ))
        
        return reminders
    }
    
    private func flareRiskColor(_ risk: FlareRiskLevel) -> Color {
        switch risk {
        case .low:
            return .green
        case .moderate:
            return .orange
        case .high:
            return .red
        case .veryHigh:
            return .red
        }
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminderIcon(for: reminder.type))
                    .foregroundColor(reminderColor(for: reminder.type))
                
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                if reminder.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Text(reminder.description)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .lineLimit(2)
            
            HStack {
                Text(reminder.time, style: .time)
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
                
                Spacer()
                
                if reminder.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
        .frame(width: 200)
    }
    
    private func reminderIcon(for type: ReminderType) -> String {
        switch type {
        case .medication:
            return "pills.fill"
        case .meal:
            return "fork.knife"
        case .hydration:
            return "drop.fill"
        case .exercise:
            return "figure.walk"
        case .appointment:
            return "calendar"
        }
    }
    
    private func reminderColor(for type: ReminderType) -> Color {
        switch type {
        case .medication:
            return .blue
        case .meal:
            return .orange
        case .hydration:
            return .cyan
        case .exercise:
            return .green
        case .appointment:
            return .purple
        }
    }
}

// MARK: - Data Models

struct Reminder: Identifiable {
    let id: String
    let title: String
    let description: String
    let time: Date
    let type: ReminderType
    let priority: ReminderPriority
    let isCompleted: Bool
}

enum ReminderType {
    case medication
    case meal
    case hydration
    case exercise
    case appointment
}

enum ReminderPriority {
    case high
    case medium
    case low
}

struct NutritionAnalysis {
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFiber: Double
    let avgFat: Double
    let daysWithMeals: Int
    let deficiencies: [NutritionDeficiency]
    let trends: [String]
}

struct NutritionDeficiency {
    let nutrient: String
    let currentIntake: Double
    let recommendedIntake: Double
    let severity: DeficiencySeverity
    let impact: String
}

struct FlareRiskData {
    let currentRisk: FlareRiskLevel
    let trend: FlareRiskTrend
    let factors: [FlareRiskFactor]
    let lastUpdated: Date
}

enum FlareRiskTrend {
    case improving
    case stable
    case worsening
}

struct FlareRiskFactor: Identifiable {
    let id = UUID()
    let type: String
    let impact: FlareRiskImpact
    let description: String
}

enum FlareRiskImpact {
    case low
    case moderate
    case high
}

#Preview {
    HomeView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"), refreshTrigger: UUID())
}
