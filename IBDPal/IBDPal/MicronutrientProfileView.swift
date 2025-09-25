import SwiftUI

struct MicronutrientProfileView: View {
    let userData: UserData?
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: String = "Prefer not to say"
    @State private var micronutrients: [MicronutrientSupplement] = []
    @State private var labResults: [LabResult] = []
    @State private var showingAddSupplement = false
    @State private var showingAddLabResult = false
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var currentProfile: MicronutrientProfile?
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    private let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutrition Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Personalize your nutrition recommendations by providing your age, weight, and supplement information. This data helps us tailor nutrition advice specifically for your IBD management.")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Required Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Required Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    // Age Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age *")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Enter your age", text: $age)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Age input")
                            .accessibilityHint("Enter your age in years")
                    }
                    
                    // Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg) *")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Enter your weight in kg", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Weight input")
                            .accessibilityHint("Enter your weight in kilograms")
                    }
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Optional Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Optional Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    // Height Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Enter your height in cm", text: $height)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Height input")
                            .accessibilityHint("Enter your height in centimeters")
                    }
                    
                    // Gender Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accessibilityLabel("Gender selection")
                        .accessibilityValue("Selected: \(gender)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Micronutrients Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Micronutrients & Supplements")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddSupplement = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.ibdPrimary)
                        }
                    }
                    
                    if micronutrients.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.ibdSecondaryText)
                            
                            Text("No supplements added yet")
                                .font(.headline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Text("Add your vitamins, minerals, and supplements to get personalized nutrition recommendations")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color.ibdSurfaceBackground.opacity(0.5))
                        .cornerRadius(12)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(micronutrients) { supplement in
                                SupplementCard(supplement: supplement) {
                                    removeSupplement(supplement)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)

                // Lab Results Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Lab Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddLabResult = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.ibdPrimary)
                        }
                    }
                    
                    if labResults.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.ibdSecondaryText)
                            
                            Text("No lab results added yet")
                                .font(.headline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Text("Add your recent lab test results to get personalized nutrition recommendations based on your actual nutrient levels")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color.ibdSurfaceBackground.opacity(0.5))
                        .cornerRadius(12)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(labResults) { labResult in
                                LabResultCard(labResult: labResult) {
                                    removeLabResult(labResult)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Save Button
                Button(action: saveProfile) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        
                        Text("Save Nutrition Profile")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.ibdPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Nutrition Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingProfile()
        }
        .sheet(isPresented: $showingAddSupplement) {
            AddSupplementView { supplement in
                micronutrients.append(supplement)
            }
        }
        .sheet(isPresented: $showingAddLabResult) {
            AddLabResultView { labResult in
                labResults.append(labResult)
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your nutrition profile has been saved successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !age.isEmpty && !weight.isEmpty &&
               Int(age) != nil && Double(weight) != nil &&
               Int(age)! > 0 && Double(weight)! > 0
    }
    
    // MARK: - Methods
    
    private func loadExistingProfile() {
        guard let userId = userData?.id else { return }
        
        Task {
            await loadProfileData(userId: userId)
        }
    }
    
    private func loadProfileData(userId: String) async {
        do {
            let profile = try await fetchMicronutrientProfile(userId: userId)
            await MainActor.run {
                if let profile = profile {
                    self.currentProfile = profile
                    self.age = String(profile.age)
                    self.weight = String(profile.weight)
                    self.height = profile.height.map { String($0) } ?? ""
                    self.gender = profile.gender ?? "Prefer not to say"
                    self.micronutrients = profile.supplements
                    self.labResults = profile.labResults
                }
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let userId = userData?.id,
              let ageInt = Int(age),
              let weightDouble = Double(weight) else { return }
        
        isLoading = true
        
        let heightDouble = height.isEmpty ? nil : Double(height)
        let profile = MicronutrientProfile(
            userId: userId,
            age: ageInt,
            weight: weightDouble,
            height: heightDouble,
            gender: gender == "Prefer not to say" ? nil : gender,
            labResults: labResults,
            supplements: micronutrients
        )
        
        Task.detached { @MainActor in
            do {
                try await saveMicronutrientProfile(profile)
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func removeSupplement(_ supplement: MicronutrientSupplement) {
        micronutrients.removeAll { $0.id == supplement.id }
    }
    
    private func removeLabResult(_ labResult: LabResult) {
        labResults.removeAll { $0.id == labResult.id }
    }
    

    // MARK: - API Methods
    
    private func fetchMicronutrientProfile(userId: String) async throws -> MicronutrientProfile? {
        let fullURL = "\(apiBaseURL)/micronutrient/profile"
        print("🔍 [DEBUG] Full URL: \(fullURL)")
        print("🔍 [DEBUG] API Base URL: \(apiBaseURL)")
        print("🔍 [DEBUG] UserData token: \(userData?.token ?? "NO TOKEN")")
        
        guard let url = URL(string: fullURL) else {
            print("❌ [ERROR] Failed to create URL from: \(fullURL)")
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        print("�� [DEBUG] Request URL: \(request.url?.absoluteString ?? "NO URL")")
        print("🔍 [DEBUG] Authorization header: Bearer \(userData?.token ?? "NO TOKEN")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [DEBUG] HTTP Status: \(httpResponse.statusCode)")
            print("🔍 [DEBUG] Response headers: \(httpResponse.allHeaderFields)")
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API response: \(jsonString)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
            return response.data
        } catch {
            print("Decoding error: \(error)")
            // If decoding fails, try to return nil (no profile exists yet)
            return nil
        }
    }
    
    private func saveMicronutrientProfile(_ profile: MicronutrientProfile) async throws {
        guard let url = URL(string: "\(apiBaseURL)/micronutrient/profile") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        print("🔍 [DEBUG] Save URL: \(url.absoluteString)")
        print("🔍 [DEBUG] Save Authorization: Bearer \(userData?.token ?? "NO TOKEN")")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)
        
        // Debug: Print the request body
        if let bodyData = request.httpBody,
           let jsonString = String(data: bodyData, encoding: .utf8) {
            print("🔍 [DEBUG] Save request body: \(jsonString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [DEBUG] Save HTTP Status: \(httpResponse.statusCode)")
            print("🔍 [DEBUG] Save Response headers: \(httpResponse.allHeaderFields)")
        }
        
        // Debug: Print the save response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 [DEBUG] Save response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Save failed", code: 0)
        }
    }
}

// MARK: - Supplement Card View

struct SupplementCard: View {
    let supplement: MicronutrientSupplement
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: iconForCategory(supplement.category))
                .font(.title2)
                .foregroundColor(colorForCategory(supplement.category))
                .frame(width: 30)
            
            // Supplement Info
            VStack(alignment: .leading, spacing: 4) {
                Text(supplement.name)
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Text("\(supplement.dosage) \(supplement.unit) • \(supplement.frequency.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.ibdSecondaryText)
                
                if let notes = supplement.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func colorForCategory(_ category: MicronutrientCategory) -> Color {
        switch category {
        case .vitamin: return .blue
        case .mineral: return .green
        case .traceElement: return .orange
        case .other: return .gray
        }
    }
}


    private func iconForCategory(_ category: MicronutrientCategory) -> String {
        switch category {
        case .vitamin: return "pills.fill"
        case .mineral: return "diamond.fill"
        case .traceElement: return "atom"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func colorForCategory(_ category: MicronutrientCategory) -> Color {
        switch category {
        case .vitamin: return .blue
        case .mineral: return .green
        case .traceElement: return .orange
        case .other: return .gray
        }
    }

// MARK: - Add Supplement View

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var category: MicronutrientCategory = .vitamin
    @State private var dosage: String = ""
    @State private var unit: DosageUnit = .mg
    @State private var frequency: SupplementFrequency = .daily
    @State private var notes: String = ""
    @State private var showingCommonSupplements = false
    
    let onSave: (MicronutrientSupplement) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Supplement Details") {
                    // Name
                    TextField("Supplement name", text: $name)
                    
                    // Category
                    Picker("Category", selection: $category) {
                        ForEach(MicronutrientCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: iconForCategory(category))
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }
                    
                    // Dosage
                    HStack {
                        TextField("Dosage", text: $dosage)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(DosageUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Frequency
                    Picker("Frequency", selection: $frequency) {
                        ForEach(SupplementFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    // Notes
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Browse Common Supplements") {
                        showingCommonSupplements = true
                    }
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSupplement()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
            .sheet(isPresented: $showingCommonSupplements) {
                CommonSupplementsView { supplementName in
                    name = supplementName
                    showingCommonSupplements = false
                }
            }
        }
    }
    
    private func saveSupplement() {
        let supplement = MicronutrientSupplement(
            name: name,
            category: category,
            dosage: Double(dosage) ?? 0.0,
            unit: unit,
            frequency: frequency,
            startDate: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(supplement)
        dismiss()
    }
}

// MARK: - Common Supplements View

struct CommonSupplementsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(MicronutrientCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(supplementsForCategory(category), id: \.self) { supplement in
                            Button(action: {
                                onSelect(supplement)
                            }) {
                                HStack {
                                    Image(systemName: iconForCategory(category))
                                        .foregroundColor(.ibdPrimary)
                                    
                                    Text(supplement)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Common Supplements")
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
    
    private func supplementsForCategory(_ category: MicronutrientCategory) -> [String] {
        switch category {
        case .vitamin: return CommonMicronutrients.criticalVitamins
        case .mineral: return CommonMicronutrients.criticalMinerals
        case .traceElement: return CommonMicronutrients.commonSupplements
        case .other: return CommonMicronutrients.commonSupplements
        }
    }
}



// MARK: - Lab Result Card

struct LabResultCard: View {
    let labResult: LabResult
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labResult.nutrient)
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Test Date: \(labResult.testDate.formattedForDisplay())")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Value")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    Text("\(labResult.value.formattedAsNutrient()) \(labResult.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    Text(labResult.status.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(labResult.status))
                }
            }
            
            if let notes = labResult.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func statusColor(_ status: LabStatus) -> Color {
        switch status {
        case .normal:
            return .green
        case .low:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
}

// MARK: - Add Lab Result View

struct AddLabResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedNutrient: IBDLabTest? = nil
    @State private var value: String = ""
    @State private var testDate: Date = Date()
    @State private var notes: String = ""
    @State private var showingNutrientPicker = false
    
    let onSave: (LabResult) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Lab Test Selection") {
                    HStack {
                        Text("Nutrient")
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            showingNutrientPicker = true
                        }) {
                            HStack {
                                if let nutrient = selectedNutrient {
                                    Text(nutrient.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Lab Test")
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if let nutrient = selectedNutrient {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.ibdPrimary)
                                Text("Reference Range")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Text(nutrient.referenceRange)
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .padding(.leading, 20)
                            
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("IBD Risk Level")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Text(nutrient.riskLevel)
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .padding(.leading, 20)
                        }
                        .padding(.vertical, 8)
                        .background(Color.ibdSurfaceBackground)
                        .cornerRadius(8)
                    }
                }
                
                Section("Test Results") {
                    HStack {
                        Text("Value")
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        TextField("Enter test value", text: $value)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if let nutrient = selectedNutrient, !value.isEmpty {
                        HStack {
                            Text("Unit")
                                .foregroundColor(.ibdPrimaryText)
                            
                            Spacer()
                            
                            Text(nutrient.unit)
                                .foregroundColor(.ibdSecondaryText)
                        }
                        
                        HStack {
                            Text("Status")
                                .foregroundColor(.ibdPrimaryText)
                            
                            Spacer()
                            
                            Text(determineStatus(for: Double(value) ?? 0.0, nutrient: nutrient).rawValue.capitalized)
                                .foregroundColor(statusColor(determineStatus(for: Double(value) ?? 0.0, nutrient: nutrient)))
                                .fontWeight(.medium)
                        }
                    }
                    
                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                }
                
                Section("Additional Information") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Lab Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLabResult()
                    }
                    .disabled(selectedNutrient == nil || value.isEmpty)
                }
            }
            .sheet(isPresented: $showingNutrientPicker) {
                IBDLabTestPickerView { labTest in
                    selectedNutrient = labTest
                    showingNutrientPicker = false
                }
            }
        }
    }
    
    private func determineStatus(for value: Double, nutrient: IBDLabTest) -> LabStatus {
        let range = nutrient.referenceRange
        
        // Parse reference range (e.g., "30-100 ng/mL" or "3.38-48.0 ng/mL")
        let numbers = range.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
            .filter { $0 > 0 }
        
        if numbers.count >= 2 {
            let minValue = numbers.min() ?? 0
            let maxValue = numbers.max() ?? 0
            
            if value < minValue {
                return .low
            } else if value > maxValue {
                return .high
            } else {
                return .normal
            }
        }
        
        return .normal
    }
    
    private func statusColor(_ status: LabStatus) -> Color {
        switch status {
        case .normal:
            return .green
        case .low:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
    
    private func saveLabResult() {
        guard let nutrient = selectedNutrient else { return }
        
        let status = determineStatus(for: Double(value) ?? 0.0, nutrient: nutrient)
        
        let labResult = LabResult(
            nutrient: nutrient.name,
            value: Double(value) ?? 0.0,
            unit: nutrient.unit,
            referenceRange: nutrient.referenceRange,
            status: status,
            testDate: testDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(labResult)
        dismiss()
    }
}

// MARK: - Common Nutrients View

struct CommonNutrientsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section("Common IBD Nutrients") {
                    ForEach(CommonMicronutrients.referenceRanges.keys.sorted(), id: \.self) { nutrient in
                        Button(action: {
                            onSelect(nutrient)
                        }) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.ibdPrimary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(nutrient)
                                        .foregroundColor(.primary)
                                    
                                    if let range = CommonMicronutrients.referenceRanges[nutrient] {
                                        Text("Range: \(range)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Common Nutrients")
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
}



// MARK: - IBD Lab Test Models

struct IBDLabTest: Identifiable, Codable {
    let id: UUID
    let name: String
    let unit: String
    let referenceRange: String
    let riskLevel: String
    let category: LabTestCategory
    
    init(name: String, unit: String, referenceRange: String, riskLevel: String, category: LabTestCategory) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.referenceRange = referenceRange
        self.riskLevel = riskLevel
        self.category = category
    }
    
    enum LabTestCategory: String, CaseIterable, Codable {
        case vitamins = "Vitamins"
        case minerals = "Minerals"
        case inflammatory = "Inflammatory Markers"
        case blood = "Blood Tests"
        case other = "Other"
    }
}

// MARK: - IBD Lab Test Data

struct IBDLabTests {
    static let allTests: [IBDLabTest] = [
        // Vitamins
        IBDLabTest(
            name: "Vitamin D (25-OH)",
            unit: "ng/mL",
            referenceRange: "30-100 ng/mL",
            riskLevel: "High - Common in IBD patients, affects bone health and immune function",
            category: .vitamins
        ),
        IBDLabTest(
            name: "Vitamin B12 (Cobalamin)",
            unit: "pg/mL",
            referenceRange: "211-911 pg/mL",
            riskLevel: "High - Especially in Crohn's disease affecting terminal ileum",
            category: .vitamins
        ),
        IBDLabTest(
            name: "Folate (Folic Acid)",
            unit: "ng/mL",
            referenceRange: "3.38-48.0 ng/mL",
            riskLevel: "High - Important for patients on methotrexate",
            category: .vitamins
        ),
        IBDLabTest(
            name: "Vitamin A",
            unit: "mcg/dL",
            referenceRange: "30-95 mcg/dL",
            riskLevel: "Medium - Can be affected by malabsorption",
            category: .vitamins
        ),
        IBDLabTest(
            name: "Vitamin E",
            unit: "mg/dL",
            referenceRange: "5.5-17.0 mg/dL",
            riskLevel: "Medium - Antioxidant, important for IBD patients",
            category: .vitamins
        ),
        IBDLabTest(
            name: "Vitamin K",
            unit: "ng/mL",
            referenceRange: "0.10-2.20 ng/mL",
            riskLevel: "Medium - Important for bone health and blood clotting",
            category: .vitamins
        ),
        
        // Minerals
        IBDLabTest(
            name: "Iron (Fe)",
            unit: "mcg/dL",
            referenceRange: "60-170 mcg/dL",
            riskLevel: "Very High - Most common deficiency in IBD (30-90% of patients)",
            category: .minerals
        ),
        IBDLabTest(
            name: "Ferritin",
            unit: "ng/mL",
            referenceRange: "10-291 ng/mL",
            riskLevel: "Very High - Iron storage indicator, often low in IBD",
            category: .minerals
        ),
        IBDLabTest(
            name: "Calcium (Ca)",
            unit: "mg/dL",
            referenceRange: "8.5-10.5 mg/dL",
            riskLevel: "High - Important for bone health, especially with steroid use",
            category: .minerals
        ),
        IBDLabTest(
            name: "Magnesium (Mg)",
            unit: "mg/dL",
            referenceRange: "1.7-2.2 mg/dL",
            riskLevel: "Medium - Can be lost through diarrhea",
            category: .minerals
        ),
        IBDLabTest(
            name: "Zinc (Zn)",
            unit: "mcg/dL",
            referenceRange: "70-120 mcg/dL",
            riskLevel: "Medium - Lost through diarrhea, important for wound healing",
            category: .minerals
        ),
        IBDLabTest(
            name: "Selenium",
            unit: "mcg/L",
            referenceRange: "70-150 mcg/L",
            riskLevel: "Low - Antioxidant, may be affected by IBD",
            category: .minerals
        ),
        
        // Inflammatory Markers
        IBDLabTest(
            name: "C-Reactive Protein (CRP)",
            unit: "mg/L",
            referenceRange: "< 3.0 mg/L",
            riskLevel: "High - Key inflammatory marker for IBD monitoring",
            category: .inflammatory
        ),
        IBDLabTest(
            name: "Erythrocyte Sedimentation Rate (ESR)",
            unit: "mm/hr",
            referenceRange: "0-20 mm/hr",
            riskLevel: "High - Inflammatory marker, elevated during flares",
            category: .inflammatory
        ),
        IBDLabTest(
            name: "Fecal Calprotectin",
            unit: "mcg/g",
            referenceRange: "< 50 mcg/g",
            riskLevel: "Very High - Specific marker for intestinal inflammation",
            category: .inflammatory
        ),
        
        // Blood Tests
        IBDLabTest(
            name: "Hemoglobin",
            unit: "g/dL",
            referenceRange: "12.0-15.5 g/dL",
            riskLevel: "High - Often low due to iron deficiency and inflammation",
            category: .blood
        ),
        IBDLabTest(
            name: "Hematocrit",
            unit: "%",
            referenceRange: "36-46%",
            riskLevel: "High - Correlates with hemoglobin levels",
            category: .blood
        ),
        IBDLabTest(
            name: "White Blood Cell Count",
            unit: "K/uL",
            referenceRange: "4.5-11.0 K/uL",
            riskLevel: "Medium - May be elevated during inflammation or infection",
            category: .blood
        ),
        IBDLabTest(
            name: "Platelet Count",
            unit: "K/uL",
            referenceRange: "150-450 K/uL",
            riskLevel: "Medium - May be elevated during active inflammation",
            category: .blood
        )
    ]
    
    static func testsForCategory(_ category: IBDLabTest.LabTestCategory) -> [IBDLabTest] {
        return allTests.filter { $0.category == category }
    }
}

// MARK: - IBD Lab Test Picker View

struct IBDLabTestPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (IBDLabTest) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(IBDLabTest.LabTestCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(IBDLabTests.testsForCategory(category)) { labTest in
                            Button(action: {
                                onSelect(labTest)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(labTest.name)
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text(labTest.unit)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    
                                    Text(labTest.referenceRange)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    
                                    Text(labTest.riskLevel)
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Lab Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MicronutrientProfileView(userData: nil)
}
