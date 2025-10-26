import Foundation
import SwiftUI

// MARK: - Healthcare Provider Target Configuration
// Allows healthcare providers to customize evidence-based targets
// Based on individual patient needs and clinical guidelines

struct HealthcareProviderTargetConfiguration: Codable {
    let providerId: String
    let patientId: String
    let configurationVersion: String
    let lastUpdated: Date
    
    // Medication Adherence Configuration
    var medicationAdherence: MedicationAdherenceConfiguration
    
    // Symptom Target Configuration
    var symptomTargets: SymptomTargetConfiguration
    
    // Health Metric Configuration
    var healthMetrics: HealthMetricConfiguration
    
    // Research Sources and Justification
    var researchSources: [String]
    var clinicalJustification: String
    var providerNotes: String
}

// MARK: - Configuration Structures

struct MedicationAdherenceConfiguration: Codable {
    var baseTarget: Double // Base adherence target (0-100%)
    var warningThreshold: Double // Warning threshold (0-100%)
    var criticalThreshold: Double // Critical threshold (0-100%)
    
    // Disease activity adjustments
    var remissionAdjustment: Double // Adjustment for remission
    var mildAdjustment: Double // Adjustment for mild activity
    var moderateAdjustment: Double // Adjustment for moderate activity
    var severeAdjustment: Double // Adjustment for severe activity
    
    // Medication complexity adjustments
    var complexityMultiplier: Double // Multiplier for complex regimens
    var maxComplexityAdjustment: Double // Maximum adjustment for complexity
    
    // Age-based adjustments
    var pediatricAdjustment: Double // Adjustment for <18 years
    var geriatricAdjustment: Double // Adjustment for >65 years
    
    // Provider overrides
    let allowProviderOverride: Bool
    let customTargets: [String: Double] // Custom targets by medication type
}

struct SymptomTargetConfiguration: Codable {
    var painTarget: SymptomTarget
    var stressTarget: SymptomTarget
    var fatigueTarget: SymptomTarget
    var bowelFrequencyTarget: SymptomTarget
    var urgencyTarget: SymptomTarget
    
    // Personalization settings
    var enablePersonalization: Bool
    var personalizationStrength: Double // 0.0-1.0 (how much to adjust based on history)
    var minimumTargetAdjustment: Int // Minimum target adjustment
    var maximumTargetAdjustment: Int // Maximum target adjustment
}

struct SymptomTarget: Codable {
    var baseTarget: Int // Base target value
    var warningThreshold: Int // Warning threshold
    var criticalThreshold: Int // Critical threshold
    
    // Disease activity adjustments
    var remissionAdjustment: Int
    var mildAdjustment: Int
    var moderateAdjustment: Int
    var severeAdjustment: Int
}

struct HealthMetricConfiguration: Codable {
    let medicationAdherence: HealthMetricTarget
    let bowelFrequency: HealthMetricTarget
    let painLevel: HealthMetricTarget
    let urgencyLevel: HealthMetricTarget
    let weightChange: HealthMetricTarget
}

struct HealthMetricTarget: Codable {
    let target: Double
    let warningThreshold: Double
    let criticalThreshold: Double
    
    // Disease activity adjustments
    let remissionAdjustment: Double
    let mildAdjustment: Double
    let moderateAdjustment: Double
    let severeAdjustment: Double
}

// MARK: - Configuration Manager

class HealthcareProviderTargetConfigurationManager: ObservableObject {
    static let shared = HealthcareProviderTargetConfigurationManager()
    
    @Published var currentConfiguration: HealthcareProviderTargetConfiguration?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Configuration Management
    
    /// Load configuration for a specific patient
    func loadConfiguration(for patientId: String, providerId: String) async {
        isLoading = true
        error = nil
        
        do {
            // In a real implementation, this would fetch from a server
            let configuration = try await fetchConfigurationFromServer(patientId: patientId, providerId: providerId)
            await MainActor.run {
                self.currentConfiguration = configuration
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load configuration: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Save configuration for a specific patient
    func saveConfiguration(_ configuration: HealthcareProviderTargetConfiguration) async {
        isLoading = true
        error = nil
        
        do {
            try await saveConfigurationToServer(configuration)
            await MainActor.run {
                self.currentConfiguration = configuration
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to save configuration: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Create default configuration based on clinical guidelines
    func createDefaultConfiguration(for patientId: String, providerId: String) -> HealthcareProviderTargetConfiguration {
        return HealthcareProviderTargetConfiguration(
            providerId: providerId,
            patientId: patientId,
            configurationVersion: "1.0",
            lastUpdated: Date(),
            medicationAdherence: MedicationAdherenceConfiguration(
                baseTarget: 90.0,
                warningThreshold: 80.0,
                criticalThreshold: 70.0,
                remissionAdjustment: -5.0,
                mildAdjustment: 0.0,
                moderateAdjustment: 5.0,
                severeAdjustment: 10.0,
                complexityMultiplier: 2.0,
                maxComplexityAdjustment: 10.0,
                pediatricAdjustment: 5.0,
                geriatricAdjustment: -5.0,
                allowProviderOverride: true,
                customTargets: [:]
            ),
            symptomTargets: SymptomTargetConfiguration(
                painTarget: SymptomTarget(
                    baseTarget: 3,
                    warningThreshold: 5,
                    criticalThreshold: 7,
                    remissionAdjustment: -1,
                    mildAdjustment: 0,
                    moderateAdjustment: 1,
                    severeAdjustment: 2
                ),
                stressTarget: SymptomTarget(
                    baseTarget: 5,
                    warningThreshold: 7,
                    criticalThreshold: 8,
                    remissionAdjustment: -1,
                    mildAdjustment: 0,
                    moderateAdjustment: 1,
                    severeAdjustment: 2
                ),
                fatigueTarget: SymptomTarget(
                    baseTarget: 4,
                    warningThreshold: 6,
                    criticalThreshold: 8,
                    remissionAdjustment: -1,
                    mildAdjustment: 0,
                    moderateAdjustment: 1,
                    severeAdjustment: 2
                ),
                bowelFrequencyTarget: SymptomTarget(
                    baseTarget: 2,
                    warningThreshold: 4,
                    criticalThreshold: 6,
                    remissionAdjustment: -1,
                    mildAdjustment: 0,
                    moderateAdjustment: 1,
                    severeAdjustment: 2
                ),
                urgencyTarget: SymptomTarget(
                    baseTarget: 3,
                    warningThreshold: 6,
                    criticalThreshold: 8,
                    remissionAdjustment: -1,
                    mildAdjustment: 0,
                    moderateAdjustment: 1,
                    severeAdjustment: 2
                ),
                enablePersonalization: true,
                personalizationStrength: 0.3,
                minimumTargetAdjustment: -2,
                maximumTargetAdjustment: 2
            ),
            healthMetrics: HealthMetricConfiguration(
                medicationAdherence: HealthMetricTarget(
                    target: 90.0,
                    warningThreshold: 80.0,
                    criticalThreshold: 70.0,
                    remissionAdjustment: -5.0,
                    mildAdjustment: 0.0,
                    moderateAdjustment: 5.0,
                    severeAdjustment: 10.0
                ),
                bowelFrequency: HealthMetricTarget(
                    target: 2.0,
                    warningThreshold: 4.0,
                    criticalThreshold: 6.0,
                    remissionAdjustment: -0.5,
                    mildAdjustment: 0.0,
                    moderateAdjustment: 1.0,
                    severeAdjustment: 2.0
                ),
                painLevel: HealthMetricTarget(
                    target: 3.0,
                    warningThreshold: 5.0,
                    criticalThreshold: 7.0,
                    remissionAdjustment: -1.0,
                    mildAdjustment: 0.0,
                    moderateAdjustment: 1.0,
                    severeAdjustment: 2.0
                ),
                urgencyLevel: HealthMetricTarget(
                    target: 3.0,
                    warningThreshold: 6.0,
                    criticalThreshold: 8.0,
                    remissionAdjustment: -1.0,
                    mildAdjustment: 0.0,
                    moderateAdjustment: 1.0,
                    severeAdjustment: 2.0
                ),
                weightChange: HealthMetricTarget(
                    target: 0.0,
                    warningThreshold: 2.0,
                    criticalThreshold: 4.0,
                    remissionAdjustment: 0.0,
                    mildAdjustment: 0.0,
                    moderateAdjustment: 0.0,
                    severeAdjustment: 0.0
                )
            ),
            researchSources: [
                "AGA Clinical Practice Update (2024)",
                "Crohn's & Colitis Foundation Guidelines",
                "ECCO Guidelines",
                "World Gastroenterology Organisation"
            ],
            clinicalJustification: "Configuration based on evidence-based clinical guidelines and individual patient assessment.",
            providerNotes: "Default configuration. Please customize based on patient-specific needs."
        )
    }
    
    // MARK: - Helper Functions
    
    private func fetchConfigurationFromServer(patientId: String, providerId: String) async throws -> HealthcareProviderTargetConfiguration {
        // In a real implementation, this would make an API call
        // For now, return a default configuration
        return createDefaultConfiguration(for: patientId, providerId: providerId)
    }
    
    private func saveConfigurationToServer(_ configuration: HealthcareProviderTargetConfiguration) async throws {
        // In a real implementation, this would make an API call to save the configuration
        print("💾 [HealthcareProviderTargetConfigurationManager] Saving configuration for patient: \(configuration.patientId)")
    }
    
    /// Apply configuration to evidence-based targets
    func applyConfigurationToTargets(_ configuration: HealthcareProviderTargetConfiguration) -> EvidenceBasedTargetsResult {
        // This would integrate with the EvidenceBasedTargetCalculator
        // to apply the healthcare provider's customizations
        // For now, return a placeholder
        return EvidenceBasedTargetsResult(
            medicationAdherence: MedicationAdherenceTarget(
                target: configuration.medicationAdherence.baseTarget,
                warningThreshold: configuration.medicationAdherence.warningThreshold,
                criticalThreshold: configuration.medicationAdherence.criticalThreshold,
                basedOn: "Healthcare provider configuration"
            ),
            symptoms: SymptomTargets(
                painTarget: configuration.symptomTargets.painTarget.baseTarget,
                stressTarget: configuration.symptomTargets.stressTarget.baseTarget,
                fatigueTarget: configuration.symptomTargets.fatigueTarget.baseTarget,
                bowelFrequencyTarget: configuration.symptomTargets.bowelFrequencyTarget.baseTarget,
                urgencyTarget: configuration.symptomTargets.urgencyTarget.baseTarget
            ),
            healthMetrics: HealthMetricTargets(
                medicationAdherenceTarget: configuration.healthMetrics.medicationAdherence.target,
                bowelFrequencyTarget: configuration.healthMetrics.bowelFrequency.target,
                painTarget: configuration.healthMetrics.painLevel.target,
                urgencyTarget: configuration.healthMetrics.urgencyLevel.target,
                weightChangeTarget: configuration.healthMetrics.weightChange.target,
                medicationAdherenceWarning: configuration.healthMetrics.medicationAdherence.warningThreshold,
                bowelFrequencyWarning: configuration.healthMetrics.bowelFrequency.warningThreshold,
                painWarning: configuration.healthMetrics.painLevel.warningThreshold,
                urgencyWarning: configuration.healthMetrics.urgencyLevel.warningThreshold,
                weightChangeWarning: configuration.healthMetrics.weightChange.warningThreshold
            ),
            lastUpdated: configuration.lastUpdated,
            researchSources: configuration.researchSources
        )
    }
}

// MARK: - Configuration UI Components

struct HealthcareProviderTargetConfigurationView: View {
    @StateObject private var configurationManager = HealthcareProviderTargetConfigurationManager.shared
    @State private var configuration: HealthcareProviderTargetConfiguration?
    
    let patientId: String
    let providerId: String
    
    var body: some View {
        NavigationView {
            VStack {
                if configurationManager.isLoading {
                    ProgressView("Loading configuration...")
                } else if let error = configurationManager.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if let config = configuration {
                    ConfigurationFormView(configuration: config, configurationManager: configurationManager)
                } else {
                    Text("No configuration found")
                }
            }
            .navigationTitle("Target Configuration")
            .onAppear {
                Task {
                    await configurationManager.loadConfiguration(for: patientId, providerId: providerId)
                    configuration = configurationManager.currentConfiguration
                }
            }
        }
    }
}

struct ConfigurationFormView: View {
    @State private var configuration: HealthcareProviderTargetConfiguration
    @ObservedObject private var configurationManager: HealthcareProviderTargetConfigurationManager
    
    init(configuration: HealthcareProviderTargetConfiguration, configurationManager: HealthcareProviderTargetConfigurationManager) {
        self._configuration = State(initialValue: configuration)
        self.configurationManager = configurationManager
    }
    
    var body: some View {
        Form {
            Section("Medication Adherence") {
                HStack {
                    Text("Base Target")
                    Spacer()
                    TextField("Target %", value: $configuration.medicationAdherence.baseTarget, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Warning Threshold")
                    Spacer()
                    TextField("Warning %", value: $configuration.medicationAdherence.warningThreshold, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            
            Section("Symptom Targets") {
                HStack {
                    Text("Pain Target")
                    Spacer()
                    TextField("Target", value: $configuration.symptomTargets.painTarget.baseTarget, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
                HStack {
                    Text("Stress Target")
                    Spacer()
                    TextField("Target", value: $configuration.symptomTargets.stressTarget.baseTarget, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
            }
            
            Section("Provider Notes") {
                TextEditor(text: $configuration.providerNotes)
                    .frame(minHeight: 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await configurationManager.saveConfiguration(configuration)
                    }
                }
            }
        }
    }
}
