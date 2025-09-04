import SwiftUI

struct MicronutrientProfileView: View {
    let userData: UserData?
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: String = "Prefer not to say"
    @State private var micronutrients: [MicronutrientSupplement] = []
    @State private var showingAddSupplement = false
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
                    }
                    
                    // Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg) *")
                            .font(.headline)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Enter your weight in kg", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
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
        guard let userId = userData?.userId else { return }
        
        Task {
            do {
                let profile = try await fetchMicronutrientProfile(userId: userId)
                await MainActor.run {
                    if let profile = profile {
                        self.currentProfile = profile
                        self.age = String(profile.age)
                        self.weight = String(profile.weight)
                        self.height = profile.height.map(String.init) ?? ""
                        self.gender = profile.gender ?? "Prefer not to say"
                        self.micronutrients = profile.micronutrients
                    }
                }
            } catch {
                print("Error loading profile: \(error)")
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = userData?.userId,
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
            micronutrients: micronutrients
        )
        
        Task {
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
    
    // MARK: - API Methods
    
    private func fetchMicronutrientProfile(userId: String) async throws -> MicronutrientProfile? {
        guard let url = URL(string: "\(apiBaseURL)/api/micronutrient/profile/\(userId)") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MicronutrientProfileResponse.self, from: data)
        
        return response.data
    }
    
    private func saveMicronutrientProfile(_ profile: MicronutrientProfile) async throws {
        guard let url = URL(string: "\(apiBaseURL)/api/micronutrient/profile") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
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
            Image(systemName: supplement.category.icon)
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
        switch category.color {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Add Supplement View

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var category: MicronutrientCategory = .vitamins
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
                                Image(systemName: category.icon)
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
            dosage: dosage,
            unit: unit.rawValue,
            frequency: frequency,
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
                                    Image(systemName: category.icon)
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
        case .vitamins: return CommonMicronutrients.vitamins
        case .minerals: return CommonMicronutrients.minerals
        case .probiotics: return CommonMicronutrients.probiotics
        case .omega3: return CommonMicronutrients.omega3
        case .antioxidants: return CommonMicronutrients.antioxidants
        case .other: return []
        }
    }
}

#Preview {
    MicronutrientProfileView(userData: nil)
}
