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
    @State private var userProfile: MicronutrientProfile?
    @State private var selectedTab = 0 // 0 for Overview, 1 for Micronutrients, 2 for Macronutrients
    @State private var showingNutritionScoreInfo = false
    @State private var showingFlareRiskInfo = false
    
    let userData: UserData?
    @ObservedObject var dataRefreshManager: DataRefreshManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Welcome Header - always visible at the top
                welcomeHeader
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Tab Selector
                tabSelector
                
                // Tab Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            // Overview Tab
                            overviewContent
                        } else if selectedTab == 1 {
                            // Micronutrients Tab
                            micronutrientsContent
                        } else {
                            // Macronutrients Tab
                            macronutrientsContent
                        }
                        
                        // No common components - all content is tab-specific
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .background(Color.ibdBackground)
            }
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
            .sheet(isPresented: $showingNutritionScoreInfo) {
                NutritionScoreInfoView()
            }
            .sheet(isPresented: $showingFlareRiskInfo) {
                FlareRiskInfoView()
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
    
    // MARK: - Tab Selector
    @ViewBuilder
    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 8) {
                    Text("Overview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == 0 ? .ibdPrimary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Rectangle()
                        .fill(selectedTab == 0 ? Color.ibdPrimary : Color.clear)
                        .frame(height: 3)
                        .cornerRadius(1.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Vertical separator
            Rectangle()
                .fill(Color.ibdPrimary.opacity(0.2))
                .frame(width: 1, height: 40)
            
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 8) {
                    Text("Micronutrients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == 1 ? .ibdPrimary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Rectangle()
                        .fill(selectedTab == 1 ? Color.ibdPrimary : Color.clear)
                        .frame(height: 3)
                        .cornerRadius(1.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Vertical separator
            Rectangle()
                .fill(Color.ibdPrimary.opacity(0.2))
                .frame(width: 1, height: 40)
            
            Button(action: { selectedTab = 2 }) {
                VStack(spacing: 8) {
                    Text("Macronutrients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == 2 ? .ibdPrimary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Rectangle()
                        .fill(selectedTab == 2 ? Color.ibdPrimary : Color.clear)
                        .frame(height: 3)
                        .cornerRadius(1.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ibdPrimary.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Content
    @ViewBuilder
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Today's Overview - moved from Other Nutrients tab
            if loadingNutrition {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Analyzing nutrition data...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Processing your nutrition data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            } else {
                // Quick Stats Grid (Today's Overview)
                quickStatsGrid
                
                // Daily Log Status - Completed and Pending Activities
                dailyLogStatusCard
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Micronutrients Content
    @ViewBuilder
    private var micronutrientsContent: some View {
        VStack(spacing: 20) {
            // Micronutrient Analysis Card
            MicronutrientAnalysisCard(userData: userData, journalEntries: journalEntries) {
                showingMicronutrientAnalysis = true
            }
            .accessibilityLabel("Micronutrient analysis for IBD patients")
            .accessibilityHint("Double tap to view detailed micronutrient breakdown and recommendations")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Daily Log Status Card
    @ViewBuilder
    private var dailyLogStatusCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Daily Log Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Completed Activities
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Completed")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(getCompletedActivities(), id: \.self) { activity in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(activity)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            
            // Pending Activities
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("Pending")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(getPendingActivities(), id: \.self) { activity in
                        HStack {
                            Image(systemName: "clock.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text(activity)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
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
    
    // MARK: - Daily Log Status Helper Functions
    private func parseJournalDate(_ dateString: String) -> Date {
        // First try ISO8601 format (for server responses)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            print("🔍 [DailyLogStatus] Parsed ISO8601 with fractional seconds: \(dateString) -> \(date)")
            return date
        }
        
        // Try ISO8601 without fractional seconds
        let isoFormatter2 = ISO8601DateFormatter()
        isoFormatter2.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter2.date(from: dateString) {
            print("🔍 [DailyLogStatus] Parsed ISO8601 without fractional seconds: \(dateString) -> \(date)")
            return date
        }
        
        // Try simple date format (yyyy-MM-dd) used when saving entries
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        simpleFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = simpleFormatter.date(from: dateString) {
            print("🔍 [DailyLogStatus] Parsed simple date format: \(dateString) -> \(date)")
            return date
        }
        
        // Fallback to distant past if parsing fails
        print("⚠️ [DailyLogStatus] Failed to parse date: \(dateString)")
        return Date.distantPast
    }
    
    private func getCompletedActivities() -> [String] {
        var completed: [String] = []
        
        // Check if there's a journal entry for today
        let today = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
        print("🔍 [DailyLogStatus] Checking for today's entry. Today: \(todayComponents)")
        print("🔍 [DailyLogStatus] Total journal entries: \(journalEntries.count)")
        
        for entry in journalEntries {
            let entryDateString = entry.entry_date
            let entryDate = parseJournalDate(entryDateString)
            let entryComponents = calendar.dateComponents([.year, .month, .day], from: entryDate)
            
            print("🔍 [DailyLogStatus] Checking entry date: \(entryComponents) from string: \(entryDateString)")
            
            if entryComponents.year == todayComponents.year &&
               entryComponents.month == todayComponents.month &&
               entryComponents.day == todayComponents.day {
                
                print("✅ [DailyLogStatus] Found today's entry, analyzing completion status...")
                
                // Check each form completion
                if hasMealsData(entry) {
                    completed.append("Meals")
                    print("✅ [DailyLogStatus] Meals: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Meals: NOT COMPLETED")
                }
                
                if hasSymptomsData(entry) {
                    completed.append("Symptoms")
                    print("✅ [DailyLogStatus] Symptoms: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Symptoms: NOT COMPLETED")
                }
                
                if hasBowelHealthData(entry) {
                    completed.append("Bowel Health")
                    print("✅ [DailyLogStatus] Bowel Health: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Bowel Health: NOT COMPLETED")
                }
                
                if hasMedicationData(entry) {
                    completed.append("Medication")
                    print("✅ [DailyLogStatus] Medication: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Medication: NOT COMPLETED")
                }
                
                if hasSupplementsData(entry) {
                    completed.append("Supplements")
                    print("✅ [DailyLogStatus] Supplements: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Supplements: NOT COMPLETED")
                }
                
                if hasSleepData(entry) {
                    completed.append("Sleep")
                    print("✅ [DailyLogStatus] Sleep: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Sleep: NOT COMPLETED")
                }
                
                if hasStressData(entry) {
                    completed.append("Stress")
                    print("✅ [DailyLogStatus] Stress: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Stress: NOT COMPLETED")
                }
                
                if hasHydrationData(entry) {
                    completed.append("Hydration")
                    print("✅ [DailyLogStatus] Hydration: COMPLETED")
                } else {
                    print("❌ [DailyLogStatus] Hydration: NOT COMPLETED")
                }
                
                print("📊 [DailyLogStatus] Final completed activities: \(completed)")
                break
            }
        }
        
        if completed.isEmpty {
            print("⚠️ [DailyLogStatus] No journal entry found for today or no activities completed")
            print("🔍 [DailyLogStatus] This means all activities will show as pending")
        }
        
        return completed
    }
    
    private func getPendingActivities() -> [String] {
        let allActivities = ["Meals", "Symptoms", "Bowel Health", "Medication", "Supplements", "Sleep", "Stress", "Hydration"]
        let completed = getCompletedActivities()
        return allActivities.filter { !completed.contains($0) }
    }
    
    private func hasMealsData(_ entry: JournalEntry) -> Bool {
        return entry.meals?.isEmpty == false
    }
    
    private func hasSymptomsData(_ entry: JournalEntry) -> Bool {
        return entry.symptoms?.isEmpty == false
    }
    
    private func hasBowelHealthData(_ entry: JournalEntry) -> Bool {
        return entry.bowel_movements?.isEmpty == false || entry.bowel_frequency != nil
    }
    
    private func hasMedicationData(_ entry: JournalEntry) -> Bool {
        // Check if there's meaningful medication data
        // Check for medication_type that's not "None" or has medication_taken
        return (entry.medication_type != nil && entry.medication_type != "None") || 
               entry.medication_taken == true ||
               (entry.dosage_level != nil && entry.dosage_level != "0") ||
               entry.last_taken_date != nil
    }
    
    private func hasSupplementsData(_ entry: JournalEntry) -> Bool {
        // Check if there's meaningful supplement data
        return entry.supplements_taken == true ||
               (entry.supplements_count != nil && entry.supplements_count! > 0) ||
               (entry.supplement_details != nil && !entry.supplement_details!.isEmpty)
    }
    
    private func hasSleepData(_ entry: JournalEntry) -> Bool {
        // Check if there's meaningful sleep data
        return entry.sleep_hours != nil ||
               entry.sleep_quality != nil ||
               (entry.sleep_notes != nil && !entry.sleep_notes!.isEmpty)
    }
    
    private func hasStressData(_ entry: JournalEntry) -> Bool {
        // Check if there's meaningful stress data
        return entry.stress_level != nil ||
               (entry.stress_source != nil && !entry.stress_source!.isEmpty) ||
               (entry.coping_strategies != nil && !entry.coping_strategies!.isEmpty)
    }
    
    private func hasHydrationData(_ entry: JournalEntry) -> Bool {
        return (entry.water_intake != nil && Double(entry.water_intake ?? "0") ?? 0 > 0) ||
               (entry.other_fluids != nil && Double(entry.other_fluids ?? "0") ?? 0 > 0)
    }
    
    // MARK: - Flare Risk Calculation
    
    private func getFlareRiskLevel() -> String {
        let riskScore = calculateFlareRiskScore()
        
        if riskScore >= 70 {
            return "High"
        } else if riskScore >= 40 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    private func getFlareRiskColor() -> Color {
        let riskScore = calculateFlareRiskScore()
        
        if riskScore >= 70 {
            return .red
        } else if riskScore >= 40 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func calculateFlareRiskScore() -> Int {
        guard !journalEntries.isEmpty else { return 0 }
        
        var totalScore = 0
        var entryCount = 0
        
        // Get last 7 days of entries
        let last7Days = journalEntries.prefix(7)
        
        for entry in last7Days {
            var entryScore = 0
            
            // Blood present is a major risk factor
            if let bloodPresent = entry.blood_present, bloodPresent {
                entryScore += 40
            }
            
            // Mucus present is also concerning
            if let mucusPresent = entry.mucus_present, mucusPresent {
                entryScore += 20
            }
            
            // High pain severity
            if let painSeverity = entry.pain_severity, painSeverity >= 4 {
                entryScore += 30
            } else if let painSeverity = entry.pain_severity, painSeverity >= 3 {
                entryScore += 15
            }
            
            // High urgency level
            if let urgencyLevel = entry.urgency_level, urgencyLevel >= 4 {
                entryScore += 25
            } else if let urgencyLevel = entry.urgency_level, urgencyLevel >= 3 {
                entryScore += 10
            }
            
            // High stress level
            if let stressLevel = entry.stress_level, stressLevel >= 4 {
                entryScore += 20
            } else if let stressLevel = entry.stress_level, stressLevel >= 3 {
                entryScore += 10
            }
            
            // High fatigue level
            if let fatigueLevel = entry.fatigue_level, fatigueLevel >= 4 {
                entryScore += 15
            } else if let fatigueLevel = entry.fatigue_level, fatigueLevel >= 3 {
                entryScore += 5
            }
            
            // Poor sleep quality
            if let sleepQuality = entry.sleep_quality, sleepQuality <= 2 {
                entryScore += 15
            } else if let sleepQuality = entry.sleep_quality, sleepQuality <= 3 {
                entryScore += 5
            }
            
            totalScore += entryScore
            entryCount += 1
        }
        
        // Calculate average score per day
        let averageScore = entryCount > 0 ? totalScore / entryCount : 0
        
        // Cap the score at 100
        return min(100, averageScore)
    }
    
    // MARK: - Macronutrients Content
    @ViewBuilder
    private var macronutrientsContent: some View {
        VStack(spacing: 20) {
            if loadingNutrition {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Analyzing nutrition data...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Processing your nutrition data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            } else {
                // Nutrition Deficiencies Analysis (moved from Micronutrients)
                NutritionDeficienciesCard(analysis: nutritionAnalysis)
                    .accessibilityLabel("Nutrition deficiencies analysis")
                    .accessibilityHint("Shows potential nutrient deficiencies based on your food intake")
                
                // Weekly Nutrition Trends
                WeeklyNutritionTrendsCard(analysis: nutritionAnalysis, userProfile: userProfile)
                    .accessibilityLabel("Weekly nutrition trends")
                    .accessibilityHint("Compare your actual intake with recommended daily values")
                
                // IBDPal Recommendations
                DieticianRecommendationsCard(analysis: nutritionAnalysis, userProfile: userProfile)
                    .accessibilityLabel("IBDPal recommendations")
                    .accessibilityHint("Professional dietary recommendations for IBD management")
                
                // Nutrition Insights Tab
                NutritionInsightsCard(analysis: nutritionAnalysis)
                    .accessibilityLabel("Nutrition insights")
                    .accessibilityHint("Detailed nutrition analysis and health insights")
            }
        }
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Today's Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Nutrition Score with info button
                VStack(spacing: 8) {
                    StatCard(
                        title: "Nutrition Score",
                        value: "\(nutritionAnalysis.overallScore)",
                        subtitle: "/100",
                        icon: "leaf.fill",
                        color: nutritionAnalysis.overallScore >= 70 ? .green : nutritionAnalysis.overallScore >= 50 ? .orange : .red
                    )
                    
                    Button(action: {
                        showingNutritionScoreInfo = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("How is this calculated?")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Flare Risk with info button
                VStack(spacing: 8) {
                    StatCard(
                        title: "Flare Risk",
                        value: getFlareRiskLevel(),
                        subtitle: "Risk",
                        icon: "heart.fill",
                        color: getFlareRiskColor()
                    )
                    
                    Button(action: {
                        showingFlareRiskInfo = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("How is this calculated?")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
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
        
        // Fetch journal entries from the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        print("🔍 [HomeView DEBUG] Date range: \(startDateString) to \(endDateString)")
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userData.id)?startDate=\(startDateString)&endDate=\(endDateString)") else {
            print("❌ [HomeView DEBUG] Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        print("🌐 [HomeView DEBUG] Fetching journal entries from: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [HomeView DEBUG] Journal entries HTTP Status: \(httpResponse.statusCode)")
            }
            
            let entries = try JSONDecoder().decode([JournalEntry].self, from: data)
            print("🔍 [HomeView DEBUG] Successfully loaded \(entries.count) journal entries from last 7 days")
            
            await MainActor.run {
                self.journalEntries = entries
                print("🔍 [HomeView DEBUG] Updated HomeView journalEntries to \(self.journalEntries.count) entries")
            }
        } catch {
            print("❌ [HomeView] Failed to load journal entries: \(error)")
        }
    }
    
    private func loadNutritionAnalysis() async {
        print("🔍 [HomeView] Starting loadNutritionAnalysis")
        
        await MainActor.run {
            loadingNutrition = true
        }
        
        guard let userData = userData else {
            print("❌ [HomeView] No userData available for nutrition analysis")
            await MainActor.run {
                loadingNutrition = false
            }
            return
        }
        
        print("🔍 [HomeView] UserData available: \(userData.id)")
        print("🔍 [HomeView] Journal entries count: \(journalEntries.count)")
        
        do {
            // Fetch user's micronutrient profile
            print("🔍 [HomeView] Fetching micronutrient profile...")
            let profile = try await fetchMicronutrientProfile(userId: userData.id)
            
            // Use the fetched profile or create a default one
            let profileToUse = profile ?? MicronutrientProfile(
                userId: userData.id,
                age: 30,
                weight: 70.0,
                height: 170.0,
                gender: "Unknown",
                diseaseActivity: .remission,
                labResults: [],
                supplements: []
            )
            
            print("🔍 [HomeView] Using profile: age=\(profileToUse.age), weight=\(profileToUse.weight)")
            
            // Store the profile in state for UI components
            await MainActor.run {
                self.userProfile = profileToUse
            }
            
            // Calculate real nutrition analysis from journal entries
            print("🔍 [HomeView] Starting calculateRealNutritionAnalysis...")
            let analysis = await calculateRealNutritionAnalysis(profile: profileToUse)
            
            print("🔍 [HomeView] Analysis completed:")
            print("🔍 [HomeView]   Calories: \(analysis.calories)")
            print("🔍 [HomeView]   Protein: \(analysis.protein)")
            print("🔍 [HomeView]   Carbs: \(analysis.carbs)")
            print("🔍 [HomeView]   Fiber: \(analysis.fiber)")
            print("🔍 [HomeView]   Fat: \(analysis.fat)")
            
            await MainActor.run {
                self.nutritionAnalysis = analysis
                self.loadingNutrition = false
            }
            
            print("✅ [HomeView] Nutrition analysis loaded successfully")
        } catch {
            print("❌ [HomeView] Failed to load nutrition analysis: \(error)")
            print("🔍 [HomeView] Falling back to generateNutritionAnalysis...")
            
            await MainActor.run {
                // Fallback to generated analysis
                self.nutritionAnalysis = generateNutritionAnalysis()
                self.loadingNutrition = false
            }
            
            print("🔍 [HomeView] Fallback analysis completed:")
            print("🔍 [HomeView]   Calories: \(self.nutritionAnalysis.calories)")
            print("🔍 [HomeView]   Protein: \(self.nutritionAnalysis.protein)")
            print("🔍 [HomeView]   Carbs: \(self.nutritionAnalysis.carbs)")
            print("🔍 [HomeView]   Fiber: \(self.nutritionAnalysis.fiber)")
            print("🔍 [HomeView]   Fat: \(self.nutritionAnalysis.fat)")
        }
    }
    
    private func refreshData() {
        dataRefreshManager.refreshData()
    }
    
    // MARK: - Real Nutrition Analysis
    
    private func fetchMicronutrientProfile(userId: String) async throws -> MicronutrientProfile? {
        let apiBaseURL = AppConfig.apiBaseURL
        let fullURL = "\(apiBaseURL)/micronutrient/profile"
        
        guard let url = URL(string: fullURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [HomeView] Micronutrient Profile HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
            return response.data
        } catch {
            print("🔍 [HomeView] Decoding error: \(error)")
            // If decoding fails, return nil (no profile exists yet)
            return nil
        }
    }
    
    private func calculateRealNutritionAnalysis(profile: MicronutrientProfile) async -> NutritionAnalysis {
        var analysis = NutritionAnalysis()
        
        print("🔍 [HomeView] ===== NUTRITION ANALYSIS DEBUG =====")
        print("🔍 [HomeView] Total journal entries available: \(journalEntries.count)")
        
        // Debug: Print all journal entries
        for (index, entry) in journalEntries.enumerated() {
            print("🔍 [HomeView] Entry \(index + 1): \(entry.entry_date)")
        }
        
        // Get last 7 days of journal entries
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        print("🔍 [HomeView] Date range: \(startDate) to \(endDate)")
        
        let recentEntries = journalEntries.filter { entry in
            let entryDate = Date.fromISOString(entry.entry_date)
            let isInRange = entryDate >= startDate && entryDate <= endDate
            print("🔍 [HomeView] Entry \(entry.entry_date) -> \(entryDate) -> In range: \(isInRange)")
            return isInRange
        }
        
        print("🔍 [HomeView] Analyzing \(recentEntries.count) entries from last 7 days")
        
        // Calculate daily micronutrient intake
        let dailyIntake = micronutrientCalculator.calculateDailyMicronutrientIntake(
            from: recentEntries,
            userProfile: profile
        )
        
        // Calculate weekly totals
        let weeklyTotals = calculateWeeklyTotals(from: recentEntries, profile: profile)
        
        print("🔍 [HomeView] Weekly totals calculated:")
        print("🔍 [HomeView]   Total Calories: \(weeklyTotals.totalCalories)")
        print("🔍 [HomeView]   Total Protein: \(weeklyTotals.totalProtein)")
        print("🔍 [HomeView]   Total Carbs: \(weeklyTotals.totalCarbs)")
        print("🔍 [HomeView]   Total Fiber: \(weeklyTotals.totalFiber)")
        print("🔍 [HomeView]   Total Fat: \(weeklyTotals.totalFat)")
        
        // Calculate averages
        let daysCount = max(1, recentEntries.count)
        let averageCalories = weeklyTotals.totalCalories / Double(daysCount)
        let averageProtein = weeklyTotals.totalProtein / Double(daysCount)
        let averageCarbs = weeklyTotals.totalCarbs / Double(daysCount)
        let averageFiber = weeklyTotals.totalFiber / Double(daysCount)
        let averageFat = weeklyTotals.totalFat / Double(daysCount)
        
        print("🔍 [HomeView] Average values:")
        print("🔍 [HomeView]   Average Calories: \(averageCalories)")
        print("🔍 [HomeView]   Average Protein: \(averageProtein)")
        print("🔍 [HomeView]   Average Carbs: \(averageCarbs)")
        print("🔍 [HomeView]   Average Fiber: \(averageFiber)")
        print("🔍 [HomeView]   Average Fat: \(averageFat)")
        
        // Set calculated values
        analysis.calories = Int(averageCalories)
        analysis.protein = Int(averageProtein)
        analysis.carbs = Int(averageCarbs)
        analysis.fiber = Int(averageFiber)
        analysis.fat = Int(averageFat)
        
        // Also set the avgXXX properties that the UI components expect
        analysis.avgCalories = averageCalories
        analysis.avgProtein = averageProtein
        analysis.avgCarbs = averageCarbs
        analysis.avgFiber = averageFiber
        analysis.avgFat = averageFat
        
        print("🔍 [HomeView] Final analysis values:")
        print("🔍 [HomeView]   Analysis Calories: \(analysis.calories)")
        print("🔍 [HomeView]   Analysis Protein: \(analysis.protein)")
        print("🔍 [HomeView]   Analysis Carbs: \(analysis.carbs)")
        print("🔍 [HomeView]   Analysis Fiber: \(analysis.fiber)")
        print("🔍 [HomeView]   Analysis Fat: \(analysis.fat)")
        
        // Calculate micronutrient analysis
        let micronutrientAnalysis = deficiencyAnalyzer.analyzeMicronutrientStatus(
            dailyIntake.totalIntake,
            dailyIntake.requirements,
            profile.labResults
        )
        
        // Set micronutrient data
        analysis.micronutrients = micronutrientAnalysis.ibdSpecificNutrients
        
        // Calculate trends
        analysis.weeklyTrends = calculateWeeklyTrends(
            actual: weeklyTotals,
            recommended: getRecommendedWeeklyIntake(profile: profile),
            daysCount: daysCount
        )
        
        print("🔍 [HomeView] Real analysis - Calories: \(analysis.calories), Protein: \(analysis.protein)")
        print("🔍 [HomeView] Weekly trends: \(analysis.weeklyTrends.count) trends calculated")
        
        // Generate deficiencies, recommendations, and other analysis components
        analysis.deficiencies = generateDeficiencies(from: analysis)
        analysis.recommendations = generateRecommendations(from: analysis)
        analysis.overallScore = calculateOverallScore(from: analysis)
        analysis.foodPatterns = generateFoodPatterns()
        analysis.lowNutritionFoods = generateLowNutritionFoods()
        analysis.enhancementRecommendations = generateEnhancementRecommendations()
        
        print("🔍 [HomeView] Analysis completed:")
        print("🔍 [HomeView]   Calories: \(analysis.calories)")
        print("🔍 [HomeView]   Protein: \(analysis.protein)")
        print("🔍 [HomeView]   Carbs: \(analysis.carbs)")
        print("🔍 [HomeView]   Fiber: \(analysis.fiber)")
        print("🔍 [HomeView]   Fat: \(analysis.fat)")
        
        return analysis
    }
    
    private func calculateWeeklyTotals(from entries: [JournalEntry], profile: MicronutrientProfile) -> WeeklyNutritionTotals {
        var totals = WeeklyNutritionTotals()
        
        print("🔍 [HomeView] ===== CALCULATING WEEKLY TOTALS =====")
        print("🔍 [HomeView] Processing \(entries.count) entries")
        
        for (entryIndex, entry) in entries.enumerated() {
            print("🔍 [HomeView] --- Entry \(entryIndex + 1): \(entry.entry_date) ---")
            if let meals = entry.meals {
                print("🔍 [HomeView] Entry has \(meals.count) meals")
                for (mealIndex, meal) in meals.enumerated() {
                    print("🔍 [HomeView]   Meal \(mealIndex + 1): \(meal.description)")
                    print("🔍 [HomeView]   Stored values - Calories: \(meal.calories ?? 0), Protein: \(meal.protein ?? 0), Carbs: \(meal.carbs ?? 0), Fiber: \(meal.fiber ?? 0), Fat: \(meal.fat ?? 0)")
                    
                    // Use stored values if available, otherwise calculate from description
                    let mealCalories = Double(meal.calories ?? 0)
                    let mealProtein = Double(meal.protein ?? 0)
                    let mealCarbs = Double(meal.carbs ?? 0)
                    let mealFiber = Double(meal.fiber ?? 0)
                    let mealFat = Double(meal.fat ?? 0)
                    
                    // If stored values are zero, try to estimate from food description
                    if mealCalories == 0 && mealProtein == 0 {
                        print("🔍 [HomeView]   ⚠️ Stored values are zero, estimating from description")
                        // Use the micronutrient calculator to get estimated nutrition
                        let micronutrients = micronutrientCalculator.calculateMicronutrients(for: meal, userProfile: profile)
                        
                        print("🔍 [HomeView]   Micronutrients calculated:")
                        print("🔍 [HomeView]     Vitamin C: \(micronutrients.vitaminC)")
                        print("🔍 [HomeView]     Iron: \(micronutrients.iron)")
                        print("🔍 [HomeView]     Vitamin D: \(micronutrients.vitaminD)")
                        print("🔍 [HomeView]     Calcium: \(micronutrients.calcium)")
                        
                        // Estimate all nutrition values from micronutrient data
                        let estimatedCalories = estimateCaloriesFromMicronutrients(micronutrients)
                        let estimatedProtein = estimateProteinFromMicronutrients(micronutrients)
                        let estimatedCarbs = estimateCarbsFromMicronutrients(micronutrients)
                        let estimatedFiber = estimateFiberFromMicronutrients(micronutrients)
                        let estimatedFat = estimateFatFromMicronutrients(micronutrients)
                        
                        print("🔍 [HomeView]   Estimated nutrition:")
                        print("🔍 [HomeView]     Calories: \(estimatedCalories)")
                        print("🔍 [HomeView]     Protein: \(estimatedProtein)")
                        print("🔍 [HomeView]     Carbs: \(estimatedCarbs)")
                        print("🔍 [HomeView]     Fiber: \(estimatedFiber)")
                        print("🔍 [HomeView]     Fat: \(estimatedFat)")
                        
                        totals.totalCalories += estimatedCalories
                        totals.totalProtein += estimatedProtein
                        totals.totalCarbs += estimatedCarbs
                        totals.totalFiber += estimatedFiber
                        totals.totalFat += estimatedFat
                        
                        print("🔍 [HomeView]   ✅ Added estimated values to totals")
                    } else {
                        print("🔍 [HomeView]   ✅ Using stored values")
                        totals.totalCalories += mealCalories
                        totals.totalProtein += mealProtein
                        totals.totalCarbs += mealCarbs
                        totals.totalFiber += mealFiber
                        totals.totalFat += mealFat
                    }
                    
                    // Calculate micronutrients for this meal
                    let micronutrients = micronutrientCalculator.calculateMicronutrients(for: meal, userProfile: profile)
                    totals.addMicronutrients(micronutrients)
                    
                    print("🔍 [HomeView]   Running totals after this meal:")
                    print("🔍 [HomeView]     Total Calories: \(totals.totalCalories)")
                    print("🔍 [HomeView]     Total Protein: \(totals.totalProtein)")
                    print("🔍 [HomeView]     Total Carbs: \(totals.totalCarbs)")
                    print("🔍 [HomeView]     Total Fiber: \(totals.totalFiber)")
                    print("🔍 [HomeView]     Total Fat: \(totals.totalFat)")
                }
            } else {
                print("🔍 [HomeView]   ❌ Entry has no meals")
            }
        }
        
        print("🔍 [HomeView] ===== FINAL WEEKLY TOTALS =====")
        print("🔍 [HomeView] Total Calories: \(totals.totalCalories)")
        print("🔍 [HomeView] Total Protein: \(totals.totalProtein)")
        print("🔍 [HomeView] Total Carbs: \(totals.totalCarbs)")
        print("🔍 [HomeView] Total Fiber: \(totals.totalFiber)")
        print("🔍 [HomeView] Total Fat: \(totals.totalFat)")
        print("🔍 [HomeView] =================================")
        
        return totals
    }
    
    // Helper functions to estimate nutrition from micronutrients
    private func estimateCaloriesFromMicronutrients(_ micronutrients: MicronutrientData) -> Double {
        print("🔍 [HomeView] Estimating calories from micronutrients:")
        print("🔍 [HomeView]   Input micronutrients - C: \(micronutrients.vitaminC), Iron: \(micronutrients.iron), B12: \(micronutrients.vitaminB12), D: \(micronutrients.vitaminD), Ca: \(micronutrients.calcium), Omega3: \(micronutrients.omega3)")
        
        // More comprehensive calorie estimation based on micronutrient content
        let baseCalories = 50.0 // Base calories for any food
        
        // Protein-rich foods (high iron, B12) tend to have more calories
        let proteinCalories = (micronutrients.iron + micronutrients.vitaminB12) * 2.0
        
        // Vitamin C rich foods (fruits) have moderate calories
        let fruitCalories = micronutrients.vitaminC * 0.5
        
        // Omega-3 rich foods (fish, nuts) have higher calories
        let fatCalories = micronutrients.omega3 * 5.0
        
        // Calcium rich foods (dairy) have moderate calories
        let dairyCalories = micronutrients.calcium * 0.1
        
        let totalCalories = baseCalories + proteinCalories + fruitCalories + fatCalories + dairyCalories
        
        print("🔍 [HomeView]   Calorie calculation breakdown:")
        print("🔍 [HomeView]     Base: \(baseCalories)")
        print("🔍 [HomeView]     Protein: \(proteinCalories)")
        print("🔍 [HomeView]     Fruit: \(fruitCalories)")
        print("🔍 [HomeView]     Fat: \(fatCalories)")
        print("🔍 [HomeView]     Dairy: \(dairyCalories)")
        print("🔍 [HomeView]     Total before cap: \(totalCalories)")
        
        // Cap at reasonable maximum (500 calories per meal)
        let finalCalories = min(totalCalories, 500.0)
        print("🔍 [HomeView]     Final calories: \(finalCalories)")
        
        return finalCalories
    }
    
    private func estimateProteinFromMicronutrients(_ micronutrients: MicronutrientData) -> Double {
        print("🔍 [HomeView] Estimating protein from micronutrients:")
        
        // Protein estimation based on iron and B12 content
        let baseProtein = 5.0 // Base protein for any food
        
        // Iron and B12 are indicators of protein-rich foods
        let proteinFromIron = micronutrients.iron * 0.5
        let proteinFromB12 = micronutrients.vitaminB12 * 0.01
        
        let totalProtein = baseProtein + proteinFromIron + proteinFromB12
        
        print("🔍 [HomeView]   Protein calculation breakdown:")
        print("🔍 [HomeView]     Base: \(baseProtein)")
        print("🔍 [HomeView]     From Iron: \(proteinFromIron)")
        print("🔍 [HomeView]     From B12: \(proteinFromB12)")
        print("🔍 [HomeView]     Total before cap: \(totalProtein)")
        
        // Cap at reasonable maximum (50g protein per meal)
        let finalProtein = min(totalProtein, 50.0)
        print("🔍 [HomeView]     Final protein: \(finalProtein)")
        
        return finalProtein
    }
    
    private func estimateCarbsFromMicronutrients(_ micronutrients: MicronutrientData) -> Double {
        // Carbohydrate estimation based on vitamin C (fruits) and other indicators
        let baseCarbs = 10.0 // Base carbs for any food
        
        // Vitamin C rich foods (fruits) have carbs
        let fruitCarbs = micronutrients.vitaminC * 0.3
        
        // Calcium rich foods (dairy) have some carbs
        let dairyCarbs = micronutrients.calcium * 0.01
        
        let totalCarbs = baseCarbs + fruitCarbs + dairyCarbs
        
        // Cap at reasonable maximum (100g carbs per meal)
        return min(totalCarbs, 100.0)
    }
    
    private func estimateFiberFromMicronutrients(_ micronutrients: MicronutrientData) -> Double {
        // Fiber estimation based on vitamin C (fruits/vegetables)
        let baseFiber = 2.0 // Base fiber for any food
        
        // Vitamin C rich foods (fruits/vegetables) have fiber
        let fruitFiber = micronutrients.vitaminC * 0.1
        
        let totalFiber = baseFiber + fruitFiber
        
        // Cap at reasonable maximum (20g fiber per meal)
        return min(totalFiber, 20.0)
    }
    
    private func estimateFatFromMicronutrients(_ micronutrients: MicronutrientData) -> Double {
        // Fat estimation based on omega-3 and other indicators
        let baseFat = 3.0 // Base fat for any food
        
        // Omega-3 rich foods have fat
        let omegaFat = micronutrients.omega3 * 2.0
        
        // Calcium rich foods (dairy) have some fat
        let dairyFat = micronutrients.calcium * 0.01
        
        let totalFat = baseFat + omegaFat + dairyFat
        
        // Cap at reasonable maximum (30g fat per meal)
        return min(totalFat, 30.0)
    }
    
    private func getRecommendedWeeklyIntake(profile: MicronutrientProfile) -> WeeklyNutritionTotals {
        // Use the same PersonalizedIBDTargets system as IBDPal Recommendations for consistency
        let targets = PersonalizedIBDTargets.calculate(for: profile)
        
        var recommended = WeeklyNutritionTotals()
        
        // Calculate weekly recommendations (7 days worth) using NIH DRI-based targets
        recommended.totalCalories = Double(targets.calorieTarget * 7)
        recommended.totalProtein = Double(targets.proteinTarget * 7)
        recommended.totalCarbs = Double(targets.carbTarget * 7)
        recommended.totalFiber = Double(targets.fiberTarget * 7)
        recommended.totalFat = Double(targets.fatTarget * 7)
        
        // Set micronutrient recommendations using NIH DRI-based targets
        recommended.vitaminD = Double(targets.vitaminDTarget * 7)
        recommended.vitaminB12 = Double(targets.vitaminB12Target * 7)
        recommended.iron = Double(targets.ironTarget * 7)
        recommended.calcium = Double(targets.calciumTarget * 7)
        recommended.zinc = Double(targets.zincTarget * 7)
        recommended.omega3 = Double(targets.omega3Target * 7)
        
        return recommended
    }
    
    private func calculateWeeklyTrends(actual: WeeklyNutritionTotals, recommended: WeeklyNutritionTotals, daysCount: Int) -> [NutritionTrend] {
        var trends: [NutritionTrend] = []
        
        // Show cumulative weekly totals instead of daily averages
        trends.append(NutritionTrend(
            nutrient: "Calories",
            actual: actual.totalCalories,
            recommended: recommended.totalCalories,
            unit: "kcal/week"
        ))
        
        trends.append(NutritionTrend(
            nutrient: "Protein",
            actual: actual.totalProtein,
            recommended: recommended.totalProtein,
            unit: "g/week"
        ))
        
        trends.append(NutritionTrend(
            nutrient: "Fiber",
            actual: actual.totalFiber,
            recommended: recommended.totalFiber,
            unit: "g/week"
        ))
        
        // Micronutrient trends - also show weekly totals
        trends.append(NutritionTrend(
            nutrient: "Vitamin D",
            actual: actual.vitaminD,
            recommended: recommended.vitaminD,
            unit: "IU/week"
        ))
        
        trends.append(NutritionTrend(
            nutrient: "Iron",
            actual: actual.iron,
            recommended: recommended.iron,
            unit: "mg/week"
        ))
        
        trends.append(NutritionTrend(
            nutrient: "Calcium",
            actual: actual.calcium,
            recommended: recommended.calcium,
            unit: "mg/week"
        ))
        
        return trends
    }
    
    // MARK: - Helper Functions
    private func getTodaysMealCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        print("🔍 [HomeView] Today's date: \(today)")
        print("🔍 [HomeView] Total journal entries: \(journalEntries.count)")
        
        let todaysEntries = journalEntries.filter { entry in
            let entryDate = Date.fromISOString(entry.entry_date)
            print("🔍 [HomeView] Entry date: \(entry.entry_date) -> \(entryDate)")
            
            // Use UTC calendar to avoid timezone issues
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            let todayComponents = utcCalendar.dateComponents([.year, .month, .day], from: today)
            let entryComponents = utcCalendar.dateComponents([.year, .month, .day], from: entryDate)
            
            print("🔍 [HomeView] Today components (UTC): year=\(todayComponents.year), month=\(todayComponents.month), day=\(todayComponents.day)")
            print("🔍 [HomeView] Entry components (UTC): year=\(entryComponents.year), month=\(entryComponents.month), day=\(entryComponents.day)")
            
            let isToday = todayComponents.year == entryComponents.year &&
                        todayComponents.month == entryComponents.month &&
                        todayComponents.day == entryComponents.day
            
            print("🔍 [HomeView] Is today: \(isToday)")
            return isToday
        }
        
        let mealCount = todaysEntries.flatMap { (entry: JournalEntry) in entry.meals ?? [] }.count
        
        print("🔍 [HomeView] Today's meal count: \(mealCount) from \(todaysEntries.count) entries")
        
        return mealCount
    }
    
    private func getTodaysSymptomCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        print("🔍 [HomeView] Today's date for symptoms: \(today)")
        print("🔍 [HomeView] Total journal entries for symptoms: \(journalEntries.count)")
        
        let todaysEntries = journalEntries.filter { entry in
            let entryDate = Date.fromISOString(entry.entry_date)
            print("🔍 [HomeView] Symptom entry date: \(entry.entry_date) -> \(entryDate)")
            
            // Use UTC calendar to avoid timezone issues
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            let todayComponents = utcCalendar.dateComponents([.year, .month, .day], from: today)
            let entryComponents = utcCalendar.dateComponents([.year, .month, .day], from: entryDate)
            
            print("🔍 [HomeView] Symptom today components (UTC): year=\(todayComponents.year), month=\(todayComponents.month), day=\(todayComponents.day)")
            print("🔍 [HomeView] Symptom entry components (UTC): year=\(entryComponents.year), month=\(entryComponents.month), day=\(entryComponents.day)")
            
            let isToday = todayComponents.year == entryComponents.year &&
                        todayComponents.month == entryComponents.month &&
                        todayComponents.day == entryComponents.day
            
            print("🔍 [HomeView] Symptom is today: \(isToday)")
            return isToday
        }
        
        let symptomCount = todaysEntries.flatMap { $0.symptoms ?? [] }.count
        
        print("🔍 [HomeView] Today's symptom count: \(symptomCount) from \(todaysEntries.count) entries")
        
        return symptomCount
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
        
        print("🔍 [HomeView] Generating fallback nutrition analysis")
        
        // Get last 7 days of journal entries
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let recentEntries = journalEntries.filter { entry in
            let entryDate = Date.fromISOString(entry.entry_date)
            return entryDate >= startDate && entryDate <= endDate
        }
        
        print("🔍 [HomeView] Fallback: Analyzing \(recentEntries.count) entries from last 7 days")
        
        // Create a default profile for estimation
        let defaultProfile = MicronutrientProfile(
            userId: userData?.id ?? "unknown",
            age: 30,
            weight: 70.0,
            height: 170.0,
            gender: "Unknown",
            diseaseActivity: .remission,
            labResults: [],
            supplements: []
        )
        
        // Calculate weekly totals using the same logic as calculateRealNutritionAnalysis
        let weeklyTotals = calculateWeeklyTotals(from: recentEntries, profile: defaultProfile)
        
        print("🔍 [HomeView] Fallback weekly totals:")
        print("🔍 [HomeView]   Total Calories: \(weeklyTotals.totalCalories)")
        print("🔍 [HomeView]   Total Protein: \(weeklyTotals.totalProtein)")
        print("🔍 [HomeView]   Total Carbs: \(weeklyTotals.totalCarbs)")
        print("🔍 [HomeView]   Total Fiber: \(weeklyTotals.totalFiber)")
        print("🔍 [HomeView]   Total Fat: \(weeklyTotals.totalFat)")
        
        // Calculate averages
        let daysCount = max(1, recentEntries.count)
        let averageCalories = weeklyTotals.totalCalories / Double(daysCount)
        let averageProtein = weeklyTotals.totalProtein / Double(daysCount)
        let averageCarbs = weeklyTotals.totalCarbs / Double(daysCount)
        let averageFiber = weeklyTotals.totalFiber / Double(daysCount)
        let averageFat = weeklyTotals.totalFat / Double(daysCount)
        
        // Set both old and new properties for compatibility
        analysis.calories = Int(averageCalories)
        analysis.protein = Int(averageProtein)
        analysis.carbs = Int(averageCarbs)
        analysis.fiber = Int(averageFiber)
        analysis.fat = Int(averageFat)
        
        analysis.avgCalories = averageCalories
        analysis.avgProtein = averageProtein
        analysis.avgCarbs = averageCarbs
        analysis.avgFiber = averageFiber
        analysis.avgFat = averageFat
        
        analysis.daysWithMeals = Set(recentEntries.map { Calendar.current.startOfDay(for: Date.fromISOString($0.entry_date)) }).count
        
        print("🔍 [HomeView] Fallback final values:")
        print("🔍 [HomeView]   Calories: \(analysis.calories)")
        print("🔍 [HomeView]   Protein: \(analysis.protein)")
        print("🔍 [HomeView]   Carbs: \(analysis.carbs)")
        print("🔍 [HomeView]   Fiber: \(analysis.fiber)")
        print("🔍 [HomeView]   Fat: \(analysis.fat)")
        
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
        
        print("🔍 [HomeView] Calculating nutrition score - starting with 100")
        print("🔍 [HomeView] Analysis values - Protein: \(analysis.avgProtein), Fiber: \(analysis.avgFiber), Calories: \(analysis.avgCalories)")
        print("🔍 [HomeView] Deficiencies count: \(analysis.deficiencies.count)")
        
        // Deduct points for deficiencies
        for deficiency in analysis.deficiencies {
            print("🔍 [HomeView] Deficiency: \(deficiency.nutrient), Severity: \(deficiency.severity)")
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
            print("🔍 [HomeView] Adding bonus for good nutrition")
            score += 10
        }
        
        let finalScore = max(0, min(100, score))
        print("🔍 [HomeView] Final nutrition score: \(finalScore)")
        
        return finalScore
    }
    
    private func generateFoodPatterns() -> [NutritionFoodPattern] {
        print("🔍 [HomeView] Generating food patterns from \(journalEntries.count) journal entries")
        
        var foodFrequency: [String: (count: Int, totalCalories: Double, totalProtein: Double, totalFiber: Double, mealTypes: Set<String>)] = [:]
        
        // Analyze journal entries from the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        print("🔍 [HomeView] Date range for food patterns: \(startDate) to \(endDate)")
        
        for entry in journalEntries {
            let entryDate = Date.fromISOString(entry.entry_date)
            print("🔍 [HomeView] Checking entry date: \(entry.entry_date) -> \(entryDate)")
            
            // Only include entries from the last 7 days
            if entryDate >= startDate && entryDate <= endDate {
                print("🔍 [HomeView] Entry is within date range")
                if let meals = entry.meals {
                    print("🔍 [HomeView] Entry has \(meals.count) meals")
                    for meal in meals {
                        let foodName = meal.description
                        print("🔍 [HomeView] Processing meal: \(foodName)")
                        
                        if foodFrequency[foodName] == nil {
                            foodFrequency[foodName] = (count: 0, totalCalories: 0, totalProtein: 0, totalFiber: 0, mealTypes: Set<String>())
                        }
                        
                        foodFrequency[foodName]?.count += 1
                        foodFrequency[foodName]?.totalCalories += Double(meal.calories ?? 0)
                        foodFrequency[foodName]?.totalProtein += Double(meal.protein ?? 0)
                        foodFrequency[foodName]?.totalFiber += Double(meal.fiber ?? 0)
                        foodFrequency[foodName]?.mealTypes.insert(meal.meal_type ?? "Unknown")
                    }
                } else {
                    print("🔍 [HomeView] Entry has no meals")
                }
            } else {
                print("🔍 [HomeView] Entry is outside date range")
            }
        }
        
        print("🔍 [HomeView] Found \(foodFrequency.count) unique foods")
        
        // Convert to NutritionFoodPattern objects
        var foodPatterns: [NutritionFoodPattern] = []
        
        for (foodName, data) in foodFrequency {
            let avgCalories = data.totalCalories / Double(data.count)
            let avgProtein = data.totalProtein / Double(data.count)
            let avgFiber = data.totalFiber / Double(data.count)
            
            // Calculate nutrition score based on protein and fiber content
            let nutritionScore = min(100, max(0, Int((avgProtein * 2) + (avgFiber * 5))))
            
            // Determine most common meal type
            let mostCommonMealType = data.mealTypes.first ?? "Unknown"
            
            let pattern = NutritionFoodPattern(
                name: foodName,
                frequency: data.count,
                nutritionScore: nutritionScore,
                calories: Int(avgCalories),
                protein: avgProtein,
                fiber: avgFiber,
                mealType: mostCommonMealType
            )
            
            foodPatterns.append(pattern)
            
            print("🔍 [HomeView] Food: \(foodName), Frequency: \(data.count), Score: \(nutritionScore)")
        }
        
        // Sort by frequency and return top foods
        let sortedPatterns = foodPatterns.sorted { $0.frequency > $1.frequency }
        print("🔍 [HomeView] Returning \(sortedPatterns.count) food patterns")
        
        return sortedPatterns
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
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
    let userProfile: MicronutrientProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.ibdAccent)
                Text("IBDPal Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                Spacer()
            }
            
            // Weekly Goals
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Goals")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                VStack(spacing: 8) {
                    // Use personalized targets if available, otherwise fall back to default
                    let targets = userProfile != nil ? 
                        PersonalizedIBDTargets.calculate(for: userProfile!) : 
                        PersonalizedIBDTargets(
                            calorieTarget: IBDTargets().calorieTarget,
                            proteinTarget: IBDTargets().proteinTarget,
                            fiberTarget: IBDTargets().fiberTarget,
                            hydrationTarget: IBDTargets().hydrationTarget,
                            fatTarget: IBDTargets().fatTarget,
                            carbTarget: IBDTargets().carbTarget,
                            vitaminDTarget: IBDTargets().vitaminDTarget,
                            vitaminB12Target: IBDTargets().vitaminB12Target,
                            ironTarget: IBDTargets().ironTarget,
                            folateTarget: IBDTargets().folateTarget,
                            calciumTarget: IBDTargets().calciumTarget,
                            zincTarget: IBDTargets().zincTarget,
                            omega3Target: IBDTargets().omega3Target
                        )
                    
                    // Show weekly targets to match WeeklyNutritionTrendsCard
                    WeeklyGoalRow(
                        title: "Protein Intake",
                        target: "\(targets.proteinTarget * 7)g/week",
                        current: "\(Int(analysis.avgProtein * 7))g/week",
                        progress: min((analysis.avgProtein * 7) / Double(targets.proteinTarget * 7), 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Fiber Intake",
                        target: "\(targets.fiberTarget * 7)g/week",
                        current: "\(Int(analysis.avgFiber * 7))g/week",
                        progress: min((analysis.avgFiber * 7) / Double(targets.fiberTarget * 7), 1.0)
                    )
                    
                    WeeklyGoalRow(
                        title: "Calorie Balance",
                        target: "\(targets.calorieTarget * 7) kcal/week",
                        current: "\(Int(analysis.avgCalories * 7)) kcal/week",
                        progress: min((analysis.avgCalories * 7) / Double(targets.calorieTarget * 7), 1.0)
                    )
                }
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
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fiber: Int = 0
    var fat: Int = 0
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
    var micronutrients: IBDSpecificNutrients = IBDSpecificNutrients(
        vitaminD: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        vitaminB12: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        iron: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        calcium: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        zinc: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        omega3: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        glutamine: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
        probiotics: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: [])
    )
    var weeklyTrends: [NutritionTrend] = []
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

// MARK: - Weekly Nutrition Trends Card
struct WeeklyNutritionTrendsCard: View {
    let analysis: NutritionAnalysis
    let userProfile: MicronutrientProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Nutrition Trends")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Last 7 days vs. Recommended")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if analysis.weeklyTrends.isEmpty {
                VStack(spacing: 8) {
                    Text("No trend data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Log more meals to see your nutrition trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(analysis.weeklyTrends, id: \.nutrient) { trend in
                        NutritionTrendRow(trend: trend)
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

struct NutritionTrendRow: View {
    let trend: NutritionTrend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trend.nutrient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: trend.status.icon)
                    .foregroundColor(trend.status.color)
                    .font(.caption)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actual")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", trend.actual)) \(trend.unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("\(String(format: "%.0f", trend.percentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(trend.status.color)
                    Text("of goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Recommended")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", trend.recommended)) \(trend.unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(trend.status.color)
                        .frame(width: min(geometry.size.width, geometry.size.width * (trend.percentage / 100)), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
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

// MARK: - Date Extension
extension Date {
    static func fromISOString(_ isoString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        // Fallback: try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = fallbackFormatter.date(from: isoString) {
            return date
        }
        
        // Last fallback: try with custom formatter
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        customFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = customFormatter.date(from: isoString) {
            return date
        }
        
        // If all else fails, return a date far in the past to ensure it's filtered out
        return Date.distantPast
    }
}

// MARK: - Nutrition Score Info View
struct NutritionScoreInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("Nutrition Score")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Your personalized nutrition score (0-100) based on your food intake and IBD-specific needs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // How it works section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Your Score is Calculated")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(
                                icon: "100.circle.fill",
                                iconColor: .green,
                                title: "Starting Score",
                                description: "Every day starts with a perfect score of 100 points"
                            )
                            
                            InfoRow(
                                icon: "minus.circle.fill",
                                iconColor: .red,
                                title: "Points Deducted",
                                description: "Points are subtracted when you're missing important nutrients"
                            )
                            
                            InfoRow(
                                icon: "plus.circle.fill",
                                iconColor: .blue,
                                title: "Bonus Points",
                                description: "Extra points are added when you meet all nutrition goals"
                            )
                        }
                    }
                    
                    // Scoring details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scoring Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ScoringDetail(
                                nutrient: "Protein",
                                good: "60g+ daily",
                                points: "No deduction",
                                poor: "Less than 50g",
                                deduction: "-20 points"
                            )
                            
                            ScoringDetail(
                                nutrient: "Fiber",
                                good: "25g+ daily",
                                points: "No deduction",
                                poor: "Less than 20g",
                                deduction: "-20 points"
                            )
                            
                            ScoringDetail(
                                nutrient: "Calories",
                                good: "1800+ daily",
                                points: "No deduction",
                                poor: "Less than 1500",
                                deduction: "-20 points"
                            )
                            
                            ScoringDetail(
                                nutrient: "Bonus",
                                good: "All goals met",
                                points: "+10 points",
                                poor: "Missing goals",
                                deduction: "No bonus"
                            )
                        }
                    }
                    
                    // Score interpretation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What Your Score Means")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ScoreInterpretation(
                                range: "80-100",
                                color: .green,
                                description: "Excellent nutrition! You're meeting most of your IBD-specific needs."
                            )
                            
                            ScoreInterpretation(
                                range: "60-79",
                                color: .blue,
                                description: "Good nutrition with room for improvement in some areas."
                            )
                            
                            ScoreInterpretation(
                                range: "40-59",
                                color: .orange,
                                description: "Fair nutrition. Focus on increasing protein, fiber, or calories."
                            )
                            
                            ScoreInterpretation(
                                range: "0-39",
                                color: .red,
                                description: "Poor nutrition. Consider consulting with a dietitian for personalized guidance."
                            )
                        }
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tips to Improve Your Score")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipItem(text: "Include lean proteins like chicken, fish, or beans in each meal")
                            TipItem(text: "Add fiber-rich foods like oats, quinoa, and vegetables")
                            TipItem(text: "Eat regular meals to meet your calorie needs")
                            TipItem(text: "Consider IBD-friendly foods that are easier to digest")
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Nutrition Score")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Supporting Views for Nutrition Score Info

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ScoringDetail: View {
    let nutrient: String
    let good: String
    let points: String
    let poor: String
    let deduction: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nutrient)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ \(good)")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(points)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("❌ \(poor)")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(deduction)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct ScoreInterpretation: View {
    let range: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(range)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct TipItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Flare Risk Info View
struct FlareRiskInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text("Flare Risk Assessment")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Your personalized flare risk assessment based on IBD symptoms and warning signs from the last 7 days.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // How it works section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Your Risk is Calculated")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FlareRiskInfoRow(
                                icon: "drop.fill",
                                iconColor: .red,
                                title: "Blood Present",
                                description: "Blood in stool is a major warning sign (+40 points per day)",
                                points: "40 points"
                            )
                            
                            FlareRiskInfoRow(
                                icon: "exclamationmark.triangle.fill",
                                iconColor: .orange,
                                title: "High Pain Severity",
                                description: "Severe pain (4-5/10) indicates potential inflammation (+30 points)",
                                points: "30 points"
                            )
                            
                            FlareRiskInfoRow(
                                icon: "arrow.up.circle.fill",
                                iconColor: .orange,
                                title: "High Urgency",
                                description: "Frequent urgent bowel movements (+25 points)",
                                points: "25 points"
                            )
                            
                            FlareRiskInfoRow(
                                icon: "brain.head.profile",
                                iconColor: .blue,
                                title: "Stress & Fatigue",
                                description: "High stress and fatigue levels (+20 points each)",
                                points: "20 points"
                            )
                            
                            FlareRiskInfoRow(
                                icon: "moon.zzz.fill",
                                iconColor: .purple,
                                title: "Poor Sleep",
                                description: "Poor sleep quality affects IBD symptoms (+15 points)",
                                points: "15 points"
                            )
                        }
                    }
                    
                    // Risk levels
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Risk Levels")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FlareRiskLevelView(
                                level: "High Risk",
                                color: .red,
                                range: "70-100 points",
                                description: "Multiple warning signs present. Consider contacting your healthcare provider.",
                                action: "Contact your doctor"
                            )
                            
                            FlareRiskLevelView(
                                level: "Medium Risk",
                                color: .orange,
                                range: "40-69 points",
                                description: "Some concerning symptoms. Monitor closely and follow your care plan.",
                                action: "Monitor symptoms"
                            )
                            
                            FlareRiskLevelView(
                                level: "Low Risk",
                                color: .green,
                                range: "0-39 points",
                                description: "Few warning signs. Continue with your current management plan.",
                                action: "Maintain routine"
                            )
                        }
                    }
                    
                    // Important factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Warning Signs")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            WarningSignItem(text: "Blood in stool - Contact your doctor immediately")
                            WarningSignItem(text: "Severe abdominal pain (4-5/10) - Monitor closely")
                            WarningSignItem(text: "Frequent urgent bowel movements - Track patterns")
                            WarningSignItem(text: "High stress levels - Practice stress management")
                            WarningSignItem(text: "Poor sleep quality - Focus on sleep hygiene")
                            WarningSignItem(text: "Persistent fatigue - Rest and gentle activity")
                        }
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Managing Your Risk")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FlareRiskTipItem(text: "Track symptoms daily in your journal")
                            FlareRiskTipItem(text: "Follow your prescribed medication schedule")
                            FlareRiskTipItem(text: "Maintain a balanced, IBD-friendly diet")
                            FlareRiskTipItem(text: "Practice stress management techniques")
                            FlareRiskTipItem(text: "Get adequate sleep and rest")
                            FlareRiskTipItem(text: "Stay hydrated and avoid trigger foods")
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Flare Risk")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Supporting Views for Flare Risk Info

struct FlareRiskInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let points: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(points)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(iconColor)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FlareRiskLevelView: View {
    let level: String
    let color: Color
    let range: String
    let description: String
    let action: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(level)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(range)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Action: \(action)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
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

struct WarningSignItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct FlareRiskTipItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
