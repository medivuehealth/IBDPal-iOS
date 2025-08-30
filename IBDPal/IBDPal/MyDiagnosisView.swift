import SwiftUI

struct MyDiagnosisView: View {
    let userData: UserData?
    @Environment(\.dismiss) private var dismiss
    
    // Basic Diagnosis Information
    @State private var diagnosis = "Select your diagnosis"
    @State private var diagnosisYear = "Select year"
    @State private var diagnosisMonth = "Select month"
    @State private var diseaseLocation = "Select location"
    @State private var diseaseBehavior = "Select behavior"
    @State private var diseaseSeverity = "Select severity"
    
    // Medication Information
    @State private var takingMedications = "Select"
    @State private var currentMedications: [String] = []
    @State private var selectedMedication = "Select medication"
    @State private var medicationComplications: [String] = []
    @State private var selectedComplication = "Select complication"
    
    // Health Status
    @State private var isAnemic = "Select"
    @State private var anemiaSeverity = "Select severity"
    @State private var giSpecialistFrequency = "Select frequency"
    @State private var lastGiVisit = Date()
    
    // Additional IBD Questions
    @State private var familyHistory = "Select"
    @State private var surgeryHistory = "Select"
    @State private var hospitalizations = "Select"
    @State private var flareFrequency = "Select frequency"
    @State private var currentSymptoms: [String] = []
    @State private var selectedSymptom = "Select symptom"
    @State private var dietaryRestrictions: [String] = []
    @State private var selectedRestriction = "Select restriction"
    @State private var comorbidities: [String] = []
    @State private var selectedComorbidity = "Select comorbidity"
    
    // Form State
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var currentStep = 1
    private let totalSteps = 4
    
    // Options
    private let diagnosisOptions = [
        "Select your diagnosis",
        "Crohn's Disease",
        "Ulcerative Colitis", 
        "Indeterminate Colitis",
        "Microscopic Colitis",
        "IBS (Irritable Bowel Syndrome)",
        "Other IBD"
    ]
    
    private let yearOptions: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return ["Select year"] + (currentYear-49...currentYear).reversed().map(String.init)
    }()
    
    private let monthOptions = [
        "Select month",
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    private let locationOptions = [
        "Select location",
        "Small intestine only",
        "Large intestine only", 
        "Both small and large intestine",
        "Upper GI tract",
        "Perianal area",
        "Other"
    ]
    
    private let behaviorOptions = [
        "Select behavior",
        "Inflammatory",
        "Stricturing",
        "Penetrating",
        "Mixed"
    ]
    
    private let severityOptions = [
        "Select severity",
        "Mild",
        "Moderate", 
        "Severe"
    ]
    
    private let yesNoOptions = ["Select", "Yes", "No"]
    
    private let medicationOptions = [
        "Select medication",
        "Mesalamine (Asacol, Pentasa, Lialda)",
        "Sulfasalazine (Azulfidine)",
        "Corticosteroids (Prednisone, Budesonide)",
        "Azathioprine (Imuran)",
        "Mercaptopurine (6-MP, Purinethol)",
        "Methotrexate (Rheumatrex, Trexall)",
        "Infliximab (Remicade)",
        "Adalimumab (Humira)",
        "Certolizumab (Cimzia)",
        "Vedolizumab (Entyvio)",
        "Ustekinumab (Stelara)",
        "Tofacitinib (Xeljanz)",
        "Golimumab (Simponi)",
        "Natalizumab (Tysabri)",
        "Filgotinib (Jyseleca)",
        "Upadacitinib (Rinvoq)",
        "Other"
    ]
    
    private let complicationOptions = [
        "Select complication",
        "Infection",
        "Liver problems",
        "Skin reactions",
        "Joint pain",
        "Eye problems",
        "Fatigue",
        "Nausea",
        "Other"
    ]
    
    private let frequencyOptions = [
        "Select frequency",
        "Every 3 months",
        "Every 6 months",
        "Once a year",
        "As needed",
        "Never"
    ]
    
    private let symptomOptions = [
        "Select symptom",
        "Abdominal pain",
        "Diarrhea",
        "Constipation",
        "Rectal bleeding",
        "Fatigue",
        "Weight loss",
        "Fever",
        "Joint pain",
        "Skin problems",
        "Eye problems",
        "Other"
    ]
    
    private let restrictionOptions = [
        "Select restriction",
        "Gluten-free",
        "Dairy-free",
        "Low FODMAP",
        "Low fiber",
        "Low fat",
        "No nuts/seeds",
        "No spicy foods",
        "Other"
    ]
    
    private let comorbidityOptions = [
        "Select comorbidity",
        "Arthritis",
        "Osteoporosis",
        "Liver disease",
        "Kidney disease",
        "Heart disease",
        "Diabetes",
        "Depression/Anxiety",
        "Other"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("My Diagnosis Assessment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Help us understand your IBD journey for personalized care")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        ProgressView(value: Double(currentStep), total: Double(totalSteps))
                            .progressViewStyle(LinearProgressViewStyle(tint: .ibdPrimary))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("Step \(currentStep) of \(totalSteps)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimary)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 1 {
                        Button("← Previous") {
                            currentStep -= 1
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    } else {
                        Spacer()
                    }
                    
                    if currentStep < totalSteps {
                        Button("Next →") {
                            if validateCurrentStep() {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Save Diagnosis") {
                            handleSave()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                    }
                }
                .padding()
                
                // Form Content
                VStack(spacing: 24) {
                    switch currentStep {
                    case 1:
                        renderStep1()
                    case 2:
                        renderStep2()
                    case 3:
                        renderStep3()
                    case 4:
                        renderStep4()
                    default:
                        renderStep1()
                    }
                }
                .padding()
            }
            .onAppear {
                loadExistingDiagnosis()
            }
        }
        .navigationTitle("My Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your diagnosis information has been saved successfully. This helps us provide personalized insights and recommendations for your IBD management.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Step Rendering
    
    private func renderStep1() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Diagnosis Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimary)
            
            // Diagnosis Type
            VStack(alignment: .leading, spacing: 8) {
                Text("What is your diagnosis?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Diagnosis", selection: $diagnosis) {
                    ForEach(diagnosisOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Diagnosis Date
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Year diagnosed")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Picker("Year", selection: $diagnosisYear) {
                        ForEach(yearOptions, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Month diagnosed")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Picker("Month", selection: $diagnosisMonth) {
                        ForEach(monthOptions, id: \.self) { month in
                            Text(month).tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                }
            }
            
            // Disease Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Where is your disease located?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Location", selection: $diseaseLocation) {
                    ForEach(locationOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Disease Behavior
            VStack(alignment: .leading, spacing: 8) {
                Text("What is your disease behavior?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Behavior", selection: $diseaseBehavior) {
                    ForEach(behaviorOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Disease Severity
            VStack(alignment: .leading, spacing: 8) {
                Text("How severe is your disease?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Severity", selection: $diseaseSeverity) {
                    ForEach(severityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
        }
    }
    
    private func renderStep2() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Medication Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimary)
            
            // Taking Medications
            VStack(alignment: .leading, spacing: 8) {
                Text("Are you currently taking medications for IBD?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Taking Medications", selection: $takingMedications) {
                    ForEach(yesNoOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            if takingMedications == "Yes" {
                // Current Medications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Medications")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    HStack {
                        Picker("Medication", selection: $selectedMedication) {
                            ForEach(medicationOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.ibdSurfaceBackground)
                        .cornerRadius(8)
                        
                        Button("Add") {
                            addMedication()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(selectedMedication.isEmpty || selectedMedication == "Select medication")
                    }
                    
                    // Selected Medications
                    if !currentMedications.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                            ForEach(currentMedications, id: \.self) { medication in
                                HStack {
                                    Text(medication)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.ibdPrimary.opacity(0.1))
                                        .foregroundColor(.ibdPrimary)
                                        .cornerRadius(16)
                                    
                                    Button(action: {
                                        removeMedication(medication)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Medication Complications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medication Complications")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    HStack {
                        Picker("Complication", selection: $selectedComplication) {
                            ForEach(complicationOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.ibdSurfaceBackground)
                        .cornerRadius(8)
                        
                        Button("Add") {
                            addComplication()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(selectedComplication.isEmpty || selectedComplication == "Select complication")
                    }
                    
                    // Selected Complications
                    if !medicationComplications.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                            ForEach(medicationComplications, id: \.self) { complication in
                                HStack {
                                    Text(complication)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundColor(.orange)
                                        .cornerRadius(16)
                                    
                                    Button(action: {
                                        removeComplication(complication)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func renderStep3() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Status")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimary)
            
            // Anemia
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you have anemia?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Anemia", selection: $isAnemic) {
                    ForEach(yesNoOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            if isAnemic == "Yes" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How severe is your anemia?")
                        .font(.headline)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Picker("Anemia Severity", selection: $anemiaSeverity) {
                        ForEach(severityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                }
            }
            
            // GI Specialist Visits
            VStack(alignment: .leading, spacing: 8) {
                Text("How often do you see a GI specialist?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("GI Specialist Frequency", selection: $giSpecialistFrequency) {
                    ForEach(frequencyOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Last GI Visit
            VStack(alignment: .leading, spacing: 8) {
                Text("When was your last GI visit?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                DatePicker("Last GI Visit", selection: $lastGiVisit, displayedComponents: .date)
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
            }
        }
    }
    
    private func renderStep4() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Additional Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimary)
            
            // Family History
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you have a family history of IBD?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Family History", selection: $familyHistory) {
                    ForEach(yesNoOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Surgery History
            VStack(alignment: .leading, spacing: 8) {
                Text("Have you had surgery for IBD?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Surgery History", selection: $surgeryHistory) {
                    ForEach(yesNoOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Hospitalizations
            VStack(alignment: .leading, spacing: 8) {
                Text("Have you been hospitalized for IBD?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Hospitalizations", selection: $hospitalizations) {
                    ForEach(yesNoOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Flare Frequency
            VStack(alignment: .leading, spacing: 8) {
                Text("How often do you experience flares?")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Picker("Flare Frequency", selection: $flareFrequency) {
                    ForEach(frequencyOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(8)
            }
            
            // Current Symptoms
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Symptoms")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack {
                    Picker("Symptom", selection: $selectedSymptom) {
                        ForEach(symptomOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                    
                    Button("Add") {
                        addSymptom()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(selectedSymptom.isEmpty || selectedSymptom == "Select symptom")
                }
                
                // Selected Symptoms
                if !currentSymptoms.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(currentSymptoms, id: \.self) { symptom in
                            HStack {
                                Text(symptom)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(16)
                                
                                Button(action: {
                                    removeSymptom(symptom)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            
            // Dietary Restrictions
            VStack(alignment: .leading, spacing: 12) {
                Text("Dietary Restrictions")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack {
                    Picker("Restriction", selection: $selectedRestriction) {
                        ForEach(restrictionOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                    
                    Button("Add") {
                        addRestriction()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(selectedRestriction.isEmpty || selectedRestriction == "Select restriction")
                }
                
                // Selected Restrictions
                if !dietaryRestrictions.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(dietaryRestrictions, id: \.self) { restriction in
                            HStack {
                                Text(restriction)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(16)
                                
                                Button(action: {
                                    removeRestriction(restriction)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            
            // Comorbidities
            VStack(alignment: .leading, spacing: 12) {
                Text("Other Health Conditions")
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                HStack {
                    Picker("Comorbidity", selection: $selectedComorbidity) {
                        ForEach(comorbidityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                    
                    Button("Add") {
                        addComorbidity()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(selectedComorbidity.isEmpty || selectedComorbidity == "Select comorbidity")
                }
                
                // Selected Comorbidities
                if !comorbidities.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(comorbidities, id: \.self) { comorbidity in
                            HStack {
                                Text(comorbidity)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(16)
                                
                                Button(action: {
                                    removeComorbidity(comorbidity)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func addMedication() {
        if !selectedMedication.isEmpty && selectedMedication != "Select medication" && !currentMedications.contains(selectedMedication) {
            currentMedications.append(selectedMedication)
            selectedMedication = ""
        }
    }
    
    private func removeMedication(_ medication: String) {
        currentMedications.removeAll { $0 == medication }
    }
    
    private func addComplication() {
        if !selectedComplication.isEmpty && selectedComplication != "Select complication" && !medicationComplications.contains(selectedComplication) {
            medicationComplications.append(selectedComplication)
            selectedComplication = ""
        }
    }
    
    private func removeComplication(_ complication: String) {
        medicationComplications.removeAll { $0 == complication }
    }
    
    private func addSymptom() {
        if !selectedSymptom.isEmpty && selectedSymptom != "Select symptom" && !currentSymptoms.contains(selectedSymptom) {
            currentSymptoms.append(selectedSymptom)
            selectedSymptom = ""
        }
    }
    
    private func removeSymptom(_ symptom: String) {
        currentSymptoms.removeAll { $0 == symptom }
    }
    
    private func addRestriction() {
        if !selectedRestriction.isEmpty && selectedRestriction != "Select restriction" && !dietaryRestrictions.contains(selectedRestriction) {
            dietaryRestrictions.append(selectedRestriction)
            selectedRestriction = ""
        }
    }
    
    private func removeRestriction(_ restriction: String) {
        dietaryRestrictions.removeAll { $0 == restriction }
    }
    
    private func addComorbidity() {
        if !selectedComorbidity.isEmpty && selectedComorbidity != "Select comorbidity" && !comorbidities.contains(selectedComorbidity) {
            comorbidities.append(selectedComorbidity)
            selectedComorbidity = ""
        }
    }
    
    private func removeComorbidity(_ comorbidity: String) {
        comorbidities.removeAll { $0 == comorbidity }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            return !diagnosis.isEmpty && diagnosis != "Select your diagnosis" &&
                   !diagnosisYear.isEmpty && diagnosisYear != "Select year" &&
                   !diagnosisMonth.isEmpty && diagnosisMonth != "Select month" &&
                   !diseaseLocation.isEmpty && diseaseLocation != "Select location" &&
                   !diseaseBehavior.isEmpty && diseaseBehavior != "Select behavior" &&
                   !diseaseSeverity.isEmpty && diseaseSeverity != "Select severity"
        case 2:
            return !takingMedications.isEmpty && takingMedications != "Select"
        case 3:
            return !giSpecialistFrequency.isEmpty && giSpecialistFrequency != "Select frequency"
        case 4:
            return !familyHistory.isEmpty && familyHistory != "Select" &&
                   !surgeryHistory.isEmpty && surgeryHistory != "Select" &&
                   !hospitalizations.isEmpty && hospitalizations != "Select" &&
                   !flareFrequency.isEmpty && flareFrequency != "Select frequency"
        default:
            return false
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        // Format the date for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let lastGiVisitString = dateFormatter.string(from: lastGiVisit)
        
        // Prepare diagnosis data
        let diagnosisData: [String: Any] = [
            "diagnosis": diagnosis,
            "diagnosisYear": diagnosisYear.isEmpty ? nil : Int(diagnosisYear),
            "diagnosisMonth": diagnosisMonth.isEmpty ? nil : diagnosisMonth,
            "diseaseLocation": diseaseLocation.isEmpty ? nil : diseaseLocation,
            "diseaseBehavior": diseaseBehavior.isEmpty ? nil : diseaseBehavior,
            "diseaseSeverity": diseaseSeverity.isEmpty ? nil : diseaseSeverity,
            "takingMedications": takingMedications.isEmpty ? nil : takingMedications,
            "currentMedications": currentMedications,
            "medicationComplications": medicationComplications,
            "isAnemic": isAnemic.isEmpty ? nil : isAnemic,
            "anemiaSeverity": anemiaSeverity.isEmpty ? nil : anemiaSeverity,
            "giSpecialistFrequency": giSpecialistFrequency.isEmpty ? nil : giSpecialistFrequency,
            "lastGiVisit": lastGiVisitString,
            "familyHistory": familyHistory.isEmpty ? nil : familyHistory,
            "surgeryHistory": surgeryHistory.isEmpty ? nil : surgeryHistory,
            "hospitalizations": hospitalizations.isEmpty ? nil : hospitalizations,
            "flareFrequency": flareFrequency.isEmpty ? nil : flareFrequency,
            "currentSymptoms": currentSymptoms,
            "dietaryRestrictions": dietaryRestrictions,
            "comorbidities": comorbidities
        ]
        
        // Make API call to save diagnosis
        saveDiagnosisToAPI(diagnosisData)
    }
    
    private func saveDiagnosisToAPI(_ data: [String: Any]) {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/diagnosis") else {
            handleError("Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            handleError("Failed to prepare request data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.handleError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.handleError("Invalid response")
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    self.showSuccessAlert = true
                } else {
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorResponse["error"] as? String {
                        self.handleError(errorMessage)
                    } else {
                        self.handleError("Failed to save diagnosis (Status: \(httpResponse.statusCode))")
                    }
                }
            }
        }.resume()
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func loadExistingDiagnosis() {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/diagnosis") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading diagnosis: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data else {
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let diagnosisData = json["diagnosis"] as? [String: Any] {
                        
                        // Populate form with existing data
                        self.diagnosis = diagnosisData["diagnosis"] as? String ?? ""
                        self.diagnosisYear = (diagnosisData["diagnosis_year"] as? Int)?.description ?? ""
                        self.diagnosisMonth = diagnosisData["diagnosis_month"] as? String ?? ""
                        self.diseaseLocation = diagnosisData["disease_location"] as? String ?? ""
                        self.diseaseBehavior = diagnosisData["disease_behavior"] as? String ?? ""
                        self.diseaseSeverity = diagnosisData["disease_severity"] as? String ?? ""
                        self.takingMedications = diagnosisData["taking_medications"] as? String ?? ""
                        self.currentMedications = diagnosisData["current_medications"] as? [String] ?? []
                        self.medicationComplications = diagnosisData["medication_complications"] as? [String] ?? []
                        self.isAnemic = diagnosisData["is_anemic"] as? String ?? ""
                        self.anemiaSeverity = diagnosisData["anemia_severity"] as? String ?? ""
                        self.giSpecialistFrequency = diagnosisData["gi_specialist_frequency"] as? String ?? ""
                        
                        // Parse last GI visit date
                        if let lastGiVisitString = diagnosisData["last_gi_visit"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            self.lastGiVisit = dateFormatter.date(from: lastGiVisitString) ?? Date()
                        } else {
                            self.lastGiVisit = Date()
                        }
                        
                        self.familyHistory = diagnosisData["family_history"] as? String ?? ""
                        self.surgeryHistory = diagnosisData["surgery_history"] as? String ?? ""
                        self.hospitalizations = diagnosisData["hospitalizations"] as? String ?? ""
                        self.flareFrequency = diagnosisData["flare_frequency"] as? String ?? ""
                        self.currentSymptoms = diagnosisData["current_symptoms"] as? [String] ?? []
                        self.dietaryRestrictions = diagnosisData["dietary_restrictions"] as? [String] ?? []
                        self.comorbidities = diagnosisData["comorbidities"] as? [String] ?? []
                    }
                } catch {
                    print("Error parsing diagnosis data: \(error)")
                }
            }
        }.resume()
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.ibdPrimary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.ibdPrimary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.ibdPrimary.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MyDiagnosisView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
} 