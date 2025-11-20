import Foundation

// MARK: - Nutrition Score Calculator
/// Shared service for calculating normalized nutrition scores using statistical methods
class NutritionScoreCalculator: ObservableObject {
    static let shared = NutritionScoreCalculator()
    
    private init() {}
    
    /// Calculate normalized nutrition score using statistical methods
    /// - Parameters:
    ///   - macronutrients: Array of (name, actual, target) tuples for macronutrients
    ///   - micronutrients: IBDSpecificNutrients containing micronutrient status
    ///   - userProfile: Optional user profile for personalized targets
    /// - Returns: Normalized score from 0-100
    func calculateScore(
        macronutrients: [(String, Double, Double)],
        micronutrients: IBDSpecificNutrients,
        userProfile: MicronutrientProfile? = nil
    ) -> Int {
        // Step 1: Normalize each macronutrient to 0-1 scale using sigmoid function for better distribution
        var macroScores: [Double] = []
        
        for (name, actual, target) in macronutrients {
            // Normalize: actual/target ratio
            let ratio = target > 0 ? min(actual / target, 1.2) : 0.0 // Cap at 120% to allow slight excess
            
            // Apply sigmoid function for better statistical distribution
            // Sigmoid: 1 / (1 + e^(-k*(x-1))) where k controls steepness
            // This gives better scores for values close to target
            let k: Double = 5.0 // Steepness parameter
            let sigmoidScore = 1.0 / (1.0 + exp(-k * (ratio - 1.0)))
            
            // For ratios < 1.0, use linear scaling to penalize deficiencies more
            let normalizedScore = ratio < 1.0 ? ratio * 0.9 : sigmoidScore * 0.9 + 0.1
            
            macroScores.append(normalizedScore)
            print("🔍 [NutritionScoreCalculator] \(name): actual=\(actual), target=\(target), ratio=\(String(format: "%.2f", ratio)), normalized=\(String(format: "%.3f", normalizedScore))")
        }
        
        // Step 2: Normalize micronutrients using status-based scoring
        let keyMicronutrients: [(NutrientStatus, String, Double)] = [
            (micronutrients.vitaminD, "Vitamin D", 0.15), // 15% weight
            (micronutrients.vitaminB12, "Vitamin B12", 0.15),
            (micronutrients.iron, "Iron", 0.20), // 20% weight (critical for IBD)
            (micronutrients.calcium, "Calcium", 0.15),
            (micronutrients.zinc, "Zinc", 0.15),
            (micronutrients.omega3, "Omega-3", 0.20) // 20% weight (anti-inflammatory)
        ]
        
        var microScores: [Double] = []
        var microWeights: [Double] = []
        
        for (nutrient, name, weight) in keyMicronutrients {
            let score: Double
            switch nutrient.status {
            case .deficient:
                score = 0.2 // 20% score for deficient
            case .suboptimal:
                score = 0.5 // 50% score for suboptimal
            case .adequate:
                score = 0.75 // 75% score for adequate
            case .optimal:
                score = 1.0 // 100% score for optimal
            case .excessive:
                score = 0.9 // 90% score for excessive (slight penalty)
            }
            
            microScores.append(score)
            microWeights.append(weight)
            print("🔍 [NutritionScoreCalculator] \(name): status=\(nutrient.status.rawValue), score=\(String(format: "%.2f", score)), weight=\(String(format: "%.2f", weight))")
        }
        
        // Step 3: Calculate weighted averages
        // Macronutrients: 60% weight (more important for overall nutrition)
        // Micronutrients: 40% weight (important but secondary)
        let macroWeight = 0.6
        let microWeight = 0.4
        
        // Weighted average of macronutrients (equal weight within group)
        let macroAverage = macroScores.isEmpty ? 0.0 : macroScores.reduce(0, +) / Double(macroScores.count)
        
        // Weighted average of micronutrients (using individual weights)
        let microWeightedSum = zip(microScores, microWeights).map { $0 * $1 }.reduce(0, +)
        let microWeightSum = microWeights.reduce(0, +)
        let microAverage = microWeightSum > 0 ? microWeightedSum / microWeightSum : 0.0
        
        // Step 4: Calculate composite score using weighted arithmetic and harmonic means
        // Arithmetic mean: primary calculation
        let arithmeticMean = (macroAverage * macroWeight) + (microAverage * microWeight)
        
        // Harmonic mean: most conservative, penalizes deficiencies more
        // Harmonic mean: n / (1/x1 + 1/x2 + ...)
        let harmonicMean: Double
        if macroAverage > 0 && microAverage > 0 {
            harmonicMean = 2.0 / ((1.0 / macroAverage) + (1.0 / microAverage))
        } else if macroAverage > 0 {
            harmonicMean = macroAverage
        } else if microAverage > 0 {
            harmonicMean = microAverage
        } else {
            harmonicMean = 0.0
        }
        
        // Use weighted arithmetic mean as primary, with harmonic mean as adjustment factor
        let finalNormalizedScore = (arithmeticMean * 0.7) + (harmonicMean * 0.3)
        
        // Convert to 0-100 scale
        let finalScore = Int(round(finalNormalizedScore * 100))
        
        print("🔍 [NutritionScoreCalculator] Macro average: \(String(format: "%.3f", macroAverage)), Micro average: \(String(format: "%.3f", microAverage))")
        print("🔍 [NutritionScoreCalculator] Arithmetic mean: \(String(format: "%.3f", arithmeticMean)), Harmonic mean: \(String(format: "%.3f", harmonicMean))")
        print("🔍 [NutritionScoreCalculator] Final normalized score: \(finalScore)")
        
        return max(0, min(100, finalScore))
    }
}





