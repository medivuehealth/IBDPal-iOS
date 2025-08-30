import Foundation
import SwiftUI

// MARK: - IBD Nutrition Analysis Models
struct IBDNutritionAnalysis {
    let dailyNutrition: DailyNutritionSummary
    let weeklyTrends: WeeklyNutritionTrends
    let ibdSpecificInsights: IBDSpecificInsights
    let recommendations: NutritionRecommendations
    let flareRiskFactors: FlareRiskFactors
    let gutHealthMetrics: GutHealthMetrics
}

struct DailyNutritionSummary {
    let totalCalories: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let fat: Double
    let vitamins: [String: Double]
    let minerals: [String: Double]
    let hydration: Double
    let fodmapLevel: String
    let ibdFriendlyScore: Double
}

struct WeeklyNutritionTrends {
    let calorieTrend: TrendDirection
    let proteinTrend: TrendDirection
    let fiberTrend: TrendDirection
    let fodmapTrend: TrendDirection
    let symptomCorrelation: [String: Double]
    let consistencyScore: Double
}

struct IBDSpecificInsights {
    let fiberIntake: FiberAnalysis
    let proteinIntake: ProteinAnalysis
    let fatIntake: FatAnalysis
    let vitaminDeficiencies: [VitaminDeficiency]
    let mineralDeficiencies: [MineralDeficiency]
    let hydrationStatus: HydrationAnalysis
    let fodmapCompliance: FODMAPAnalysis
}

struct NutritionRecommendations {
    let immediateActions: [NutritionAction]
    let weeklyGoals: [NutritionGoal]
    let longTermStrategies: [NutritionStrategy]
    let foodSuggestions: [FoodSuggestion]
    let mealTiming: MealTimingRecommendations
}

struct FlareRiskFactors {
    let highRiskFoods: [RiskFood]
    let triggerFoods: [TriggerFood]
    let inflammatoryFoods: [InflammatoryFood]
    let riskScore: Double
    let recommendations: [FlarePreventionAction]
}

struct GutHealthMetrics {
    let microbiomeScore: Double
    let inflammationMarkers: [String: Double]
    let gutBarrierHealth: String
    let probioticFoods: [String]
    let prebioticFoods: [String]
}

// MARK: - Supporting Structures
enum TrendDirection {
    case increasing
    case decreasing
    case stable
    case fluctuating
}

struct FiberAnalysis {
    let currentIntake: Double
    let recommendedIntake: Double
    let solubleFiber: Double
    let insolubleFiber: Double
    let recommendation: String
    let ibdConsiderations: String
}

struct ProteinAnalysis {
    let currentIntake: Double
    let recommendedIntake: Double
    let qualityScore: Double
    let sources: [String]
    let recommendation: String
}

struct FatAnalysis {
    let totalFat: Double
    let saturatedFat: Double
    let omega3: Double
    let omega6: Double
    let ratio: Double
    let recommendation: String
}

struct VitaminDeficiency {
    let vitamin: String
    let currentLevel: Double
    let recommendedLevel: Double
    let deficiency: Double
    let foodSources: [String]
    let supplementation: String?
}

struct MineralDeficiency {
    let mineral: String
    let currentLevel: Double
    let recommendedLevel: Double
    let deficiency: Double
    let foodSources: [String]
    let supplementation: String?
}

struct HydrationAnalysis {
    let currentIntake: Double
    let recommendedIntake: Double
    let dehydrationRisk: String
    let electrolyteBalance: String
    let recommendation: String
}

struct FODMAPAnalysis {
    let complianceScore: Double
    let highFODMAPFoods: [String]
    let lowFODMAPAlternatives: [String]
    let symptomCorrelation: Double
    let recommendation: String
}

struct NutritionAction {
    let priority: ActionPriority
    let title: String
    let description: String
    let impact: String
    let timeframe: String
}

struct NutritionGoal {
    let category: String
    let currentValue: Double
    let targetValue: Double
    let timeframe: String
    let strategies: [String]
}

struct NutritionStrategy {
    let title: String
    let description: String
    let benefits: [String]
    let implementation: [String]
    let timeframe: String
}

struct FoodSuggestion {
    let name: String
    let category: String
    let benefits: [String]
    let ibdFriendly: Bool
    let fodmapLevel: String
    let servingSize: String
    let frequency: String
}

struct MealTimingRecommendations {
    let breakfast: String
    let lunch: String
    let dinner: String
    let snacks: String
    let hydration: String
    let fasting: String?
}

struct RiskFood {
    let name: String
    let riskLevel: RiskLevel
    let reason: String
    let alternative: String
    let frequency: String
}

struct TriggerFood {
    let name: String
    let triggerType: String
    let symptoms: [String]
    let avoidance: String
    let reintroduction: String
}

struct InflammatoryFood {
    let name: String
    let inflammatoryCompounds: [String]
    let alternatives: [String]
    let preparation: String
}

struct FlarePreventionAction {
    let action: String
    let rationale: String
    let implementation: String
    let priority: ActionPriority
}

enum ActionPriority: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum RiskLevel: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

// MARK: - IBD Nutrition Analyzer
class IBDNutritionAnalyzer: ObservableObject {
    static let shared = IBDNutritionAnalyzer()
    
    // IBD-specific nutrition requirements
    private let ibdNutritionRequirements = [
        "calories": 2000.0, // May need more during flares
        "protein": 1.2, // g/kg body weight (higher for IBD)
        "fiber": 25.0, // g/day (adjustable based on symptoms)
        "fat": 65.0, // g/day
        "vitamin_d": 800.0, // IU/day (often deficient in IBD)
        "vitamin_b12": 2.4, // mcg/day
        "iron": 18.0, // mg/day (higher for IBD)
        "calcium": 1200.0, // mg/day
        "zinc": 11.0, // mg/day
        "folate": 400.0, // mcg/day
        "omega3": 1.1, // g/day
        "hydration": 2000.0 // ml/day (more during flares)
    ]
    
    // IBD-specific food considerations
    private let ibdFriendlyFoods = [
        "low_fiber": ["white rice", "white bread", "banana", "applesauce", "yogurt"],
        "high_protein": ["chicken", "fish", "eggs", "tofu", "greek yogurt"],
        "anti_inflammatory": ["salmon", "turmeric", "ginger", "olive oil", "berries"],
        "probiotic": ["yogurt", "kefir", "sauerkraut", "kimchi", "miso"],
        "prebiotic": ["banana", "asparagus", "garlic", "onion", "leeks"]
    ]
    
    private let flareTriggerFoods = [
        "high_fiber": ["raw vegetables", "nuts", "seeds", "whole grains"],
        "high_fat": ["fried foods", "cream", "butter", "red meat"],
        "spicy": ["hot peppers", "curry", "spicy sauces"],
        "dairy": ["milk", "ice cream", "cheese"],
        "caffeine": ["coffee", "tea", "soda"],
        "alcohol": ["beer", "wine", "spirits"],
        "artificial": ["sweeteners", "preservatives", "colorings"]
    ]
    
    private init() {}
    
    // MARK: - Main Analysis Function
    func analyzeNutrition(for userData: UserData, journalEntries: [JournalEntry]) -> IBDNutritionAnalysis {
        let dailySummary = calculateDailyNutrition(journalEntries)
        let weeklyTrends = analyzeWeeklyTrends(journalEntries)
        let ibdInsights = analyzeIBDSpecificFactors(dailySummary, journalEntries)
        let recommendations = generateRecommendations(dailySummary, ibdInsights, weeklyTrends)
        let flareRisk = assessFlareRisk(journalEntries, dailySummary)
        let gutHealth = assessGutHealth(journalEntries, dailySummary)
        
        return IBDNutritionAnalysis(
            dailyNutrition: dailySummary,
            weeklyTrends: weeklyTrends,
            ibdSpecificInsights: ibdInsights,
            recommendations: recommendations,
            flareRiskFactors: flareRisk,
            gutHealthMetrics: gutHealth
        )
    }
    
    // MARK: - Daily Nutrition Calculation
    private func calculateDailyNutrition(_ entries: [JournalEntry]) -> DailyNutritionSummary {
        var totalCalories = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFiber = 0.0
        var totalFat = 0.0
        var vitamins: [String: Double] = [:]
        var minerals: [String: Double] = [:]
        var hydration = 0.0
        var fodmapScore = 0.0
        var ibdFriendlyScore = 0.0
        
        for entry in entries {
            // Calculate nutrition from meals
            if let meals = entry.meals {
                for meal in meals {
                    totalCalories += Double(meal.calories ?? 0)
                    totalProtein += Double(meal.protein ?? 0)
                    totalCarbs += Double(meal.carbs ?? 0)
                    totalFiber += Double(meal.fiber ?? 0)
                    totalFat += Double(meal.fat ?? 0)
                }
            }
            
            // Calculate hydration from entry
            if let entryHydration = entry.hydration {
                hydration += Double(entryHydration)
            }
            
            // Calculate FODMAP and IBD-friendly scores
            fodmapScore += calculateFODMAPScore(entry)
            ibdFriendlyScore += calculateIBDFriendlyScore(entry)
        }
        
        return DailyNutritionSummary(
            totalCalories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fiber: totalFiber,
            fat: totalFat,
            vitamins: vitamins,
            minerals: minerals,
            hydration: hydration,
            fodmapLevel: determineFODMAPLevel(fodmapScore),
            ibdFriendlyScore: ibdFriendlyScore / Double(entries.count)
        )
    }
    
    // MARK: - Weekly Trends Analysis
    private func analyzeWeeklyTrends(_ entries: [JournalEntry]) -> WeeklyNutritionTrends {
        // Group entries by day and analyze trends
        let dailyData = groupEntriesByDay(entries)
        
        let calorieTrend = calculateTrend(dailyData.map { $0.calories })
        let proteinTrend = calculateTrend(dailyData.map { $0.protein })
        let fiberTrend = calculateTrend(dailyData.map { $0.fiber })
        let fodmapTrend = calculateTrend(dailyData.map { $0.fodmapScore })
        
        let symptomCorrelation = analyzeSymptomCorrelation(entries)
        let consistencyScore = calculateConsistencyScore(dailyData)
        
        return WeeklyNutritionTrends(
            calorieTrend: calorieTrend,
            proteinTrend: proteinTrend,
            fiberTrend: fiberTrend,
            fodmapTrend: fodmapTrend,
            symptomCorrelation: symptomCorrelation,
            consistencyScore: consistencyScore
        )
    }
    
    // MARK: - IBD-Specific Analysis
    private func analyzeIBDSpecificFactors(_ daily: DailyNutritionSummary, _ entries: [JournalEntry]) -> IBDSpecificInsights {
        let fiberAnalysis = analyzeFiberIntake(daily.fiber)
        let proteinAnalysis = analyzeProteinIntake(daily.protein)
        let fatAnalysis = analyzeFatIntake(daily.fat)
        let vitaminDeficiencies = identifyVitaminDeficiencies(daily.vitamins)
        let mineralDeficiencies = identifyMineralDeficiencies(daily.minerals)
        let hydrationAnalysis = analyzeHydration(daily.hydration)
        let fodmapAnalysis = analyzeFODMAPCompliance(entries)
        
        return IBDSpecificInsights(
            fiberIntake: fiberAnalysis,
            proteinIntake: proteinAnalysis,
            fatIntake: fatAnalysis,
            vitaminDeficiencies: vitaminDeficiencies,
            mineralDeficiencies: mineralDeficiencies,
            hydrationStatus: hydrationAnalysis,
            fodmapCompliance: fodmapAnalysis
        )
    }
    
    // MARK: - Fiber Analysis (Critical for IBD)
    private func analyzeFiberIntake(_ currentFiber: Double) -> FiberAnalysis {
        let recommended = ibdNutritionRequirements["fiber"] ?? 25.0
        let solubleFiber = currentFiber * 0.3 // Estimate
        let insolubleFiber = currentFiber * 0.7 // Estimate
        
        let recommendation: String
        let ibdConsiderations: String
        
        if currentFiber < 15 {
            recommendation = "Gradually increase fiber intake with soluble fiber sources like bananas, applesauce, and oatmeal."
            ibdConsiderations = "Start with 5g/day and increase slowly. Focus on soluble fiber during flares."
        } else if currentFiber > 35 {
            recommendation = "Consider reducing fiber intake if experiencing symptoms. Focus on soluble fiber sources."
            ibdConsiderations = "High fiber may trigger symptoms in active flares. Monitor tolerance."
        } else {
            recommendation = "Maintain current fiber intake. Ensure good balance of soluble and insoluble fiber."
            ibdConsiderations = "Good fiber range for IBD. Continue monitoring symptoms."
        }
        
        return FiberAnalysis(
            currentIntake: currentFiber,
            recommendedIntake: recommended,
            solubleFiber: solubleFiber,
            insolubleFiber: insolubleFiber,
            recommendation: recommendation,
            ibdConsiderations: ibdConsiderations
        )
    }
    
    // MARK: - Protein Analysis (Important for IBD)
    private func analyzeProteinIntake(_ currentProtein: Double) -> ProteinAnalysis {
        let recommended = 1.2 * 70.0 // Assuming 70kg body weight
        let qualityScore = calculateProteinQuality(70.0) // Placeholder
        
        let sources = ["chicken", "fish", "eggs", "tofu", "greek yogurt"]
        
        let recommendation: String
        if currentProtein < recommended * 0.8 {
            recommendation = "Increase protein intake to support healing and prevent muscle loss. Aim for 1.2g/kg body weight."
        } else if currentProtein > recommended * 1.5 {
            recommendation = "Protein intake is adequate. Focus on quality sources and timing."
        } else {
            recommendation = "Protein intake is in good range. Continue with current sources."
        }
        
        return ProteinAnalysis(
            currentIntake: currentProtein,
            recommendedIntake: recommended,
            qualityScore: qualityScore,
            sources: sources,
            recommendation: recommendation
        )
    }
    
    // MARK: - Fat Analysis (Anti-inflammatory focus)
    private func analyzeFatIntake(_ totalFat: Double) -> FatAnalysis {
        let saturatedFat = totalFat * 0.3 // Estimate
        let omega3 = 0.5 // Estimate from typical intake
        let omega6 = 10.0 // Estimate from typical intake
        let ratio = omega6 / omega3
        
        let recommendation: String
        if ratio > 10 {
            recommendation = "Increase omega-3 intake and reduce omega-6 to improve anti-inflammatory balance."
        } else if ratio < 4 {
            recommendation = "Good omega-3 to omega-6 ratio. Continue with current fat sources."
        } else {
            recommendation = "Moderate omega-3 to omega-6 ratio. Consider increasing omega-3 sources."
        }
        
        return FatAnalysis(
            totalFat: totalFat,
            saturatedFat: saturatedFat,
            omega3: omega3,
            omega6: omega6,
            ratio: ratio,
            recommendation: recommendation
        )
    }
    
    // MARK: - Vitamin/Mineral Deficiency Analysis
    private func identifyVitaminDeficiencies(_ vitamins: [String: Double]) -> [VitaminDeficiency] {
        var deficiencies: [VitaminDeficiency] = []
        
        // Check Vitamin D (common in IBD)
        let vitaminD = vitamins["D"] ?? 0
        let recommendedD = ibdNutritionRequirements["vitamin_d"] ?? 800.0
        if vitaminD < recommendedD * 0.8 {
            deficiencies.append(VitaminDeficiency(
                vitamin: "D",
                currentLevel: vitaminD,
                recommendedLevel: recommendedD,
                deficiency: recommendedD - vitaminD,
                foodSources: ["salmon", "egg yolks", "fortified milk"],
                supplementation: "Consider 1000-2000 IU daily"
            ))
        }
        
        // Check Vitamin B12 (common in IBD)
        let vitaminB12 = vitamins["B12"] ?? 0
        let recommendedB12 = ibdNutritionRequirements["vitamin_b12"] ?? 2.4
        if vitaminB12 < recommendedB12 * 0.8 {
            deficiencies.append(VitaminDeficiency(
                vitamin: "B12",
                currentLevel: vitaminB12,
                recommendedLevel: recommendedB12,
                deficiency: recommendedB12 - vitaminB12,
                foodSources: ["fish", "eggs", "dairy"],
                supplementation: "Consider B12 supplementation"
            ))
        }
        
        return deficiencies
    }
    
    private func identifyMineralDeficiencies(_ minerals: [String: Double]) -> [MineralDeficiency] {
        var deficiencies: [MineralDeficiency] = []
        
        // Check Iron (common in IBD)
        let iron = minerals["Iron"] ?? 0
        let recommendedIron = ibdNutritionRequirements["iron"] ?? 18.0
        if iron < recommendedIron * 0.8 {
            deficiencies.append(MineralDeficiency(
                mineral: "Iron",
                currentLevel: iron,
                recommendedLevel: recommendedIron,
                deficiency: recommendedIron - iron,
                foodSources: ["lean meat", "fish", "beans", "fortified cereals"],
                supplementation: "Consider iron supplementation with vitamin C"
            ))
        }
        
        // Check Zinc (important for IBD)
        let zinc = minerals["Zinc"] ?? 0
        let recommendedZinc = ibdNutritionRequirements["zinc"] ?? 11.0
        if zinc < recommendedZinc * 0.8 {
            deficiencies.append(MineralDeficiency(
                mineral: "Zinc",
                currentLevel: zinc,
                recommendedLevel: recommendedZinc,
                deficiency: recommendedZinc - zinc,
                foodSources: ["oysters", "beef", "pumpkin seeds"],
                supplementation: "Consider zinc supplementation"
            ))
        }
        
        return deficiencies
    }
    
    // MARK: - Hydration Analysis
    private func analyzeHydration(_ currentHydration: Double) -> HydrationAnalysis {
        let recommended = ibdNutritionRequirements["hydration"] ?? 2000.0
        let dehydrationRisk: String
        let electrolyteBalance: String
        let recommendation: String
        
        if currentHydration < recommended * 0.7 {
            dehydrationRisk = "High"
            electrolyteBalance = "May be imbalanced"
            recommendation = "Increase fluid intake to 8-10 cups daily. Include electrolyte-rich beverages."
        } else if currentHydration < recommended * 0.9 {
            dehydrationRisk = "Moderate"
            electrolyteBalance = "Generally balanced"
            recommendation = "Slightly increase fluid intake. Monitor hydration during flares."
        } else {
            dehydrationRisk = "Low"
            electrolyteBalance = "Well balanced"
            recommendation = "Maintain current hydration. Continue monitoring during flares."
        }
        
        return HydrationAnalysis(
            currentIntake: currentHydration,
            recommendedIntake: recommended,
            dehydrationRisk: dehydrationRisk,
            electrolyteBalance: electrolyteBalance,
            recommendation: recommendation
        )
    }
    
    // MARK: - FODMAP Analysis
    private func analyzeFODMAPCompliance(_ entries: [JournalEntry]) -> FODMAPAnalysis {
        var highFODMAPFoods: [String] = []
        var complianceScore = 0.0
        var totalFoods = 0
        
        for entry in entries {
            if let meals = entry.meals {
                for meal in meals {
                    totalFoods += 1
                    if isHighFODMAP(meal.description) {
                        highFODMAPFoods.append(meal.description)
                    } else {
                        complianceScore += 1
                    }
                }
            }
        }
        
        complianceScore = totalFoods > 0 ? (complianceScore / Double(totalFoods)) * 100 : 0
        
        let lowFODMAPAlternatives = generateLowFODMAPAlternatives(highFODMAPFoods)
        let symptomCorrelation = calculateSymptomCorrelation(entries)
        
        let recommendation: String
        if complianceScore < 70 {
            recommendation = "Consider reducing high FODMAP foods to manage symptoms."
        } else if complianceScore < 90 {
            recommendation = "Good FODMAP compliance. Monitor individual tolerance."
        } else {
            recommendation = "Excellent FODMAP compliance. Continue current approach."
        }
        
        return FODMAPAnalysis(
            complianceScore: complianceScore,
            highFODMAPFoods: highFODMAPFoods,
            lowFODMAPAlternatives: lowFODMAPAlternatives,
            symptomCorrelation: symptomCorrelation,
            recommendation: recommendation
        )
    }
    
    // MARK: - Flare Risk Assessment
    private func assessFlareRisk(_ entries: [JournalEntry], _ daily: DailyNutritionSummary) -> FlareRiskFactors {
        var highRiskFoods: [RiskFood] = []
        var triggerFoods: [TriggerFood] = []
        var inflammatoryFoods: [InflammatoryFood] = []
        var riskScore = 0.0
        
        // Analyze each entry for risk factors
        for entry in entries {
            if let meals = entry.meals {
                for meal in meals {
                    let risk = assessFoodRisk(meal.description)
                    if risk.riskLevel == .high {
                        highRiskFoods.append(risk)
                        riskScore += 0.3
                    }
                    
                    if isTriggerFood(meal.description) {
                        triggerFoods.append(TriggerFood(
                            name: meal.description,
                            triggerType: "Common IBD trigger",
                            symptoms: ["abdominal pain", "diarrhea", "bloating"],
                            avoidance: "Avoid during flares",
                            reintroduction: "Reintroduce gradually during remission"
                        ))
                        riskScore += 0.2
                    }
                    
                    if isInflammatory(meal.description) {
                        inflammatoryFoods.append(InflammatoryFood(
                            name: meal.description,
                            inflammatoryCompounds: ["saturated fat", "trans fat"],
                            alternatives: ["olive oil", "avocado", "nuts"],
                            preparation: "Choose grilled or baked over fried"
                        ))
                        riskScore += 0.1
                    }
                }
            }
        }
        
        let recommendations = generateFlarePreventionActions(riskScore, highRiskFoods, triggerFoods)
        
        return FlareRiskFactors(
            highRiskFoods: highRiskFoods,
            triggerFoods: triggerFoods,
            inflammatoryFoods: inflammatoryFoods,
            riskScore: min(riskScore, 1.0),
            recommendations: recommendations
        )
    }
    
    // MARK: - Gut Health Assessment
    private func assessGutHealth(_ entries: [JournalEntry], _ daily: DailyNutritionSummary) -> GutHealthMetrics {
        let microbiomeScore = calculateMicrobiomeScore(entries)
        let inflammationMarkers = calculateInflammationMarkers(daily)
        let gutBarrierHealth = assessGutBarrierHealth(daily)
        let probioticFoods = identifyProbioticFoods(entries)
        let prebioticFoods = identifyPrebioticFoods(entries)
        
        return GutHealthMetrics(
            microbiomeScore: microbiomeScore,
            inflammationMarkers: inflammationMarkers,
            gutBarrierHealth: gutBarrierHealth,
            probioticFoods: probioticFoods,
            prebioticFoods: prebioticFoods
        )
    }
    
    // MARK: - Recommendation Generation
    private func generateRecommendations(_ daily: DailyNutritionSummary, _ insights: IBDSpecificInsights, _ trends: WeeklyNutritionTrends) -> NutritionRecommendations {
        let immediateActions = generateImmediateActions(daily, insights)
        let weeklyGoals = generateWeeklyGoals(daily, insights)
        let longTermStrategies = generateLongTermStrategies(insights, trends)
        let foodSuggestions = generateFoodSuggestions(daily, insights)
        let mealTiming = generateMealTimingRecommendations(daily)
        
        return NutritionRecommendations(
            immediateActions: immediateActions,
            weeklyGoals: weeklyGoals,
            longTermStrategies: longTermStrategies,
            foodSuggestions: foodSuggestions,
            mealTiming: mealTiming
        )
    }
    
    // MARK: - Helper Functions
    private func calculateFODMAPScore(_ entry: JournalEntry) -> Double {
        // Implementation for FODMAP scoring
        return 0.5 // Placeholder
    }
    
    private func calculateIBDFriendlyScore(_ entry: JournalEntry) -> Double {
        // Implementation for IBD-friendly scoring
        return 0.8 // Placeholder
    }
    
    private func determineFODMAPLevel(_ score: Double) -> String {
        if score < 0.3 { return "low" }
        else if score < 0.7 { return "medium" }
        else { return "high" }
    }
    
    private func groupEntriesByDay(_ entries: [JournalEntry]) -> [DailyData] {
        // Implementation for grouping entries by day
        return [] // Placeholder
    }
    
    private func calculateTrend(_ values: [Double]) -> TrendDirection {
        // Implementation for trend calculation
        return .stable // Placeholder
    }
    
    private func analyzeSymptomCorrelation(_ entries: [JournalEntry]) -> [String: Double] {
        // Implementation for symptom correlation
        return [:] // Placeholder
    }
    
    private func calculateConsistencyScore(_ dailyData: [DailyData]) -> Double {
        // Implementation for consistency scoring
        return 0.8 // Placeholder
    }
    
    private func calculateProteinQuality(_ weight: Double) -> Double {
        // Implementation for protein quality calculation
        return 0.9 // Placeholder
    }
    
    private func isHighFODMAP(_ food: String) -> Bool {
        // Implementation for FODMAP checking
        return false // Placeholder
    }
    
    private func generateLowFODMAPAlternatives(_ highFODMAPFoods: [String]) -> [String] {
        // Implementation for generating alternatives
        return [] // Placeholder
    }
    
    private func calculateSymptomCorrelation(_ entries: [JournalEntry]) -> Double {
        // Implementation for symptom correlation
        return 0.6 // Placeholder
    }
    
    private func assessFoodRisk(_ food: String) -> RiskFood {
        // Implementation for food risk assessment
        return RiskFood(
            name: food,
            riskLevel: .medium,
            reason: "Common trigger food",
            alternative: "Low-risk alternative",
            frequency: "Occasional"
        )
    }
    
    private func isTriggerFood(_ food: String) -> Bool {
        // Implementation for trigger food checking
        return false // Placeholder
    }
    
    private func isInflammatory(_ food: String) -> Bool {
        // Implementation for inflammatory food checking
        return false // Placeholder
    }
    
    private func generateFlarePreventionActions(_ riskScore: Double, _ highRiskFoods: [RiskFood], _ triggerFoods: [TriggerFood]) -> [FlarePreventionAction] {
        // Implementation for flare prevention actions
        return [] // Placeholder
    }
    
    private func calculateMicrobiomeScore(_ entries: [JournalEntry]) -> Double {
        // Implementation for microbiome scoring
        return 0.7 // Placeholder
    }
    
    private func calculateInflammationMarkers(_ daily: DailyNutritionSummary) -> [String: Double] {
        // Implementation for inflammation markers
        return [:] // Placeholder
    }
    
    private func assessGutBarrierHealth(_ daily: DailyNutritionSummary) -> String {
        // Implementation for gut barrier health assessment
        return "Good" // Placeholder
    }
    
    private func identifyProbioticFoods(_ entries: [JournalEntry]) -> [String] {
        // Implementation for probiotic food identification
        return [] // Placeholder
    }
    
    private func identifyPrebioticFoods(_ entries: [JournalEntry]) -> [String] {
        // Implementation for prebiotic food identification
        return [] // Placeholder
    }
    
    private func generateImmediateActions(_ daily: DailyNutritionSummary, _ insights: IBDSpecificInsights) -> [NutritionAction] {
        // Implementation for immediate actions
        return [] // Placeholder
    }
    
    private func generateWeeklyGoals(_ daily: DailyNutritionSummary, _ insights: IBDSpecificInsights) -> [NutritionGoal] {
        // Implementation for weekly goals
        return [] // Placeholder
    }
    
    private func generateLongTermStrategies(_ insights: IBDSpecificInsights, _ trends: WeeklyNutritionTrends) -> [NutritionStrategy] {
        // Implementation for long-term strategies
        return [] // Placeholder
    }
    
    private func generateFoodSuggestions(_ daily: DailyNutritionSummary, _ insights: IBDSpecificInsights) -> [FoodSuggestion] {
        // Implementation for food suggestions
        return [] // Placeholder
    }
    
    private func generateMealTimingRecommendations(_ daily: DailyNutritionSummary) -> MealTimingRecommendations {
        // Implementation for meal timing recommendations
        return MealTimingRecommendations(
            breakfast: "Eat within 1 hour of waking",
            lunch: "Consistent timing, avoid large meals",
            dinner: "Light meal 3 hours before bed",
            snacks: "Small, frequent snacks",
            hydration: "Drink throughout the day",
            fasting: nil
        )
    }
}

// MARK: - Supporting Structures
struct DailyData {
    let date: Date
    let calories: Double
    let protein: Double
    let fiber: Double
    let fodmapScore: Double
}

// JournalEntry is now defined in FlarePredictionML.swift

struct FoodItem {
    let name: String
    let quantity: Double
    let unit: String
}

struct BeverageData {
    let totalHydration: Double
}

struct NutritionData {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let fat: Double
    let vitamins: [String: Double]
    let minerals: [String: Double]
} 