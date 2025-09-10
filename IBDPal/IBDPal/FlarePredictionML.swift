import Foundation
import SwiftUI

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
    
    var threshold: Double {
        switch self {
        case .low: return 0.0
        case .moderate: return 0.3
        case .high: return 0.6
        case .veryHigh: return 0.8
        }
    }
}
import CoreML
import Accelerate

// MARK: - Data Models for API Response
struct JournalEntry: Codable {
    let entry_id: String
    let user_id: String
    let entry_date: String
    let meals: [Meal]?
    let symptoms: [Symptom]?
    let bowel_movements: [BowelMovement]?
    let bowel_frequency: Int?
    let blood_present: Bool?
    let mucus_present: Bool?
    let pain_severity: Int?
    let pain_location: String?
    let urgency_level: Int?
    let bristol_scale: Int?
    let hydration: Int?
    let notes: String?
    let created_at: String
    let updated_at: String
}

struct Meal: Codable {
    let meal_id: String
    let meal_type: String
    let description: String
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fiber: Int?
    let fat: Int?
}

struct Symptom: Codable {
    let symptom_id: String
    let type: String
    let severity: Int
    let notes: String?
}

struct BowelMovement: Codable {
    let movement_id: String
    let time: String
    let consistency: Int
    let urgency: Int?
    let blood_present: Bool?
    let notes: String?
}

// MARK: - Extensions
extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
}

// MARK: - Flare Prediction ML Models
struct FlarePredictionInput {
    let nutritionData: NutritionFeatures
    let symptomData: SymptomFeatures
    let lifestyleData: LifestyleFeatures
    let medicationData: MedicationFeatures
    let environmentalData: EnvironmentalFeatures
    let historicalData: HistoricalFeatures
}

struct FlarePredictionOutput {
    let flareProbability: Double
    let confidenceScore: Double
    let riskLevel: FlareRiskLevel
    let predictedOnset: Date?
    let contributingFactors: [String: Double]
    let recommendations: [FlarePreventionAction]
    let nextPredictionDate: Date
}


// MARK: - Feature Structures
struct NutritionFeatures {
    let fiberIntake: Double
    let proteinIntake: Double
    let fatIntake: Double
    let fodmapScore: Double
    let triggerFoodCount: Int
    let inflammatoryFoodCount: Int
    let hydrationLevel: Double
    let mealTiming: [Double] // Hours since last meal
    let foodDiversity: Double
    let supplementIntake: [String: Double]
}

struct SymptomFeatures {
    let abdominalPain: Double
    let diarrhea: Double
    let constipation: Double
    let bloating: Double
    let fatigue: Double
    let appetite: Double
    let weightChange: Double
    let bloodInStool: Bool
    let urgency: Double
    let incompleteEvacuation: Bool
    let symptomSeverity: Double
    let symptomDuration: Double
}

struct LifestyleFeatures {
    let stressLevel: Double
    let sleepQuality: Double
    let sleepDuration: Double
    let exerciseLevel: Double
    let exerciseType: String
    let smokingStatus: Bool
    let alcoholConsumption: Double
    let caffeineIntake: Double
    let waterIntake: Double
    let mealRegularity: Double
}

struct MedicationFeatures {
    let medicationAdherence: Double
    let medicationType: [String: Bool]
    let dosageCompliance: Double
    let sideEffects: [String: Double]
    let medicationChanges: Bool
    let lastMedicationTime: Date?
    let medicationEffectiveness: Double
}

struct EnvironmentalFeatures {
    let season: String
    let temperature: Double
    let humidity: Double
    let airQuality: Double
    let travelStatus: Bool
    let timeZone: String
    let location: String
    let weatherConditions: String
}

struct HistoricalFeatures {
    let previousFlares: Int
    let averageFlareDuration: Double
    let timeSinceLastFlare: Double
    let flarePattern: [Double] // Historical flare probabilities
    let seasonalPattern: [Double]
    let medicationHistory: [String: Double]
    let dietHistory: [String: Double]
    let stressHistory: [Double]
}

// MARK: - Flare Prediction ML Engine
class FlarePredictionMLEngine: ObservableObject {
    static let shared = FlarePredictionMLEngine()
    
    @Published var modelAccuracy: Double = 0.0
    @Published var lastTrainingDate: Date?
    @Published var isModelReady: Bool = false
    
    private var flareModel: MLModel?
    private let modelName = "IBDFlarePredictionModel"
    
    private init() {
        loadModel()
    }
    
    // MARK: - Model Management
    private func loadModel() {
        do {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
                flareModel = try MLModel(contentsOf: modelURL)
                isModelReady = true
                print("✅ Flare prediction model loaded successfully")
            } else {
                print("⚠️ No pre-trained model found, will use rule-based prediction")
                isModelReady = false
            }
        } catch {
            print("❌ Error loading flare prediction model: \(error)")
            isModelReady = false
        }
    }
    
    // MARK: - Main Prediction Function
    func predictFlare(for userData: UserData, journalEntries: [JournalEntry]) async -> FlarePredictionOutput {
        let input = prepareInputFeatures(userData: userData, journalEntries: journalEntries)
        
        if isModelReady, let model = flareModel {
            return await predictWithMLModel(input: input, model: model)
        } else {
            print("📊 Using rule-based prediction (ML model not available)")
            return predictWithRuleBased(input: input)
        }
    }
    
    // MARK: - ML Model Prediction
    private func predictWithMLModel(input: FlarePredictionInput, model: MLModel) async -> FlarePredictionOutput {
        do {
            guard let features = extractMLFeatures(from: input) else {
                print("⚠️ ML features not available, using rule-based prediction")
                return predictWithRuleBased(input: input)
            }
            
            let prediction = try await model.prediction(from: features)
            
            let flareProbability = extractProbability(from: prediction)
            let confidenceScore = calculateConfidence(from: prediction)
            let riskLevel = determineRiskLevel(probability: flareProbability)
            let contributingFactors = extractContributingFactors(from: prediction, input: input)
            let recommendations = generateRecommendations(for: riskLevel, factors: contributingFactors)
            
            return FlarePredictionOutput(
                flareProbability: flareProbability,
                confidenceScore: confidenceScore,
                riskLevel: riskLevel,
                predictedOnset: calculatePredictedOnset(probability: flareProbability),
                contributingFactors: contributingFactors,
                recommendations: recommendations,
                nextPredictionDate: Date().addingTimeInterval(24 * 3600) // Next day
            )
        } catch {
            print("❌ ML prediction failed: \(error), falling back to rule-based")
            return predictWithRuleBased(input: input)
        }
    }
    
    // MARK: - Rule-Based Prediction (Fallback)
    private func predictWithRuleBased(input: FlarePredictionInput) -> FlarePredictionOutput {
        var probability = 0.0
        var contributingFactors: [String: Double] = [:]
        
        // Nutrition factors (30% weight)
        let nutritionRisk = calculateNutritionRisk(input.nutritionData)
        probability += nutritionRisk * 0.3
        contributingFactors["nutrition"] = nutritionRisk
        
        // Symptom factors (40% weight)
        let symptomRisk = calculateSymptomRisk(input.symptomData)
        probability += symptomRisk * 0.4
        contributingFactors["symptoms"] = symptomRisk
        
        // Lifestyle factors (20% weight)
        let lifestyleRisk = calculateLifestyleRisk(input.lifestyleData)
        probability += lifestyleRisk * 0.2
        contributingFactors["lifestyle"] = lifestyleRisk
        
        // Medication factors (10% weight)
        let medicationRisk = calculateMedicationRisk(input.medicationData)
        probability += medicationRisk * 0.1
        contributingFactors["medication"] = medicationRisk
        
        let riskLevel = determineRiskLevel(probability: probability)
        let recommendations = generateRecommendations(for: riskLevel, factors: contributingFactors)
        
        return FlarePredictionOutput(
            flareProbability: min(probability, 1.0),
            confidenceScore: 0.7, // Lower confidence for rule-based
            riskLevel: riskLevel,
            predictedOnset: calculatePredictedOnset(probability: probability),
            contributingFactors: contributingFactors,
            recommendations: recommendations,
            nextPredictionDate: Date().addingTimeInterval(24 * 3600)
        )
    }
    
    // MARK: - Feature Preparation
    private func prepareInputFeatures(userData: UserData, journalEntries: [JournalEntry]) -> FlarePredictionInput {
        let nutritionData = extractNutritionFeatures(from: journalEntries)
        let symptomData = extractSymptomFeatures(from: journalEntries)
        let lifestyleData = extractLifestyleFeatures(from: journalEntries, userData: userData)
        let medicationData = extractMedicationFeatures(from: journalEntries, userData: userData)
        let environmentalData = extractEnvironmentalFeatures()
        let historicalData = extractHistoricalFeatures(from: journalEntries, userData: userData)
        
        return FlarePredictionInput(
            nutritionData: nutritionData,
            symptomData: symptomData,
            lifestyleData: lifestyleData,
            medicationData: medicationData,
            environmentalData: environmentalData,
            historicalData: historicalData
        )
    }
    
    // MARK: - Feature Extraction
    private func extractNutritionFeatures(from entries: [JournalEntry]) -> NutritionFeatures {
        let recentEntries = Array(entries.suffix(7)) // Last 7 days
        
        var fiberIntake = 0.0
        var proteinIntake = 0.0
        var fatIntake = 0.0
        let _fodmapScore = calculateFODMAPScore(entries: recentEntries)
        var triggerFoodCount = 0
        var inflammatoryFoodCount = 0
        var hydrationLevel = 0.0
        var mealTimings: [Double] = []
        var foodItems: Set<String> = []
        let supplementIntake: [String: Double] = [:]
        
        for entry in recentEntries {
            if let meals = entry.meals {
                for meal in meals {
                    // Use nutrition data from meal properties
                    fiberIntake += Double(meal.fiber ?? 0)
                    proteinIntake += Double(meal.protein ?? 0)
                    fatIntake += Double(meal.fat ?? 0)
                    
                    if isTriggerFood(meal.description) {
                        triggerFoodCount += 1
                    }
                    if isInflammatoryFood(meal.description) {
                        inflammatoryFoodCount += 1
                    }
                    
                    foodItems.insert(meal.description)
                }
            }
            
            if let hydration = entry.hydration {
                hydrationLevel += Double(hydration)
            }
            
            let hoursSinceMidnight = Calendar.current.component(.hour, from: entry.entry_date.toDate() ?? Date())
            mealTimings.append(Double(hoursSinceMidnight))
        }
        
        let entryCount = Double(recentEntries.count)
        let averageFiber = entryCount > 0 ? fiberIntake / entryCount : 0.0
        let averageProtein = entryCount > 0 ? proteinIntake / entryCount : 0.0
        let averageFat = entryCount > 0 ? fatIntake / entryCount : 0.0
        let averageHydration = entryCount > 0 ? hydrationLevel / entryCount : 0.0
        let foodDiversity = entryCount > 0 ? Double(foodItems.count) / entryCount : 0.0
        
        return NutritionFeatures(
            fiberIntake: averageFiber,
            proteinIntake: averageProtein,
            fatIntake: averageFat,
            fodmapScore: calculateFODMAPScore(entries: recentEntries),
            triggerFoodCount: triggerFoodCount,
            inflammatoryFoodCount: inflammatoryFoodCount,
            hydrationLevel: averageHydration,
            mealTiming: mealTimings,
            foodDiversity: foodDiversity,
            supplementIntake: supplementIntake
        )
    }
    
    private func extractSymptomFeatures(from entries: [JournalEntry]) -> SymptomFeatures {
        let recentEntries = Array(entries.suffix(3)) // Last 3 days
        
        var abdominalPain = 0.0
        var diarrhea = 0.0
        var constipation = 0.0
        var bloating = 0.0
        var fatigue = 0.0
        let _appetite = 7.0 // Default appetite
        let weightChange = 0.0 // Not available in current data structure
        var bloodInStool = false
        var urgency = 0.0
        var incompleteEvacuation = false
        let _symptomSeverity = calculateSymptomSeverity(entries: recentEntries)
        let _symptomDuration = calculateSymptomDuration(entries: recentEntries)
        
        for entry in recentEntries {
            if let symptoms = entry.symptoms {
                // Parse symptoms from string array
                for symptom in symptoms {
                    switch symptom.type.lowercased() {
                    case "abdominal_pain", "stomach_pain":
                        abdominalPain += Double(symptom.severity) * 0.5
                    case "diarrhea":
                        diarrhea += Double(symptom.severity) * 0.7
                    case "constipation":
                        constipation += Double(symptom.severity) * 0.6
                    case "bloating":
                        bloating += Double(symptom.severity) * 0.5
                    case "fatigue":
                        fatigue += Double(symptom.severity) * 0.4
                    case "urgency":
                        urgency += Double(symptom.severity) * 0.6
                    case "blood_in_stool":
                        bloodInStool = true
                    case "incomplete_evacuation":
                        incompleteEvacuation = true
                    default:
                        break
                    }
                }
            }
        }
        
        let entryCount = Double(recentEntries.count)
        return SymptomFeatures(
            abdominalPain: entryCount > 0 ? abdominalPain / entryCount : 0.0,
            diarrhea: entryCount > 0 ? diarrhea / entryCount : 0.0,
            constipation: entryCount > 0 ? constipation / entryCount : 0.0,
            bloating: entryCount > 0 ? bloating / entryCount : 0.0,
            fatigue: entryCount > 0 ? fatigue / entryCount : 0.0,
            appetite: 7.0, // Default appetite
            weightChange: weightChange / entryCount,
            bloodInStool: bloodInStool,
            urgency: entryCount > 0 ? urgency / entryCount : 0.0,
            incompleteEvacuation: incompleteEvacuation,
            symptomSeverity: calculateSymptomSeverity(entries: recentEntries),
            symptomDuration: calculateSymptomDuration(entries: recentEntries)
        )
    }
    
    private func extractLifestyleFeatures(from entries: [JournalEntry], userData: UserData) -> LifestyleFeatures {
        let recentEntries = Array(entries.suffix(7)) // Last 7 days
        
        // Default lifestyle values since this data isn't in the current JournalEntry structure
        let stressLevel = 5.0 // Default moderate stress
        let sleepQuality = 7.0 // Default good sleep
        let sleepDuration = 7.5 // Default 7.5 hours
        let exerciseLevel = 5.0 // Default moderate exercise
        let exerciseType = "none"
        let smokingStatus = false
        let alcoholConsumption = 0.0 // Default no alcohol
        let caffeineIntake = 1.0 // Default 1 cup coffee
        let waterIntake = 2000.0 // Default 2L water
        let mealRegularity = calculateMealRegularity(entries: recentEntries)
        
        return LifestyleFeatures(
            stressLevel: stressLevel,
            sleepQuality: sleepQuality,
            sleepDuration: sleepDuration,
            exerciseLevel: exerciseLevel,
            exerciseType: exerciseType,
            smokingStatus: smokingStatus,
            alcoholConsumption: alcoholConsumption,
            caffeineIntake: caffeineIntake,
            waterIntake: waterIntake,
            mealRegularity: mealRegularity
        )
    }
    
    private func extractMedicationFeatures(from entries: [JournalEntry], userData: UserData) -> MedicationFeatures {
        // Default medication values since this data isn't in the current JournalEntry structure
        let medicationAdherence = 0.9 // Default 90% adherence
        let medicationType: [String: Bool] = ["Anti-inflammatory": true]
        let dosageCompliance = 0.95 // Default 95% compliance
        let sideEffects: [String: Double] = [:]
        let medicationChanges = false
        let lastMedicationTime: Date? = Date()
        let medicationEffectiveness = 0.8 // Default 80% effectiveness
        
        return MedicationFeatures(
            medicationAdherence: medicationAdherence,
            medicationType: medicationType,
            dosageCompliance: dosageCompliance,
            sideEffects: sideEffects,
            medicationChanges: medicationChanges,
            lastMedicationTime: lastMedicationTime,
            medicationEffectiveness: medicationEffectiveness
        )
    }
    
    private func extractEnvironmentalFeatures() -> EnvironmentalFeatures {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        
        var season = "unknown"
        switch month {
        case 12, 1, 2: season = "winter"
        case 3, 4, 5: season = "spring"
        case 6, 7, 8: season = "summer"
        case 9, 10, 11: season = "fall"
        default: season = "unknown"
        }
        
        return EnvironmentalFeatures(
            season: season,
            temperature: 20.0, // Placeholder - would integrate with weather API
            humidity: 50.0, // Placeholder
            airQuality: 50.0, // Placeholder
            travelStatus: false,
            timeZone: TimeZone.current.identifier,
            location: "unknown",
            weatherConditions: "unknown"
        )
    }
    
    private func extractHistoricalFeatures(from entries: [JournalEntry], userData: UserData) -> HistoricalFeatures {
        let allEntries = entries
        let flareEntries = allEntries.filter { entry in
            if let symptoms = entry.symptoms {
                // Check for severe symptoms in the string array
                return symptoms.contains { symptom in
                    symptom.type.lowercased() == "abdominal_pain" || 
                    symptom.type.lowercased() == "diarrhea" ||
                    symptom.type.lowercased() == "blood_in_stool"
                }
            }
            return false
        }
        
        let previousFlares = flareEntries.count
        let averageFlareDuration = calculateAverageFlareDuration(flareEntries: flareEntries)
        let timeSinceLastFlare = calculateTimeSinceLastFlare(flareEntries: flareEntries)
        
        return HistoricalFeatures(
            previousFlares: previousFlares,
            averageFlareDuration: averageFlareDuration,
            timeSinceLastFlare: timeSinceLastFlare,
            flarePattern: generateFlarePattern(entries: allEntries),
            seasonalPattern: generateSeasonalPattern(entries: allEntries),
            medicationHistory: generateMedicationHistory(entries: allEntries),
            dietHistory: generateDietHistory(entries: allEntries),
            stressHistory: generateStressHistory(entries: allEntries)
        )
    }
    
    // MARK: - Risk Calculation Functions
    private func calculateNutritionRisk(_ nutrition: NutritionFeatures) -> Double {
        var risk = 0.0
        
        // Fiber risk (too high or too low)
        if nutrition.fiberIntake < 10 || nutrition.fiberIntake > 50 {
            risk += 0.2
        }
        
        // Trigger foods
        risk += Double(nutrition.triggerFoodCount) * 0.1
        
        // Inflammatory foods
        risk += Double(nutrition.inflammatoryFoodCount) * 0.05
        
        // FODMAP score
        risk += nutrition.fodmapScore * 0.15
        
        // Hydration
        if nutrition.hydrationLevel < 1500 {
            risk += 0.1
        }
        
        return min(risk, 1.0)
    }
    
    private func calculateSymptomRisk(_ symptoms: SymptomFeatures) -> Double {
        var risk = 0.0
        
        // High symptom severity
        if symptoms.symptomSeverity > 7 {
            risk += 0.4
        } else if symptoms.symptomSeverity > 5 {
            risk += 0.2
        }
        
        // Blood in stool
        if symptoms.bloodInStool {
            risk += 0.3
        }
        
        // High urgency
        if symptoms.urgency > 7 {
            risk += 0.2
        }
        
        // Abdominal pain
        if symptoms.abdominalPain > 6 {
            risk += 0.15
        }
        
        return min(risk, 1.0)
    }
    
    private func calculateLifestyleRisk(_ lifestyle: LifestyleFeatures) -> Double {
        var risk = 0.0
        
        // High stress
        if lifestyle.stressLevel > 7 {
            risk += 0.3
        }
        
        // Poor sleep
        if lifestyle.sleepQuality < 5 {
            risk += 0.2
        }
        
        // Low sleep duration
        if lifestyle.sleepDuration < 6 {
            risk += 0.15
        }
        
        // High alcohol consumption
        if lifestyle.alcoholConsumption > 2 {
            risk += 0.1
        }
        
        return min(risk, 1.0)
    }
    
    private func calculateMedicationRisk(_ medication: MedicationFeatures) -> Double {
        var risk = 0.0
        
        // Poor adherence
        if medication.medicationAdherence < 0.8 {
            risk += 0.4
        }
        
        // Recent medication changes
        if medication.medicationChanges {
            risk += 0.2
        }
        
        // Side effects
        let totalSideEffects = medication.sideEffects.values.reduce(0, +)
        risk += totalSideEffects * 0.1
        
        return min(risk, 1.0)
    }
    
    // MARK: - Helper Functions
    private func determineRiskLevel(probability: Double) -> FlareRiskLevel {
        if probability >= FlareRiskLevel.veryHigh.threshold {
            return .veryHigh
        } else if probability >= FlareRiskLevel.high.threshold {
            return .high
        } else if probability >= FlareRiskLevel.moderate.threshold {
            return .moderate
        } else {
            return .low
        }
    }
    
    // MARK: - Nutrition Estimation Functions
    private func estimateProtein(for foodName: String, quantity: Double) -> Double {
        let name = foodName.lowercased()
        if name.contains("chicken") || name.contains("turkey") || name.contains("fish") {
            return quantity * 0.25 // ~25g protein per 100g
        } else if name.contains("beef") || name.contains("pork") {
            return quantity * 0.26 // ~26g protein per 100g
        } else if name.contains("egg") {
            return quantity * 0.13 // ~13g protein per 100g
        } else if name.contains("bean") || name.contains("lentil") {
            return quantity * 0.21 // ~21g protein per 100g
        } else {
            return quantity * 0.1 // Default estimate
        }
    }
    
    private func estimateFat(for foodName: String, quantity: Double) -> Double {
        let name = foodName.lowercased()
        if name.contains("avocado") || name.contains("olive") {
            return quantity * 0.15 // ~15g fat per 100g
        } else if name.contains("nut") || name.contains("seed") {
            return quantity * 0.50 // ~50g fat per 100g
        } else if name.contains("cheese") || name.contains("milk") {
            return quantity * 0.25 // ~25g fat per 100g
        } else {
            return quantity * 0.05 // Default estimate
        }
    }
    
    private func estimateFiber(for foodName: String, quantity: Double) -> Double {
        let name = foodName.lowercased()
        if name.contains("apple") || name.contains("banana") {
            return quantity * 0.03 // ~3g fiber per 100g
        } else if name.contains("broccoli") || name.contains("spinach") {
            return quantity * 0.04 // ~4g fiber per 100g
        } else if name.contains("bean") || name.contains("lentil") {
            return quantity * 0.08 // ~8g fiber per 100g
        } else if name.contains("oat") || name.contains("whole grain") {
            return quantity * 0.10 // ~10g fiber per 100g
        } else {
            return quantity * 0.02 // Default estimate
        }
    }
    
    private func calculatePredictedOnset(probability: Double) -> Date? {
        if probability > 0.7 {
            return Date().addingTimeInterval(24 * 3600) // Within 24 hours
        } else if probability > 0.5 {
            return Date().addingTimeInterval(3 * 24 * 3600) // Within 3 days
        } else if probability > 0.3 {
            return Date().addingTimeInterval(7 * 24 * 3600) // Within 1 week
        }
        return nil
    }
    
    private func generateRecommendations(for riskLevel: FlareRiskLevel, factors: [String: Double]) -> [FlarePreventionAction] {
        var recommendations: [FlarePreventionAction] = []
        
        switch riskLevel {
        case .veryHigh:
            recommendations.append(FlarePreventionAction(
                action: "Immediate Medical Attention",
                rationale: "High risk of flare detected. Contact your healthcare provider immediately.",
                implementation: "Call your doctor, monitor symptoms closely, avoid trigger foods",
                priority: .critical
            ))
        case .high:
            recommendations.append(FlarePreventionAction(
                action: "High Risk Alert",
                rationale: "Elevated risk of flare. Take preventive measures.",
                implementation: "Increase medication adherence, avoid known triggers, reduce stress",
                priority: .high
            ))
        case .moderate:
            recommendations.append(FlarePreventionAction(
                action: "Moderate Risk",
                rationale: "Some risk factors detected. Monitor closely.",
                implementation: "Track symptoms daily, maintain healthy diet, get adequate sleep",
                priority: .medium
            ))
        case .low:
            recommendations.append(FlarePreventionAction(
                action: "Low Risk",
                rationale: "Risk factors are well managed. Continue current routine.",
                implementation: "Maintain current routine, continue healthy habits, regular monitoring",
                priority: .low
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Utility Functions
    private func isTriggerFood(_ foodName: String) -> Bool {
        let triggerFoods = ["dairy", "gluten", "nuts", "seeds", "spicy", "fried", "processed"]
        return triggerFoods.contains { foodName.lowercased().contains($0) }
    }
    
    private func isInflammatoryFood(_ foodName: String) -> Bool {
        let inflammatoryFoods = ["red meat", "processed meat", "refined sugar", "trans fat"]
        return inflammatoryFoods.contains { foodName.lowercased().contains($0) }
    }
    
    private func calculateFODMAPScore(entries: [JournalEntry]) -> Double {
        // Simplified FODMAP scoring
        return 0.3 // Placeholder
    }
    
    private func calculateSymptomSeverity(entries: [JournalEntry]) -> Double {
        var totalSeverity = 0.0
        var count = 0
        
        for entry in entries {
            if let symptoms = entry.symptoms {
                // Calculate severity based on symptom strings
                for symptom in symptoms {
                    switch symptom.type.lowercased() {
                    case "abdominal_pain", "stomach_pain":
                        totalSeverity += Double(symptom.severity) * 0.5
                    case "diarrhea":
                        totalSeverity += Double(symptom.severity) * 0.7
                    case "constipation":
                        totalSeverity += Double(symptom.severity) * 0.6
                    case "bloating":
                        totalSeverity += Double(symptom.severity) * 0.5
                    case "fatigue":
                        totalSeverity += Double(symptom.severity) * 0.4
                    case "urgency":
                        totalSeverity += Double(symptom.severity) * 0.6
                    case "blood_in_stool":
                        totalSeverity += Double(symptom.severity) * 0.8
                    default:
                        totalSeverity += Double(symptom.severity) * 0.3
                    }
                }
                count += 1
            }
        }
        
        return count > 0 ? totalSeverity / Double(count) : 0.0
    }
    
    private func calculateSymptomDuration(entries: [JournalEntry]) -> Double {
        // Calculate how long symptoms have been present
        return Double(entries.count) // Simplified
    }
    
    private func calculateMealRegularity(entries: [JournalEntry]) -> Double {
        // Calculate meal timing consistency
        return 0.7 // Placeholder
    }
    
    private func calculateAverageFlareDuration(flareEntries: [JournalEntry]) -> Double {
        return 7.0 // Placeholder - 7 days average
    }
    
    private func calculateTimeSinceLastFlare(flareEntries: [JournalEntry]) -> Double {
        guard let lastFlare = flareEntries.last?.entry_date.toDate() else { return 30.0 }
        return Date().timeIntervalSince(lastFlare) / (24 * 3600) // Days since last flare
    }
    
    private func generateFlarePattern(entries: [JournalEntry]) -> [Double] {
        // Generate historical flare pattern
        return Array(repeating: 0.1, count: 30) // Placeholder
    }
    
    private func generateSeasonalPattern(entries: [JournalEntry]) -> [Double] {
        // Generate seasonal flare pattern
        return Array(repeating: 0.1, count: 12) // Placeholder
    }
    
    private func generateMedicationHistory(entries: [JournalEntry]) -> [String: Double] {
        // Generate medication usage history
        return ["mesalamine": 0.8, "prednisone": 0.2] // Placeholder
    }
    
    private func generateDietHistory(entries: [JournalEntry]) -> [String: Double] {
        // Generate diet pattern history
        return ["low_fiber": 0.6, "low_fodmap": 0.4] // Placeholder
    }
    
    private func generateStressHistory(entries: [JournalEntry]) -> [Double] {
        // Generate stress level history
        return Array(repeating: 0.3, count: 30) // Placeholder
    }
    
    // MARK: - ML Model Integration (Placeholder functions)
    private func extractMLFeatures(from input: FlarePredictionInput) -> MLFeatureProvider? {
        // Convert input to ML features
        // This would be implemented based on the actual ML model structure
        // For now, return nil to use rule-based prediction
        return nil
    }
    
    private func extractProbability(from prediction: MLFeatureProvider) -> Double {
        // Extract flare probability from ML prediction
        return 0.5 // Placeholder
    }
    
    private func calculateConfidence(from prediction: MLFeatureProvider) -> Double {
        // Calculate prediction confidence
        return 0.8 // Placeholder
    }
    
    private func extractContributingFactors(from prediction: MLFeatureProvider, input: FlarePredictionInput) -> [String: Double] {
        // Extract feature importance from ML prediction
        return ["nutrition": 0.3, "symptoms": 0.4, "lifestyle": 0.2, "medication": 0.1]
    }
} 