import SwiftUI

struct DailyLogView: View {
    let userData: UserData?
    
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var isLoading = false
    @State private var entries: [LogEntry] = []
    @State private var showingEntryForm = false
    @State private var selectedEntryType: EntryType = .meals
    @State private var showingDebugLogs = false
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Header
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            loadEntries()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            VStack {
                                Text(dateString)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Tap to change date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            loadEntries()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Entry Type Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(EntryType.allCases, id: \.self) { entryType in
                            EntryTypeCard(
                                entryType: entryType,
                                isSelected: selectedEntryType == entryType,
                                hasData: hasDataForEntryType(entryType),
                                action: {
                                    selectedEntryType = entryType
                                    showingEntryForm = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Existing Entries Section
                    if isLoading {
                        ProgressView("Loading entries...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if entries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No entries for \(dateString)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add your first entry using the options above")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Entries")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.ibdPrimaryText)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(entries) { entry in
                                    LogEntryCard(entry: entry)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        showingDebugLogs = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingDebugLogs) {
                LogViewerView()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate, onDateSelected: {
                    showingDatePicker = false
                    loadEntries()
                })
            }
            .sheet(isPresented: $showingEntryForm) {
                EntryFormView(
                    userData: userData,
                    selectedDate: selectedDate,
                    entryType: selectedEntryType,
                    onEntrySaved: {
                        showingEntryForm = false
                        loadEntries()
                    }
                )
            }
            .onAppear {
                loadEntries()
            }
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private func loadEntries() {
        guard let userData = userData else { 
            NetworkLogger.shared.log("❌ No user data available for loading entries", level: .error, category: .journal)
            return 
        }
        
        NetworkLogger.shared.log("🔄 Loading entries for user: \(userData.id)", level: .info, category: .journal)
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        NetworkLogger.shared.log("📅 Loading entries for date: \(dateString)", level: .info, category: .journal)
        
        guard let url = URL(string: "\(apiBaseURL)/journal/entries/\(userData.id)?date=\(dateString)") else { 
            NetworkLogger.shared.log("❌ Invalid URL for loading entries", level: .error, category: .journal)
            return 
        }
        
        NetworkLogger.shared.log("🌐 Making GET request to: \(url.absoluteString)", level: .info, category: .journal)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    NetworkLogger.shared.log("❌ Error loading entries: \(error.localizedDescription)", level: .error, category: .journal)
                    return
                }
                
                NetworkLogger.shared.log("📥 Received response for entries", level: .info, category: .journal)
                
                if let httpResponse = response as? HTTPURLResponse {
                    NetworkLogger.shared.log("📊 HTTP Status: \(httpResponse.statusCode)", level: .info, category: .journal)
                    
                    if httpResponse.statusCode == 200 {
                        NetworkLogger.shared.log("✅ Entries loaded successfully", level: .info, category: .journal)
                    } else {
                        NetworkLogger.shared.log("❌ Server error loading entries: \(httpResponse.statusCode)", level: .error, category: .journal)
                    }
                }
                
                guard let data = data else { 
                    NetworkLogger.shared.log("❌ No data received for entries", level: .error, category: .journal)
                    return 
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    NetworkLogger.shared.log("📄 Response data: \(responseString)", level: .debug, category: .journal)
                }
                
                do {
                    if let jsonEntries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        NetworkLogger.shared.log("✅ Parsed \(jsonEntries.count) entries", level: .info, category: .journal)
                        self.entries = jsonEntries.compactMap { LogEntry(from: $0) }
                    } else {
                        NetworkLogger.shared.log("❌ Failed to parse entries as array", level: .error, category: .journal)
                    }
                } catch {
                    NetworkLogger.shared.log("❌ Error parsing entries: \(error)", level: .error, category: .journal)
                }
            }
        }.resume()
    }
    
    private func hasDataForEntryType(_ entryType: EntryType) -> Bool {
        guard let entry = entries.first else { return false }
        
        switch entryType {
        case .meals:
            return (entry.breakfast?.isEmpty == false) ||
                   (entry.lunch?.isEmpty == false) ||
                   (entry.dinner?.isEmpty == false) ||
                   (entry.snacks?.isEmpty == false) ||
                   (entry.breakfastCalories?.isEmpty == false) ||
                   (entry.lunchCalories?.isEmpty == false) ||
                   (entry.dinnerCalories?.isEmpty == false) ||
                   (entry.snackCalories?.isEmpty == false)
        case .bowelHealth:
            return (entry.bowelFrequency ?? 0) > 0 ||
                   (entry.bristolScale ?? 0) > 0 ||
                   (entry.bloodPresent == true)
        case .medication:
            return (entry.medicationTaken == true) ||
                   (entry.medicationType?.isEmpty == false)
        case .stress:
            return (entry.stressLevel ?? 0) > 0 ||
                   (entry.fatigueLevel ?? 0) > 0
        case .sleep:
            return (entry.sleepHours ?? 0) > 0
        case .hydration:
            return false // No hydration field in current schema
        }
    }
}

enum EntryType: String, CaseIterable {
    case meals = "meals"
    case bowelHealth = "bowel"
    case medication = "medication"
    case stress = "stress"
    case sleep = "sleep"
    case hydration = "hydration"
    
    var displayName: String {
        switch self {
        case .meals: return "Meals"
        case .bowelHealth: return "Bowel Health"
        case .medication: return "Medication"
        case .stress: return "Stress"
        case .sleep: return "Sleep"
        case .hydration: return "Hydration"
        }
    }
    
    var icon: String {
        switch self {
        case .meals: return "fork.knife"
        case .bowelHealth: return "drop.fill"
        case .medication: return "pills.fill"
        case .stress: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .hydration: return "drop.degreesign"
        }
    }
    
    var color: Color {
        switch self {
        case .meals: return .green
        case .bowelHealth: return .orange
        case .medication: return .blue
        case .stress: return .red
        case .sleep: return .purple
        case .hydration: return .cyan
        }
    }
}

struct EntryFormView: View {
    let userData: UserData?
    let selectedDate: Date
    let entryType: EntryType
    let onEntrySaved: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showingDebugLogs = false
    
    // Form data
    @State private var mealsData = MealsFormData()
    @State private var bowelData = BowelHealthFormData()
    @State private var medicationData = MedicationFormData()
    @State private var stressData = StressFormData()
    @State private var sleepData = SleepFormData()
    @State private var hydrationData = HydrationFormData()
    
    init(userData: UserData?, selectedDate: Date, entryType: EntryType, onEntrySaved: @escaping () -> Void) {
        self.userData = userData
        self.selectedDate = selectedDate
        self.entryType = entryType
        self.onEntrySaved = onEntrySaved
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    switch entryType {
                    case .meals:
                        MealsFormView(data: $mealsData)
                    case .bowelHealth:
                        BowelHealthFormView(data: $bowelData)
                    case .medication:
                        MedicationFormView(data: $medicationData)
                    case .stress:
                        StressFormView(data: $stressData)
                    case .sleep:
                        SleepFormView(data: $sleepData)
                    case .hydration:
                        HydrationFormView(data: $hydrationData)
                    }
                }
                .padding()
            }
            .navigationTitle(entryType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Debug") {
                            showingDebugLogs = true
                        }
                        .foregroundColor(.blue)
                        
                        Button("Save") {
                            saveEntry()
                        }
                        .disabled(isLoading)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDebugLogs) {
            LogViewerView()
        }
        .onAppear {
            loadExistingEntry()
        }
    }
    
    private func loadExistingEntry() {
        guard let userData = userData else { return }
        
        NetworkLogger.shared.log("🔄 Loading existing entry for date: \(selectedDate)", level: .info, category: .journal)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userData.id)?date=\(dateString)") else { return }
        
        NetworkLogger.shared.log("🔄 Requesting URL: \(url)", level: .debug, category: .journal)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    NetworkLogger.shared.log("❌ Error loading existing entry: \(error.localizedDescription)", level: .error, category: .journal)
                    return
                }
                
                guard let data = data else { 
                    NetworkLogger.shared.log("❌ No data received from server", level: .error, category: .journal)
                    return 
                }
                
                NetworkLogger.shared.log("🔄 Received data from server: \(String(data: data, encoding: .utf8) ?? "Unable to decode")", level: .debug, category: .journal)
                
                do {
                    if let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        NetworkLogger.shared.log("🔄 Parsed \(entries.count) entries from server", level: .info, category: .journal)
                        if let existingEntry = entries.first {
                            NetworkLogger.shared.log("✅ Found existing entry, loading data", level: .info, category: .journal)
                            NetworkLogger.shared.log("🔄 Entry keys: \(Array(existingEntry.keys))", level: .debug, category: .journal)
                            self.populateFormData(from: existingEntry)
                        } else {
                            NetworkLogger.shared.log("ℹ️ No existing entry found for this date", level: .info, category: .journal)
                        }
                    } else {
                        NetworkLogger.shared.log("❌ Failed to parse entries as array", level: .error, category: .journal)
                    }
                } catch {
                    NetworkLogger.shared.log("❌ Error parsing existing entry: \(error)", level: .error, category: .journal)
                }
            }
        }.resume()
    }
    
    private func populateFormData(from entry: [String: Any]) {
        switch entryType {
        case .meals:
            // Populate meals data
            DispatchQueue.main.async {
                NetworkLogger.shared.log("🍽️ POPULATE: Starting to populate meals data from entry", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Raw entry data: \(entry)", level: .debug, category: .journal)
                
                // Store original values for comparison
                let originalBreakfast = self.mealsData.breakfastDescription
                let originalLunch = self.mealsData.lunchDescription
                let originalDinner = self.mealsData.dinnerDescription
                let originalSnack = self.mealsData.snackDescription
                
                self.mealsData.breakfastDescription = entry["breakfast"] as? String ?? ""
                self.mealsData.lunchDescription = entry["lunch"] as? String ?? ""
                self.mealsData.dinnerDescription = entry["dinner"] as? String ?? ""
                self.mealsData.snackDescription = entry["snacks"] as? String ?? ""
                
                NetworkLogger.shared.log("🍽️ POPULATE: Set breakfast='\(self.mealsData.breakfastDescription)' (was: '\(originalBreakfast)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set lunch='\(self.mealsData.lunchDescription)' (was: '\(originalLunch)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set dinner='\(self.mealsData.dinnerDescription)' (was: '\(originalDinner)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set snack='\(self.mealsData.snackDescription)' (was: '\(originalSnack)')", level: .info, category: .journal)
                
                // Load nutrition data for each meal - handle both string and integer types
                self.mealsData.breakfastCalories = self.parseNutritionValue(entry["breakfast_calories"])
                self.mealsData.breakfastProtein = self.parseNutritionValue(entry["breakfast_protein"])
                self.mealsData.breakfastCarbs = self.parseNutritionValue(entry["breakfast_carbs"])
                self.mealsData.breakfastFiber = self.parseNutritionValue(entry["breakfast_fiber"])
                self.mealsData.breakfastFat = self.parseNutritionValue(entry["breakfast_fat"])
                
                self.mealsData.lunchCalories = self.parseNutritionValue(entry["lunch_calories"])
                self.mealsData.lunchProtein = self.parseNutritionValue(entry["lunch_protein"])
                self.mealsData.lunchCarbs = self.parseNutritionValue(entry["lunch_carbs"])
                self.mealsData.lunchFiber = self.parseNutritionValue(entry["lunch_fiber"])
                self.mealsData.lunchFat = self.parseNutritionValue(entry["lunch_fat"])
                
                self.mealsData.dinnerCalories = self.parseNutritionValue(entry["dinner_calories"])
                self.mealsData.dinnerProtein = self.parseNutritionValue(entry["dinner_protein"])
                self.mealsData.dinnerCarbs = self.parseNutritionValue(entry["dinner_carbs"])
                self.mealsData.dinnerFiber = self.parseNutritionValue(entry["dinner_fiber"])
                self.mealsData.dinnerFat = self.parseNutritionValue(entry["dinner_fat"])
                
                self.mealsData.snackCalories = self.parseNutritionValue(entry["snack_calories"])
                self.mealsData.snackProtein = self.parseNutritionValue(entry["snack_protein"])
                self.mealsData.snackCarbs = self.parseNutritionValue(entry["snack_carbs"])
                self.mealsData.snackFiber = self.parseNutritionValue(entry["snack_fiber"])
                self.mealsData.snackFat = self.parseNutritionValue(entry["snack_fat"])
                
                self.mealsData.notes = entry["notes"] as? String ?? ""
                
                NetworkLogger.shared.log("🍽️ POPULATE: Final meals data - breakfast='\(self.mealsData.breakfastDescription)', lunch='\(self.mealsData.lunchDescription)', dinner='\(self.mealsData.dinnerDescription)', snack='\(self.mealsData.snackDescription)'", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Total calories=\(self.mealsData.totalCalories)", level: .info, category: .journal)
                
                // Trigger nutrition calculation for all meal types that have descriptions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.calculateNutritionForAllMeals()
                }
            }
            
        case .bowelHealth:
            // Populate bowel health data
            DispatchQueue.main.async {
                self.bowelData.frequency = entry["bowel_frequency"] as? Int ?? 0
                self.bowelData.bristolScale = entry["bristol_scale"] as? Int ?? 4
                self.bowelData.bloodPresent = entry["blood_present"] as? Bool ?? false
                self.bowelData.mucusPresent = entry["mucus_present"] as? Bool ?? false
                self.bowelData.urgency = entry["urgency_level"] as? Int ?? 0
                self.bowelData.painLevel = entry["pain_severity"] as? Int ?? 0
                self.bowelData.painLocation = entry["pain_location"] as? String ?? "None"
                self.bowelData.painTime = entry["pain_time"] as? String ?? "None"
                self.bowelData.notes = entry["notes"] as? String ?? ""
            }
            
        case .medication:
            // Populate medication data
            DispatchQueue.main.async {
                self.medicationData.taken = entry["medication_taken"] as? Bool ?? false
                self.medicationData.medicationType = entry["medication_type"] as? String ?? "None"
                self.medicationData.dosageLevel = entry["dosage_level"] as? String ?? "0"
                self.medicationData.notes = entry["notes"] as? String ?? ""
            }
            
        case .stress:
            // Populate stress data
            DispatchQueue.main.async {
                self.stressData.stressLevel = entry["stress_level"] as? Int ?? 5
                self.stressData.stressSource = entry["stress_source"] as? String ?? ""
                self.stressData.copingStrategies = entry["coping_strategies"] as? String ?? ""
                self.stressData.mood = entry["mood_level"] as? Int ?? 5
                self.stressData.notes = entry["notes"] as? String ?? ""
            }
            
        case .sleep:
            // Populate sleep data
            DispatchQueue.main.async {
                self.sleepData.sleepHours = entry["sleep_hours"] as? Double ?? 8.0
                self.sleepData.sleepQuality = entry["sleep_quality"] as? Int ?? 5
                self.sleepData.notes = entry["notes"] as? String ?? ""
            }
            
        case .hydration:
            // Populate hydration data
            DispatchQueue.main.async {
                self.hydrationData.waterIntake = entry["water_intake"] as? Double ?? 0
                self.hydrationData.otherFluids = entry["other_fluids"] as? Double ?? 0
                self.hydrationData.fluidType = entry["fluid_type"] as? String ?? "Water"
                self.hydrationData.hydrationLevel = entry["hydration_level"] as? Int ?? 5
                self.hydrationData.notes = entry["notes"] as? String ?? ""
            }
        }
    }
    
    // Helper function to parse nutrition values that can be either strings or integers
    private func parseNutritionValue(_ value: Any?) -> Double {
        if let intValue = value as? Int {
            return Double(intValue)
        } else if let stringValue = value as? String {
            return Double(stringValue) ?? 0.0
        } else if let doubleValue = value as? Double {
            return doubleValue
        }
        return 0.0
    }
    
    private func saveEntry() {
        guard let userData = userData else { 
            NetworkLogger.shared.log("❌ No user data available for saving entry", level: .error, category: .journal)
            return 
        }
        
        NetworkLogger.shared.log("🚀 Starting to save entry for user: \(userData.id)", level: .info, category: .journal)
        NetworkLogger.shared.log("📅 Entry type: \(entryType.rawValue)", level: .info, category: .journal)
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        NetworkLogger.shared.log("📅 Formatted date: \(dateString)", level: .info, category: .journal)
        
        var entryData: [String: Any] = [
            "username": userData.id,  // Use username instead of user_id
            "entry_date": dateString,
            "entry_type": entryType.rawValue
        ]
        
        NetworkLogger.shared.log("🔧 Base entry data: \(entryData)", level: .debug, category: .journal)
        
        // Add specific form data
        switch entryType {
        case .meals:
            let mealsDict = mealsData.toDictionary()
            entryData.merge(mealsDict) { _, new in new }
            NetworkLogger.shared.log("🍽️ Meals data: \(mealsDict)", level: .debug, category: .journal)
        case .bowelHealth:
            let bowelDict = bowelData.toDictionary()
            entryData.merge(bowelDict) { _, new in new }
            NetworkLogger.shared.log("💩 Bowel data: \(bowelDict)", level: .debug, category: .journal)
        case .medication:
            let medDict = medicationData.toDictionary()
            entryData.merge(medDict) { _, new in new }
            NetworkLogger.shared.log("💊 Medication data: \(medDict)", level: .debug, category: .journal)
        case .stress:
            let stressDict = stressData.toDictionary()
            entryData.merge(stressDict) { _, new in new }
            NetworkLogger.shared.log("😰 Stress data: \(stressDict)", level: .debug, category: .journal)
        case .sleep:
            let sleepDict = sleepData.toDictionary()
            entryData.merge(sleepDict) { _, new in new }
            NetworkLogger.shared.log("😴 Sleep data: \(sleepDict)", level: .debug, category: .journal)
        case .hydration:
            let hydrationDict = hydrationData.toDictionary()
            entryData.merge(hydrationDict) { _, new in new }
            NetworkLogger.shared.log("💧 Hydration data: \(hydrationDict)", level: .debug, category: .journal)
        }
        
        NetworkLogger.shared.log("📦 Final entry data: \(entryData)", level: .debug, category: .journal)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries") else { 
            NetworkLogger.shared.log("❌ Invalid URL: \(AppConfig.apiBaseURL)/journal/entries", level: .error, category: .journal)
            isLoading = false
            return 
        }
        
        NetworkLogger.shared.log("🌐 Making request to: \(url.absoluteString)", level: .info, category: .journal)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        NetworkLogger.shared.log("📋 Request headers: \(request.allHTTPHeaderFields ?? [:])", level: .debug, category: .journal)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: entryData)
            NetworkLogger.shared.log("✅ Request body serialized successfully", level: .debug, category: .journal)
        } catch {
            NetworkLogger.shared.log("❌ Error creating request body: \(error)", level: .error, category: .journal)
            isLoading = false
            return
        }
        
        NetworkLogger.shared.log("🚀 Sending request via NetworkManager...", level: .info, category: .journal)
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    NetworkLogger.shared.log("❌ Network error: \(error.localizedDescription)", level: .error, category: .journal)
                    NetworkLogger.shared.log("❌ Error details: \(error)", level: .error, category: .journal)
                    return
                }
                
                NetworkLogger.shared.log("📥 Received response", level: .info, category: .journal)
                
                if let httpResponse = response as? HTTPURLResponse {
                    NetworkLogger.shared.log("📊 HTTP Status: \(httpResponse.statusCode)", level: .info, category: .journal)
                    NetworkLogger.shared.log("📋 Response headers: \(httpResponse.allHeaderFields)", level: .debug, category: .journal)
                    
                    if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                        NetworkLogger.shared.log("✅ Entry saved successfully!", level: .info, category: .journal)
                        
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            NetworkLogger.shared.log("📄 Response body: \(responseString)", level: .debug, category: .journal)
                        }
                        
                        self.onEntrySaved()
                    } else {
                        NetworkLogger.shared.log("❌ Server error: \(httpResponse.statusCode)", level: .error, category: .journal)
                        
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            NetworkLogger.shared.log("📄 Error response body: \(responseString)", level: .error, category: .journal)
                        }
                    }
                } else {
                    NetworkLogger.shared.log("❌ No HTTP response received", level: .error, category: .journal)
                }
            }
        }.resume()
    }
    
    private func calculateNutritionForAllMeals() {
        // Calculate nutrition for breakfast if it has a description
        if !mealsData.breakfastDescription.isEmpty {
            let breakfastNutrition = calculateNutritionFromDescription(mealsData.breakfastDescription)
            mealsData.breakfastCalories = breakfastNutrition.totalCalories
            mealsData.breakfastProtein = breakfastNutrition.totalProtein
            mealsData.breakfastCarbs = breakfastNutrition.totalCarbs
            mealsData.breakfastFiber = breakfastNutrition.totalFiber
            mealsData.breakfastFat = breakfastNutrition.totalFat
        }
        
        // Calculate nutrition for lunch if it has a description
        if !mealsData.lunchDescription.isEmpty {
            let lunchNutrition = calculateNutritionFromDescription(mealsData.lunchDescription)
            mealsData.lunchCalories = lunchNutrition.totalCalories
            mealsData.lunchProtein = lunchNutrition.totalProtein
            mealsData.lunchCarbs = lunchNutrition.totalCarbs
            mealsData.lunchFiber = lunchNutrition.totalFiber
            mealsData.lunchFat = lunchNutrition.totalFat
        }
        
        // Calculate nutrition for dinner if it has a description
        if !mealsData.dinnerDescription.isEmpty {
            let dinnerNutrition = calculateNutritionFromDescription(mealsData.dinnerDescription)
            mealsData.dinnerCalories = dinnerNutrition.totalCalories
            mealsData.dinnerProtein = dinnerNutrition.totalProtein
            mealsData.dinnerCarbs = dinnerNutrition.totalCarbs
            mealsData.dinnerFiber = dinnerNutrition.totalFiber
            mealsData.dinnerFat = dinnerNutrition.totalFat
        }
        
        // Calculate nutrition for snacks if it has a description
        if !mealsData.snackDescription.isEmpty {
            let snackNutrition = calculateNutritionFromDescription(mealsData.snackDescription)
            mealsData.snackCalories = snackNutrition.totalCalories
            mealsData.snackProtein = snackNutrition.totalProtein
            mealsData.snackCarbs = snackNutrition.totalCarbs
            mealsData.snackFiber = snackNutrition.totalFiber
            mealsData.snackFat = snackNutrition.totalFat
        }
        
        NetworkLogger.shared.log("🧮 Calculated nutrition for all meals: totalCalories=\(mealsData.totalCalories), totalProtein=\(mealsData.totalProtein)", level: .info, category: .journal)
    }
    
    private func calculateNutritionFromDescription(_ description: String) -> CalculatedNutrition {
        let foodWords = description.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let detectedFoods = parseFoodItems(from: foodWords)
        
        if !detectedFoods.isEmpty {
            return calculateNutrition(for: detectedFoods)
        }
        
        return CalculatedNutrition(detectedFoods: [], totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFiber: 0, totalFat: 0)
    }
    
    private func parseFoodItems(from words: [String]) -> [String] {
        var detectedFoods: [String] = []
        
        for word in words {
            if word.count > 2 { // Only consider words with 3+ characters
                let matchingFoods = FoodDatabase.shared.allFoods.filter { food in
                    food.name.lowercased().contains(word) ||
                    food.category.lowercased().contains(word)
                }
                
                if !matchingFoods.isEmpty {
                    detectedFoods.append(matchingFoods.first!.name)
                }
            }
        }
        
        return Array(Set(detectedFoods)) // Remove duplicates
    }
    
    private func calculateNutrition(for foods: [String]) -> CalculatedNutrition {
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        for foodName in foods {
            if let food = FoodDatabase.shared.allFoods.first(where: { $0.name.lowercased() == foodName.lowercased() }) {
                // Validate values before calculation to prevent NaN
                let calories = food.calories.isFinite ? food.calories : 0
                let protein = food.protein.isFinite ? food.protein : 0
                let carbs = food.carbs.isFinite ? food.carbs : 0
                let fiber = food.fiber.isFinite ? food.fiber : 0
                let fat = food.fat.isFinite ? food.fat : 0
                
                // Teen portion size (1.5x normal serving)
                totalCalories += calories * 1.5
                totalProtein += protein * 1.5
                totalCarbs += carbs * 1.5
                totalFiber += fiber * 1.5
                totalFat += fat * 1.5
            }
        }
        
        // Final validation to ensure no NaN values
        return CalculatedNutrition(
            detectedFoods: foods,
            totalCalories: totalCalories.isFinite ? totalCalories : 0,
            totalProtein: totalProtein.isFinite ? totalProtein : 0,
            totalCarbs: totalCarbs.isFinite ? totalCarbs : 0,
            totalFiber: totalFiber.isFinite ? totalFiber : 0,
            totalFat: totalFat.isFinite ? totalFat : 0
        )
    }
}

struct EntryTypeCard: View {
    let entryType: EntryType
    let isSelected: Bool
    let hasData: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: entryType.icon)
                        .font(.system(size: 32))
                        .foregroundColor(entryType.color)
                    
                    Spacer()
                    
                    if hasData {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }
                
                Text(entryType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hasData ? Color.green : entryType.color.opacity(0.3), lineWidth: hasData ? 3 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Form Data Structures
struct MealsFormData {
    var mealType = "Breakfast"
    var breakfastDescription = ""
    var lunchDescription = ""
    var dinnerDescription = ""
    var snackDescription = ""
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fiber: Double = 0
    var fat: Double = 0
    var notes = ""
    
    var foodDescription: String {
        get {
            let result: String
            switch mealType {
            case "Breakfast": result = breakfastDescription
            case "Lunch": result = lunchDescription
            case "Dinner": result = dinnerDescription
            case "Snack": result = snackDescription
            default: result = breakfastDescription
            }
            return result
        }
        set {
            switch mealType {
            case "Breakfast": breakfastDescription = newValue
            case "Lunch": lunchDescription = newValue
            case "Dinner": dinnerDescription = newValue
            case "Snack": snackDescription = newValue
            default: breakfastDescription = newValue
            }
        }
    }
    
    // Computed properties for cumulative nutrition across all meals
    var totalCalories: Double {
        return breakfastCalories + lunchCalories + dinnerCalories + snackCalories
    }
    
    var totalProtein: Double {
        return breakfastProtein + lunchProtein + dinnerProtein + snackProtein
    }
    
    var totalCarbs: Double {
        return breakfastCarbs + lunchCarbs + dinnerCarbs + snackCarbs
    }
    
    var totalFiber: Double {
        return breakfastFiber + lunchFiber + dinnerFiber + snackFiber
    }
    
    var totalFat: Double {
        return breakfastFat + lunchFat + dinnerFat + snackFat
    }
    
    // Individual meal nutrition (these will be calculated based on food descriptions)
    var breakfastCalories: Double = 0
    var breakfastProtein: Double = 0
    var breakfastCarbs: Double = 0
    var breakfastFiber: Double = 0
    var breakfastFat: Double = 0
    
    var lunchCalories: Double = 0
    var lunchProtein: Double = 0
    var lunchCarbs: Double = 0
    var lunchFiber: Double = 0
    var lunchFat: Double = 0
    
    var dinnerCalories: Double = 0
    var dinnerProtein: Double = 0
    var dinnerCarbs: Double = 0
    var dinnerFiber: Double = 0
    var dinnerFat: Double = 0
    
    var snackCalories: Double = 0
    var snackProtein: Double = 0
    var snackCarbs: Double = 0
    var snackFiber: Double = 0
    var snackFat: Double = 0
    
    func toDictionary() -> [String: Any] {
        return [
            "meal_type": mealType,
            "food_description": foodDescription,
            "calories": totalCalories,
            "protein": totalProtein,
            "carbs": totalCarbs,
            "fiber": totalFiber,
            "fat": totalFat,
            "notes": notes,
            // Meal descriptions for each meal type
            "breakfast": breakfastDescription,
            "lunch": lunchDescription,
            "dinner": dinnerDescription,
            "snacks": snackDescription,
            // Individual meal nutrition for detailed tracking
            "breakfast_calories": breakfastCalories,
            "breakfast_protein": breakfastProtein,
            "breakfast_carbs": breakfastCarbs,
            "breakfast_fiber": breakfastFiber,
            "breakfast_fat": breakfastFat,
            "lunch_calories": lunchCalories,
            "lunch_protein": lunchProtein,
            "lunch_carbs": lunchCarbs,
            "lunch_fiber": lunchFiber,
            "lunch_fat": lunchFat,
            "dinner_calories": dinnerCalories,
            "dinner_protein": dinnerProtein,
            "dinner_carbs": dinnerCarbs,
            "dinner_fiber": dinnerFiber,
            "dinner_fat": dinnerFat,
            "snack_calories": snackCalories,
            "snack_protein": snackProtein,
            "snack_carbs": snackCarbs,
            "snack_fiber": snackFiber,
            "snack_fat": snackFat
        ]
    }
}

struct BowelHealthFormData {
    var frequency: Int = 0
    var bristolScale: Int = 4
    var bloodPresent = false
    var mucusPresent = false
    var urgency: Int = 0
    var painLevel: Int = 0
    var painLocation: String = "None"
    var painTime: String = "None"
    var notes = ""
    
    // Available pain locations (server constraints)
    static let painLocations = ["None", "full_abdomen", "lower_abdomen", "upper_abdomen"]
    
    // Available pain times (server constraints)
    static let painTimes = ["None", "morning", "afternoon", "evening", "night", "variable"]
    
    // Validate bristol scale (1-7 constraint)
    var validatedBristolScale: Int {
        return max(1, min(7, bristolScale))
    }
    
    // Validate pain location
    var validatedPainLocation: String {
        return Self.painLocations.contains(painLocation) ? painLocation : "None"
    }
    
    // Validate pain time
    var validatedPainTime: String {
        return Self.painTimes.contains(painTime) ? painTime : "None"
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "bowel_frequency": frequency,
            "bristol_scale": validatedBristolScale,
            "blood_present": bloodPresent,
            "mucus_present": mucusPresent,
            "urgency_level": urgency,
            "pain_severity": painLevel,
            "pain_location": validatedPainLocation,
            "pain_time": validatedPainTime,
            "notes": notes
        ]
    }
}

struct MedicationFormData {
    var medicationType = "None"
    var dosageLevel = "0"
    var taken = true
    var notes = ""
    
    // Available medication types
    static let medicationTypes = ["None", "biologic", "immunosuppressant", "steroid"]
    
    // Available dosage levels by medication type
    static let biologicDosages = ["every_2_weeks", "every_4_weeks", "every_8_weeks"]
    static let immunosuppressantDosages = ["daily", "twice_daily", "weekly"]
    static let steroidDosages = ["5", "10", "20"]
    
    // Get available dosage levels for current medication type
    var availableDosageLevels: [String] {
        switch medicationType {
        case "biologic":
            return Self.biologicDosages
        case "immunosuppressant":
            return Self.immunosuppressantDosages
        case "steroid":
            return Self.steroidDosages
        default:
            return ["0"]
        }
    }
    
    // Validate and get correct dosage level
    var validatedDosageLevel: String {
        if medicationType == "None" {
            return "0"
        }
        
        let availableLevels = availableDosageLevels
        if availableLevels.contains(dosageLevel) {
            return dosageLevel
        } else {
            // Return first available dosage as default
            return availableLevels.first ?? "0"
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "medication_taken": taken,
            "medication_type": medicationType,
            "dosage_level": validatedDosageLevel,
            "notes": notes
        ]
    }
}

struct StressFormData {
    var stressLevel: Int = 5
    var stressSource = ""
    var copingStrategies = ""
    var mood: Int = 5
    var notes = ""
    
    // Validate stress level (0-10 constraint)
    var validatedStressLevel: Int {
        return max(0, min(10, stressLevel))
    }
    
    // Validate mood level (0-10 constraint)
    var validatedMoodLevel: Int {
        return max(0, min(10, mood))
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "stress_level": validatedStressLevel,
            "stress_source": stressSource,
            "coping_strategies": copingStrategies,
            "mood_level": validatedMoodLevel,
            "notes": notes
        ]
    }
}

struct SleepFormData {
    var sleepHours: Double = 8.0
    var sleepQuality: Int = 5
    var bedtime = Date()
    var wakeTime = Date()
    var sleepInterruptions = 0
    var notes = ""
    
    // Validate sleep hours (0-24 constraint)
    var validatedSleepHours: Double {
        return max(0, min(24, sleepHours))
    }
    
    // Validate sleep quality (0-10 constraint)
    var validatedSleepQuality: Int {
        return max(0, min(10, sleepQuality))
    }
    
    // Validate sleep interruptions (non-negative)
    var validatedSleepInterruptions: Int {
        return max(0, sleepInterruptions)
    }
    
    func toDictionary() -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return [
            "sleep_hours": validatedSleepHours,
            "sleep_quality": validatedSleepQuality,
            "bedtime": formatter.string(from: bedtime),
            "wake_time": formatter.string(from: wakeTime),
            "sleep_interruptions": validatedSleepInterruptions,
            "notes": notes
        ]
    }
}

struct HydrationFormData {
    var waterIntake: Double = 0
    var otherFluids: Double = 0
    var fluidType = "Water"
    var hydrationLevel: Int = 5
    var notes = ""
    
    // Validate water intake (non-negative)
    var validatedWaterIntake: Double {
        return max(0, waterIntake)
    }
    
    // Validate other fluids (non-negative)
    var validatedOtherFluids: Double {
        return max(0, otherFluids)
    }
    
    // Validate hydration level (0-10 constraint)
    var validatedHydrationLevel: Int {
        return max(0, min(10, hydrationLevel))
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "water_intake": validatedWaterIntake,
            "other_fluids": validatedOtherFluids,
            "fluid_type": fluidType,
            "hydration_level": validatedHydrationLevel,
            "notes": notes
        ]
    }
}

// Form Views
struct MealsFormView: View {
    @Binding var data: MealsFormData
    @StateObject private var foodDatabase = FoodDatabase.shared
    @State private var isNutritionLocked = false
    @State private var autoCalculatedNutrition: CalculatedNutrition?
    @State private var showingAutoCalculation = false
    @State private var currentFoodDescription = ""
    @State private var previousMealType = "Breakfast"
    
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    init(data: Binding<MealsFormData>) {
        self._data = data
        NetworkLogger.shared.log("🍽️ FORM: MealsFormView initialized with mealType='\(data.wrappedValue.mealType)', breakfast='\(data.wrappedValue.breakfastDescription)', lunch='\(data.wrappedValue.lunchDescription)', dinner='\(data.wrappedValue.dinnerDescription)', snack='\(data.wrappedValue.snackDescription)'", level: .info, category: .journal)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.headline)
                    
                    Picker("Meal Type", selection: $data.mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: data.mealType) { oldValue, newMealType in
                        NetworkLogger.shared.log("🍽️ FORM: Meal type changed from '\(oldValue)' to '\(newMealType)'", level: .info, category: .journal)
                        
                        // Save current text to the previous meal type BEFORE switching
                        saveCurrentTextToMealType(previousMealType)
                        
                        // Update previous meal type
                        previousMealType = newMealType
                        
                        // Load text for the new meal type by directly accessing the stored value
                        let newText = getStoredTextForMealType(newMealType)
                        NetworkLogger.shared.log("🍽️ FORM: Loading text for '\(newMealType)': '\(newText)'", level: .info, category: .journal)
                        currentFoodDescription = newText
                        
                        // Clear auto-calculation results for fresh calculation
                        autoCalculatedNutrition = nil
                        showingAutoCalculation = false
                        
                        // Trigger nutrition calculation for the new meal type if there's text
                        if !newText.isEmpty {
                            performAutoCalculation()
                        }
                    }
                }
                .onChange(of: data.breakfastDescription) { _, _ in
                    // Update currentFoodDescription if we're on breakfast and the data changed
                    if data.mealType == "Breakfast" {
                        NetworkLogger.shared.log("🍽️ FORM: Breakfast description changed to '\(data.breakfastDescription)', updating currentFoodDescription", level: .info, category: .journal)
                        currentFoodDescription = data.breakfastDescription
                    }
                }
                .onChange(of: data.lunchDescription) { _, _ in
                    // Update currentFoodDescription if we're on lunch and the data changed
                    if data.mealType == "Lunch" {
                        NetworkLogger.shared.log("🍽️ FORM: Lunch description changed to '\(data.lunchDescription)', updating currentFoodDescription", level: .info, category: .journal)
                        currentFoodDescription = data.lunchDescription
                    }
                }
                .onChange(of: data.dinnerDescription) { _, _ in
                    // Update currentFoodDescription if we're on dinner and the data changed
                    if data.mealType == "Dinner" {
                        NetworkLogger.shared.log("🍽️ FORM: Dinner description changed to '\(data.dinnerDescription)', updating currentFoodDescription", level: .info, category: .journal)
                        currentFoodDescription = data.dinnerDescription
                    }
                }
                .onChange(of: data.snackDescription) { _, _ in
                    // Update currentFoodDescription if we're on snack and the data changed
                    if data.mealType == "Snack" {
                        NetworkLogger.shared.log("🍽️ FORM: Snack description changed to '\(data.snackDescription)', updating currentFoodDescription", level: .info, category: .journal)
                        currentFoodDescription = data.snackDescription
                    }
                }
                
                // Food Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your meal")
                        .font(.headline)
                    
                    TextField("Describe your meal (e.g., chicken pasta, eggs toast)...", text: $currentFoodDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .onChange(of: currentFoodDescription) { oldValue, newValue in
                            data.foodDescription = newValue
                            performAutoCalculation()
                        }
                        .onAppear {
                            // Initialize with the current meal type's description
                            let initialText = getStoredTextForMealType(data.mealType)
                            NetworkLogger.shared.log("🍽️ FORM: onAppear - Initializing currentFoodDescription with '\(initialText)' for meal type '\(data.mealType)'", level: .info, category: .journal)
                            currentFoodDescription = initialText
                        }

                    
                    // Auto-calculated Nutrition Results
                    if let nutrition = autoCalculatedNutrition, showingAutoCalculation {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Auto-calculated Nutrition")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button("Apply") {
                                    applyAutoCalculatedNutrition(nutrition)
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                                
                                Button("Hide") {
                                    showingAutoCalculation = false
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Foods detected:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                ForEach(nutrition.detectedFoods, id: \.self) { food in
                                    HStack {
                                        Text("• \(food)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                AutoNutritionCard(title: "Calories", value: "\(Int(nutrition.totalCalories))", unit: "kcal", color: .green)
                                AutoNutritionCard(title: "Protein", value: String(format: "%.1f", nutrition.totalProtein), unit: "g", color: .blue)
                                AutoNutritionCard(title: "Carbs", value: String(format: "%.1f", nutrition.totalCarbs), unit: "g", color: .orange)
                                AutoNutritionCard(title: "Fat", value: String(format: "%.1f", nutrition.totalFat), unit: "g", color: .red)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Nutrition Information
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Nutrition Information")
                            .font(.headline)
                        
                        Spacer()
                        
                        if autoCalculatedNutrition != nil {
                            Button(isNutritionLocked ? "Unlock" : "Lock") {
                                isNutritionLocked.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(isNutritionLocked ? .red : .green)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        NutritionInputField(title: "Total Calories", value: Binding(
                            get: { data.totalCalories },
                            set: { _ in } // Read-only for cumulative totals
                        ), unit: "kcal", isLocked: true)
                        NutritionInputField(title: "Total Protein", value: Binding(
                            get: { data.totalProtein },
                            set: { _ in } // Read-only for cumulative totals
                        ), unit: "g", isLocked: true)
                        NutritionInputField(title: "Total Carbs", value: Binding(
                            get: { data.totalCarbs },
                            set: { _ in } // Read-only for cumulative totals
                        ), unit: "g", isLocked: true)
                        NutritionInputField(title: "Total Fiber", value: Binding(
                            get: { data.totalFiber },
                            set: { _ in } // Read-only for cumulative totals
                        ), unit: "g", isLocked: true)
                        NutritionInputField(title: "Total Fat", value: Binding(
                            get: { data.totalFat },
                            set: { _ in } // Read-only for cumulative totals
                        ), unit: "g", isLocked: true)
                    }
                }
                
                // Daily Nutrition Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Nutrition Summary")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Calories")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(data.totalCalories))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Total Protein")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(data.totalProtein))g")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Total Carbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(data.totalCarbs))g")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Total Fiber")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(data.totalFiber))g")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        
                        HStack {
                            Text("Total Fat")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(data.totalFat))g")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }

        .onAppear {
            NetworkLogger.shared.log("🍽️ FORM: MealsFormView onAppear - mealType='\(data.mealType)', currentFoodDescription='\(currentFoodDescription)'", level: .info, category: .journal)
            
            previousMealType = data.mealType
            currentFoodDescription = data.foodDescription
            
            // Initialize currentFoodDescription with the current meal type's description
            let initialText = getStoredTextForMealType(data.mealType)
            NetworkLogger.shared.log("🍽️ FORM: onAppear - Setting currentFoodDescription to '\(initialText)' for meal type '\(data.mealType)'", level: .info, category: .journal)
            currentFoodDescription = initialText
            
            // If there's text, trigger auto-calculation
            if !currentFoodDescription.isEmpty {
                performAutoCalculation()
            }
        }
    }
    
    private func performAutoCalculation() {
        guard !currentFoodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            autoCalculatedNutrition = nil
            showingAutoCalculation = false
            return
        }
        
        // Parse food items from description
        let foodWords = currentFoodDescription.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let detectedFoods = parseFoodItems(from: foodWords)
        
        if !detectedFoods.isEmpty {
            autoCalculatedNutrition = calculateNutrition(for: detectedFoods)
            showingAutoCalculation = true
        }
    }
    
    private func parseFoodItems(from words: [String]) -> [String] {
        var detectedFoods: [String] = []
        
        for word in words {
            if word.count > 2 { // Only consider words with 3+ characters
                let matchingFoods = FoodDatabase.shared.allFoods.filter { food in
                    food.name.lowercased().contains(word) ||
                    food.category.lowercased().contains(word)
                }
                
                if !matchingFoods.isEmpty {
                    detectedFoods.append(matchingFoods.first!.name)
                }
            }
        }
        
        return Array(Set(detectedFoods)) // Remove duplicates
    }
    
    private func calculateNutrition(for foods: [String]) -> CalculatedNutrition {
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        for foodName in foods {
            if let food = FoodDatabase.shared.allFoods.first(where: { $0.name.lowercased() == foodName.lowercased() }) {
                // Validate values before calculation to prevent NaN
                let calories = food.calories.isFinite ? food.calories : 0
                let protein = food.protein.isFinite ? food.protein : 0
                let carbs = food.carbs.isFinite ? food.carbs : 0
                let fiber = food.fiber.isFinite ? food.fiber : 0
                let fat = food.fat.isFinite ? food.fat : 0
                
                // Teen portion size (1.5x normal serving)
                totalCalories += calories * 1.5
                totalProtein += protein * 1.5
                totalCarbs += carbs * 1.5
                totalFiber += fiber * 1.5
                totalFat += fat * 1.5
            }
        }
        
        // Final validation to ensure no NaN values
        return CalculatedNutrition(
            detectedFoods: foods,
            totalCalories: totalCalories.isFinite ? totalCalories : 0,
            totalProtein: totalProtein.isFinite ? totalProtein : 0,
            totalCarbs: totalCarbs.isFinite ? totalCarbs : 0,
            totalFiber: totalFiber.isFinite ? totalFiber : 0,
            totalFat: totalFat.isFinite ? totalFat : 0
        )
    }
    
    private func applyAutoCalculatedNutrition(_ nutrition: CalculatedNutrition) {
        // Update the nutrition for the current meal type
        switch data.mealType {
        case "Breakfast":
            data.breakfastCalories = nutrition.totalCalories.isFinite ? nutrition.totalCalories : 0
            data.breakfastProtein = nutrition.totalProtein.isFinite ? nutrition.totalProtein : 0
            data.breakfastCarbs = nutrition.totalCarbs.isFinite ? nutrition.totalCarbs : 0
            data.breakfastFiber = nutrition.totalFiber.isFinite ? nutrition.totalFiber : 0
            data.breakfastFat = nutrition.totalFat.isFinite ? nutrition.totalFat : 0
        case "Lunch":
            data.lunchCalories = nutrition.totalCalories.isFinite ? nutrition.totalCalories : 0
            data.lunchProtein = nutrition.totalProtein.isFinite ? nutrition.totalProtein : 0
            data.lunchCarbs = nutrition.totalCarbs.isFinite ? nutrition.totalCarbs : 0
            data.lunchFiber = nutrition.totalFiber.isFinite ? nutrition.totalFiber : 0
            data.lunchFat = nutrition.totalFat.isFinite ? nutrition.totalFat : 0
        case "Dinner":
            data.dinnerCalories = nutrition.totalCalories.isFinite ? nutrition.totalCalories : 0
            data.dinnerProtein = nutrition.totalProtein.isFinite ? nutrition.totalProtein : 0
            data.dinnerCarbs = nutrition.totalCarbs.isFinite ? nutrition.totalCarbs : 0
            data.dinnerFiber = nutrition.totalFiber.isFinite ? nutrition.totalFiber : 0
            data.dinnerFat = nutrition.totalFat.isFinite ? nutrition.totalFat : 0
        case "Snack":
            data.snackCalories = nutrition.totalCalories.isFinite ? nutrition.totalCalories : 0
            data.snackProtein = nutrition.totalProtein.isFinite ? nutrition.totalProtein : 0
            data.snackCarbs = nutrition.totalCarbs.isFinite ? nutrition.totalCarbs : 0
            data.snackFiber = nutrition.totalFiber.isFinite ? nutrition.totalFiber : 0
            data.snackFat = nutrition.totalFat.isFinite ? nutrition.totalFat : 0
        default:
            break
        }
        
        isNutritionLocked = true
        showingAutoCalculation = false
    }
    

    
    private func saveCurrentTextToMealType(_ mealType: String) {
        switch mealType {
        case "Breakfast": 
            data.breakfastDescription = currentFoodDescription
        case "Lunch": 
            data.lunchDescription = currentFoodDescription
        case "Dinner": 
            data.dinnerDescription = currentFoodDescription
        case "Snack": 
            data.snackDescription = currentFoodDescription
        default: 
            break
        }
    }
    
    private func clearCurrentMealNutrition() {
        // Clear nutrition for the current meal type only
        switch data.mealType {
        case "Breakfast":
            data.breakfastCalories = 0
            data.breakfastProtein = 0
            data.breakfastCarbs = 0
            data.breakfastFiber = 0
            data.breakfastFat = 0
        case "Lunch":
            data.lunchCalories = 0
            data.lunchProtein = 0
            data.lunchCarbs = 0
            data.lunchFiber = 0
            data.lunchFat = 0
        case "Dinner":
            data.dinnerCalories = 0
            data.dinnerProtein = 0
            data.dinnerCarbs = 0
            data.dinnerFiber = 0
            data.dinnerFat = 0
        case "Snack":
            data.snackCalories = 0
            data.snackProtein = 0
            data.snackCarbs = 0
            data.snackFiber = 0
            data.snackFat = 0
        default:
            break
        }
        isNutritionLocked = false
    }
    
    private func getStoredTextForMealType(_ mealType: String) -> String {
        let result: String
        switch mealType {
        case "Breakfast": 
            result = data.breakfastDescription
            NetworkLogger.shared.log("🍽️ GET_TEXT: Breakfast text = '\(result)'", level: .debug, category: .journal)
        case "Lunch": 
            result = data.lunchDescription
            NetworkLogger.shared.log("🍽️ GET_TEXT: Lunch text = '\(result)'", level: .debug, category: .journal)
        case "Dinner": 
            result = data.dinnerDescription
            NetworkLogger.shared.log("🍽️ GET_TEXT: Dinner text = '\(result)'", level: .debug, category: .journal)
        case "Snack": 
            result = data.snackDescription
            NetworkLogger.shared.log("🍽️ GET_TEXT: Snack text = '\(result)'", level: .debug, category: .journal)
        default: 
            result = data.breakfastDescription
            NetworkLogger.shared.log("🍽️ GET_TEXT: Default (breakfast) text = '\(result)'", level: .debug, category: .journal)
        }
        return result
    }
}

struct AutoNutritionCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Data Models

struct CalculatedNutrition {
    let detectedFoods: [String]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFiber: Double
    let totalFat: Double
}





struct BowelHealthFormView: View {
    @Binding var data: BowelHealthFormData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Frequency
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bowel Movements Today")
                        .font(.headline)
                    
                    Stepper("\(data.frequency) times", value: $data.frequency, in: 0...10)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Bristol Scale
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bristol Stool Scale")
                        .font(.headline)
                    
                    Picker("Bristol Scale", selection: $data.bristolScale) {
                        ForEach(1...7, id: \.self) { scale in
                            Text("Type \(scale)").tag(scale)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                
                // Symptoms
                VStack(alignment: .leading, spacing: 12) {
                    Text("Symptoms")
                        .font(.headline)
                    
                    Toggle("Blood Present", isOn: $data.bloodPresent)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Toggle("Mucus Present", isOn: $data.mucusPresent)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Pain and Urgency
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pain Level (0-10)")
                            .font(.headline)
                        
                        Slider(value: Binding(
                            get: { Double(data.painLevel) },
                            set: { data.painLevel = Int($0) }
                        ), in: 0...10, step: 1)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Text("\(data.painLevel)/10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pain Location")
                            .font(.headline)
                        
                        Picker("Pain Location", selection: $data.painLocation) {
                            ForEach(BowelHealthFormData.painLocations, id: \.self) { location in
                                Text(formatPainLocation(location)).tag(location)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pain Time")
                            .font(.headline)
                        
                        Picker("Pain Time", selection: $data.painTime) {
                            ForEach(BowelHealthFormData.painTimes, id: \.self) { time in
                                Text(formatPainTime(time)).tag(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Urgency Level (0-10)")
                            .font(.headline)
                        
                        Slider(value: Binding(
                            get: { Double(data.urgency) },
                            set: { data.urgency = Int($0) }
                        ), in: 0...10, step: 1)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Text("\(data.urgency)/10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }
    }
    
    private func formatPainLocation(_ location: String) -> String {
        switch location {
        case "full_abdomen": return "Full Abdomen"
        case "lower_abdomen": return "Lower Abdomen"
        case "upper_abdomen": return "Upper Abdomen"
        default: return location.capitalized
        }
    }
    
    private func formatPainTime(_ time: String) -> String {
        switch time {
        case "morning": return "Morning"
        case "afternoon": return "Afternoon"
        case "evening": return "Evening"
        case "night": return "Night"
        case "variable": return "Variable"
        default: return time.capitalized
        }
    }
}

struct MedicationFormView: View {
    @Binding var data: MedicationFormData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Medication Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medication Type")
                        .font(.headline)
                    
                    Picker("Medication Type", selection: $data.medicationType) {
                        ForEach(MedicationFormData.medicationTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Dosage Level (only show if medication type is not None)
                if data.medicationType != "None" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dosage/Frequency")
                            .font(.headline)
                        
                        Picker("Dosage Level", selection: $data.dosageLevel) {
                            ForEach(data.availableDosageLevels, id: \.self) { dosage in
                                Text(formatDosageDisplay(dosage)).tag(dosage)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Taken Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)
                    
                    Toggle("Medication Taken", isOn: $data.taken)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }
    }
    
    private func formatDosageDisplay(_ dosage: String) -> String {
        switch dosage {
        case "every_2_weeks": return "Every 2 Weeks"
        case "every_4_weeks": return "Every 4 Weeks"
        case "every_8_weeks": return "Every 8 Weeks"
        case "daily": return "Daily"
        case "twice_daily": return "Twice Daily"
        case "weekly": return "Weekly"
        case "5": return "5mg"
        case "10": return "10mg"
        case "20": return "20mg"
        default: return dosage
        }
    }
}

struct StressFormView: View {
    @Binding var data: StressFormData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stress Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stress Level (0-10)")
                        .font(.headline)
                    
                    Slider(value: Binding(
                        get: { Double(data.stressLevel) },
                        set: { data.stressLevel = Int($0) }
                    ), in: 0...10, step: 1)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("\(data.stressLevel)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Stress Source
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's causing stress?")
                        .font(.headline)
                    
                    TextField("Describe stress source...", text: $data.stressSource, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                // Coping Strategies
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coping Strategies")
                        .font(.headline)
                    
                    TextField("What helped you cope...", text: $data.copingStrategies, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                // Mood Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood Level (0-10)")
                        .font(.headline)
                    
                    Slider(value: Binding(
                        get: { Double(data.mood) },
                        set: { data.mood = Int($0) }
                    ), in: 0...10, step: 1)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("\(data.mood)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }
    }
}

struct SleepFormView: View {
    @Binding var data: SleepFormData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sleep Hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hours of Sleep")
                        .font(.headline)
                    
                    Stepper("\(String(format: "%.1f", data.sleepHours)) hours", value: $data.sleepHours, in: 0...24, step: 0.5)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Sleep Quality
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Quality (0-10)")
                        .font(.headline)
                    
                    Slider(value: Binding(
                        get: { Double(data.sleepQuality) },
                        set: { data.sleepQuality = Int($0) }
                    ), in: 0...10, step: 1)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("\(data.sleepQuality)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Bedtime and Wake Time
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bedtime")
                            .font(.headline)
                        
                        DatePicker("Bedtime", selection: $data.bedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wake Time")
                            .font(.headline)
                        
                        DatePicker("Wake Time", selection: $data.wakeTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .frame(height: 100)
                    }
                }
                
                // Sleep Interruptions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Interruptions")
                        .font(.headline)
                    
                    Stepper("\(data.sleepInterruptions) times", value: $data.sleepInterruptions, in: 0...10)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }
    }
}

struct HydrationFormView: View {
    @Binding var data: HydrationFormData
    
    private let fluidTypes = ["Water", "Tea", "Coffee", "Juice", "Sports Drink", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Water Intake
                VStack(alignment: .leading, spacing: 8) {
                    Text("Water Intake (liters)")
                        .font(.headline)
                    
                    Stepper("\(String(format: "%.1f", data.waterIntake)) L", value: $data.waterIntake, in: 0...10, step: 0.1)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Other Fluids
                VStack(alignment: .leading, spacing: 8) {
                    Text("Other Fluids (liters)")
                        .font(.headline)
                    
                    Stepper("\(String(format: "%.1f", data.otherFluids)) L", value: $data.otherFluids, in: 0...5, step: 0.1)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Fluid Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Fluid Type")
                        .font(.headline)
                    
                    Picker("Fluid Type", selection: $data.fluidType) {
                        ForEach(fluidTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                
                // Hydration Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hydration Level (0-10)")
                        .font(.headline)
                    
                    Slider(value: Binding(
                        get: { Double(data.hydrationLevel) },
                        set: { data.hydrationLevel = Int($0) }
                    ), in: 0...10, step: 1)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Text("\(data.hydrationLevel)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
            .padding()
        }
    }
}

struct NutritionInputField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let isLocked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("0", value: $value, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .disabled(isLocked)
                    .opacity(isLocked ? 0.6 : 1.0)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Keep existing LogEntry and related structures
struct LogEntry: Identifiable, Codable {
    let id: Int
    let entryDate: String
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fiber: Double?
    let fat: Double?
    let painSeverity: Int?
    let painLocation: String?
    let painTime: String?
    let bowelFrequency: Int?
    let bristolScale: Int?
    let urgencyLevel: Int?
    let bloodPresent: Bool?
    let mucusPresent: Bool?
    let medicationTaken: Bool?
    let medicationType: String?
    let dosageLevel: String?
    let sleepHours: Double?
    let sleepQuality: Int?
    let stressLevel: Int?
    let stressSource: String?
    let copingStrategies: String?
    let moodLevel: Int?
    let waterIntake: Double?
    let otherFluids: Double?
    let fluidType: String?
    let hydrationLevel: Int?
    let hasAllergens: Bool?
    let mealsPerDay: Int?
    let menstruation: String?
    let fatigueLevel: Int?
    let notes: String?
    
    // Meal data
    let breakfast: String?
    let lunch: String?
    let dinner: String?
    let snacks: String?
    let breakfastCalories: String?
    let breakfastProtein: String?
    let breakfastCarbs: String?
    let breakfastFiber: String?
    let breakfastFat: String?
    let lunchCalories: String?
    let lunchProtein: String?
    let lunchCarbs: String?
    let lunchFiber: String?
    let lunchFat: String?
    let dinnerCalories: String?
    let dinnerProtein: String?
    let dinnerCarbs: String?
    let dinnerFiber: String?
    let dinnerFat: String?
    let snackCalories: String?
    let snackProtein: String?
    let snackCarbs: String?
    let snackFiber: String?
    let snackFat: String?
    
    // Helper function to parse nutrition values to string
    private static func parseNutritionValueToString(_ value: Any?) -> String? {
        if let intValue = value as? Int {
            return String(intValue)
        } else if let stringValue = value as? String {
            return stringValue
        } else if let doubleValue = value as? Double {
            return String(Int(doubleValue))
        }
        return nil
    }
    
    init(from dict: [String: Any]) {
        id = dict["entry_id"] as? Int ?? 0  // Use entry_id instead of id
        entryDate = dict["entry_date"] as? String ?? ""
        calories = dict["calories"] as? Double
        protein = dict["protein"] as? Double
        carbs = dict["carbs"] as? Double
        fiber = dict["fiber"] as? Double
        fat = dict["fat"] as? Double
        painSeverity = dict["pain_severity"] as? Int
        painLocation = dict["pain_location"] as? String
        painTime = dict["pain_time"] as? String
        bowelFrequency = dict["bowel_frequency"] as? Int
        bristolScale = dict["bristol_scale"] as? Int
        urgencyLevel = dict["urgency_level"] as? Int
        bloodPresent = dict["blood_present"] as? Bool
        mucusPresent = dict["mucus_present"] as? Bool
        medicationTaken = dict["medication_taken"] as? Bool
        medicationType = dict["medication_type"] as? String
        dosageLevel = dict["dosage_level"] as? String
        sleepHours = dict["sleep_hours"] as? Double
        sleepQuality = dict["sleep_quality"] as? Int
        stressLevel = dict["stress_level"] as? Int
        stressSource = dict["stress_source"] as? String
        copingStrategies = dict["coping_strategies"] as? String
        moodLevel = dict["mood_level"] as? Int
        waterIntake = dict["water_intake"] as? Double
        otherFluids = dict["other_fluids"] as? Double
        fluidType = dict["fluid_type"] as? String
        hydrationLevel = dict["hydration_level"] as? Int
        hasAllergens = dict["has_allergens"] as? Bool
        mealsPerDay = dict["meals_per_day"] as? Int
        menstruation = dict["menstruation"] as? String
        fatigueLevel = dict["fatigue_level"] as? Int
        notes = dict["notes"] as? String
        
        // Meal data - handle both string and integer types for nutrition
        breakfast = dict["breakfast"] as? String
        lunch = dict["lunch"] as? String
        dinner = dict["dinner"] as? String
        snacks = dict["snacks"] as? String
        
        // Parse nutrition values that can be either strings or integers
        breakfastCalories = LogEntry.parseNutritionValueToString(dict["breakfast_calories"])
        breakfastProtein = LogEntry.parseNutritionValueToString(dict["breakfast_protein"])
        breakfastCarbs = LogEntry.parseNutritionValueToString(dict["breakfast_carbs"])
        breakfastFiber = LogEntry.parseNutritionValueToString(dict["breakfast_fiber"])
        breakfastFat = LogEntry.parseNutritionValueToString(dict["breakfast_fat"])
        lunchCalories = LogEntry.parseNutritionValueToString(dict["lunch_calories"])
        lunchProtein = LogEntry.parseNutritionValueToString(dict["lunch_protein"])
        lunchCarbs = LogEntry.parseNutritionValueToString(dict["lunch_carbs"])
        lunchFiber = LogEntry.parseNutritionValueToString(dict["lunch_fiber"])
        lunchFat = LogEntry.parseNutritionValueToString(dict["lunch_fat"])
        dinnerCalories = LogEntry.parseNutritionValueToString(dict["dinner_calories"])
        dinnerProtein = LogEntry.parseNutritionValueToString(dict["dinner_protein"])
        dinnerCarbs = LogEntry.parseNutritionValueToString(dict["dinner_carbs"])
        dinnerFiber = LogEntry.parseNutritionValueToString(dict["dinner_fiber"])
        dinnerFat = LogEntry.parseNutritionValueToString(dict["dinner_fat"])
        snackCalories = LogEntry.parseNutritionValueToString(dict["snack_calories"])
        snackProtein = LogEntry.parseNutritionValueToString(dict["snack_protein"])
        snackCarbs = LogEntry.parseNutritionValueToString(dict["snack_carbs"])
        snackFiber = LogEntry.parseNutritionValueToString(dict["snack_fiber"])
        snackFat = LogEntry.parseNutritionValueToString(dict["snack_fat"])
    }
}

struct LogEntryCard: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(timeString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if hasNutritionData {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.green)
                }
                
                if hasPainData {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                
                if hasBowelData {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.orange)
                }
            }
            
            if hasNutritionData {
                NutritionSection(entry: entry)
            }
            
            if hasPainData {
                PainSection(entry: entry)
            }
            
            if hasBowelData {
                BowelSection(entry: entry)
            }
            
            if hasLifestyleData {
                LifestyleSection(entry: entry)
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        // Try ISO8601 format first
        if let date = ISO8601DateFormatter().date(from: entry.entryDate) {
            return formatter.string(from: date)
        }
        
        // Try alternative date formats
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = dateFormatter.date(from: entry.entryDate) {
            return formatter.string(from: date)
        }
        
        // Try simple date format
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: entry.entryDate) {
            return formatter.string(from: date)
        }
        
        // Fallback to showing the date string as is
        return entry.entryDate.isEmpty ? "Unknown time" : entry.entryDate
    }
    
    private var hasNutritionData: Bool {
        return (entry.calories ?? 0) > 0 || 
               (entry.protein ?? 0) > 0 || 
               (entry.carbs ?? 0) > 0 || 
               (entry.fiber ?? 0) > 0 ||
               (entry.breakfast?.isEmpty == false) ||
               (entry.lunch?.isEmpty == false) ||
               (entry.dinner?.isEmpty == false) ||
               (entry.snacks?.isEmpty == false) ||
               (entry.breakfastCalories?.isEmpty == false) ||
               (entry.lunchCalories?.isEmpty == false) ||
               (entry.dinnerCalories?.isEmpty == false) ||
               (entry.snackCalories?.isEmpty == false)
    }
    
    private var hasPainData: Bool {
        return (entry.painSeverity ?? 0) > 0 || 
               (entry.painLocation?.isEmpty == false && entry.painLocation != "None") ||
               (entry.painTime?.isEmpty == false && entry.painTime != "None")
    }
    
    private var hasBowelData: Bool {
        return (entry.bowelFrequency ?? 0) > 0 || (entry.bristolScale ?? 0) > 0 || (entry.bloodPresent == true)
    }
    
    private var hasLifestyleData: Bool {
        return (entry.sleepHours ?? 0) > 0 || (entry.stressLevel ?? 0) > 0 || (entry.fatigueLevel ?? 0) > 0 || (entry.medicationTaken == true)
    }
}

struct NutritionSection: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            HStack {
                if let calories = entry.calories, calories > 0 {
                    NutritionItem(label: "Calories", value: "\(Int(calories))")
                }
                
                if let protein = entry.protein, protein > 0 {
                    NutritionItem(label: "Protein", value: "\(Int(protein))g")
                }
                
                if let carbs = entry.carbs, carbs > 0 {
                    NutritionItem(label: "Carbs", value: "\(Int(carbs))g")
                }
                
                if let fiber = entry.fiber, fiber > 0 {
                    NutritionItem(label: "Fiber", value: "\(Int(fiber))g")
                }
            }
        }
    }
}

struct PainSection: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pain")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            HStack {
                if let severity = entry.painSeverity, severity > 0 {
                    Text("Severity: \(severity)/10")
                        .font(.caption)
                }
                
                if let location = entry.painLocation, location != "None" {
                    Text("Location: \(location.toDisplayText())")
                        .font(.caption)
                }
                
                if let time = entry.painTime, time != "None" {
                    Text("Time: \(time.toDisplayText())")
                        .font(.caption)
                }
            }
        }
    }
}

struct BowelSection: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bowel Health")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            HStack {
                if let frequency = entry.bowelFrequency, frequency > 0 {
                    Text("Frequency: \(frequency)")
                        .font(.caption)
                }
                
                if let scale = entry.bristolScale, scale > 0 {
                    Text("Bristol Scale: \(scale) (\(scale.bristolScaleDescription()))")
                        .font(.caption)
                }
                
                if entry.bloodPresent == true {
                    Text("Blood Present")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct LifestyleSection: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lifestyle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            HStack {
                if let sleep = entry.sleepHours, sleep > 0 {
                    Text("Sleep: \(Int(sleep))h")
                        .font(.caption)
                }
                
                if let stress = entry.stressLevel, stress > 0 {
                    Text("Stress: \(stress)/10 (\(stress.stressLevelDescription()))")
                        .font(.caption)
                }
                
                if let fatigue = entry.fatigueLevel, fatigue > 0 {
                    Text("Fatigue: \(fatigue)/10 (\(fatigue.fatigueLevelDescription()))")
                        .font(.caption)
                }
                
                if entry.medicationTaken == true {
                    let medType = entry.medicationType?.toDisplayText() ?? "Taken"
                    Text("Medication: \(medType)")
                        .font(.caption)
                }
            }
        }
    }
}

struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(6)
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Done") {
                    onDateSelected()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DailyLogView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", token: "token"))
}

// MARK: - Lookup Value Mappings
struct LookupMappings {
    // Pain location mappings
    static let painLocations = [
        "None": "None",
        "full_abdomen": "Full Abdomen", 
        "lower_abdomen": "Lower Abdomen",
        "upper_abdomen": "Upper Abdomen"
    ]
    
    // Pain time mappings
    static let painTimes = [
        "None": "None",
        "morning": "Morning",
        "afternoon": "Afternoon", 
        "evening": "Evening",
        "night": "Night",
        "variable": "Variable"
    ]
    
    // Medication type mappings
    static let medicationTypes = [
        "None": "None",
        "biologic": "Biologic",
        "immunosuppressant": "Immunosuppressant",
        "steroid": "Steroid"
    ]
    
    // Dosage level mappings for different medication types
    static let biologicDosages = [
        "every_2_weeks": "Every 2 Weeks",
        "every_4_weeks": "Every 4 Weeks", 
        "every_8_weeks": "Every 8 Weeks"
    ]
    
    static let immunosuppressantDosages = [
        "daily": "Daily",
        "twice_daily": "Twice Daily",
        "weekly": "Weekly"
    ]
    
    static let steroidDosages = [
        "5": "5mg",
        "10": "10mg",
        "20": "20mg"
    ]
    
    // Bristol scale mappings (1-7)
    static let bristolScaleDescriptions = [
        1: "Separate hard lumps",
        2: "Sausage-like but lumpy", 
        3: "Sausage-like with cracks",
        4: "Smooth and soft",
        5: "Soft blobs with clear edges",
        6: "Mushy consistency",
        7: "Entirely liquid"
    ]
    
    // Stress level descriptions (1-10)
    static let stressLevelDescriptions = [
        1: "Very Low",
        2: "Low",
        3: "Mild",
        4: "Moderate",
        5: "Average",
        6: "Elevated", 
        7: "High",
        8: "Very High",
        9: "Extreme",
        10: "Critical"
    ]
    
    // Fatigue level descriptions (1-10)
    static let fatigueLevelDescriptions = [
        1: "Very Energetic",
        2: "Energetic",
        3: "Slightly Energetic",
        4: "Normal",
        5: "Slightly Tired",
        6: "Tired",
        7: "Very Tired",
        8: "Exhausted",
        9: "Very Exhausted",
        10: "Completely Exhausted"
    ]
}

// MARK: - Helper Extensions
extension String {
    func toDisplayText() -> String {
        // Handle pain location
        if let display = LookupMappings.painLocations[self] {
            return display
        }
        // Handle pain time
        if let display = LookupMappings.painTimes[self] {
            return display
        }
        // Handle medication type
        if let display = LookupMappings.medicationTypes[self] {
            return display
        }
        // Default to capitalized version
        return self.capitalized
    }
}

extension Int {
    func bristolScaleDescription() -> String {
        return LookupMappings.bristolScaleDescriptions[self] ?? "Unknown"
    }
    
    func stressLevelDescription() -> String {
        return LookupMappings.stressLevelDescriptions[self] ?? "Unknown"
    }
    
    func fatigueLevelDescription() -> String {
        return LookupMappings.fatigueLevelDescriptions[self] ?? "Unknown"
    }
} 