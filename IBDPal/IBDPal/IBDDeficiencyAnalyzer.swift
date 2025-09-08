import Foundation

// MARK: - IBD Deficiency Analyzer
class IBDDeficiencyAnalyzer: ObservableObject {
    static let shared = IBDDeficiencyAnalyzer()
    
    private init() {}
    
    // MARK: - Main Analysis Functions
    
    /// Analyze micronutrient deficiencies and excesses
    func analyzeMicronutrientStatus(_ intake: MicronutrientData, _ requirements: IBDMicronutrientRequirements, _ labResults: [LabResult]) -> IBDMicronutrientAnalysis {
        
        // Calculate deficiencies
        let deficiencies = calculateDeficiencies(intake, requirements, labResults)
        
        // Calculate excesses
        let excesses = calculateExcesses(intake, requirements)
        
        // Create IBD-specific nutrient status
        let ibdSpecificNutrients = createIBDSpecificNutrients(intake, requirements, labResults)
        
        // Generate recommendations
        let recommendations = generateRecommendations(deficiencies, excesses, labResults)
        
        return IBDMicronutrientAnalysis(
            dailyIntake: intake,
            requirements: requirements,
            deficiencies: deficiencies,
            excesses: excesses,
            ibdSpecificNutrients: ibdSpecificNutrients,
            absorptionFactors: calculateAbsorptionFactors(labResults),
            recommendations: recommendations
        )
    }
    
    // MARK: - Deficiency Calculation
    
    private func calculateDeficiencies(_ intake: MicronutrientData, _ requirements: IBDMicronutrientRequirements, _ labResults: [LabResult]) -> [MicronutrientDeficiency] {
        var deficiencies: [MicronutrientDeficiency] = []
        
        // Check Vitamin D
        if intake.vitaminD < requirements.vitaminD {
            let labResult = labResults.first { $0.nutrient.contains("Vitamin D") }
            let severity = determineDeficiencySeverity(intake.vitaminD, requirements.vitaminD, labResult)
            
            let deficiency = MicronutrientDeficiency(
                nutrient: "Vitamin D",
                currentIntake: intake.vitaminD,
                requiredIntake: requirements.vitaminD,
                symptoms: getVitaminDSymptoms(severity),
                recommendations: getVitaminDRecommendations(severity, labResult)
            )
            deficiencies.append(deficiency)
        }
        
        // Check Vitamin B12
        if intake.vitaminB12 < requirements.vitaminB12 {
            let labResult = labResults.first { $0.nutrient.contains("B12") }
            let severity = determineDeficiencySeverity(intake.vitaminB12, requirements.vitaminB12, labResult)
            
            let deficiency = MicronutrientDeficiency(
                nutrient: "Vitamin B12",
                currentIntake: intake.vitaminB12,
                requiredIntake: requirements.vitaminB12,
                symptoms: getB12Symptoms(severity),
                recommendations: getB12Recommendations(severity, labResult)
            )
            deficiencies.append(deficiency)
        }
        
        // Check Iron
        if intake.iron < requirements.iron {
            let labResult = labResults.first { $0.nutrient.contains("Iron") || $0.nutrient.contains("Ferritin") }
            let severity = determineDeficiencySeverity(intake.iron, requirements.iron, labResult)
            
            let deficiency = MicronutrientDeficiency(
                nutrient: "Iron",
                currentIntake: intake.iron,
                requiredIntake: requirements.iron,
                symptoms: getIronSymptoms(severity),
                recommendations: getIronRecommendations(severity, labResult)
            )
            deficiencies.append(deficiency)
        }
        
        // Check Calcium
        if intake.calcium < requirements.calcium {
            let deficiency = MicronutrientDeficiency(
                nutrient: "Calcium",
                currentIntake: intake.calcium,
                requiredIntake: requirements.calcium,
                symptoms: ["Bone pain", "Fractures", "Muscle cramps", "Numbness"],
                recommendations: ["Increase dairy intake", "Consider calcium supplement", "Eat leafy greens", "Ensure adequate vitamin D"]
            )
            deficiencies.append(deficiency)
        }
        
        // Check Zinc
        if intake.zinc < requirements.zinc {
            let deficiency = MicronutrientDeficiency(
                nutrient: "Zinc",
                currentIntake: intake.zinc,
                requiredIntake: requirements.zinc,
                symptoms: ["Slow wound healing", "Frequent infections", "Loss of taste/smell", "Hair loss"],
                recommendations: ["Eat zinc-rich foods (oysters, beef, pumpkin seeds)", "Consider zinc supplement", "Avoid high-dose iron supplements"]
            )
            deficiencies.append(deficiency)
        }
        
        // Check Omega-3
        if intake.omega3 < requirements.omega3 {
            let deficiency = MicronutrientDeficiency(
                nutrient: "Omega-3",
                currentIntake: intake.omega3,
                requiredIntake: requirements.omega3,
                symptoms: ["Inflammation", "Joint pain", "Depression", "Dry skin", "Poor memory"],
                recommendations: ["Eat fatty fish 2-3 times per week", "Consider fish oil supplement", "Add flaxseeds, walnuts to diet"]
            )
            deficiencies.append(deficiency)
        }
        
        return deficiencies
    }
    
    // MARK: - Excess Calculation
    
    private func calculateExcesses(_ intake: MicronutrientData, _ requirements: IBDMicronutrientRequirements) -> [MicronutrientExcess] {
        var excesses: [MicronutrientExcess] = []
        
        // Safe upper limits (from medical literature)
        let safeUpperLimits: [String: Double] = [
            "Vitamin D": 100.0, // mcg - can cause hypercalcemia
            "Iron": 45.0, // mg - can cause iron overload
            "Zinc": 40.0, // mg - can cause copper deficiency
            "Calcium": 2500.0, // mg - can cause kidney stones
            "Magnesium": 700.0, // mg - can cause diarrhea
            "Vitamin A": 3000.0, // mcg - can cause liver damage
            "Selenium": 400.0 // mcg - can cause selenosis
        ]
        
        // Check for excesses
        if intake.vitaminD > safeUpperLimits["Vitamin D"]! {
            let excess = MicronutrientExcess(
                nutrient: "Vitamin D",
                currentIntake: intake.vitaminD,
                safeUpperLimit: safeUpperLimits["Vitamin D"]!,
                risks: ["Hypercalcemia", "Kidney stones", "Nausea", "Vomiting", "Confusion"],
                recommendations: ["Reduce vitamin D supplement", "Monitor blood calcium levels", "Consult healthcare provider immediately"]
            )
            excesses.append(excess)
        }
        
        if intake.iron > safeUpperLimits["Iron"]! {
            let excess = MicronutrientExcess(
                nutrient: "Iron",
                currentIntake: intake.iron,
                safeUpperLimit: safeUpperLimits["Iron"]!,
                risks: ["Iron overload", "Liver damage", "Joint pain", "Heart problems"],
                recommendations: ["Reduce iron supplement", "Monitor ferritin levels", "Consider phlebotomy if severe"]
            )
            excesses.append(excess)
        }
        
        if intake.zinc > safeUpperLimits["Zinc"]! {
            let excess = MicronutrientExcess(
                nutrient: "Zinc",
                currentIntake: intake.zinc,
                safeUpperLimit: safeUpperLimits["Zinc"]!,
                risks: ["Copper deficiency", "Nausea", "Vomiting", "Immune suppression"],
                recommendations: ["Reduce zinc supplement", "Monitor copper levels", "Consider copper supplement"]
            )
            excesses.append(excess)
        }
        
        return excesses
    }
    
    // MARK: - IBD-Specific Nutrient Status
    
    private func createIBDSpecificNutrients(_ intake: MicronutrientData, _ requirements: IBDMicronutrientRequirements, _ labResults: [LabResult]) -> IBDSpecificNutrients {
        
        let vitaminDStatus = createNutrientStatus("Vitamin D", intake.vitaminD, requirements.vitaminD, labResults)
        let vitaminB12Status = createNutrientStatus("Vitamin B12", intake.vitaminB12, requirements.vitaminB12, labResults)
        let ironStatus = createNutrientStatus("Iron", intake.iron, requirements.iron, labResults)
        let calciumStatus = createNutrientStatus("Calcium", intake.calcium, requirements.calcium, labResults)
        let zincStatus = createNutrientStatus("Zinc", intake.zinc, requirements.zinc, labResults)
        let omega3Status = createNutrientStatus("Omega-3", intake.omega3, requirements.omega3, labResults)
        let glutamineStatus = createNutrientStatus("Glutamine", intake.glutamine, requirements.glutamine, labResults)
        let probioticsStatus = createNutrientStatus("Probiotics", intake.probiotics, requirements.probiotics, labResults)
        
        return IBDSpecificNutrients(
            vitaminD: vitaminDStatus,
            vitaminB12: vitaminB12Status,
            iron: ironStatus,
            calcium: calciumStatus,
            zinc: zincStatus,
            omega3: omega3Status,
            glutamine: glutamineStatus,
            probiotics: probioticsStatus
        )
    }
    
    private func createNutrientStatus(_ nutrientName: String, _ currentIntake: Double?, _ requiredIntake: Double, _ labResults: [LabResult]) -> NutrientStatus {
        let intake = currentIntake ?? 0.0
        let labResult = labResults.first { $0.nutrient.contains(nutrientName) }
        
        let status: NutrientStatusLevel
        if let lab = labResult {
            switch lab.status {
            case .critical:
                status = .deficient
            case .low:
                status = .deficient
            case .normal:
                status = intake >= requiredIntake ? .optimal : .suboptimal
            case .high:
                status = .excessive
            }
        } else {
            if intake >= requiredIntake * 1.2 {
                status = .optimal
            } else if intake >= requiredIntake {
                status = .adequate
            } else if intake >= requiredIntake * 0.7 {
                status = .suboptimal
            } else {
                status = .deficient
            }
        }
        
        let absorptionRate = calculateAbsorptionRate(nutrientName, labResult)
        let ibdFactors = getIBDFactors(nutrientName, labResult)
        
        return NutrientStatus(
            currentIntake: intake,
            requiredIntake: requiredIntake,
            status: status,
            absorptionRate: absorptionRate,
            ibdFactors: ibdFactors
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineDeficiencySeverity(_ current: Double, _ required: Double, _ labResult: LabResult?) -> DeficiencySeverity {
        let percentage = ((required - current) / required) * 100
        
        if let lab = labResult {
            switch lab.status {
            case .critical:
                return .critical
            case .low:
                return .severe
            case .normal:
                return percentage > 50 ? .severe : percentage > 25 ? .moderate : .mild
            case .high:
                return .mild
            }
        }
        
        if percentage >= 75 {
            return .critical
        } else if percentage >= 50 {
            return .severe
        } else if percentage >= 25 {
            return .moderate
        } else {
            return .mild
        }
    }
    
    private func calculateAbsorptionRate(_ nutrientName: String, _ labResult: LabResult?) -> Double {
        // Base absorption rates for IBD patients (typically lower than healthy individuals)
        let baseRates: [String: Double] = [
            "Vitamin D": 0.7, // 70% absorption
            "Vitamin B12": 0.6, // 60% absorption (ileal issues)
            "Iron": 0.7, // 70% absorption
            "Calcium": 0.9, // 90% absorption
            "Zinc": 0.8, // 80% absorption
            "Omega-3": 0.9, // 90% absorption
            "Glutamine": 0.8, // 80% absorption
            "Probiotics": 0.7 // 70% survival
        ]
        
        var rate = baseRates[nutrientName] ?? 0.8
        
        // Adjust based on lab results
        if let lab = labResult {
            switch lab.status {
            case .critical:
                rate *= 0.5 // Very poor absorption
            case .low:
                rate *= 0.7 // Poor absorption
            case .normal:
                rate *= 1.0 // Normal absorption
            case .high:
                rate *= 1.2 // Good absorption
            }
        }
        
        return min(rate, 1.0) // Cap at 100%
    }
    
    private func getIBDFactors(_ nutrientName: String, _ labResult: LabResult?) -> [String] {
        var factors: [String] = []
        
        switch nutrientName {
        case "Vitamin D":
            factors.append("Reduced sun exposure")
            factors.append("Malabsorption")
            if labResult?.status == .low || labResult?.status == .critical {
                factors.append("Severe deficiency detected")
            }
        case "Vitamin B12":
            factors.append("Ileal resection risk")
            factors.append("Medication interactions")
            factors.append("Intrinsic factor issues")
        case "Iron":
            factors.append("Blood loss from inflammation")
            factors.append("Malabsorption")
            factors.append("Medication interactions")
        case "Calcium":
            factors.append("Corticosteroid use")
            factors.append("Bone density concerns")
        case "Zinc":
            factors.append("Diarrhea losses")
            factors.append("Malabsorption")
        case "Omega-3":
            factors.append("Anti-inflammatory needs")
            factors.append("Reduced fish intake")
        case "Glutamine":
            factors.append("Gut healing requirements")
            factors.append("Increased demand during flares")
        case "Probiotics":
            factors.append("Gut microbiome disruption")
            factors.append("Antibiotic use")
        default:
            break
        }
        
        return factors
    }
    
    // MARK: - Symptom and Recommendation Methods
    
    private func getVitaminDSymptoms(_ severity: DeficiencySeverity) -> [String] {
        switch severity {
        case .mild:
            return ["Mild fatigue", "Slight muscle weakness"]
        case .moderate:
            return ["Bone pain", "Muscle weakness", "Fatigue", "Mood changes"]
        case .severe:
            return ["Severe bone pain", "Muscle weakness", "Fatigue", "Depression", "Frequent infections"]
        case .critical:
            return ["Severe bone pain", "Muscle weakness", "Severe fatigue", "Depression", "Frequent infections", "Bone fractures"]
        }
    }
    
    private func getVitaminDRecommendations(_ severity: DeficiencySeverity, _ labResult: LabResult?) -> [String] {
        var recommendations: [String] = []
        
        switch severity {
        case .mild:
            recommendations.append("Increase sun exposure (15-30 minutes daily)")
            recommendations.append("Consider vitamin D3 supplement (1000-2000 IU)")
        case .moderate:
            recommendations.append("Take vitamin D3 supplement (2000-4000 IU daily)")
            recommendations.append("Eat fatty fish (salmon, mackerel) 2-3 times per week")
            recommendations.append("Consider fortified foods")
        case .severe:
            recommendations.append("Take high-dose vitamin D3 supplement (4000-6000 IU daily)")
            recommendations.append("Eat fatty fish regularly")
            recommendations.append("Consider vitamin D testing every 3 months")
        case .critical:
            recommendations.append("Immediate high-dose vitamin D3 supplement (6000+ IU daily)")
            recommendations.append("Consult healthcare provider for prescription vitamin D")
            recommendations.append("Monitor blood levels monthly")
            recommendations.append("Consider calcium and magnesium supplements")
        }
        
        if let lab = labResult, lab.status == .critical {
            recommendations.append("URGENT: Critical deficiency detected - consult doctor immediately")
        }
        
        return recommendations
    }
    
    private func getB12Symptoms(_ severity: DeficiencySeverity) -> [String] {
        switch severity {
        case .mild:
            return ["Mild fatigue", "Slight memory issues"]
        case .moderate:
            return ["Fatigue", "Weakness", "Memory problems", "Mood changes"]
        case .severe:
            return ["Severe fatigue", "Weakness", "Numbness", "Memory problems", "Depression"]
        case .critical:
            return ["Severe fatigue", "Weakness", "Numbness", "Severe memory problems", "Depression", "Neurological symptoms"]
        }
    }
    
    private func getB12Recommendations(_ severity: DeficiencySeverity, _ labResult: LabResult?) -> [String] {
        var recommendations: [String] = []
        
        switch severity {
        case .mild:
            recommendations.append("Eat B12-rich foods (meat, fish, dairy)")
            recommendations.append("Consider B12 supplement (1000 mcg daily)")
        case .moderate:
            recommendations.append("Take B12 supplement (1000-2000 mcg daily)")
            recommendations.append("Eat fortified foods")
            recommendations.append("Consider sublingual B12")
        case .severe:
            recommendations.append("Take high-dose B12 supplement (2000+ mcg daily)")
            recommendations.append("Consider B12 injections")
            recommendations.append("Monitor B12 levels every 3 months")
        case .critical:
            recommendations.append("URGENT: Consider B12 injections")
            recommendations.append("High-dose oral B12 (5000+ mcg daily)")
            recommendations.append("Consult healthcare provider immediately")
            recommendations.append("Monitor neurological symptoms")
        }
        
        return recommendations
    }
    
    private func getIronSymptoms(_ severity: DeficiencySeverity) -> [String] {
        switch severity {
        case .mild:
            return ["Mild fatigue", "Slight weakness"]
        case .moderate:
            return ["Fatigue", "Weakness", "Pale skin", "Shortness of breath"]
        case .severe:
            return ["Severe fatigue", "Weakness", "Pale skin", "Shortness of breath", "Heart palpitations"]
        case .critical:
            return ["Severe fatigue", "Weakness", "Very pale skin", "Severe shortness of breath", "Heart palpitations", "Dizziness"]
        }
    }
    
    private func getIronRecommendations(_ severity: DeficiencySeverity, _ labResult: LabResult?) -> [String] {
        var recommendations: [String] = []
        
        switch severity {
        case .mild:
            recommendations.append("Eat iron-rich foods (red meat, spinach)")
            recommendations.append("Consider iron supplement with vitamin C")
        case .moderate:
            recommendations.append("Take iron supplement (18-27 mg daily)")
            recommendations.append("Take with vitamin C for better absorption")
            recommendations.append("Avoid coffee/tea with iron-rich meals")
        case .severe:
            recommendations.append("Take high-dose iron supplement (27-45 mg daily)")
            recommendations.append("Take with vitamin C")
            recommendations.append("Consider iron infusion if oral not effective")
        case .critical:
            recommendations.append("URGENT: Consider iron infusion")
            recommendations.append("High-dose oral iron (45+ mg daily)")
            recommendations.append("Consult healthcare provider immediately")
            recommendations.append("Monitor for iron overload")
        }
        
        return recommendations
    }
    
    // MARK: - Additional Helper Methods
    
    private func calculateAbsorptionFactors(_ labResults: [LabResult]) -> AbsorptionFactors {
        var medicationInteractions: [String: Double] = [:]
        var foodCombinations: [String: Double] = [:]
        
        // Common IBD medications and their absorption impacts
        medicationInteractions = [
            "Prednisone": 0.7, // Reduces calcium absorption
            "Methotrexate": 0.8, // Reduces folate absorption
            "Azathioprine": 0.9, // Minimal impact
            "Infliximab": 1.0, // No direct impact
            "Adalimumab": 1.0 // No direct impact
        ]
        
        // Food combinations that enhance absorption
        foodCombinations = [
            "Vitamin C": 1.5, // Enhances iron absorption
            "Fat": 1.2, // Enhances fat-soluble vitamins
            "Calcium": 0.8, // Reduces iron absorption
            "Fiber": 0.9 // Slightly reduces mineral absorption
        ]
        
        let diseaseActivity = 0.6 // Moderate disease activity
        let gutHealth = 0.7 // Moderate gut health
        
        return AbsorptionFactors(
            medicationInteractions: medicationInteractions,
            diseaseActivity: diseaseActivity,
            gutHealth: gutHealth,
            foodCombinations: foodCombinations
        )
    }
    
    private func generateRecommendations(_ deficiencies: [MicronutrientDeficiency], _ excesses: [MicronutrientExcess], _ labResults: [LabResult]) -> MicronutrientRecommendations {
        var immediateActions: [MicronutrientAction] = []
        var supplementSuggestions: [SupplementSuggestion] = []
        var foodRecommendations: [FoodRecommendation] = []
        var timingRecommendations: [TimingRecommendation] = []
        var monitoringSuggestions: [MonitoringSuggestion] = []
        
        // Generate immediate actions from deficiencies
        for deficiency in deficiencies {
            if deficiency.severity == .critical || deficiency.severity == .severe {
                let action = MicronutrientAction(
                    nutrient: deficiency.nutrient,
                    action: deficiency.recommendations.first ?? "Consult healthcare provider",
                    priority: deficiency.severity == .critical ? .critical : .high,
                    timeframe: "Immediately"
                )
                immediateActions.append(action)
            }
        }
        
        // Generate supplement suggestions
        for deficiency in deficiencies {
            if deficiency.severity != .mild {
                let suggestion = SupplementSuggestion(
                    nutrient: deficiency.nutrient,
                    supplementName: getSupplementName(deficiency.nutrient),
                    dosage: getRecommendedDosage(deficiency.nutrient, deficiency.severity),
                    unit: getSupplementUnit(deficiency.nutrient),
                    frequency: "Daily",
                    reasoning: "Address \(deficiency.severity.displayName.lowercased()) deficiency",
                    interactions: getSupplementInteractions(deficiency.nutrient)
                )
                supplementSuggestions.append(suggestion)
            }
        }
        
        // Generate food recommendations
        for deficiency in deficiencies {
            let recommendation = FoodRecommendation(
                nutrient: deficiency.nutrient,
                foodName: getFoodRecommendation(deficiency.nutrient),
                servingSize: getRecommendedServingSize(deficiency.nutrient),
                frequency: "2-3 times per week",
                preparation: getPreparationMethod(deficiency.nutrient),
                reasoning: "Natural source of \(deficiency.nutrient)"
            )
            foodRecommendations.append(recommendation)
        }
        
        // Generate monitoring suggestions
        for labResult in labResults {
            if labResult.status == .low || labResult.status == .critical {
                let suggestion = MonitoringSuggestion(
                    nutrient: labResult.nutrient,
                    testType: "Blood test",
                    frequency: "Every 3 months",
                    targetRange: labResult.referenceRange,
                    reasoning: "Monitor improvement of deficiency"
                )
                monitoringSuggestions.append(suggestion)
            }
        }
        
        return MicronutrientRecommendations(
            immediateActions: immediateActions,
            supplementSuggestions: supplementSuggestions,
            foodRecommendations: foodRecommendations,
            timingRecommendations: timingRecommendations,
            monitoringSuggestions: monitoringSuggestions
        )
    }
    
    // MARK: - Helper Methods for Recommendations
    
    private func getSupplementName(_ nutrient: String) -> String {
        switch nutrient {
        case "Vitamin D": return "Vitamin D3"
        case "Vitamin B12": return "Methylcobalamin"
        case "Iron": return "Iron Bisglycinate"
        case "Calcium": return "Calcium Citrate"
        case "Zinc": return "Zinc Picolinate"
        case "Omega-3": return "Fish Oil"
        default: return "\(nutrient) Supplement"
        }
    }
    
    private func getRecommendedDosage(_ nutrient: String, _ severity: DeficiencySeverity) -> Double {
        let baseDosages: [String: Double] = [
            "Vitamin D": 2000.0, // IU
            "Vitamin B12": 1000.0, // mcg
            "Iron": 18.0, // mg
            "Calcium": 600.0, // mg
            "Zinc": 15.0, // mg
            "Omega-3": 1000.0 // mg
        ]
        
        let base = baseDosages[nutrient] ?? 100.0
        let multiplier: Double
        
        switch severity {
        case .mild: multiplier = 1.0
        case .moderate: multiplier = 1.5
        case .severe: multiplier = 2.0
        case .critical: multiplier = 3.0
        }
        
        return base * multiplier
    }
    
    private func getSupplementUnit(_ nutrient: String) -> String {
        switch nutrient {
        case "Vitamin D": return "IU"
        case "Vitamin B12": return "mcg"
        case "Iron": return "mg"
        case "Calcium": return "mg"
        case "Zinc": return "mg"
        case "Omega-3": return "mg"
        default: return "mg"
        }
    }
    
    private func getSupplementInteractions(_ nutrient: String) -> [String] {
        switch nutrient {
        case "Iron":
            return ["Take with vitamin C", "Avoid with calcium", "Take on empty stomach"]
        case "Calcium":
            return ["Take with vitamin D", "Avoid with iron", "Take with food"]
        case "Zinc":
            return ["Avoid with iron", "Take with food", "Monitor copper levels"]
        default:
            return ["Take with food"]
        }
    }
    
    private func getFoodRecommendation(_ nutrient: String) -> String {
        switch nutrient {
        case "Vitamin D": return "Fatty fish (salmon, mackerel)"
        case "Vitamin B12": return "Beef, fish, dairy products"
        case "Iron": return "Red meat, spinach, lentils"
        case "Calcium": return "Dairy products, leafy greens"
        case "Zinc": return "Oysters, beef, pumpkin seeds"
        case "Omega-3": return "Fatty fish, flaxseeds, walnuts"
        default: return "Nutrient-rich foods"
        }
    }
    
    private func getRecommendedServingSize(_ nutrient: String) -> String {
        switch nutrient {
        case "Vitamin D": return "3-4 oz"
        case "Vitamin B12": return "3-4 oz"
        case "Iron": return "1 cup cooked"
        case "Calcium": return "1 cup"
        case "Zinc": return "1 oz"
        case "Omega-3": return "3-4 oz"
        default: return "1 serving"
        }
    }
    
    private func getPreparationMethod(_ nutrient: String) -> String {
        switch nutrient {
        case "Vitamin D": return "Grilled or baked"
        case "Vitamin B12": return "Grilled, baked, or steamed"
        case "Iron": return "Lightly cooked to preserve nutrients"
        case "Calcium": return "Raw or lightly cooked"
        case "Zinc": return "Raw or lightly roasted"
        case "Omega-3": return "Grilled or baked (avoid frying)"
        default: return "As preferred"
        }
    }
}
