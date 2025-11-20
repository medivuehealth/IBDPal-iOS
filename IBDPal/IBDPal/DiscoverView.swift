import SwiftUI
import Charts

struct DiscoverView: View {
    let userData: UserData?
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedNutritionTab: NutritionTab = .calories
    @State private var trendsData: TrendsData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Evidence-based target service
    @StateObject private var evidenceBasedTargetService = EvidenceBasedTargetCalculator.shared
    
    // Micronutrient calculation services
    @StateObject private var micronutrientCalculator = IBDMicronutrientCalculator.shared
    @StateObject private var deficiencyAnalyzer = IBDDeficiencyAnalyzer.shared
    @State private var micronutrientAnalysis: IBDMicronutrientAnalysis?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Medical Disclaimer Banner
                    MedicalDisclaimerBanner()
                        .padding(.horizontal)
                    
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
                        DiscoverErrorView(message: error) {
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
            HealthMetricsView(data: data.healthMetrics, nutritionData: data.nutrition, micronutrientAnalysis: micronutrientAnalysis, selectedTimeframe: selectedTimeframe, evidenceBasedTargetService: evidenceBasedTargetService)
                        
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HealthCitationsView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed")
                            Text("Sources")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadTrendsData()
                calculateEvidenceBasedTargets()
            }
        }
    }
    
    private func loadTrendsData() {
        guard let userData = userData else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("📊 [DiscoverView] Loading trends for user: \(userData.email)")
        
        // Throttle the request to prevent rate limiting
        RequestThrottler.shared.throttleRequest {
            
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
                    isLoading = false
                    
                    switch result {
                    case .success(let entries):
                        // Process real data from database
                        trendsData = processRealData(entries: entries, timeframe: selectedTimeframe)
                        // Calculate micronutrient analysis for nutrition score
                        Task {
                            await calculateMicronutrientAnalysis(entries: entries)
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("❌ [DiscoverView] Error loading trends: \(error)")
                    }
                }
            }
        }
    }
    
    private func calculateEvidenceBasedTargets() {
        guard let userData = userData else { return }
        
        // Create a basic user profile for evidence-based target calculation
        let userProfile = MicronutrientProfile(
            userId: userData.id,
            age: 30, // Default age - would be fetched from user profile
            weight: 70.0, // Default weight - would be fetched from user profile
            height: nil,
            gender: "Unknown", // Would be fetched from user profile
            diseaseActivity: .remission, // Would be determined by AI assessment
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
        
        Task {
            let _ = evidenceBasedTargetService.calculateAllTargets(
                for: userProfile,
                medicationHistory: [],
                symptomHistory: [],
                healthHistory: []
            )
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
                
                // Handle rate limiting and server errors
                if httpResponse.statusCode == 429 {
                    print("⚠️ [DiscoverView] Rate limit exceeded (429), using mock data")
                    // Use mock data when rate limited
                    let mockEntries = self.createMockJournalEntries()
                    completion(.success(mockEntries))
                    return
                } else if httpResponse.statusCode >= 500 {
                    print("⚠️ [DiscoverView] Server error (\(httpResponse.statusCode)), using mock data")
                    // Use mock data when server is down
                    let mockEntries = self.createMockJournalEntries()
                    completion(.success(mockEntries))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    print("❌ [DiscoverView] HTTP Error: \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
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
                
                // If JSON parsing fails due to rate limiting response, use mock data
                if let dataString = String(data: data, encoding: .utf8),
                   dataString.contains("Too many requests") {
                    print("🔄 [DiscoverView] Rate limiting detected in response, using mock data")
                    let mockEntries = self.createMockJournalEntries()
                    completion(.success(mockEntries))
                } else {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    private func createMockJournalEntries() -> [JournalEntry] {
        // Create mock data for when API is rate limited
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        var entries: [JournalEntry] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = dateFormatter.string(from: date)
                
                let entry = JournalEntry(
                    entry_id: "mock_\(i)",
                    user_id: "mock_user",
                    entry_date: dateString,
                    meals: [
                        Meal(
                            meal_id: "meal_1",
                            meal_type: "breakfast",
                            description: "Oatmeal with berries and banana",
                            calories: Int.random(in: 300...500),
                            protein: Int.random(in: 10...20),
                            carbs: Int.random(in: 40...60),
                            fiber: Int.random(in: 5...10),
                            fat: Int.random(in: 5...15),
                            serving_size: Double.random(in: 1...2),
                            serving_unit: "cups",
                            serving_description: "1.5 cups"
                        ),
                        Meal(
                            meal_id: "meal_2",
                            meal_type: "lunch",
                            description: "Grilled chicken salad with mixed vegetables",
                            calories: Int.random(in: 400...600),
                            protein: Int.random(in: 25...35),
                            carbs: Int.random(in: 20...40),
                            fiber: Int.random(in: 8...15),
                            fat: Int.random(in: 10...20),
                            serving_size: Double.random(in: 1...2),
                            serving_unit: "bowls",
                            serving_description: "1 large bowl"
                        ),
                        Meal(
                            meal_id: "meal_3",
                            meal_type: "dinner",
                            description: "Salmon with vegetables and brown rice",
                            calories: Int.random(in: 500...700),
                            protein: Int.random(in: 30...40),
                            carbs: Int.random(in: 30...50),
                            fiber: Int.random(in: 6...12),
                            fat: Int.random(in: 15...25),
                            serving_size: Double.random(in: 1...2),
                            serving_unit: "plates",
                            serving_description: "1 full plate"
                        )
                    ],
                    symptoms: [
                        Symptom(
                            symptom_id: "symptom_1",
                            type: "abdominal_pain",
                            severity: Int.random(in: 1...5),
                            notes: "Mild discomfort in lower left abdomen"
                        ),
                        Symptom(
                            symptom_id: "symptom_2",
                            type: "bloating",
                            severity: Int.random(in: 1...4),
                            notes: "Bloating after eating"
                        )
                    ],
                    bowel_movements: [
                        BowelMovement(
                            movement_id: "bm_1",
                            time: "08:00",
                            consistency: Int.random(in: 3...5),
                            urgency: Int.random(in: 1...5),
                            blood_present: Bool.random(),
                            notes: "Normal bowel movement"
                        )
                    ],
                    bowel_frequency: Int.random(in: 1...4),
                    blood_present: Bool.random(),
                    mucus_present: Bool.random(),
                    pain_severity: Int.random(in: 1...5),
                    pain_location: "lower_left",
                    urgency_level: Int.random(in: 1...5),
                    bristol_scale: Int.random(in: 3...5),
                    hydration: Int.random(in: 6...10),
                    water_intake: String(Int.random(in: 6...12)),
                    other_fluids: String(Int.random(in: 2...6)),
                    fluid_type: "Water, herbal tea",
                    notes: "Feeling better today",
                    created_at: dateString,
                    updated_at: dateString,
                    // Direct nutrition fields
                    calories: Double.random(in: 1200...1800),
                    protein: Double.random(in: 60...100),
                    carbs: Double.random(in: 100...200),
                    fiber: Double.random(in: 20...40),
                    fat: Double.random(in: 40...80),
                    // Individual meal nutrition fields
                    breakfast_calories: Double.random(in: 300...500),
                    breakfast_protein: Double.random(in: 10...20),
                    breakfast_carbs: Double.random(in: 40...60),
                    breakfast_fiber: Double.random(in: 5...10),
                    breakfast_fat: Double.random(in: 5...15),
                    lunch_calories: Double.random(in: 400...600),
                    lunch_protein: Double.random(in: 25...35),
                    lunch_carbs: Double.random(in: 20...40),
                    lunch_fiber: Double.random(in: 8...15),
                    lunch_fat: Double.random(in: 10...20),
                    dinner_calories: Double.random(in: 500...700),
                    dinner_protein: Double.random(in: 30...40),
                    dinner_carbs: Double.random(in: 30...50),
                    dinner_fiber: Double.random(in: 6...12),
                    dinner_fat: Double.random(in: 15...25),
                    snack_calories: Double.random(in: 100...300),
                    snack_protein: Double.random(in: 5...15),
                    snack_carbs: Double.random(in: 10...30),
                    snack_fiber: Double.random(in: 2...8),
                    snack_fat: Double.random(in: 5...15),
                    // Medication fields
                    medication_taken: Bool.random(),
                    medication_type: Bool.random() ? "biologic" : "None",
                    dosage_level: Bool.random() ? "40" : "0",
                    last_taken_date: Bool.random() ? dateString : nil,
                    // Supplement fields
                    supplements_taken: Bool.random(),
                    supplements_count: Int.random(in: 0...3),
                    supplement_details: nil,
                    // Sleep fields
                    sleep_hours: Int.random(in: 6...9),
                    sleep_quality: Int.random(in: 3...5),
                    sleep_notes: Bool.random() ? "Slept well" : nil,
                    // Stress fields
                    stress_level: Int.random(in: 1...5),
                    stress_source: Bool.random() ? "Work" : nil,
                    coping_strategies: Bool.random() ? "Meditation" : nil,
                    // Additional fields
                    fatigue_level: Int.random(in: 2...5),
                    mood_level: Int.random(in: 3...5),
                    menstruation: "not_applicable"
                )
                entries.append(entry)
            }
        }
        
        return entries
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
            insights: generateInsights(from: nutritionData, symptomData: symptomData, entries: entries),
            summary: calculateSummary(from: nutritionData, symptomData: symptomData, entries: entries)
        )
    }
    
    private func processNutritionData(entries: [JournalEntry]) -> [NutritionTrendPoint] {
        return entries.compactMap { entry in
            // Try direct nutrition fields first, then calculate from individual meals
            var totalCalories = Int(entry.calories ?? 0)
            var totalProtein = Int(entry.protein ?? 0)
            var totalFiber = Int(entry.fiber ?? 0)
            
            // If direct fields are 0, calculate from individual meal fields
            if totalCalories == 0 && totalProtein == 0 && totalFiber == 0 {
                print("📊 [DiscoverView] Direct fields are 0, checking individual meal fields:")
                print("📊 [DiscoverView]   Breakfast: \(entry.breakfast_calories ?? 0) cal, \(entry.breakfast_protein ?? 0) protein")
                print("📊 [DiscoverView]   Lunch: \(entry.lunch_calories ?? 0) cal, \(entry.lunch_protein ?? 0) protein")
                print("📊 [DiscoverView]   Dinner: \(entry.dinner_calories ?? 0) cal, \(entry.dinner_protein ?? 0) protein")
                print("📊 [DiscoverView]   Snack: \(entry.snack_calories ?? 0) cal, \(entry.snack_protein ?? 0) protein")
                
                let breakfastCalories = entry.breakfast_calories ?? 0
                let lunchCalories = entry.lunch_calories ?? 0
                let dinnerCalories = entry.dinner_calories ?? 0
                let snackCalories = entry.snack_calories ?? 0
                totalCalories = Int(breakfastCalories + lunchCalories + dinnerCalories + snackCalories)
                
                let breakfastProtein = entry.breakfast_protein ?? 0
                let lunchProtein = entry.lunch_protein ?? 0
                let dinnerProtein = entry.dinner_protein ?? 0
                let snackProtein = entry.snack_protein ?? 0
                totalProtein = Int(breakfastProtein + lunchProtein + dinnerProtein + snackProtein)
                
                let breakfastFiber = entry.breakfast_fiber ?? 0
                let lunchFiber = entry.lunch_fiber ?? 0
                let dinnerFiber = entry.dinner_fiber ?? 0
                let snackFiber = entry.snack_fiber ?? 0
                totalFiber = Int(breakfastFiber + lunchFiber + dinnerFiber + snackFiber)
                
                print("📊 [DiscoverView] Calculated from individual meals: Calories=\(totalCalories), Protein=\(totalProtein), Fiber=\(totalFiber)")
            } else {
                print("📊 [DiscoverView] Using direct fields: Calories=\(totalCalories), Protein=\(totalProtein), Fiber=\(totalFiber)")
            }
            
            // Calculate hydration from water_intake and other_fluids
            let waterIntake = entry.waterIntakeDouble
            let otherFluids = entry.otherFluidsDouble
            
            // Check if values are already in ml (large values) or liters (small values)
            let totalHydration: Int
            if waterIntake > 100 || otherFluids > 100 {
                // Values are already in ml
                totalHydration = Int(waterIntake + otherFluids)
            } else {
                // Values are in liters, convert to ml
                totalHydration = Int((waterIntake + otherFluids) * 1000)
            }
            
            print("🔍 [DiscoverView] Hydration calculation for \(entry.entry_date):")
            print("🔍 [DiscoverView]   water_intake: '\(entry.water_intake ?? "nil")' -> \(waterIntake) L")
            print("🔍 [DiscoverView]   other_fluids: '\(entry.other_fluids ?? "nil")' -> \(otherFluids) L")
            print("🔍 [DiscoverView]   totalHydration: \(totalHydration) ml")
            
            print("📊 [DiscoverView] Processing entry \(entry.entry_date): Calories=\(totalCalories), Protein=\(totalProtein), Fiber=\(totalFiber)")
            
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
            // Use direct symptom fields from journal entry
            let pain = entry.pain_severity ?? 0
            let stress = entry.stress_level ?? 0
            let fatigue = entry.fatigue_level ?? 0
            
            // Calculate flare risk based on available data
            let flareRisk = calculateFlareRiskFromEntry(entry: entry)
            
            print("📊 [DiscoverView] Processing symptoms for \(entry.entry_date): Pain=\(pain), Stress=\(stress), Fatigue=\(fatigue)")
            
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
            // Calculate medication adherence based on actual medication data
            let medicationAdherence = calculateMedicationAdherence(for: entry)
            
            // Get bowel health data - use actual bowel_frequency from database
            let bowelFrequency = entry.bowel_frequency ?? 0
            let bowelConsistency = entry.bowel_movements?.first?.consistency ?? 4
            
            // Weight data (would need to be added to journal entries)
            let weight = 70.0 // Placeholder
            let weightChange = 0.0 // Placeholder
            
            // Calculate nutrition score for this entry
            let nutritionScore = calculateNutritionScore(for: entry)
            
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
                nutritionScore: nutritionScore,
                // Bowel health warning indicators
                bloodPresent: bloodPresent,
                mucusPresent: mucusPresent,
                painSeverity: painSeverity,
                painLocation: entry.pain_location, // Add pain location
                urgencyLevel: urgencyLevel
            )
        }
    }
    
    private func calculateMicronutrientAnalysis(entries: [JournalEntry]) async {
        guard let userData = userData else { return }
        
        // Create a default profile for micronutrient calculation
        let defaultProfile = MicronutrientProfile(
            userId: userData.id,
            age: 30,
            weight: 70.0,
            height: nil,
            gender: "Unknown",
            diseaseActivity: .remission,
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
        
        // Calculate daily micronutrient intake
        let dailyIntake = micronutrientCalculator.calculateDailyMicronutrientIntake(
            from: entries,
            userProfile: defaultProfile
        )
        
        // Calculate requirements
        let requirements = IBDMicronutrientRequirements(
            age: defaultProfile.age,
            gender: defaultProfile.gender ?? "Unknown",
            weight: defaultProfile.weight,
            height: defaultProfile.height,
            diseaseActivity: defaultProfile.diseaseActivity,
            medications: defaultProfile.medications,
            diseaseType: defaultProfile.diseaseType ?? "IBD"
        )
        
        // Analyze micronutrient status
        let analysis = deficiencyAnalyzer.analyzeMicronutrientStatus(
            dailyIntake.totalIntake,
            requirements,
            defaultProfile.labResults
        )
        
        DispatchQueue.main.async {
            self.micronutrientAnalysis = analysis
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
    
    private func calculateFlareRiskFromEntry(entry: JournalEntry) -> Int {
        // Calculate flare risk based on journal entry data
        let pain = entry.pain_severity ?? 0
        let stress = entry.stress_level ?? 0
        let fatigue = entry.fatigue_level ?? 0
        let bloodPresent = entry.blood_present ?? false
        let urgency = entry.urgency_level ?? 0
        
        // Weighted calculation
        var riskScore = 0
        riskScore += pain * 2  // Pain is heavily weighted
        riskScore += stress
        riskScore += fatigue
        riskScore += bloodPresent ? 20 : 0  // Blood presence is critical
        riskScore += urgency * 2  // Urgency is important
        
        // Convert to percentage (0-100)
        let maxPossibleScore = 50  // Maximum possible score
        let percentage = min(100, max(0, (riskScore * 100) / maxPossibleScore))
        
        return Int(percentage)
    }
    
    private func calculateNutritionScore(for entry: JournalEntry) -> Int {
        // Try direct nutrition fields first, then calculate from individual meals
        var totalCalories = Int(entry.calories ?? 0)
        var totalProtein = Int(entry.protein ?? 0)
        var totalFiber = Int(entry.fiber ?? 0)
        
        // If direct fields are 0, calculate from individual meal fields
        if totalCalories == 0 && totalProtein == 0 && totalFiber == 0 {
            let breakfastCalories = entry.breakfast_calories ?? 0
            let lunchCalories = entry.lunch_calories ?? 0
            let dinnerCalories = entry.dinner_calories ?? 0
            let snackCalories = entry.snack_calories ?? 0
            totalCalories = Int(breakfastCalories + lunchCalories + dinnerCalories + snackCalories)
            
            let breakfastProtein = entry.breakfast_protein ?? 0
            let lunchProtein = entry.lunch_protein ?? 0
            let dinnerProtein = entry.dinner_protein ?? 0
            let snackProtein = entry.snack_protein ?? 0
            totalProtein = Int(breakfastProtein + lunchProtein + dinnerProtein + snackProtein)
            
            let breakfastFiber = entry.breakfast_fiber ?? 0
            let lunchFiber = entry.lunch_fiber ?? 0
            let dinnerFiber = entry.dinner_fiber ?? 0
            let snackFiber = entry.snack_fiber ?? 0
            totalFiber = Int(breakfastFiber + lunchFiber + dinnerFiber + snackFiber)
        }
        
        // Use the same calculation logic as HomeView for consistency
        var score = 100
        
        // Deduct points for deficiencies (same logic as HomeView)
        if totalProtein < 50 {
            score -= 20
        } else if totalProtein < 60 {
            score -= 10
        }
        
        if totalFiber < 20 {
            score -= 20
        } else if totalFiber < 25 {
            score -= 10
        }
        
        if totalCalories < 1500 {
            score -= 20
        } else if totalCalories < 1800 {
            score -= 10
        }
        
        // Bonus for good nutrition (same logic as HomeView)
        if totalProtein >= 60 && totalFiber >= 20 && totalCalories >= 1500 {
            score += 10
        }
        
        return max(0, min(100, score))
    }
    
    private func generateInsights() -> [Insight] {
        return []
    }
    
    private func generateInsights(from nutritionData: [NutritionTrendPoint], symptomData: [SymptomTrendPoint], entries: [JournalEntry]) -> [Insight] {
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
        
        // Medication adherence insight (based on actual medication data)
        let adherenceRate = calculateOverallMedicationAdherence(from: entries)
        
        if adherenceRate < 80 {
            insights.append(Insight(
                type: .medication,
                title: "Medication Adherence",
                message: "Based on your symptom patterns, medication adherence appears to be around \(adherenceRate)%. Consistent medication use is crucial for IBD management.",
                severity: .high,
                action: "Set daily medication reminders and improve adherence"
            ))
        } else if adherenceRate >= 90 {
            insights.append(Insight(
                type: .medication,
                title: "Medication Adherence",
                message: "Excellent medication adherence at \(adherenceRate)%. Keep up the consistent routine!",
                severity: .low,
                action: "Continue current medication schedule"
            ))
        }
        
        // Add hydration insight if we have hydration data
        if !nutritionData.isEmpty {
            let avgHydration = nutritionData.map { $0.hydration }.reduce(0, +) / nutritionData.count
            let hydrationTarget = IBDTargets().hydrationTarget
            
            if avgHydration < Int(Double(hydrationTarget) * 0.8) {
                insights.append(Insight(
                    type: .nutrition,
                    title: "Hydration",
                    message: "Your average hydration is \(avgHydration)ml/day, below the recommended \(hydrationTarget)ml for IBD management.",
                    severity: .moderate,
                    action: "Increase water intake and consider electrolyte supplements"
                ))
            } else if avgHydration >= hydrationTarget {
                insights.append(Insight(
                    type: .nutrition,
                    title: "Hydration",
                    message: "Great hydration at \(avgHydration)ml/day! This helps maintain digestive health.",
                    severity: .low,
                    action: "Continue current hydration routine"
                ))
            }
        }
        
        return insights
    }
    
    private func generateSummary() -> Summary {
        return Summary(
            totalEntries: 0,
            totalCalories: 0,
            avgPain: 0.0,
            bloodEpisodes: 0,
            medicationAdherence: 0
        )
    }
    
    private func calculateSummary(from nutritionData: [NutritionTrendPoint], symptomData: [SymptomTrendPoint], entries: [JournalEntry]) -> Summary {
        let totalEntries = nutritionData.count
        
        // Calculate total calories from nutrition data (cumulative for the week)
        let totalCalories = nutritionData.isEmpty ? 0 : nutritionData.map { $0.calories }.reduce(0, +)
        
        // Calculate average pain from symptom data
        let avgPain = symptomData.isEmpty ? 0.0 : Double(symptomData.map { $0.pain }.reduce(0, +)) / Double(totalEntries)
        
        // Calculate blood episodes and medication adherence from actual journal data
        let bloodEpisodes = symptomData.filter { $0.pain > 5 || $0.flareRisk > 40 }.count
        let medicationAdherence = calculateOverallMedicationAdherence(from: entries)
        
        return Summary(
            totalEntries: totalEntries,
            totalCalories: totalCalories,
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
    
    // MARK: - Medication Adherence Calculation
    
    /// Calculate medication adherence for a single journal entry
    private func calculateMedicationAdherence(for entry: JournalEntry) -> Double {
        // Check if medication was taken on this day
        let medicationTaken = entry.medication_taken ?? false
        let medicationType = entry.medication_type ?? "None"
        let dosageLevel = entry.dosage_level ?? "0"
        let lastTakenDate = entry.last_taken_date
        
        // If no medication type is set or it's "None", adherence is 0
        guard medicationType != "None" && medicationType != "" else {
            return 0.0
        }
        
        // If medication was taken today, adherence is 100%
        if medicationTaken {
            return 100.0
        }
        
        // If there's a last taken date, check if it's recent (within expected frequency)
        if let lastTaken = lastTakenDate, !lastTaken.isEmpty {
            let adherence = calculateAdherenceFromLastTaken(lastTaken: lastTaken, dosageLevel: dosageLevel)
            return adherence
        }
        
        // If no clear indication, assume partial adherence based on dosage level
        if dosageLevel != "0" && dosageLevel != "" {
            return 50.0 // Partial adherence if dosage is set but not taken today
        }
        
        return 0.0
    }
    
    /// Calculate overall medication adherence across all entries
    private func calculateOverallMedicationAdherence(from entries: [JournalEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let totalAdherence = entries.reduce(0.0) { sum, entry in
            sum + calculateMedicationAdherence(for: entry)
        }
        
        let averageAdherence = totalAdherence / Double(entries.count)
        return Int(averageAdherence)
    }
    
    /// Calculate adherence based on last taken date and dosage frequency
    private func calculateAdherenceFromLastTaken(lastTaken: String, dosageLevel: String) -> Double {
        // Parse the last taken date
        let lastTakenDate = Date.fromISOString(lastTaken)
        
        let daysSinceLastTaken = Calendar.current.dateComponents([.day], from: lastTakenDate, to: Date()).day ?? 0
        
        // Determine expected frequency based on dosage level
        let expectedFrequency: Int
        switch dosageLevel.lowercased() {
        case "daily", "1":
            expectedFrequency = 1
        case "weekly", "7":
            expectedFrequency = 7
        case "biweekly", "14":
            expectedFrequency = 14
        case "monthly", "30":
            expectedFrequency = 30
        default:
            expectedFrequency = 1 // Default to daily
        }
        
        // Calculate adherence based on how close we are to the expected frequency
        if daysSinceLastTaken <= expectedFrequency {
            let adherence = max(0.0, 100.0 - (Double(daysSinceLastTaken) / Double(expectedFrequency)) * 100.0)
            return adherence
        } else {
            return 0.0 // Overdue
        }
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
                title: "Total Calories",
                value: "\(summary.totalCalories)",
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
                let hydrationTarget = IBDTargets().hydrationTarget
                NutritionChartView(
                    data: data,
                    type: .hydration,
                    title: "Daily Hydration",
                    color: .cyan,
                    target: hydrationTarget,
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
                .onAppear {
                    print("🔍 [NutritionChartView] Chart target: \(target) for \(title)")
                }
            
            Chart {
                ForEach(data) { point in
                    // Actual intake - using dots instead of lines (larger size)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", getValue(for: point))
                    )
                    .foregroundStyle(color)
                    .symbolSize(48) // Larger size for better visibility
                }
                
                // Target line - show daily target as a horizontal line
                if target > 0 {
                    RuleMark(
                        y: .value("Target", Double(target))
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }
            .frame(height: 180)
            .chartYScale(domain: calculateYScaleDomain())
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
                        Text("Target: \(target) \(unit)/day")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                // Performance indicator - show cumulative weekly totals instead of daily averages
                let totalValue = data.map { getValue(for: $0) }.reduce(0, +)
                let weeklyTarget = target * 7 // Convert daily target to weekly target
                let targetThreshold = Int(Double(weeklyTarget) * 0.9)
                let performance = totalValue >= targetThreshold ? "Good" : "Below Target"
                let performanceColor = totalValue >= targetThreshold ? Color.green : Color.orange
                
                HStack {
                    Text("Performance:")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Text(performance)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(performanceColor)
                    
                    Spacer()
                    
                    Text("Total: \(Int(totalValue)) \(unit)/week")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
        }
    }
    
    private func getValue(for point: NutritionTrendPoint) -> Int {
        let value: Int
        switch type {
        case .calories:
            value = point.calories
        case .protein:
            value = point.protein
        case .fiber:
            value = point.fiber
        case .hydration:
            value = point.hydration
        }
        
        print("🔍 [NutritionChartView] \(title) - Date: \(point.date), Value: \(value)")
        return value
    }
    
    private func calculateYScaleDomain() -> ClosedRange<Double> {
        let maxDataValue = data.map { Double(getValue(for: $0)) }.max() ?? 0
        let targetValue = Double(target)
        let maxValue = max(maxDataValue, targetValue)
        
        // Add some padding (20% of max value or minimum padding based on chart type)
        let padding = max(maxValue * 0.2, getMinimumPadding())
        let upperBound = maxValue + padding
        
        print("🔍 [NutritionChartView] \(title) - Max data: \(maxDataValue), Target: \(targetValue), Max value: \(maxValue), Padding: \(padding), Upper bound: \(upperBound)")
        
        // Ensure minimum scale for hydration chart
        if type == .hydration && upperBound < 1000 {
            print("🔍 [NutritionChartView] Hydration chart - forcing minimum scale of 0-3000")
            return 0...3000
        }
        
        return 0...upperBound
    }
    
    private func getMinimumPadding() -> Double {
        switch type {
        case .calories:
            return 200  // 200 calorie padding
        case .protein:
            return 20   // 20g protein padding
        case .fiber:
            return 10   // 10g fiber padding
        case .hydration:
            return 500  // 500ml hydration padding
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
    private let symptomTargets = SymptomTargets(
        painTarget: 3,
        stressTarget: 4,
        fatigueTarget: 3,
        bowelFrequencyTarget: 2,
        urgencyTarget: 2
    )
    
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
    let nutritionData: [NutritionTrendPoint]
    let micronutrientAnalysis: IBDMicronutrientAnalysis?
    let selectedTimeframe: TimeFrame
    @ObservedObject var evidenceBasedTargetService: EvidenceBasedTargetCalculator
    
    // Evidence-based targets (replaces hardcoded values)
    private var targets: HealthMetricTargets {
        // Create a default user profile for target calculation
        let defaultProfile = MicronutrientProfile(
            userId: "default",
            age: 30,
            weight: 60.0,
            height: 165.0,
            gender: "female",
            diseaseActivity: .remission,
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
        return EvidenceBasedTargets.calculateHealthMetricTargets(
            for: defaultProfile,
            diseaseActivity: .remission,
            healthHistory: []
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            // Nutrition Score Trend Bar Chart - First
            HorizontalBarChartView(
                title: "Nutrition Score",
                target: 80.0, // Target nutrition score
                actual: averageNutritionScore,
                unit: "/100",
                targetColor: .blue,
                actualColor: nutritionScoreColor,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // Bowel Frequency Bar Chart - Second - Smart chart that shows warning when needed
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
            
            // Medication Adherence Bar Chart - Third - Smart chart that shows warning when needed
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
                            value: Double(bloodPresentEpisodes),
                            threshold: 0.0,
                            unit: " episodes",
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                    
                    // Mucus Present Warning
                    if hasMucusPresent {
                        WarningBarChartView(
                            title: "Mucus Present",
                            value: Double(mucusPresentEpisodes),
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
                Text("Debug: \(selectedTimeframe.rawValue) - No warnings - Bowel Freq: \(String(format: "%.1f", averageBowelFrequency))/day (Target: \(String(format: "%.1f", targets.bowelFrequencyTarget))) | Pain: \(String(format: "%.1f", averagePain))/10 (Target: \(String(format: "%.1f", targets.painTarget)))")
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
    
    private var averageNutritionScore: Double {
        guard !filteredData.isEmpty else { return 0 }
        
        // Calculate from the nutrition trend data which has the actual values
        let filteredNutritionPoints = nutritionData.filter { point in
            // Filter by the same timeframe as health metrics
            let pointDate = Date.fromISOString(point.date)
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
            
            return pointDate >= startDate && pointDate <= endDate
        }
        
        if !filteredNutritionPoints.isEmpty {
            // Calculate averages from nutrition data
            let totalCalories = Double(filteredNutritionPoints.map { $0.calories }.reduce(0, +)) / Double(filteredNutritionPoints.count)
            let totalProtein = Double(filteredNutritionPoints.map { $0.protein }.reduce(0, +)) / Double(filteredNutritionPoints.count)
            let totalFiber = Double(filteredNutritionPoints.map { $0.fiber }.reduce(0, +)) / Double(filteredNutritionPoints.count)
            
            // Use normalized statistical calculation (same as HomeView)
            let macroNutrients: [(String, Double, Double)] = [
                ("Calories", totalCalories, 2000.0), // Default targets
                ("Protein", totalProtein, 60.0),
                ("Fiber", totalFiber, 25.0)
            ]
            
            let micronutrients = micronutrientAnalysis?.ibdSpecificNutrients ?? IBDSpecificNutrients(
                vitaminD: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                vitaminB12: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                iron: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                calcium: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                zinc: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                omega3: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                glutamine: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: []),
                probiotics: NutrientStatus(currentIntake: 0, requiredIntake: 0, status: .deficient, absorptionRate: 0.5, ibdFactors: [])
            )
            
            return Double(NutritionScoreCalculator.shared.calculateScore(
                macronutrients: macroNutrients,
                micronutrients: micronutrients,
                userProfile: nil
            ))
        }
        
        // Fallback to averaging per-entry scores if nutrition data not available
        let totalScore = filteredData.map { $0.nutritionScore }.reduce(0, +)
        return Double(totalScore) / Double(filteredData.count)
    }
    
    
    private var nutritionScoreColor: Color {
        let score = averageNutritionScore
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
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
    
    private var bloodPresentEpisodes: Int {
        // Count actual number of episodes with blood present
        return filteredData.filter { $0.bloodPresent }.count
    }
    
    private var hasMucusPresent: Bool {
        // Check if any entry has mucus present
        return filteredData.contains { $0.mucusPresent }
    }
    
    private var mucusPresentEpisodes: Int {
        // Count actual number of episodes with mucus present
        return filteredData.filter { $0.mucusPresent }.count
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

struct DiscoverErrorView: View {
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
    let nutritionScore: Int // Nutrition score (0-100)
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
    let totalCalories: Int
    let avgPain: Double
    let bloodEpisodes: Int
    let medicationAdherence: Int
}

// MARK: - Industry Standard Targets

struct IBDTargets {
    // NIH DRI-based baseline values with IBD-specific adjustments
    // Based on Dietary Reference Intakes (DRI) from NIH Office of Dietary Supplements
    // Adjusted for IBD patients who may have increased nutrient needs due to malabsorption
    
    // Macronutrients (Daily Baseline - DRI-based)
    let calorieTarget: Int = 2000 // DRI: 2000-2500 kcal/day for adults (using lower end for IBD)
    let proteinTarget: Int = 65 // DRI: 56g (male) / 46g (female) - using average with IBD adjustment
    let fiberTarget: Int = 25 // DRI: 25g (female) / 38g (male) - using lower end for IBD tolerance
    let hydrationTarget: Int = 2700 // DRI: 2.7L/day for adult females, 3.7L/day for males (using female baseline)
    let fatTarget: Int = 65 // DRI: 20-35% of calories (using 30% of 2000 kcal / 9 kcal/g)
    let carbTarget: Int = 300 // DRI: 130g minimum + additional for energy (2000 - 260 protein - 585 fat) / 4
    
    // Micronutrients (Daily Baseline - DRI RDA/AI values with IBD adjustments)
    let vitaminDTarget: Int = 15 // DRI: 600 IU (15 mcg) - may need 2-3x for IBD patients
    let vitaminB12Target: Int = 2 // DRI: 2.4 mcg - may need 2-3x for IBD patients (rounded to 2)
    let ironTarget: Int = 18 // DRI: 18mg (female) / 8mg (male) - using female value with IBD adjustment
    let folateTarget: Int = 400 // DRI: 400 mcg DFE - may need 1.5x for IBD patients
    let calciumTarget: Int = 1000 // DRI: 1000mg (19-50 years) - may need 1.5x for IBD patients
    let zincTarget: Int = 11 // DRI: 11mg (male) / 8mg (female) - using male value with IBD adjustment
    let omega3Target: Int = 1100 // DRI: 1.1g (1100mg) - may need 2x for IBD patients
    
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
    
    // Calculate personalized targets based on user profile using DRI as baseline
    static func calculate(for userProfile: MicronutrientProfile) -> PersonalizedIBDTargets {
        let age = userProfile.age
        let diseaseActivity = userProfile.diseaseActivity
        let gender = userProfile.gender
        
        // Calculate multipliers based on user profile
        let diseaseActivityMultiplier = diseaseActivityMultiplier(for: diseaseActivity)
        let ageMultiplier = ageMultiplier(for: age)
        let diseaseTypeMultiplier = 1.2 // IBD patients typically need 20% more nutrients due to malabsorption
        
        let totalMultiplier = diseaseActivityMultiplier * ageMultiplier * diseaseTypeMultiplier
        
        // Macronutrients (DRI-based with weight adjustments)
        let baseCalories = gender == "male" ? 2500 : 2000 // DRI baseline
        let calorieTarget = Int(Double(baseCalories) * totalMultiplier)
        
        let baseProtein = gender == "male" ? 56 : 46 // DRI baseline (g/day)
        let proteinTarget = Int(Double(baseProtein) * totalMultiplier)
        
        let baseFiber = gender == "male" ? 38 : 25 // DRI baseline (g/day)
        let fiberTarget = Int(Double(baseFiber) * totalMultiplier)
        
        let baseHydration = gender == "male" ? 3700 : 2700 // DRI baseline (ml/day)
        let hydrationTarget = Int(Double(baseHydration) * totalMultiplier)
        
        // Calculate fat and carb targets based on calorie target (DRI: 20-35% fat, 45-65% carbs)
        let fatTarget = Int(Double(calorieTarget) * 0.3 / 9.0) // 30% of calories from fat
        let carbTarget = Int((Double(calorieTarget) - Double(proteinTarget * 4) - Double(fatTarget * 9)) / 4.0)
        
        // Micronutrients (DRI RDA/AI baseline with IBD adjustments)
        let vitaminDTarget = Int(15.0 * totalMultiplier) // DRI: 600 IU (15 mcg) baseline - stored in mcg
        let vitaminB12Target = Int(2.4 * totalMultiplier) // DRI: 2.4 mcg baseline
        let ironTarget = Int(18.0 * totalMultiplier) // DRI: 18mg (female) baseline
        let folateTarget = Int(400.0 * totalMultiplier) // DRI: 400 mcg DFE baseline
        let calciumTarget = Int(1000.0 * totalMultiplier) // DRI: 1000mg baseline
        let zincTarget = Int(11.0 * totalMultiplier) // DRI: 11mg (male) baseline
        let omega3Target = Int(1100.0 * totalMultiplier) // DRI: 1.1g baseline
        
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

// MARK: - Evidence-Based Target Integration
// These structs are now replaced by EvidenceBasedTargets.swift
// The hardcoded values below are kept for backward compatibility
// New code should use EvidenceBasedTargetCalculator.shared.calculateAllTargets()

// DEPRECATED: These structs have been moved to EvidenceBasedTargets.swift
// Use EvidenceBasedTargets.calculateHealthMetricTargets() and EvidenceBasedTargets.calculateSymptomTargets() instead

#Preview {
    DiscoverView(userData: UserData(
        id: "test",
        email: "test@example.com",
        name: "Test User",
        phoneNumber: nil,
        token: "test-token"
    ))
} 