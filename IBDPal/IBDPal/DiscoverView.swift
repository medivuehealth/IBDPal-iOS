import SwiftUI
import Charts

struct DiscoverView: View {
    let userData: UserData?
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedNutritionTab: NutritionTab = .calories
    @State private var trendsData: TrendsData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Trends")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Timeframe Selector
                    HStack(spacing: 12) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            TimeFrameButton(
                                timeframe: timeframe,
                                isSelected: selectedTimeframe == timeframe
                            ) {
                                selectedTimeframe = timeframe
                                loadTrendsData()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading your trends...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = errorMessage {
                        ErrorView(message: error) {
                            loadTrendsData()
                        }
                    } else if let data = trendsData {
                        // Summary Cards
                        SummaryCardsView(summary: data.summary)
                        
                        // Nutrition Charts with Tabs
                        NutritionTabsView(
                            data: data.nutrition,
                            selectedTab: $selectedNutritionTab,
                            timeframe: selectedTimeframe
                        )
                        
                                    // Health Metrics Section
            HealthMetricsView(data: data.healthMetrics, selectedTimeframe: selectedTimeframe)
                        
                        // Insights
                        InsightsView(insights: data.insights)
                    } else {
                        EmptyStateView()
                    }
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadTrendsData()
            }
        }
    }
    
    private func loadTrendsData() {
        guard let userData = userData else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("📊 [DiscoverView] Loading trends for user: \(userData.email)")
        
        // Calculate date range based on timeframe
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .threeMonths:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Fetch journal entries from the database
        fetchJournalEntries(userData: userData, startDate: startDateString, endDate: endDateString) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let entries):
                    // Process real data from database
                    self.trendsData = self.processRealData(entries: entries, timeframe: self.selectedTimeframe)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ [DiscoverView] Error loading trends: \(error)")
                }
            }
        }
    }
    
    private func fetchJournalEntries(userData: UserData, startDate: String, endDate: String, completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userData.email)?startDate=\(startDate)&endDate=\(endDate)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        let task = NetworkManager.shared.dataTask(with: request) { data, response, error in
            print("🔧 [DiscoverView] Network response received")
            
            if let error = error {
                print("❌ [DiscoverView] Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔧 [DiscoverView] HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ [DiscoverView] No data received")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            print("🔧 [DiscoverView] Received \(data.count) bytes of data")
            
            do {
                let entries = try JSONDecoder().decode([JournalEntry].self, from: data)
                print("✅ [DiscoverView] Successfully decoded \(entries.count) journal entries")
                completion(.success(entries))
            } catch {
                print("❌ [DiscoverView] JSON decode error: \(error)")
                print("🔧 [DiscoverView] Raw data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func processRealData(entries: [JournalEntry], timeframe: TimeFrame) -> TrendsData {
        // Process real journal entries to create trends data
        let nutritionData = processNutritionData(entries: entries)
        let symptomData = processSymptomData(entries: entries)
        let healthMetricsData = processHealthMetricsData(entries: entries)
        
        return TrendsData(
            nutrition: nutritionData,
            symptoms: symptomData,
            healthMetrics: healthMetricsData,
            insights: generateInsights(from: nutritionData, symptomData: symptomData),
            summary: calculateSummary(from: nutritionData, symptomData: symptomData)
        )
    }
    
    private func processNutritionData(entries: [JournalEntry]) -> [NutritionTrendPoint] {
        return entries.compactMap { entry in
            guard let meals = entry.meals else { return nil }
            
            // Calculate total nutrition from all meals
            let totalCalories = meals.reduce(0) { $0 + ($1.calories ?? 0) }
            let totalProtein = meals.reduce(0) { $0 + ($1.protein ?? 0) }
            let totalFiber = meals.reduce(0) { $0 + ($1.fiber ?? 0) }
            let totalHydration = entry.hydration ?? 0
            
            return NutritionTrendPoint(
                date: entry.entry_date,
                calories: totalCalories,
                protein: totalProtein,
                fiber: totalFiber,
                hydration: totalHydration
            )
        }
    }
    
    private func processSymptomData(entries: [JournalEntry]) -> [SymptomTrendPoint] {
        return entries.compactMap { entry in
            guard let symptoms = entry.symptoms else { return nil }
            
            // Calculate average symptom levels
            let pain = symptoms.first { $0.type == "pain" }?.severity ?? 0
            let stress = symptoms.first { $0.type == "stress" }?.severity ?? 0
            let fatigue = symptoms.first { $0.type == "fatigue" }?.severity ?? 0
            
            // Calculate flare risk based on symptoms
            let flareRisk = calculateFlareRisk(symptoms: symptoms)
            
            return SymptomTrendPoint(
                date: entry.entry_date,
                pain: pain,
                stress: stress,
                fatigue: fatigue,
                flareRisk: flareRisk
            )
        }
    }
    
    private func processHealthMetricsData(entries: [JournalEntry]) -> [HealthMetricPoint] {
        return entries.compactMap { entry in
            // Calculate medication adherence (simplified - would need medication data)
            let medicationAdherence = 85.0 // Placeholder - would calculate from medication data
            
            // Get bowel health data - use actual bowel_frequency from database
            let bowelFrequency = entry.bowel_frequency ?? 0
            let bowelConsistency = entry.bowel_movements?.first?.consistency ?? 4
            
            // Weight data (would need to be added to journal entries)
            let weight = 70.0 // Placeholder
            let weightChange = 0.0 // Placeholder
            
            // Bowel health warning indicators
            let bloodPresent = entry.blood_present ?? false
            let mucusPresent = entry.mucus_present ?? false
            let painSeverity = entry.pain_severity ?? 0
            let urgencyLevel = entry.urgency_level ?? 0
            
            return HealthMetricPoint(
                date: entry.entry_date,
                medicationAdherence: medicationAdherence,
                bowelFrequency: bowelFrequency,
                bowelConsistency: bowelConsistency,
                weight: weight,
                weightChange: weightChange,
                // Bowel health warning indicators
                bloodPresent: bloodPresent,
                mucusPresent: mucusPresent,
                painSeverity: painSeverity,
                painLocation: entry.pain_location, // Add pain location
                urgencyLevel: urgencyLevel
            )
        }
    }
    
    private func calculateFlareRisk(symptoms: [Symptom]) -> Int {
        // Calculate flare risk based on symptom severity
        let painLevel = symptoms.first { $0.type == "pain" }?.severity ?? 0
        let stressLevel = symptoms.first { $0.type == "stress" }?.severity ?? 0
        let fatigueLevel = symptoms.first { $0.type == "fatigue" }?.severity ?? 0
        
        // Simple algorithm: higher symptoms = higher flare risk
        let riskScore = (painLevel * 3) + (stressLevel * 2) + (fatigueLevel * 1)
        return min(70, max(10, riskScore * 2))
    }
    
    private func generateInsights() -> [Insight] {
        return []
    }
    
    private func generateInsights(from nutritionData: [NutritionTrendPoint], symptomData: [SymptomTrendPoint]) -> [Insight] {
        var insights: [Insight] = []
        
        guard !nutritionData.isEmpty && !symptomData.isEmpty else {
            return insights
        }
        
        // Calculate averages
        let avgCalories = nutritionData.map { $0.calories }.reduce(0, +) / nutritionData.count
        let avgProtein = nutritionData.map { $0.protein }.reduce(0, +) / nutritionData.count
        let avgFiber = nutritionData.map { $0.fiber }.reduce(0, +) / nutritionData.count
        let avgPain = Double(symptomData.map { $0.pain }.reduce(0, +)) / Double(symptomData.count)
        let avgStress = Double(symptomData.map { $0.stress }.reduce(0, +)) / Double(symptomData.count)
        
        // Nutrition insights
        let ibdTargets = IBDTargets()
        
        if avgCalories < Int(Double(ibdTargets.calorieTarget) * 0.9) {
            insights.append(Insight(
                type: .nutrition,
                title: "Calorie Intake",
                message: "Your average calorie intake is \(avgCalories) kcal/day, which is below the recommended \(ibdTargets.calorieTarget) kcal for IBD management.",
                severity: .moderate,
                action: "Increase portion sizes or add healthy snacks"
            ))
        } else if avgCalories > Int(Double(ibdTargets.calorieTarget) * 1.1) {
            insights.append(Insight(
                type: .nutrition,
                title: "Calorie Intake",
                message: "Your average calorie intake is \(avgCalories) kcal/day, which is above typical IBD recommendations.",
                severity: .low,
                action: "Monitor portion sizes and weight"
            ))
        }
        
        if avgProtein < Int(Double(ibdTargets.proteinTarget) * 0.9) {
            insights.append(Insight(
                type: .nutrition,
                title: "Protein Intake",
                message: "Your average protein intake is \(avgProtein)g/day, which is below the recommended \(ibdTargets.proteinTarget)g for IBD management.",
                severity: .moderate,
                action: "Add lean protein sources to meals"
            ))
        }
        
        if avgFiber < Int(Double(ibdTargets.fiberTarget) * 0.6) {
            insights.append(Insight(
                type: .nutrition,
                title: "Fiber Intake",
                message: "Your average fiber intake is \(avgFiber)g/day, which is below the recommended \(ibdTargets.fiberTarget)g for IBD management.",
                severity: .high,
                action: "Gradually increase soluble fiber intake"
            ))
        } else if avgFiber > Int(Double(ibdTargets.fiberTarget) * 1.4) {
            insights.append(Insight(
                type: .nutrition,
                title: "Fiber Intake",
                message: "Your average fiber intake is \(avgFiber)g/day, which is above typical IBD recommendations.",
                severity: .moderate,
                action: "Monitor fiber tolerance and reduce if needed"
            ))
        }
        
        // Symptom insights
        if avgPain > 5 {
            insights.append(Insight(
                type: .symptom,
                title: "Pain Levels",
                message: "Your average pain level is \(String(format: "%.1f", avgPain))/10, which is elevated.",
                severity: .high,
                action: "Consult healthcare provider about pain management"
            ))
        } else if avgPain < 3 {
            insights.append(Insight(
                type: .symptom,
                title: "Pain Levels",
                message: "Your average pain level is \(String(format: "%.1f", avgPain))/10, which is well managed. Keep up the good work!",
                severity: .low,
                action: "Continue current management strategies"
            ))
        }
        
        if avgStress > 7 {
            insights.append(Insight(
                type: .symptom,
                title: "Stress Levels",
                message: "Your average stress level is \(String(format: "%.1f", avgStress))/10, which is high and may impact IBD symptoms.",
                severity: .moderate,
                action: "Practice stress management techniques"
            ))
        }
        
        // Medication adherence insight (simulated based on symptom patterns)
        let goodDays = symptomData.filter { $0.pain < 4 && $0.stress < 6 }.count
        let adherenceRate = Int((Double(goodDays) / Double(symptomData.count)) * 100)
        
        if adherenceRate < 80 {
            insights.append(Insight(
                type: .medication,
                title: "Medication Adherence",
                message: "Based on your symptom patterns, medication adherence appears to be around \(adherenceRate)%.",
                severity: .high,
                action: "Set daily medication reminders and improve adherence"
            ))
        }
        
        return insights
    }
    
    private func generateSummary() -> Summary {
        return Summary(
            totalEntries: 0,
            avgCalories: 0,
            avgPain: 0.0,
            bloodEpisodes: 0,
            medicationAdherence: 0
        )
    }
    
    private func calculateSummary(from nutritionData: [NutritionTrendPoint], symptomData: [SymptomTrendPoint]) -> Summary {
        let totalEntries = nutritionData.count
        
        // Calculate average calories from nutrition data
        let avgCalories = nutritionData.isEmpty ? 0 : nutritionData.map { $0.calories }.reduce(0, +) / totalEntries
        
        // Calculate average pain from symptom data
        let avgPain = symptomData.isEmpty ? 0.0 : Double(symptomData.map { $0.pain }.reduce(0, +)) / Double(totalEntries)
        
        // For now, simulate blood episodes and medication adherence based on symptom data
        // In a real implementation, these would come from the actual journal entries
        let bloodEpisodes = symptomData.filter { $0.pain > 5 || $0.flareRisk > 40 }.count
        let medicationAdherence = symptomData.isEmpty ? 0 : Int((Double(symptomData.filter { $0.pain < 4 && $0.stress < 6 }.count) / Double(totalEntries)) * 100)
        
        return Summary(
            totalEntries: totalEntries,
            avgCalories: avgCalories,
            avgPain: avgPain,
            bloodEpisodes: bloodEpisodes,
            medicationAdherence: medicationAdherence
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func mostFrequent() -> Element? {
        let counts = self.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Supporting Views

struct TimeFrameButton: View {
    let timeframe: TimeFrame
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                .foregroundColor(isSelected ? .white : .ibdPrimaryText)
                .cornerRadius(20)
        }
    }
}

struct SummaryCardsView: View {
    let summary: Summary
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SummaryCard(
                title: "Avg Calories",
                value: "\(summary.avgCalories)",
                unit: "kcal",
                color: .orange
            )
            
            SummaryCard(
                title: "Avg Pain",
                value: String(format: "%.1f", summary.avgPain),
                unit: "/10",
                color: .red
            )
            
            SummaryCard(
                title: "Blood Episodes",
                value: "\(summary.bloodEpisodes)",
                unit: "times",
                color: .red
            )
            
            SummaryCard(
                title: "Medication",
                value: "\(summary.medicationAdherence)",
                unit: "%",
                color: summary.medicationAdherence >= 80 ? .green : .orange
            )
        }
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

struct NutritionTabsView: View {
    let data: [NutritionTrendPoint]
    @Binding var selectedTab: NutritionTab
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            // Nutrition Tab Selector - Full Width Design
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(NutritionTab.allCases, id: \.self) { tab in
                    NutritionTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            
            // Chart based on selected tab
            switch selectedTab {
            case .calories:
                NutritionChartView(
                    data: data,
                    type: .calories,
                    title: "Daily Calories",
                    color: .orange,
                    target: IBDTargets().calorieTarget,
                    unit: "kcal",
                    timeframe: timeframe
                )
            case .protein:
                NutritionChartView(
                    data: data,
                    type: .protein,
                    title: "Daily Protein",
                    color: .blue,
                    target: IBDTargets().proteinTarget,
                    unit: "g",
                    timeframe: timeframe
                )
            case .fiber:
                NutritionChartView(
                    data: data,
                    type: .fiber,
                    title: "Daily Fiber",
                    color: .green,
                    target: IBDTargets().fiberTarget,
                    unit: "g",
                    timeframe: timeframe
                )
            case .hydration:
                NutritionChartView(
                    data: data,
                    type: .hydration,
                    title: "Daily Hydration",
                    color: .cyan,
                    target: IBDTargets().hydrationTarget,
                    unit: "ml",
                    timeframe: timeframe
                )
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NutritionTabButton: View {
    let tab: NutritionTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(tab.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .ibdPrimaryText)
                
                // Small indicator line
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.ibdPrimary : Color.ibdCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.ibdPrimary : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct NutritionChartView: View {
    let data: [NutritionTrendPoint]
    let type: NutritionType
    let title: String
    let color: Color
    let target: Int
    let unit: String
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            Chart {
                ForEach(data) { point in
                    // Actual intake - using dots instead of lines
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", getValue(for: point))
                    )
                    .foregroundStyle(color)
                    .symbolSize(16)
                }
                
                // Target line
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Target", target)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                // Remove x-axis labels for cleaner look
                AxisMarks(values: .automatic(desiredCount: timeframe == .week ? 7 : timeframe == .month ? 5 : 3)) { _ in
                    // No labels
                }
            }
            
            // Legend and performance
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text("Your \(type.displayName)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Spacer()
                    
                    HStack {
                        Rectangle()
                            .fill(.red)
                            .frame(width: 12, height: 2)
                        Text("Target: \(target) \(unit)")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                // Performance indicator
                let avgValue = data.map { getValue(for: $0) }.reduce(0, +) / max(data.count, 1)
                let targetThreshold = Int(Double(target) * 0.9)
                let performance = avgValue >= targetThreshold ? "Good" : "Below Target"
                let performanceColor = avgValue >= targetThreshold ? Color.green : Color.orange
                
                HStack {
                    Text("Performance:")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Text(performance)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(performanceColor)
                    
                    Spacer()
                    
                    Text("Avg: \(Int(avgValue)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
        }
    }
    
    private func getValue(for point: NutritionTrendPoint) -> Int {
        switch type {
        case .calories:
            return point.calories
        case .protein:
            return point.protein
        case .fiber:
            return point.fiber
        case .hydration:
            return point.hydration
        }
    }
    
    private func formatDateLabel(_ dateString: String, timeframe: TimeFrame) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        switch timeframe {
        case .week:
            // Show day names for week view
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            return dayFormatter.string(from: date)
        case .month:
            // Show dates for month view
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "dd"
            return monthFormatter.string(from: date)
        case .threeMonths:
            // Show month names for 3-month view
            let threeMonthFormatter = DateFormatter()
            threeMonthFormatter.dateFormat = "MMM"
            return threeMonthFormatter.string(from: date)
        }
    }
}

struct SimpleSymptomChart: View {
    let data: [SymptomTrendPoint]
    let timeframe: TimeFrame
    
    // IBD Symptom Management Targets
    private let symptomTargets = SymptomTargets()
    
    // Calculate smoothed trend data
    private var smoothedPainData: [SymptomTrendPoint] {
        calculateSmoothedTrend(for: data.map { $0.pain }, originalData: data)
    }
    
    private var smoothedStressData: [SymptomTrendPoint] {
        calculateSmoothedTrend(for: data.map { $0.stress }, originalData: data)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Management")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            Chart {
                // Raw data points (smaller, less prominent)
                ForEach(data) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Pain Raw", point.pain)
                    )
                    .foregroundStyle(.red.opacity(0.3))
                    .symbolSize(20)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Stress Raw", point.stress)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    .symbolSize(20)
                }
                
                // Smoothed trend lines (prominent)
                ForEach(smoothedPainData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Pain Trend", point.pain)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 4))
                }
                
                ForEach(smoothedStressData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Stress Trend", point.stress)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 4))
                }
                
                // Target lines
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Pain Target", symptomTargets.painTarget)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Stress Target", symptomTargets.stressTarget)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: timeframe == .week ? 7 : timeframe == .month ? 5 : 3)) { value in
                    AxisValueLabel {
                        if let dateString = value.as(String.self) {
                            Text(formatDateLabel(dateString, timeframe: timeframe))
                                .font(.caption2)
                                .foregroundColor(.ibdSecondaryText)
                        }
                    }
                }
            }
            
            // Enhanced legend with targets
            VStack(spacing: 8) {
                HStack {
                    HStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text("Pain")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    HStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Stress")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    Spacer()
                }
                
                // Target indicators
                HStack {
                    HStack {
                        Rectangle()
                            .fill(.orange)
                            .frame(width: 8, height: 2)
                        Text("Target: ≤\(symptomTargets.painTarget)/10")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(.purple)
                            .frame(width: 8, height: 2)
                        Text("Target: ≤\(symptomTargets.stressTarget)/10")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    Spacer()
                }
                
                // Performance summary
                let avgPain = data.map { $0.pain }.reduce(0, +) / max(data.count, 1)
                let avgStress = data.map { $0.stress }.reduce(0, +) / max(data.count, 1)
                let painStatus = avgPain <= symptomTargets.painTarget ? "Good" : "Needs Attention"
                let stressStatus = avgStress <= symptomTargets.stressTarget ? "Good" : "High"
                
                HStack {
                    Text("Pain: \(painStatus)")
                        .font(.caption)
                        .foregroundColor(avgPain <= symptomTargets.painTarget ? .green : .orange)
                    
                    Spacer()
                    
                    Text("Stress: \(stressStatus)")
                        .font(.caption)
                        .foregroundColor(avgStress <= symptomTargets.stressTarget ? .green : .orange)
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Smoothing Functions
extension SimpleSymptomChart {
    // Calculate moving average for smooth trend lines
    private func calculateSmoothedTrend(for values: [Int], originalData: [SymptomTrendPoint]) -> [SymptomTrendPoint] {
        guard values.count > 3 else { return originalData }
        
        let windowSize = min(7, values.count / 3) // Adaptive window size
        var smoothedData: [SymptomTrendPoint] = []
        
        for i in 0..<originalData.count {
            let startIndex = max(0, i - windowSize / 2)
            let endIndex = min(values.count, i + windowSize / 2 + 1)
            let window = Array(values[startIndex..<endIndex])
            
            let average = Double(window.reduce(0, +)) / Double(window.count)
            let smoothedValue = Int(round(average))
            
            smoothedData.append(SymptomTrendPoint(
                date: originalData[i].date,
                pain: smoothedValue,
                stress: smoothedValue,
                fatigue: originalData[i].fatigue,
                flareRisk: originalData[i].flareRisk
            ))
        }
        
        return smoothedData
    }
    
    private func formatDateLabel(_ dateString: String, timeframe: TimeFrame) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        switch timeframe {
        case .week:
            // Show day names for week view
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            return dayFormatter.string(from: date)
        case .month:
            // Show dates for month view
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "dd"
            return monthFormatter.string(from: date)
        case .threeMonths:
            // Show month names for 3-month view
            let threeMonthFormatter = DateFormatter()
            threeMonthFormatter.dateFormat = "MMM"
            return threeMonthFormatter.string(from: date)
        }
    }
}

struct HealthMetricsView: View {
    let data: [HealthMetricPoint]
    let selectedTimeframe: TimeFrame
    
    // Industry-defined targets (fixed, don't change)
    private let targets = HealthMetricTargets()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            // Medication Adherence Bar Chart - Smart chart that shows warning when needed
            if averageMedicationAdherence < medicationAdherenceWarningThreshold {
                // Show as warning chart
                WarningBarChartView(
                    title: "Medication Adherence",
                    value: averageMedicationAdherence,
                    threshold: medicationAdherenceWarningThreshold,
                    unit: "%",
                    icon: "exclamationmark.triangle.fill"
                )
            } else {
                // Show as normal chart
                HorizontalBarChartView(
                    title: "Medication Adherence",
                    target: targets.medicationAdherenceTarget,
                    actual: averageMedicationAdherence,
                    unit: "%",
                    targetColor: .blue,
                    actualColor: .green,
                    icon: "pills.fill"
                )
            }
            
            // Bowel Frequency Bar Chart - Smart chart that shows warning when needed
            if averageBowelFrequency > bowelFrequencyWarningThreshold {
                // Show as warning chart
                WarningBarChartView(
                    title: "Bowel Frequency",
                    value: averageBowelFrequency,
                    threshold: bowelFrequencyWarningThreshold,
                    unit: "/day",
                    icon: "exclamationmark.triangle.fill"
                )
            } else {
                // Show as normal chart
                HorizontalBarChartView(
                    title: "Bowel Frequency",
                    target: targets.bowelFrequencyTarget,
                    actual: averageBowelFrequency,
                    unit: "/day",
                    targetColor: .blue,
                    actualColor: .green,
                    icon: "chart.bar.fill"
                )
            }
            
            // Weight Trend Bar Chart
            HorizontalBarChartView(
                title: "Weight Trend",
                target: targets.weightChangeTarget,
                actual: weightChangeValue,
                unit: "kg",
                targetColor: .blue,
                actualColor: weightChangeColor,
                icon: "scalemass.fill"
            )
            
            // Warning Indicators Section
            if hasWarningIndicators {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Warning Indicators")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    // High Pain Warning
                    if averagePain > painWarningThreshold {
                        WarningBarChartView(
                            title: "High Pain Level (\(mostCommonPainLocation))",
                            value: averagePain,
                            threshold: painWarningThreshold,
                            unit: "/10",
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                    
                    // Blood Present Warning
                    if hasBloodPresent {
                        WarningBarChartView(
                            title: "Blood Present",
                            value: 1.0,
                            threshold: 0.0,
                            unit: " episodes",
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                    
                    // Mucus Present Warning
                    if hasMucusPresent {
                        WarningBarChartView(
                            title: "Mucus Present",
                            value: 1.0,
                            threshold: 0.0,
                            unit: " episodes",
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                    
                    // High Urgency Level Warning
                    if averageUrgencyLevel > urgencyWarningThreshold {
                        WarningBarChartView(
                            title: "High Urgency Level",
                            value: averageUrgencyLevel,
                            threshold: urgencyWarningThreshold,
                            unit: "/10",
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                }
            } else {
                // Debug info when no warnings
                Text("Debug: \(selectedTimeframe) - No warnings - Bowel Freq: \(String(format: "%.1f", averageBowelFrequency))/day (Target: \(String(format: "%.1f", targets.bowelFrequencyTarget))) | Pain: \(String(format: "%.1f", averagePain))/10 (Target: \(String(format: "%.1f", targets.painTarget)))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Computed properties for metrics
    private var filteredData: [HealthMetricPoint] {
        let days = selectedTimeframe == .week ? 7 : selectedTimeframe == .month ? 30 : 90
        return Array(data.suffix(days))
    }
    
    // Industry-defined warning thresholds (fixed, based on medical guidelines)
    private var medicationAdherenceWarningThreshold: Double {
        return targets.medicationAdherenceWarning // 80%
    }
    
    private var bowelFrequencyWarningThreshold: Double {
        return targets.bowelFrequencyWarning // 4.0/day
    }
    
    private var painWarningThreshold: Double {
        return targets.painWarning // 5.0/10
    }
    
    private var urgencyWarningThreshold: Double {
        return targets.urgencyWarning // 6.0/10
    }
    
    private var averageMedicationAdherence: Double {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map { $0.medicationAdherence }.reduce(0, +) / Double(filteredData.count)
    }
    
    private var averageBowelFrequency: Double {
        guard !filteredData.isEmpty else { return 0 }
        let average = Double(filteredData.map { $0.bowelFrequency }.reduce(0, +)) / Double(filteredData.count)
        print("🔧 [DiscoverView] Bowel frequency calculation:")
        print("   - Timeframe: \(selectedTimeframe)")
        print("   - Filtered data count: \(filteredData.count)")
        print("   - Individual frequencies: \(filteredData.map { $0.bowelFrequency })")
        print("   - Average: \(average)")
        print("   - Industry Target: \(targets.bowelFrequencyTarget)")
        print("   - Industry Warning Threshold: \(bowelFrequencyWarningThreshold)")
        print("   - Should show warning: \(average > bowelFrequencyWarningThreshold)")
        return average
    }
    
    private var weightChangeValue: Double {
        guard filteredData.count >= 2 else { return 0 }
        let firstWeight = filteredData.first?.weight ?? 0
        let lastWeight = filteredData.last?.weight ?? 0
        return lastWeight - firstWeight
    }
    
    private var weightChangeColor: Color {
        let change = weightChangeValue
        return abs(change) < 0.5 ? .green : change > 0 ? .orange : .red
    }
    
    private var averagePain: Double {
        guard !filteredData.isEmpty else { return 0 }
        // Calculate average pain severity from health metrics data
        let totalPain = filteredData.map { $0.painSeverity }.reduce(0, +)
        let average = Double(totalPain) / Double(filteredData.count)
        
        print("🔧 [DiscoverView] Pain calculation:")
        print("   - Timeframe: \(selectedTimeframe)")
        print("   - Filtered data count: \(filteredData.count)")
        print("   - Individual pain levels: \(filteredData.map { $0.painSeverity })")
        print("   - Average pain: \(average)")
        print("   - Industry Target: \(targets.painTarget)")
        print("   - Industry Warning Threshold: \(painWarningThreshold)")
        print("   - Should show pain warning: \(average > painWarningThreshold)")
        
        return average
    }
    
    private var hasBloodPresent: Bool {
        // Check if any entry has blood present
        return filteredData.contains { $0.bloodPresent }
    }
    
    private var hasMucusPresent: Bool {
        // Check if any entry has mucus present
        return filteredData.contains { $0.mucusPresent }
    }
    
    private var mostCommonPainLocation: String {
        let locations = filteredData.compactMap { $0.painLocation }.filter { !$0.isEmpty }
        
        if let mostCommon = locations.mostFrequent() {
            return mostCommon
        }
        return "abdomen" // Default
    }
    
    private var averageUrgencyLevel: Double {
        guard !filteredData.isEmpty else { return 0 }
        // Calculate average urgency level
        let totalUrgency = filteredData.map { $0.urgencyLevel }.reduce(0, +)
        return Double(totalUrgency) / Double(filteredData.count)
    }
    
    private var hasWarningIndicators: Bool {
        return averagePain > painWarningThreshold || 
               hasBloodPresent ||
               hasMucusPresent ||
               averageUrgencyLevel > urgencyWarningThreshold
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trendColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
    
    private var trendColor: Color {
        switch trend.lowercased() {
        case "improving", "stable": return .green
        case "declining", "decreasing", "losing": return .red
        case "increasing", "gaining": return .orange
        default: return .gray
        }
    }
}

struct HorizontalBarChartView: View {
    let title: String
    let target: Double
    let actual: Double
    let unit: String
    let targetColor: Color
    let actualColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(actualColor)
                    .font(.title2)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text("\(Int(actual))\(unit)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(actualColor)
            }
            
            // Bar chart container
            VStack(spacing: 4) {
                // Target bar (blue)
                HStack {
                    Text("Target: \(Int(target))\(unit)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(targetColor)
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // Actual bar (green)
                HStack {
                    Text("Actual: \(Int(actual))\(unit)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(actualColor)
                    .frame(height: 8)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

struct WarningBarChartView: View {
    let title: String
    let value: Double
    let threshold: Double
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            // Bar chart container
            VStack(spacing: 4) {
                // Threshold bar (red)
                HStack {
                    Text("Threshold: \(Int(threshold)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(.red.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // Actual value bar (red)
                HStack {
                    Text("Current: \(Int(value)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(.red)
                    .frame(height: 8)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.ibdCardBackground)
        .cornerRadius(8)
    }
}

struct SmallTrendChart: View {
    let title: String
    let data: [(String, Double)]
    let color: Color
    let target: Double?
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.ibdPrimaryText)
            
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Date", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                if let target = target {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        LineMark(
                            x: .value("Date", point.0),
                            y: .value("Target", target)
                        )
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
            }
            .frame(height: 60)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: timeframe == .week ? 7 : timeframe == .month ? 5 : 3)) { value in
                    AxisValueLabel {
                        if let dateString = value.as(String.self) {
                            Text(formatDateLabel(dateString, timeframe: timeframe))
                                .font(.caption2)
                                .foregroundColor(.ibdSecondaryText)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDateLabel(_ dateString: String, timeframe: TimeFrame) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        switch timeframe {
        case .week:
            // Show day names for week view
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            return dayFormatter.string(from: date)
        case .month:
            // Show dates for month view
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "dd"
            return monthFormatter.string(from: date)
        case .threeMonths:
            // Show month names for 3-month view
            let threeMonthFormatter = DateFormatter()
            threeMonthFormatter.dateFormat = "MMM"
            return threeMonthFormatter.string(from: date)
        }
    }
}

struct InsightsView: View {
    let insights: [Insight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            ForEach(insights, id: \.title) { insight in
                InsightCard(insight: insight)
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                SeverityBadge(severity: insight.severity)
            }
            
            Text(insight.message)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .lineLimit(3)
            
            Text("Action: \(insight.action)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(insight.severity.color)
        }
        .padding()
        .background(Color.ibdBackground)
        .cornerRadius(8)
    }
}

struct SeverityBadge: View {
    let severity: InsightSeverity
    
    var body: some View {
        Text(severity.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .cornerRadius(12)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Unable to load trends")
                .font(.headline)
                .foregroundColor(.ibdPrimaryText)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.ibdSecondaryText)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.ibdPrimaryText)
            
            Text("Start logging your daily entries to see personalized trends and insights.")
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

// MARK: - Data Models

enum TimeFrame: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        }
    }
}

enum NutritionTab: String, CaseIterable {
    case calories = "calories"
    case protein = "protein"
    case fiber = "fiber"
    case hydration = "hydration"
    
    var displayName: String {
        switch self {
        case .calories: return "Cal"
        case .protein: return "Protein"
        case .fiber: return "Fiber"
        case .hydration: return "H2O"
        }
    }
}

enum NutritionType {
    case calories
    case protein
    case fiber
    case hydration
    
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .fiber: return "Fiber"
        case .hydration: return "Hydration"
        }
    }
}

struct TrendsData {
    let nutrition: [NutritionTrendPoint]
    let symptoms: [SymptomTrendPoint]
    let healthMetrics: [HealthMetricPoint]
    let insights: [Insight]
    let summary: Summary
}

struct NutritionTrendPoint: Identifiable {
    let id = UUID()
    let date: String
    let calories: Int
    let protein: Int
    let fiber: Int
    let hydration: Int
}

struct SymptomTrendPoint: Identifiable {
    let id = UUID()
    let date: String
    let pain: Int
    let stress: Int
    let fatigue: Int
    let flareRisk: Int
}

struct HealthMetricPoint: Identifiable {
    let id = UUID()
    let date: String
    let medicationAdherence: Double // Percentage (0-100)
    let bowelFrequency: Int // Number of movements per day
    let bowelConsistency: Int // Bristol scale (1-7)
    let weight: Double // Weight in kg
    let weightChange: Double // Change from baseline
    // Bowel health warning indicators
    let bloodPresent: Bool // Blood in stool
    let mucusPresent: Bool // Mucus in stool
    let painSeverity: Int // Pain level (0-10)
    let painLocation: String? // Location of pain
    let urgencyLevel: Int // Urgency level (0-10)
}

struct Insight {
    let type: InsightType
    let title: String
    let message: String
    let severity: InsightSeverity
    let action: String
}

enum InsightType {
    case nutrition
    case symptom
    case medication
}

enum InsightSeverity: String {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

struct Summary {
    let totalEntries: Int
    let avgCalories: Int
    let avgPain: Double
    let bloodEpisodes: Int
    let medicationAdherence: Int
}

// MARK: - Industry Standard Targets

struct IBDTargets {
    // Research-driven baseline values based on AGA Guidelines 2024 and Crohn's & Colitis Congress 2024
    // These are default values - should be personalized based on user profile
    
    // Macronutrients (Daily Baseline)
    let calorieTarget: Int = 2100 // 30 kcal/kg × 70kg (default weight)
    let proteinTarget: Int = 105 // 1.5 g/kg × 70kg (minimum for IBD patients)
    let fiberTarget: Int = 17 // Mid-range of 10-25 g/day (symptom-adjustable)
    let hydrationTarget: Int = 2500 // Mid-range of 2000-3000 ml/day (activity-dependent)
    let fatTarget: Int = 70 // 30% of calories from fat (2100 × 0.3 / 9 kcal/g)
    let carbTarget: Int = 262 // Remaining calories from carbs (2100 - 420 protein - 630 fat) / 4 kcal/g
    
    // Micronutrients (Daily Baseline - vs RDA)
    let vitaminDTarget: Int = 2500 // IU (3-5x higher than RDA)
    let vitaminB12Target: Int = 1000 // mcg (400x higher than RDA)
    let ironTarget: Int = 37 // mg (2-3x higher than RDA)
    let folateTarget: Int = 600 // mcg (1.5x higher than RDA)
    let calciumTarget: Int = 1350 // mg (age-adjusted, mid-range)
    let zincTarget: Int = 15 // mg (1.4x higher than RDA)
    let omega3Target: Int = 2000 // mg (1.8x higher than RDA)
    
    // FODMAP-specific targets (more conservative for symptom management)
    let fodmapFiberTarget: Int = 10 // g/day (lower end of range for FODMAP diet)
    let fodmapCarbTarget: Int = 200 // g/day (lower carb tolerance)
    
    // Multipliers for personalization
    let diseaseActivityMultiplier: Double = 1.0 // 1.0x - 1.5x (Remission → Severe)
    let diseaseTypeMultiplier: Double = 1.0 // 1.05x - 1.2x (IBS → Crohn's)
    let ageMultiplier: Double = 1.0 // 0.8x - 1.2x (Pediatric → Geriatric)
}

// Personalized nutrition targets based on user profile
struct PersonalizedIBDTargets {
    let calorieTarget: Int
    let proteinTarget: Int
    let fiberTarget: Int
    let hydrationTarget: Int
    let fatTarget: Int
    let carbTarget: Int
    
    // Micronutrients
    let vitaminDTarget: Int
    let vitaminB12Target: Int
    let ironTarget: Int
    let folateTarget: Int
    let calciumTarget: Int
    let zincTarget: Int
    let omega3Target: Int
    
    // Calculate personalized targets based on user profile
    static func calculate(for userProfile: MicronutrientProfile) -> PersonalizedIBDTargets {
        let weight = userProfile.weight
        let age = userProfile.age
        let diseaseActivity = userProfile.diseaseActivity
        
        // Calculate multipliers based on user profile
        let diseaseActivityMultiplier = diseaseActivityMultiplier(for: diseaseActivity)
        let ageMultiplier = ageMultiplier(for: age)
        let diseaseTypeMultiplier = 1.1 // Default for IBD (between IBS and Crohn's)
        
        let totalMultiplier = diseaseActivityMultiplier * ageMultiplier * diseaseTypeMultiplier
        
        // Macronutrients (weight-based calculations)
        let calorieTarget = Int(Double(weight * 30) * totalMultiplier) // 30 kcal/kg
        let proteinTarget = Int(Double(weight * 2) * totalMultiplier) // 2.0 g/kg (upper range for IBD)
        let fiberTarget = Int(17.0 * totalMultiplier) // Mid-range, symptom-adjustable
        let hydrationTarget = Int(2500.0 * totalMultiplier) // Activity-dependent
        
        // Calculate fat and carb targets based on calorie target
        let fatTarget = Int(Double(calorieTarget) * 0.3 / 9.0) // 30% of calories from fat
        let carbTarget = Int((Double(calorieTarget) - Double(proteinTarget * 4) - Double(fatTarget * 9)) / 4.0)
        
        // Micronutrients (research-based, with multipliers)
        let vitaminDTarget = Int(2500.0 * totalMultiplier)
        let vitaminB12Target = Int(1000.0 * totalMultiplier)
        let ironTarget = Int(37.0 * totalMultiplier)
        let folateTarget = Int(600.0 * totalMultiplier)
        let calciumTarget = Int(1350.0 * totalMultiplier)
        let zincTarget = Int(15.0 * totalMultiplier)
        let omega3Target = Int(2000.0 * totalMultiplier)
        
        return PersonalizedIBDTargets(
            calorieTarget: calorieTarget,
            proteinTarget: proteinTarget,
            fiberTarget: fiberTarget,
            hydrationTarget: hydrationTarget,
            fatTarget: fatTarget,
            carbTarget: carbTarget,
            vitaminDTarget: vitaminDTarget,
            vitaminB12Target: vitaminB12Target,
            ironTarget: ironTarget,
            folateTarget: folateTarget,
            calciumTarget: calciumTarget,
            zincTarget: zincTarget,
            omega3Target: omega3Target
        )
    }
    
    // Disease activity multiplier (1.0x - 1.5x)
    private static func diseaseActivityMultiplier(for activity: DiseaseActivity) -> Double {
        switch activity {
        case .remission:
            return 1.0
        case .mild:
            return 1.1
        case .moderate:
            return 1.3
        case .severe:
            return 1.5
        }
    }
    
    // Age multiplier (0.8x - 1.2x)
    private static func ageMultiplier(for age: Int) -> Double {
        switch age {
        case 0..<18:
            return 1.2 // Pediatric - higher needs
        case 18..<65:
            return 1.0 // Adult - standard needs
        case 65...:
            return 0.8 // Geriatric - lower needs
        default:
            return 1.0
        }
    }
}

struct HealthMetricTargets {
    // Based on IBD clinical guidelines and research
    let medicationAdherenceTarget: Double = 90.0 // % (target for optimal disease control)
    let bowelFrequencyTarget: Double = 2.0 // times/day (normal range for IBD remission)
    let painTarget: Double = 3.0 // /10 (target for well-managed IBD)
    let urgencyTarget: Double = 3.0 // /10 (target for urgency control)
    let weightChangeTarget: Double = 0.0 // kg (target for stable weight)
    
    // Warning thresholds (when to show warnings)
    let medicationAdherenceWarning: Double = 80.0 // % (below this triggers warning)
    let bowelFrequencyWarning: Double = 4.0 // times/day (above this triggers warning)
    let painWarning: Double = 5.0 // /10 (above this triggers warning)
    let urgencyWarning: Double = 6.0 // /10 (above this triggers warning)
    let weightChangeWarning: Double = 2.0 // kg (above this triggers warning)
}

struct SymptomTargets {
    // Based on IBD symptom management guidelines
    let painTarget: Int = 3 // /10 (target for well-managed IBD)
    let stressTarget: Int = 5 // /10 (target for stress management)
    let fatigueTarget: Int = 4 // /10 (target for energy levels)
    let bowelFrequencyTarget: Int = 2 // times/day (normal range)
    let urgencyTarget: Int = 3 // /10 (target for urgency control)
}

#Preview {
    DiscoverView(userData: UserData(
        id: "test",
        email: "test@example.com",
        name: "Test User",
        phoneNumber: nil,
        token: "test-token"
    ))
} 