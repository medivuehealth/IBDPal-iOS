import SwiftUI

struct DailyLogView: View {
    let userData: UserData?
    
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var isLoading = false
    @State private var entries: [LogEntry] = []
    @State private var showingEntryForm = false
    @State private var selectedEntryType: EntryType = .meals
    
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
                            let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            let today = Date()
                            if nextDate <= today {
                                selectedDate = nextDate
                                loadEntries()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                        .disabled(Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
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
    @State private var dataLoaded = false
    
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
                        MealsFormView(data: $mealsData, dataLoaded: dataLoaded)
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
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .sheet(isPresented: $showingDebugLogs) {
            LogViewerView()
        }
        .onAppear {
            loadExistingEntry()
            
            // For medication form, also load previous medication data if it's today
            if entryType == .medication && Calendar.current.isDateInToday(selectedDate) {
                loadPreviousMedicationData()
            }
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
                
                // First try to parse from new structured format (meals array)
                if let mealsArray = entry["meals"] as? [[String: Any]], !mealsArray.isEmpty {
                    NetworkLogger.shared.log("🍽️ POPULATE: Found structured meals array with \(mealsArray.count) meals", level: .info, category: .journal)
                    
                    // Reset all meal data first
                    self.mealsData.breakfastDescription = ""
                    self.mealsData.lunchDescription = ""
                    self.mealsData.dinnerDescription = ""
                    self.mealsData.snackDescription = ""
                    
                    // Parse each meal from the structured array
                    for mealDict in mealsArray {
                        guard let mealType = mealDict["meal_type"] as? String,
                              let description = mealDict["description"] as? String else {
                            continue
                        }
                        
                        NetworkLogger.shared.log("🍽️ POPULATE: Processing meal: \(mealType) - \(description)", level: .debug, category: .journal)
                        
                        switch mealType.lowercased() {
                        case "breakfast":
                            self.mealsData.breakfastDescription = description
                            self.mealsData.breakfastCalories = mealDict["calories"] as? Double ?? 0
                            self.mealsData.breakfastProtein = mealDict["protein"] as? Double ?? 0
                            self.mealsData.breakfastCarbs = mealDict["carbs"] as? Double ?? 0
                            self.mealsData.breakfastFiber = mealDict["fiber"] as? Double ?? 0
                            self.mealsData.breakfastFat = mealDict["fat"] as? Double ?? 0
                            
                        case "lunch":
                            self.mealsData.lunchDescription = description
                            self.mealsData.lunchCalories = mealDict["calories"] as? Double ?? 0
                            self.mealsData.lunchProtein = mealDict["protein"] as? Double ?? 0
                            self.mealsData.lunchCarbs = mealDict["carbs"] as? Double ?? 0
                            self.mealsData.lunchFiber = mealDict["fiber"] as? Double ?? 0
                            self.mealsData.lunchFat = mealDict["fat"] as? Double ?? 0
                            
                        case "dinner":
                            self.mealsData.dinnerDescription = description
                            self.mealsData.dinnerCalories = mealDict["calories"] as? Double ?? 0
                            self.mealsData.dinnerProtein = mealDict["protein"] as? Double ?? 0
                            self.mealsData.dinnerCarbs = mealDict["carbs"] as? Double ?? 0
                            self.mealsData.dinnerFiber = mealDict["fiber"] as? Double ?? 0
                            self.mealsData.dinnerFat = mealDict["fat"] as? Double ?? 0
                            
                        case "snack":
                            self.mealsData.snackDescription = description
                            self.mealsData.snackCalories = mealDict["calories"] as? Double ?? 0
                            self.mealsData.snackProtein = mealDict["protein"] as? Double ?? 0
                            self.mealsData.snackCarbs = mealDict["carbs"] as? Double ?? 0
                            self.mealsData.snackFiber = mealDict["fiber"] as? Double ?? 0
                            self.mealsData.snackFat = mealDict["fat"] as? Double ?? 0
                            
                        default:
                            NetworkLogger.shared.log("🍽️ POPULATE: Unknown meal type: \(mealType)", level: .warning, category: .journal)
                        }
                    }
                } else {
                    // Fallback to old flat format
                    NetworkLogger.shared.log("🍽️ POPULATE: Using old flat format", level: .info, category: .journal)
                    
                    self.mealsData.breakfastDescription = entry["breakfast"] as? String ?? ""
                    self.mealsData.lunchDescription = entry["lunch"] as? String ?? ""
                    self.mealsData.dinnerDescription = entry["dinner"] as? String ?? ""
                    self.mealsData.snackDescription = entry["snacks"] as? String ?? ""
                    
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
                }
                
                self.mealsData.notes = entry["notes"] as? String ?? ""
                
                NetworkLogger.shared.log("🍽️ POPULATE: Set breakfast='\(self.mealsData.breakfastDescription)' (was: '\(originalBreakfast)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set lunch='\(self.mealsData.lunchDescription)' (was: '\(originalLunch)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set dinner='\(self.mealsData.dinnerDescription)' (was: '\(originalDinner)')", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Set snack='\(self.mealsData.snackDescription)' (was: '\(originalSnack)')", level: .info, category: .journal)
                
                NetworkLogger.shared.log("🍽️ POPULATE: Final meals data - breakfast='\(self.mealsData.breakfastDescription)', lunch='\(self.mealsData.lunchDescription)', dinner='\(self.mealsData.dinnerDescription)', snack='\(self.mealsData.snackDescription)'", level: .info, category: .journal)
                NetworkLogger.shared.log("🍽️ POPULATE: Total calories=\(self.mealsData.totalCalories)", level: .info, category: .journal)
                
                // Trigger nutrition calculation for all meal types that have descriptions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.calculateNutritionForAllMeals()
                }
                
                // Mark data as loaded
                self.dataLoaded = true
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
                self.medicationData.medicationType = entry["medication_type"] as? String ?? "None"
                
                // Parse dosage_level to separate dosage and frequency
                if let dosageLevel = entry["dosage_level"] as? String {
                    let (dosage, frequency) = MedicationFormData.fromDosageLevel(dosageLevel)
                    self.medicationData.dosage = dosage
                    self.medicationData.frequency = frequency
                    NetworkLogger.shared.log("💊 MEDICATION: Parsed dosage_level '\(dosageLevel)' to dosage='\(dosage)', frequency='\(frequency)'", level: .debug, category: .journal)
                } else {
                    self.medicationData.dosage = "0"
                    self.medicationData.frequency = "daily"
                }
                
                self.medicationData.notes = entry["notes"] as? String ?? ""
                
                // Load last taken date
                NetworkLogger.shared.log("💊 MEDICATION: Raw last_taken_date from database: \(entry["last_taken_date"] ?? "nil")", level: .debug, category: .journal)
                NetworkLogger.shared.log("💊 MEDICATION: Type of last_taken_date: \(type(of: entry["last_taken_date"]))", level: .debug, category: .journal)
                
                if let lastTakenDateString = entry["last_taken_date"] as? String {
                    NetworkLogger.shared.log("💊 MEDICATION: Parsing last_taken_date string: '\(lastTakenDateString)'", level: .debug, category: .journal)
                    
                    var lastTakenDate: Date?
                    
                    // Try multiple date formats
                    let dateFormats = [
                        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",  // 2025-08-18T00:00:00.000Z
                        "yyyy-MM-dd'T'HH:mm:ss'Z'",      // 2025-08-18T00:00:00Z
                        "yyyy-MM-dd'T'HH:mm:ss",         // 2025-08-18T00:00:00
                        "yyyy-MM-dd"                     // 2025-08-18
                    ]
                    
                    // For dates like "2025-08-18T00:00:00.000Z", extract just the date part "2025-08-18"
                    if lastTakenDateString.contains("T") {
                        let dateOnlyString = String(lastTakenDateString.prefix(10)) // Take first 10 characters: "2025-08-18"
                        NetworkLogger.shared.log("💊 MEDICATION: Extracted date part: '\(dateOnlyString)' from '\(lastTakenDateString)'", level: .debug, category: .journal)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        dateFormatter.timeZone = TimeZone.current // Use local timezone for display
                        
                        if let parsedDate = dateFormatter.date(from: dateOnlyString) {
                            lastTakenDate = parsedDate
                            NetworkLogger.shared.log("💊 MEDICATION: Successfully parsed date part: '\(dateOnlyString)' -> \(parsedDate)", level: .debug, category: .journal)
                        }
                    } else {
                        // Try multiple date formats for other formats
                        for format in dateFormats {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = format
                            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                            
                            if let parsedDate = dateFormatter.date(from: lastTakenDateString) {
                                // Extract just the date part to avoid timezone issues
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                                lastTakenDate = calendar.date(from: components)
                                
                                NetworkLogger.shared.log("💊 MEDICATION: Successfully parsed date using format '\(format)'", level: .debug, category: .journal)
                                NetworkLogger.shared.log("💊 MEDICATION: Original: \(parsedDate), Date only: \(lastTakenDate ?? parsedDate)", level: .debug, category: .journal)
                                break
                            }
                        }
                    }
                    
                    if let parsedDate = lastTakenDate {
                        self.medicationData.lastTakenDate = parsedDate
                        NetworkLogger.shared.log("💊 MEDICATION: Successfully loaded last_taken_date '\(lastTakenDateString)' -> \(parsedDate) for \(self.medicationData.medicationType)", level: .debug, category: .journal)
                    } else {
                        NetworkLogger.shared.log("💊 MEDICATION: Failed to parse date from '\(lastTakenDateString)'", level: .error, category: .journal)
                    }
                } else {
                    // Only set to today's date if there's no existing medication data
                    // If medication type is "None", don't set a default date
                    if self.medicationData.medicationType != "None" {
                        self.medicationData.lastTakenDate = Date()
                        NetworkLogger.shared.log("💊 MEDICATION: No last_taken_date found, setting to today for new medication", level: .debug, category: .journal)
                    } else {
                        NetworkLogger.shared.log("💊 MEDICATION: No last_taken_date found and no medication type set", level: .debug, category: .journal)
                    }
                }
                
                // Store previous medication type for change detection
                self.medicationData.previousMedicationType = self.medicationData.medicationType
            }
            
        case .stress:
            // Populate stress data
            DispatchQueue.main.async {
                self.stressData.stressLevel = entry["stress_level"] as? Int ?? 3
                self.stressData.stressSource = entry["stress_source"] as? String ?? ""
                self.stressData.copingStrategies = entry["coping_strategies"] as? String ?? ""
                self.stressData.mood = entry["mood_level"] as? Int ?? 3
                self.stressData.notes = ""  // Always empty for user to fill
            }
            
        case .sleep:
            // Populate sleep data
            DispatchQueue.main.async {
                self.sleepData.sleepHours = entry["sleep_hours"] as? Int ?? 8
                self.sleepData.sleepQuality = entry["sleep_quality"] as? Int ?? 5
                self.sleepData.sleepNotes = entry["sleep_notes"] as? String ?? ""
                self.sleepData.notes = ""  // Always empty for user to fill
            }
            
        case .hydration:
            // Populate hydration data
            DispatchQueue.main.async {
                // Convert liters back to cups for display (1 liter = 4.22675 cups)
                let waterIntakeLiters = entry["water_intake"] as? Double ?? 0
                self.hydrationData.waterCups = Int(round(waterIntakeLiters * 4.22675))
                self.hydrationData.otherFluids = entry["other_fluids"] as? Double ?? 0
                self.hydrationData.fluidType = entry["fluid_type"] as? String ?? "Water"
                self.hydrationData.hydrationLevel = entry["hydration_level"] as? Int ?? 5
                self.hydrationData.notes = ""  // Always empty for user to fill
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
            "entry_date": dateString
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
        // Use enhanced nutrition calculator for better compound food recognition
        let enhancedCalculator = EnhancedNutritionCalculator.shared
        return enhancedCalculator.calculateNutrition(for: description)
    }
    
    private func loadPreviousMedicationData() {
        guard let userData = userData else { return }
        
        NetworkLogger.shared.log("💊 Loading previous medication data for user: \(userData.id)", level: .info, category: .journal)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/latest-medication/\(userData.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    NetworkLogger.shared.log("❌ Error loading previous medication data: \(error.localizedDescription)", level: .error, category: .journal)
                    return
                }
                
                guard let data = data else { 
                    NetworkLogger.shared.log("❌ No medication data received from server", level: .error, category: .journal)
                    return 
                }
                
                do {
                    if let medicationData = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        NetworkLogger.shared.log("💊 Received previous medication data: \(medicationData)", level: .debug, category: .journal)
                        
                        // Only populate if medication type is not "None"
                        if let medicationType = medicationData["medication_type"] as? String, medicationType != "None" {
                            self.medicationData.medicationType = medicationType
                            
                            // Parse dosage_level to separate dosage and frequency
                            if let dosageLevel = medicationData["dosage_level"] as? String {
                                let (dosage, frequency) = MedicationFormData.fromDosageLevel(dosageLevel)
                                self.medicationData.dosage = dosage
                                self.medicationData.frequency = frequency
                                NetworkLogger.shared.log("💊 Loaded previous medication: \(medicationType), \(dosage)mg, \(frequency)", level: .info, category: .journal)
                            }
                        } else {
                            NetworkLogger.shared.log("💊 No previous medication data found or medication type is None", level: .info, category: .journal)
                        }
                    } else {
                        NetworkLogger.shared.log("❌ Failed to parse medication data", level: .error, category: .journal)
                    }
                } catch {
                    NetworkLogger.shared.log("❌ Error parsing medication data: \(error)", level: .error, category: .journal)
                }
            }
        }.resume()
    }
    
    // Note: Old nutrition calculation functions removed - now using EnhancedNutritionCalculator
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
            "food_description": foodDescription,
            "calories": totalCalories,
            "protein": totalProtein,
            "carbs": totalCarbs,
            "fiber": totalFiber,
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
    var dosage = "0" // Standard dosage in mg
    var frequency = "daily" // Frequency of administration
    var notes = ""
    var lastTakenDate = Date()
    var previousMedicationType = "None" // Track for change detection
    
    // Available medication types with descriptions
    static let medicationTypes = ["None", "biologic", "immunosuppressant", "steroid", "mesalamine"]
    
    // Medication type descriptions for warnings
    static let medicationDescriptions: [String: String] = [
        "biologic": "Biologic medications (e.g., Humira, Remicade, Stelara)",
        "immunosuppressant": "Immunosuppressant medications (e.g., Azathioprine, Methotrexate)",
        "steroid": "Steroid medications (e.g., Prednisone, Budesonide)",
        "mesalamine": "Mesalamine medications (e.g., Lialda, Asacol, Pentasa)"
    ]
    
    // Industry standard dosages by medication type (in mg)
    static let biologicDosages = ["40", "80", "120", "160"] // Standard biologic dosages
    static let immunosuppressantDosages = ["25", "50", "75", "100", "150", "200"] // Standard immunosuppressant dosages
    static let steroidDosages = ["5", "10", "15", "20", "30", "40"] // Standard steroid dosages
    static let mesalamineDosages = ["400", "800", "1200", "2400", "4800"] // Standard mesalamine dosages (in mg)
    
    // Available frequencies by medication type
    static let biologicFrequencies = ["every_2_weeks", "every_4_weeks", "every_8_weeks"]
    static let immunosuppressantFrequencies = ["daily", "twice_daily", "weekly"]
    static let steroidFrequencies = ["daily", "twice_daily", "weekly"]
    static let mesalamineFrequencies = ["daily", "twice_daily", "three_times_daily"]
    
    // Frequency details for validation
    static let frequencyDetails: [String: (days: Int, description: String)] = [
        "daily": (1, "Every day"),
        "twice_daily": (1, "Twice daily"),
        "three_times_daily": (1, "Three times daily"),
        "weekly": (7, "Every week"),
        "every_2_weeks": (14, "Every 2 weeks"),
        "every_4_weeks": (28, "Every 4 weeks"),
        "every_8_weeks": (56, "Every 8 weeks")
    ]
    
    // Get available dosages for current medication type
    var availableDosages: [String] {
        switch medicationType {
        case "biologic":
            return Self.biologicDosages
        case "immunosuppressant":
            return Self.immunosuppressantDosages
        case "steroid":
            return Self.steroidDosages
        case "mesalamine":
            return Self.mesalamineDosages
        default:
            return ["0"]
        }
    }
    
    // Get available frequencies for current medication type
    var availableFrequencies: [String] {
        switch medicationType {
        case "biologic":
            return Self.biologicFrequencies
        case "immunosuppressant":
            return Self.immunosuppressantFrequencies
        case "steroid":
            return Self.steroidFrequencies
        case "mesalamine":
            return Self.mesalamineFrequencies
        default:
            return ["daily"]
        }
    }
    
    // Validate and get correct dosage
    var validatedDosage: String {
        if medicationType == "None" {
            return "0"
        }
        
        let availableDosages = availableDosages
        if availableDosages.contains(dosage) {
            return dosage
        } else {
            // Return first available dosage as default
            return availableDosages.first ?? "0"
        }
    }
    
    // Validate and get correct frequency
    var validatedFrequency: String {
        if medicationType == "None" {
            return "daily"
        }
        
        let availableFrequencies = availableFrequencies
        if availableFrequencies.contains(frequency) {
            return frequency
        } else {
            // Return first available frequency as default
            return availableFrequencies.first ?? "daily"
        }
    }
    
    // Check if medication type has changed
    var hasMedicationTypeChanged: Bool {
        return previousMedicationType != "None" && previousMedicationType != medicationType
    }
    
    // Get frequency details for current frequency
    var currentFrequencyDetails: (days: Int, description: String)? {
        return Self.frequencyDetails[validatedFrequency]
    }
    
    // Check if medication is overdue
    var isOverdue: Bool {
        guard let frequency = currentFrequencyDetails else { return false }
        let daysSinceLastTaken = Calendar.current.dateComponents([.day], from: lastTakenDate, to: Date()).day ?? 0
        return daysSinceLastTaken > frequency.days
    }
    
    // Get days overdue
    var daysOverdue: Int {
        guard let frequency = currentFrequencyDetails else { return 0 }
        let daysSinceLastTaken = Calendar.current.dateComponents([.day], from: lastTakenDate, to: Date()).day ?? 0
        return max(0, daysSinceLastTaken - frequency.days)
    }
    
    // Get next due date
    var nextDueDate: Date {
        guard let frequency = currentFrequencyDetails else { return Date() }
        return Calendar.current.date(byAdding: .day, value: frequency.days, to: lastTakenDate) ?? Date()
    }
    
    // Get medication adherence status
    var adherenceStatus: (status: String, color: Color, description: String) {
        if medicationType == "None" {
            return ("No Medication", .gray, "No medication prescribed")
        }
        
        if isOverdue {
            return ("Overdue", .red, "\(daysOverdue) days overdue")
        } else {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
            if daysUntilDue <= 0 {
                return ("Due Today", .orange, "Medication due today")
            } else {
                return ("Due Soon", .orange, "Due in \(daysUntilDue) days")
            }
        }
    }
    
    func toDictionary() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let lastTakenDateString = dateFormatter.string(from: lastTakenDate)
        NetworkLogger.shared.log("💊 MEDICATION: Saving last_taken_date as '\(lastTakenDateString)' for \(medicationType)", level: .debug, category: .journal)
        
        // Combine dosage and frequency into dosage_level for backward compatibility
        let dosageLevel = "\(validatedDosage)mg_\(validatedFrequency)"
        
        return [
            "medication_type": medicationType,
            "dosage_level": dosageLevel,
            "last_taken_date": lastTakenDateString,
            "notes": notes
        ]
    }
    
    // Parse dosage_level back to separate dosage and frequency
    static func fromDosageLevel(_ dosageLevel: String) -> (dosage: String, frequency: String) {
        if dosageLevel == "0" {
            return ("0", "daily")
        }
        
        // Handle formats like "40mg_every_4_weeks" or "2.4g" or "2400mg"
        let components = dosageLevel.components(separatedBy: "_")
        if components.count >= 2 {
            // New format: "40mg_every_4_weeks"
            let dosage = components[0].replacingOccurrences(of: "mg", with: "")
            let frequency = components.dropFirst().joined(separator: "_")
            return (dosage, frequency)
        } else {
            // Old format or single value: "2.4g" or "2400mg"
            var dosage = dosageLevel
            
            // Convert g to mg if needed
            if dosageLevel.contains("g") {
                let numericValue = dosageLevel.replacingOccurrences(of: "g", with: "")
                if let doubleValue = Double(numericValue) {
                    dosage = String(Int(doubleValue * 1000)) // Convert g to mg
                }
            } else if dosageLevel.contains("mg") {
                dosage = dosageLevel.replacingOccurrences(of: "mg", with: "")
            }
            
            // Default frequency based on medication type (will be updated when medication type is known)
            return (dosage, "daily")
        }
    }
}

struct StressFormData {
    var stressLevel: Int = 3
    var stressSource = ""
    var copingStrategies = ""
    var mood: Int = 3
    var notes = ""
    
    // Validate stress level (1-5 constraint)
    var validatedStressLevel: Int {
        return max(1, min(5, stressLevel))
    }
    
    // Validate mood level (1-5 constraint)
    var validatedMoodLevel: Int {
        return max(1, min(5, mood))
    }
    
    // Get mood emoji based on level
    var moodEmoji: String {
        switch validatedMoodLevel {
        case 1: return "😢"  // Desperate
        case 2: return "😔"  // Sad
        case 3: return "😐"  // Neutral
        case 4: return "😊"  // Happy
        case 5: return "😄"  // Very Happy
        default: return "😐"
        }
    }
    
    // Get mood description based on level
    var moodDescription: String {
        switch validatedMoodLevel {
        case 1: return "Desperate"
        case 2: return "Sad"
        case 3: return "Neutral"
        case 4: return "Happy"
        case 5: return "Very Happy"
        default: return "Neutral"
        }
    }
    
    // Get stress description based on level
    var stressDescription: String {
        switch validatedStressLevel {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Moderate"
        }
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
    var sleepHours: Int = 8
    var sleepQuality: Int = 5
    var sleepNotes = ""
    var notes = ""
    
    // Validate sleep hours (0-24 constraint)
    var validatedSleepHours: Int {
        return max(0, min(24, sleepHours))
    }
    
    // Validate sleep quality (0-10 constraint)
    var validatedSleepQuality: Int {
        return max(0, min(10, sleepQuality))
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "sleep_hours": validatedSleepHours,
            "sleep_quality": validatedSleepQuality,
            "sleep_notes": sleepNotes,
            "notes": notes
        ]
    }
}

struct HydrationFormData {
    var waterCups: Int = 0  // User input in cups
    var otherFluids: Double = 0
    var fluidType = "Water"
    var hydrationLevel: Int = 5
    var notes = ""
    
    // Convert cups to liters (1 cup = 0.236588 liters)
    var waterIntakeInLiters: Double {
        return Double(waterCups) * 0.236588
    }
    
    // Validate water cups (non-negative)
    var validatedWaterCups: Int {
        return max(0, waterCups)
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
            "water_intake": waterIntakeInLiters,  // Convert to liters for database
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
    @State var dataLoaded: Bool
    @StateObject private var foodDatabase = FoodDatabase.shared
    @State private var isNutritionLocked = false
    @State private var autoCalculatedNutrition: CalculatedNutrition?
    @State private var showingAutoCalculation = false
    @State private var currentFoodDescription = ""
    @State private var previousMealType = "Breakfast"
    @State private var isLoadingText = false
    @State private var lastSavedMealType = "Breakfast"
    
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    init(data: Binding<MealsFormData>, dataLoaded: Bool) {
        self._data = data
        self.dataLoaded = dataLoaded
        NetworkLogger.shared.log("🍽️ FORM: MealsFormView initialized with mealType='\(data.wrappedValue.mealType)', breakfast='\(data.wrappedValue.breakfastDescription)', lunch='\(data.wrappedValue.lunchDescription)', dinner='\(data.wrappedValue.dinnerDescription)', snack='\(data.wrappedValue.snackDescription)', dataLoaded=\(dataLoaded)", level: .info, category: .journal)
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
                            
                            // Use DispatchQueue.main.async to ensure UI updates happen after state changes
                            DispatchQueue.main.async {
                                // Load text for the new meal type by directly accessing the stored value
                                let newText = getStoredTextForMealType(newMealType)
                                NetworkLogger.shared.log("🍽️ FORM: Loading text for '\(newMealType)': '\(newText)'", level: .info, category: .journal)
                                
                                // Set loading flag to prevent onChange from saving
                                isLoadingText = true
                                currentFoodDescription = newText
                                isLoadingText = false
                                
                                // Clear auto-calculation results for fresh calculation
                                autoCalculatedNutrition = nil
                                showingAutoCalculation = false
                                
                                // Trigger nutrition calculation for the new meal type if there's text
                                if !newText.isEmpty {
                                    performAutoCalculation()
                                }
                            }
                        }
                        .onChange(of: currentFoodDescription) { oldValue, newValue in
                            // Only save if the text actually changed and we're not loading
                            if oldValue != newValue && !isLoadingText {
                                saveCurrentTextToMealType(data.mealType)
                                // Also update the main foodDescription for consistency
                                data.foodDescription = newValue
                            }
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
                            // Only update if we're not loading and the text actually changed
                            if !isLoadingText && oldValue != newValue {
                                data.foodDescription = newValue
                                
                                // Save to the current meal type immediately
                                saveCurrentTextToMealType(data.mealType)
                                
                                // Trigger auto-calculation with a slight delay to avoid too frequent calls
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if currentFoodDescription == newValue { // Only calculate if text hasn't changed
                                        performAutoCalculation()
                                    }
                                }
                            }
                        }
                        .onAppear {
                            // Initialize with the current meal type's description
                            let initialText = getStoredTextForMealType(data.mealType)
                            NetworkLogger.shared.log("🍽️ FORM: onAppear - Initializing currentFoodDescription with '\(initialText)' for meal type '\(data.mealType)'", level: .info, category: .journal)
                            
                            // Set initial text without triggering onChange
                            isLoadingText = true
                            currentFoodDescription = initialText
                            isLoadingText = false
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
                

                
                // Daily Nutrition Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Daily Nutrition Summary")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        if autoCalculatedNutrition != nil {
                            Button(isNutritionLocked ? "Unlock" : "Lock") {
                                isNutritionLocked.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(isNutritionLocked ? .red : .green)
                        }
                    }
                    
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
            
            // Initialize currentFoodDescription with the current meal type's description
            let initialText = getStoredTextForMealType(data.mealType)
            NetworkLogger.shared.log("🍽️ FORM: onAppear - Setting currentFoodDescription to '\(initialText)' for meal type '\(data.mealType)'", level: .info, category: .journal)
            
            // Set loading flag to prevent onChange from saving during initialization
            isLoadingText = true
            currentFoodDescription = initialText
            isLoadingText = false
            
            // If there's text, trigger auto-calculation
            if !currentFoodDescription.isEmpty {
                performAutoCalculation()
            }
        }
        .onChange(of: dataLoaded) { oldValue, newValue in
            if newValue && !oldValue {
                // Data was just loaded, update the current food description
                NetworkLogger.shared.log("🍽️ FORM: Data loaded, updating currentFoodDescription", level: .info, category: .journal)
                
                let activeMealDescription = getStoredTextForMealType(data.mealType)
                NetworkLogger.shared.log("🍽️ FORM: Setting currentFoodDescription to '\(activeMealDescription)' for meal type '\(data.mealType)'", level: .info, category: .journal)
                
                // Set loading flag to prevent onChange from saving during update
                isLoadingText = true
                currentFoodDescription = activeMealDescription
                isLoadingText = false
                
                // Trigger auto-calculation if there's text
                if !currentFoodDescription.isEmpty {
                    performAutoCalculation()
                }
            }
        }
        .onChange(of: data.breakfastDescription) { oldValue, newValue in
            // If we're on the breakfast tab and breakfast description changed, update the text field
            if data.mealType == "Breakfast" && oldValue != newValue && !newValue.isEmpty {
                NetworkLogger.shared.log("🍽️ FORM: Breakfast description changed to '\(newValue)', updating text field", level: .info, category: .journal)
                
                isLoadingText = true
                currentFoodDescription = newValue
                isLoadingText = false
                
                // Trigger auto-calculation
                performAutoCalculation()
            }
        }
        .onChange(of: data.lunchDescription) { oldValue, newValue in
            // If we're on the lunch tab and lunch description changed, update the text field
            if data.mealType == "Lunch" && oldValue != newValue && !newValue.isEmpty {
                NetworkLogger.shared.log("🍽️ FORM: Lunch description changed to '\(newValue)', updating text field", level: .info, category: .journal)
                
                isLoadingText = true
                currentFoodDescription = newValue
                isLoadingText = false
                
                // Trigger auto-calculation
                performAutoCalculation()
            }
        }
        .onChange(of: data.dinnerDescription) { oldValue, newValue in
            // If we're on the dinner tab and dinner description changed, update the text field
            if data.mealType == "Dinner" && oldValue != newValue && !newValue.isEmpty {
                NetworkLogger.shared.log("🍽️ FORM: Dinner description changed to '\(newValue)', updating text field", level: .info, category: .journal)
                
                isLoadingText = true
                currentFoodDescription = newValue
                isLoadingText = false
                
                // Trigger auto-calculation
                performAutoCalculation()
            }
        }
        .onChange(of: data.snackDescription) { oldValue, newValue in
            // If we're on the snack tab and snack description changed, update the text field
            if data.mealType == "Snack" && oldValue != newValue && !newValue.isEmpty {
                NetworkLogger.shared.log("🍽️ FORM: Snack description changed to '\(newValue)', updating text field", level: .info, category: .journal)
                
                isLoadingText = true
                currentFoodDescription = newValue
                isLoadingText = false
                
                // Trigger auto-calculation
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
        
        // Use enhanced nutrition calculator for better compound food recognition
        let enhancedCalculator = EnhancedNutritionCalculator.shared
        autoCalculatedNutrition = enhancedCalculator.calculateNutrition(for: currentFoodDescription)
        showingAutoCalculation = true
    }
    
    // Note: Old nutrition calculation functions removed - now using EnhancedNutritionCalculator
    
    // Note: Enhanced nutrition calculation now handled directly by EnhancedNutritionCalculator
    
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
        NetworkLogger.shared.log("🍽️ SAVE: Saving text '\(currentFoodDescription)' to meal type '\(mealType)'", level: .info, category: .journal)
        
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
        
        lastSavedMealType = mealType
        NetworkLogger.shared.log("🍽️ SAVE: Successfully saved to '\(mealType)', lastSavedMealType is now '\(lastSavedMealType)'", level: .info, category: .journal)
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
    @State private var showingBristolScaleInfo = false
    
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
                    HStack {
                        Text("Bristol Stool Scale")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingBristolScaleInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    
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
        .sheet(isPresented: $showingBristolScaleInfo) {
            BristolScaleInfoView()
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
    @State private var showingMedicationChangeAlert = false
    @State private var showingDatePicker = false
    @State private var showingOverdueAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Medication Type with Change Warning
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medication Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Picker("Medication Type", selection: $data.medicationType) {
                        ForEach(MedicationFormData.medicationTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: data.medicationType) { oldValue, newValue in
                        if data.hasMedicationTypeChanged {
                            showingMedicationChangeAlert = true
                        }
                        
                        // If changing from "None" to a real medication type, set default date
                        if oldValue == "None" && newValue != "None" {
                            // Check if lastTakenDate is still the default (today's date when initialized)
                            let calendar = Calendar.current
                            let today = Date()
                            let isLastTakenDateToday = calendar.isDate(data.lastTakenDate, inSameDayAs: today)
                            
                            if isLastTakenDateToday {
                                // Set to today as default for new medication
                                data.lastTakenDate = Date()
                                NetworkLogger.shared.log("💊 MEDICATION: Setting default date to today for new medication type: \(newValue)", level: .debug, category: .journal)
                            }
                        }
                    }
                }
                
                // Medication Type Change Alert
                if data.hasMedicationTypeChanged {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Medication Type Changed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        Text("Changing medication type requires doctor's approval. Please consult your healthcare provider before making changes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Dosage and Frequency (only show if medication type is not None)
                if data.medicationType != "None" {
                    VStack(alignment: .leading, spacing: 20) {
                        // Dosage Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dosage (mg)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Picker("Dosage", selection: $data.dosage) {
                                ForEach(data.availableDosages, id: \.self) { dosage in
                                    Text("\(dosage) mg").tag(dosage)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // Frequency Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frequency")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Picker("Frequency", selection: $data.frequency) {
                                ForEach(data.availableFrequencies, id: \.self) { frequency in
                                    Text(formatFrequencyDisplay(frequency)).tag(frequency)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // Last Taken Date (for all medications)
                if data.medicationType != "None" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Taken Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            NetworkLogger.shared.log("💊 MEDICATION: Opening date picker, current lastTakenDate: \(formatDate(data.lastTakenDate))", level: .debug, category: .journal)
                            showingDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatDate(data.lastTakenDate))
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    Text("Tap to change")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // Show next due date for non-daily medications
                        if data.frequency != "daily" && data.frequency != "twice_daily" {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text("Next due: \(formatDate(data.nextDueDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // Medication Status and Adherence
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Adherence Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(data.adherenceStatus.color)
                                .frame(width: 12, height: 12)
                            Text(data.adherenceStatus.status)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(data.adherenceStatus.color)
                            Spacer()
                        }
                        
                        Text(data.adherenceStatus.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Show frequency details
                        if let frequency = data.currentFrequencyDetails {
                            HStack {
                                Image(systemName: "repeat")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Frequency: \(frequency.description)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(data.adherenceStatus.color.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Overdue Warning
                if data.isOverdue {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text("Medication Overdue")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        
                        Text("Your medication is \(data.daysOverdue) days overdue. Please take it as soon as possible and contact your doctor if you have concerns.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(
                selectedDate: $data.lastTakenDate,
                onDateSelected: {
                    NetworkLogger.shared.log("💊 MEDICATION: Date picker closed, lastTakenDate is now: \(formatDate(data.lastTakenDate))", level: .debug, category: .journal)
                    showingDatePicker = false
                }
            )
        }
        .alert("Medication Type Change", isPresented: $showingMedicationChangeAlert) {
            Button("OK") {
                // User acknowledges the warning
            }
        } message: {
            Text("Changing medication type requires doctor's approval. Please consult your healthcare provider before making changes.")
        }
        .onAppear {
            // Store the current medication type for change detection
            data.previousMedicationType = data.medicationType
        }
    }
    
    private func formatDosageDisplay(_ dosage: String) -> String {
        switch dosage {
        case "every_2_weeks": return "Every 2 Weeks"
        case "every_4_weeks": return "Every 4 Weeks"
        case "every_8_weeks": return "Every 8 Weeks"
        case "daily": return "Daily"
        case "twice_daily": return "Twice Daily"
        case "three_times_daily": return "Three Times Daily"
        case "weekly": return "Weekly"
        case "5": return "5mg"
        case "10": return "10mg"
        case "20": return "20mg"
        default: return dosage
        }
    }
    
    private func formatFrequencyDisplay(_ frequency: String) -> String {
        switch frequency {
        case "every_2_weeks": return "Every 2 Weeks"
        case "every_4_weeks": return "Every 4 Weeks"
        case "every_8_weeks": return "Every 8 Weeks"
        case "daily": return "Daily"
        case "twice_daily": return "Twice Daily"
        case "three_times_daily": return "Three Times Daily"
        case "weekly": return "Weekly"
        default: return frequency.capitalized
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StressFormView: View {
    @Binding var data: StressFormData
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Stress Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stress Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { Double(data.stressLevel) },
                            set: { data.stressLevel = Int($0) }
                        ), in: 1...5, step: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(data.stressDescription)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Stress Source
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's causing stress?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Describe stress source...", text: $data.stressSource, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal, 4)
                }
                
                // Coping Strategies
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coping Strategies")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("What helped you cope...", text: $data.copingStrategies, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal, 4)
                }
                
                // Mood Level with Emojis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mood Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { Double(data.mood) },
                            set: { data.mood = Int($0) }
                        ), in: 1...5, step: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(data.moodEmoji)
                                    .font(.title2)
                                Text(data.moodDescription)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
                    
                    Stepper("\(data.sleepHours) hours", value: $data.sleepHours, in: 0...24, step: 1)
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
                
                // Sleep Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Notes")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $data.sleepNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
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
            VStack(alignment: .leading, spacing: 24) {
                // Water Intake in Cups
                VStack(alignment: .leading, spacing: 12) {
                    Text("Water Intake")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Stepper("\(data.waterCups) cups", value: $data.waterCups, in: 0...20, step: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        // Show equivalent in liters for reference
                        Text("≈ \(String(format: "%.1f", data.waterIntakeInLiters)) liters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                
                // Other Fluids
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Fluids (liters)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Stepper("\(String(format: "%.1f", data.otherFluids)) L", value: $data.otherFluids, in: 0...5, step: 0.1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Fluid Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Fluid Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Picker("Fluid Type", selection: $data.fluidType) {
                        ForEach(fluidTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Hydration Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hydration Level (0-10)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { Double(data.hydrationLevel) },
                            set: { data.hydrationLevel = Int($0) }
                        ), in: 0...10, step: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(data.hydrationLevel)/10")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Any additional notes...", text: $data.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
    
    // Meal data - old flat format
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
    
    // New structured format - meals array
    let meals: [Meal]?
    
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
        
        // Meal data - handle both string and integer types for nutrition (old flat format)
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
        
        // New structured format - meals array
        if let mealsArray = dict["meals"] as? [[String: Any]] {
            meals = mealsArray.compactMap { mealDict in
                guard let mealId = mealDict["meal_id"] as? String,
                      let mealType = mealDict["meal_type"] as? String,
                      let description = mealDict["description"] as? String else {
                    return nil
                }
                
                return Meal(
                    meal_id: mealId,
                    meal_type: mealType,
                    description: description,
                    calories: mealDict["calories"] as? Int,
                    protein: mealDict["protein"] as? Int,
                    carbs: mealDict["carbs"] as? Int,
                    fiber: mealDict["fiber"] as? Int,
                    fat: mealDict["fat"] as? Int
                )
            }
        } else {
            meals = nil
        }
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
        // Check new structured format first
        if let meals = entry.meals, !meals.isEmpty {
            return true
        }
        
        // Fallback to old flat format
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
            
            // Display meals from new structured format if available
            if let meals = entry.meals, !meals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(meals, id: \.meal_id) { meal in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(meal.meal_type.capitalized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if let calories = meal.calories, calories > 0 {
                                    Text("\(calories) cal")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(meal.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show nutrition breakdown if available
                            if let protein = meal.protein, let carbs = meal.carbs, let fiber = meal.fiber, let fat = meal.fat,
                               protein > 0 || carbs > 0 || fiber > 0 || fat > 0 {
                                HStack(spacing: 12) {
                                    if protein > 0 {
                                        NutritionItem(label: "Protein", value: "\(protein)g")
                                    }
                                    if carbs > 0 {
                                        NutritionItem(label: "Carbs", value: "\(carbs)g")
                                    }
                                    if fiber > 0 {
                                        NutritionItem(label: "Fiber", value: "\(fiber)g")
                                    }
                                    if fat > 0 {
                                        NutritionItem(label: "Fat", value: "\(fat)g")
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            } else {
                // Fallback to old flat format
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
                
                // Show individual meals from old format if available
                VStack(alignment: .leading, spacing: 4) {
                    if let breakfast = entry.breakfast, !breakfast.isEmpty {
                        MealItem(mealType: "Breakfast", description: breakfast, calories: entry.breakfastCalories)
                    }
                    if let lunch = entry.lunch, !lunch.isEmpty {
                        MealItem(mealType: "Lunch", description: lunch, calories: entry.lunchCalories)
                    }
                    if let dinner = entry.dinner, !dinner.isEmpty {
                        MealItem(mealType: "Dinner", description: dinner, calories: entry.dinnerCalories)
                    }
                    if let snacks = entry.snacks, !snacks.isEmpty {
                        MealItem(mealType: "Snacks", description: snacks, calories: entry.snackCalories)
                    }
                }
            }
        }
    }
}

struct MealItem: View {
    let mealType: String
    let description: String
    let calories: String?
    
    var body: some View {
        HStack {
            Text(mealType)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let calories = calories, !calories.isEmpty {
                Text("\(calories) cal")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        
        Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
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
    DailyLogView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
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

// MARK: - Bristol Scale Info View
struct BristolScaleInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bristol Stool Scale")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("The Bristol Stool Scale is a medical aid designed to classify the form of human feces into seven categories. It helps healthcare providers understand your bowel health.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(1...7, id: \.self) { scale in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Type \(scale)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(scale.bristolScaleDescription())
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                
                                // Add color coding for better understanding
                                Rectangle()
                                    .fill(bristolScaleColor(for: scale))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to look for:")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text("• Types 1-2: May indicate constipation")
                        Text("• Types 3-4: Normal, healthy stools")
                        Text("• Types 5-7: May indicate diarrhea or urgency")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Bristol Scale Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func bristolScaleColor(for scale: Int) -> Color {
        switch scale {
        case 1, 2:
            return .brown // Constipation
        case 3, 4:
            return .green // Normal
        case 5, 6, 7:
            return .orange // Diarrhea
        default:
            return .gray
        }
    }
}