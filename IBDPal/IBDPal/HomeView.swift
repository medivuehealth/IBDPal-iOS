import SwiftUI
import Charts

struct HomeView: View {
    let userData: UserData?
    
    @State private var isLoading = true
    @State private var last7DaysStats = Last7DaysStats()
    @State private var reminders: [Reminder] = []
    @State private var diagnosisCompleted = false
    @State private var loadingDiagnosis = true
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
                    
                    // Diagnosis Status Card
                    if loadingDiagnosis {
                        ProgressView("Checking diagnosis status...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else if !diagnosisCompleted {
                        DiagnosisCard()
                    }
                    
                    // Last 7 Days Stats
                    if isLoading {
                        ProgressView("Loading your stats...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        Last7DaysStatsCard(stats: last7DaysStats)
                    }
                    
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
                loadData()
            }
        }
    }
    
    private func loadData() {
        loadLast7DaysStats()
        checkDiagnosisStatus()
        loadNutritionAnalysis()
        loadFlareRiskData()
    }
    
    private func checkDiagnosisStatus() {
        guard let userData = userData else { return }
        
        loadingDiagnosis = true
        
        guard let url = URL(string: "\(apiBaseURL)/diagnosis/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                loadingDiagnosis = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        diagnosisCompleted = true
                    } else if httpResponse.statusCode == 404 {
                        diagnosisCompleted = false
                    }
                }
            }
        }.resume()
    }
    
    private func loadLast7DaysStats() {
        guard let userData = userData else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)/journal/entries/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data else { return }
                
                do {
                    if let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        let stats = calculateStats(from: entries)
                        last7DaysStats = stats
                        reminders = generateReminders(from: entries)
                    }
                } catch {
                    print("Error parsing entries: \(error)")
                }
            }
        }.resume()
    }
    
    private func loadNutritionAnalysis() {
        guard let userData = userData else { return }
        
        loadingNutrition = true
        
        guard let url = URL(string: "\(apiBaseURL)/journal/nutrition/analysis/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                loadingNutrition = false
                
                guard let data = data else { return }
                
                do {
                    if let analysis = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        nutritionAnalysis = NutritionAnalysis.from(dictionary: analysis)
                    }
                } catch {
                    print("Error parsing nutrition analysis: \(error)")
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
    
    private func calculateStats(from entries: [[String: Any]]) -> Last7DaysStats {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let last7DaysEntries = entries.filter { entry in
            guard let entryDateString = entry["entry_date"] as? String else { return false }
            guard let entryDate = dateFormatter.date(from: entryDateString.components(separatedBy: "T").first ?? "") else { return false }
            return entryDate >= sevenDaysAgo && entryDate <= today
        }
        
        let totalEntries = last7DaysEntries.count
        let mealsLogged = last7DaysEntries.filter { entry in
            let calories = entry["calories"] as? Double ?? 0
            let protein = entry["protein"] as? Double ?? 0
            let carbs = entry["carbs"] as? Double ?? 0
            return calories > 0 || protein > 0 || carbs > 0
        }.count
        
        let hasSymptoms = last7DaysEntries.contains { entry in
            let painSeverity = entry["pain_severity"] as? Int ?? 0
            let bowelFrequency = entry["bowel_frequency"] as? Int ?? 0
            let bloodPresent = entry["blood_present"] as? Bool ?? false
            return painSeverity > 0 || bowelFrequency > 0 || bloodPresent
        }
        
        let averageEntries = totalEntries > 0 ? Double(totalEntries) / 7.0 : 0
        
        return Last7DaysStats(
            logEntries: totalEntries,
            mealsLogged: mealsLogged,
            symptoms: hasSymptoms ? "Reported" : "None",
            averageEntries: averageEntries,
            mostActiveDay: "This week"
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
}

// MARK: - Data Models

struct Last7DaysStats {
    var logEntries: Int = 0
    var mealsLogged: Int = 0
    var symptoms: String = "None"
    var averageEntries: Double = 0
    var mostActiveDay: String = "None"
}

struct NutritionAnalysis {
    var deficiencies: [NutritionDeficiency] = []
    var recommendations: [String] = []
    var overallScore: Int = 0
    var lastUpdated: Date = Date()
    
    static func from(dictionary: [String: Any]) -> NutritionAnalysis {
        var analysis = NutritionAnalysis()
        
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
              let currentLevel = dictionary["current_level"] as? Double,
              let recommendedLevel = dictionary["recommended_level"] as? Double,
              let severityString = dictionary["severity"] as? String,
              let impact = dictionary["impact"] as? String,
              let foodSources = dictionary["food_sources"] as? [String] else {
            return nil
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

struct DiagnosisCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.ibdSecondary)
                Text("Complete Your Diagnosis")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
            }
            
            Text("Start your IBD care journey by completing a comprehensive diagnosis assessment.")
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
            
            Button("Start Diagnosis") {
                // Navigate to diagnosis
            }
            .buttonStyle(.borderedProminent)
            .tint(.ibdPrimary)
        }
        .padding()
        .background(Color.ibdSecondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct Last7DaysStatsCard: View {
    let stats: Last7DaysStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(title: "Log Entries", value: "\(stats.logEntries)", icon: "list.bullet", color: .ibdInfo)
                StatItem(title: "Meals Logged", value: "\(stats.mealsLogged)", icon: "fork.knife", color: .ibdNutritionColor)
                StatItem(title: "Symptoms", value: stats.symptoms, icon: "heart.fill", color: .ibdPainColor)
                StatItem(title: "Avg/Day", value: String(format: "%.1f", stats.averageEntries), icon: "chart.bar", color: .ibdAccent)
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

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

#Preview {
    HomeView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", token: "token"))
} 