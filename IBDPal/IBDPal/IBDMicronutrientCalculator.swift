import Foundation

// MARK: - IBD Micronutrient Calculator
class IBDMicronutrientCalculator: ObservableObject {
    static let shared = IBDMicronutrientCalculator()
    
    private let enhancedFoodDB = EnhancedFoodDatabase.shared
    private let compoundFoodDB = CompoundFoodDatabase.shared
    
    private init() {}
    
    // MARK: - Main Calculation Functions
    
    /// Calculate micronutrients from a food description with intelligent serving size parsing
    func calculateMicronutrients(for foodDescription: String, userProfile: MicronutrientProfile) -> MicronutrientData {
        let correctedDescription = correctSpelling(foodDescription)
        
        // Use intelligent serving size parser
        let servingSize = IntelligentServingSizeParser.shared.parseServingSize(from: correctedDescription, userProfile: userProfile)
        
        // Use NLP processor for intelligent food recognition
        let nlpResult = FoodNLPProcessor.shared.processFoodDescription(correctedDescription)
        
        // First, try to find compound dishes
        for compoundFood in nlpResult.compoundFoods {
            if let compoundFoodItem = findCompoundFood(in: compoundFood.name.lowercased()) {
                return calculateFromCompoundFood(compoundFoodItem, servingSize: servingSize)
            }
        }
        
        // Then try enhanced individual foods
        for foodEntity in nlpResult.individualFoods {
            if let enhancedFood = findEnhancedFood(in: foodEntity.normalizedText) {
                return calculateFromEnhancedFood(enhancedFood, servingSize: servingSize)
            }
        }
        
        // Fallback to estimated micronutrients based on food category
        return estimateMicronutrients(for: correctedDescription, servingSize: servingSize)
    }
    
    /// Calculate micronutrients with explicit serving size (for backward compatibility)
    func calculateMicronutrients(for foodDescription: String, servingSize: Double = 1.0) -> MicronutrientData {
        let correctedDescription = correctSpelling(foodDescription)
        
        // Use NLP processor for intelligent food recognition
        let nlpResult = FoodNLPProcessor.shared.processFoodDescription(correctedDescription)
        
        // First, try to find compound dishes
        for compoundFood in nlpResult.compoundFoods {
            if let compoundFoodItem = findCompoundFood(in: compoundFood.name.lowercased()) {
                return calculateFromCompoundFood(compoundFoodItem, servingSize: servingSize)
            }
        }
        
        // Then try enhanced individual foods
        for foodEntity in nlpResult.individualFoods {
            if let enhancedFood = findEnhancedFood(in: foodEntity.normalizedText) {
                return calculateFromEnhancedFood(enhancedFood, servingSize: servingSize)
            }
        }
        
        // Fallback to estimated micronutrients based on food category
        return estimateMicronutrients(for: correctedDescription, servingSize: servingSize)
    }
    
    /// Calculate daily micronutrient intake from journal entries with intelligent serving size parsing
    func calculateDailyMicronutrientIntake(from journalEntries: [JournalEntry], userProfile: MicronutrientProfile) -> DailyMicronutrientIntake {
        var totalMicronutrients = MicronutrientData()
        var foodSources: [String: MicronutrientData] = [:]
        var supplementSources: [String: MicronutrientData] = [:]
        
        // Calculate from food intake using intelligent serving size parsing
        for entry in journalEntries {
            if let meals = entry.meals {
                for meal in meals {
                    let foodName = meal.description
                    // Use intelligent serving size parser instead of hardcoded serving size
                    let micronutrients = calculateMicronutrients(for: foodName, userProfile: userProfile)
                    totalMicronutrients = addMicronutrients(totalMicronutrients, micronutrients)
                    foodSources[foodName] = micronutrients
                }
            }
        }
        
        // Calculate from supplements
        for supplement in userProfile.supplements where supplement.isActive {
            let supplementMicronutrients = calculateSupplementMicronutrients(supplement)
            totalMicronutrients = addMicronutrients(totalMicronutrients, supplementMicronutrients)
            supplementSources[supplement.name] = supplementMicronutrients
        }
        
        // Create requirements based on user profile - Fixed: removed labResults parameter
        let requirements = IBDMicronutrientRequirements(
            age: userProfile.age,
            gender: userProfile.gender ?? "Unknown",
            weight: userProfile.weight,
            height: userProfile.height,
            diseaseActivity: userProfile.diseaseActivity,
            medications: [] // TODO: Add medications to user profile
        )
        
        // Fixed: DailyMicronutrientIntake doesn't accept deficiencies and excesses parameters
        return DailyMicronutrientIntake(
            date: Date(),
            totalIntake: totalMicronutrients,
            foodSources: foodSources,
            supplementSources: supplementSources,
            requirements: requirements
        )
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculateFromEnhancedFood(_ food: EnhancedFoodItem, servingSize: Double) -> MicronutrientData {
        return scaleMicronutrients(food.micronutrients, by: servingSize)
    }
    
    private func calculateFromCompoundFood(_ food: CompoundFoodItem, servingSize: Double) -> MicronutrientData {
        var totalMicronutrients = MicronutrientData()
        
        for ingredient in food.ingredients {
            if let enhancedFood = findEnhancedFood(in: ingredient.name.lowercased()) {
                let ingredientMicronutrients = scaleMicronutrients(enhancedFood.micronutrients, by: ingredient.quantity * servingSize)
                totalMicronutrients = addMicronutrients(totalMicronutrients, ingredientMicronutrients)
            }
        }
        
        return totalMicronutrients
    }
    
    private func estimateMicronutrients(for foodDescription: String, servingSize: Double) -> MicronutrientData {
        let category = determineFoodCategory(foodDescription)
        return getEstimatedMicronutrients(for: category, servingSize: servingSize)
    }
    
    private func calculateSupplementMicronutrients(_ supplement: MicronutrientSupplement) -> MicronutrientData {
        // Convert supplement to micronutrient data based on category and dosage
        switch supplement.category {
        case .vitamin:
            return getVitaminMicronutrients(supplement.name, dosage: supplement.dosage, unit: supplement.unit)
        case .mineral:
            return getMineralMicronutrients(supplement.name, dosage: supplement.dosage, unit: supplement.unit)
        case .traceElement:
            return getTraceElementMicronutrients(supplement.name, dosage: supplement.dosage, unit: supplement.unit)
        case .other:
            return MicronutrientData() // Unknown supplement
        }
    }
    
    // MARK: - Micronutrient Arithmetic
    
    // Fixed: Break up complex expression to avoid type-checking timeout
    private func addMicronutrients(_ a: MicronutrientData, _ b: MicronutrientData) -> MicronutrientData {
        // Vitamins
        let vitaminA = a.vitaminA + b.vitaminA
        let vitaminB1 = a.vitaminB1 + b.vitaminB1
        let vitaminB2 = a.vitaminB2 + b.vitaminB2
        let vitaminB3 = a.vitaminB3 + b.vitaminB3
        let vitaminB5 = a.vitaminB5 + b.vitaminB5
        let vitaminB6 = a.vitaminB6 + b.vitaminB6
        let vitaminB7 = a.vitaminB7 + b.vitaminB7
        let vitaminB9 = a.vitaminB9 + b.vitaminB9
        let vitaminB12 = a.vitaminB12 + b.vitaminB12
        let vitaminC = a.vitaminC + b.vitaminC
        let vitaminD = a.vitaminD + b.vitaminD
        let vitaminE = a.vitaminE + b.vitaminE
        let vitaminK = a.vitaminK + b.vitaminK
        
        // Minerals
        let calcium = a.calcium + b.calcium
        let iron = a.iron + b.iron
        let magnesium = a.magnesium + b.magnesium
        let phosphorus = a.phosphorus + b.phosphorus
        let potassium = a.potassium + b.potassium
        let sodium = a.sodium + b.sodium
        let zinc = a.zinc + b.zinc
        let copper = a.copper + b.copper
        let manganese = a.manganese + b.manganese
        let selenium = a.selenium + b.selenium
        let iodine = a.iodine + b.iodine
        let chromium = a.chromium + b.chromium
        let molybdenum = a.molybdenum + b.molybdenum
        let boron = a.boron + b.boron
        let silicon = a.silicon + b.silicon
        let vanadium = a.vanadium + b.vanadium
        
        // IBD-specific nutrients
        let omega3 = a.omega3 + b.omega3
        let glutamine = a.glutamine + b.glutamine
        let probiotics = a.probiotics + b.probiotics
        let prebiotics = a.prebiotics + b.prebiotics
        
        return MicronutrientData(
            vitaminA: vitaminA,
            vitaminB1: vitaminB1,
            vitaminB2: vitaminB2,
            vitaminB3: vitaminB3,
            vitaminB5: vitaminB5,
            vitaminB6: vitaminB6,
            vitaminB7: vitaminB7,
            vitaminB9: vitaminB9,
            vitaminB12: vitaminB12,
            vitaminC: vitaminC,
            vitaminD: vitaminD,
            vitaminE: vitaminE,
            vitaminK: vitaminK,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            phosphorus: phosphorus,
            potassium: potassium,
            sodium: sodium,
            zinc: zinc,
            copper: copper,
            manganese: manganese,
            selenium: selenium,
            iodine: iodine,
            chromium: chromium,
            molybdenum: molybdenum,
            boron: boron,
            silicon: silicon,
            vanadium: vanadium,
            omega3: omega3,
            glutamine: glutamine,
            probiotics: probiotics,
            prebiotics: prebiotics
        )
    }
    
    // Fixed: Break up complex expression and remove non-existent properties
    private func scaleMicronutrients(_ micronutrients: MicronutrientData, by factor: Double) -> MicronutrientData {
        // Vitamins
        let vitaminA = micronutrients.vitaminA * factor
        let vitaminB1 = micronutrients.vitaminB1 * factor
        let vitaminB2 = micronutrients.vitaminB2 * factor
        let vitaminB3 = micronutrients.vitaminB3 * factor
        let vitaminB5 = micronutrients.vitaminB5 * factor
        let vitaminB6 = micronutrients.vitaminB6 * factor
        let vitaminB7 = micronutrients.vitaminB7 * factor
        let vitaminB9 = micronutrients.vitaminB9 * factor
        let vitaminB12 = micronutrients.vitaminB12 * factor
        let vitaminC = micronutrients.vitaminC * factor
        let vitaminD = micronutrients.vitaminD * factor
        let vitaminE = micronutrients.vitaminE * factor
        let vitaminK = micronutrients.vitaminK * factor
        
        // Minerals
        let calcium = micronutrients.calcium * factor
        let iron = micronutrients.iron * factor
        let magnesium = micronutrients.magnesium * factor
        let phosphorus = micronutrients.phosphorus * factor
        let potassium = micronutrients.potassium * factor
        let sodium = micronutrients.sodium * factor
        let zinc = micronutrients.zinc * factor
        let copper = micronutrients.copper * factor
        let manganese = micronutrients.manganese * factor
        let selenium = micronutrients.selenium * factor
        let iodine = micronutrients.iodine * factor
        let chromium = micronutrients.chromium * factor
        let molybdenum = micronutrients.molybdenum * factor
        let boron = micronutrients.boron * factor
        let silicon = micronutrients.silicon * factor
        let vanadium = micronutrients.vanadium * factor
        
        // IBD-specific nutrients
        let omega3 = micronutrients.omega3 * factor
        let glutamine = micronutrients.glutamine * factor
        let probiotics = micronutrients.probiotics * factor
        let prebiotics = micronutrients.prebiotics * factor
        
        return MicronutrientData(
            vitaminA: vitaminA,
            vitaminB1: vitaminB1,
            vitaminB2: vitaminB2,
            vitaminB3: vitaminB3,
            vitaminB5: vitaminB5,
            vitaminB6: vitaminB6,
            vitaminB7: vitaminB7,
            vitaminB9: vitaminB9,
            vitaminB12: vitaminB12,
            vitaminC: vitaminC,
            vitaminD: vitaminD,
            vitaminE: vitaminE,
            vitaminK: vitaminK,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            phosphorus: phosphorus,
            potassium: potassium,
            sodium: sodium,
            zinc: zinc,
            copper: copper,
            manganese: manganese,
            selenium: selenium,
            iodine: iodine,
            chromium: chromium,
            molybdenum: molybdenum,
            boron: boron,
            silicon: silicon,
            vanadium: vanadium,
            omega3: omega3,
            glutamine: glutamine,
            probiotics: probiotics,
            prebiotics: prebiotics
        )
    }
    
    // MARK: - Helper Methods
    
    private func findEnhancedFood(in name: String) -> EnhancedFoodItem? {
        return enhancedFoodDB.allFoods.first { food in
            food.name.lowercased().contains(name.lowercased()) ||
            name.lowercased().contains(food.name.lowercased())
        }
    }
    
    private func findCompoundFood(in name: String) -> CompoundFoodItem? {
        return compoundFoodDB.compoundFoods.first { food in
            food.name.lowercased().contains(name.lowercased()) ||
            name.lowercased().contains(food.name.lowercased())
        }
    }
    
    private func correctSpelling(_ text: String) -> String {
        // Basic spelling correction - can be enhanced with more sophisticated algorithms
        return text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func determineFoodCategory(_ foodDescription: String) -> String {
        let description = foodDescription.lowercased()
        
        if description.contains("fruit") || description.contains("apple") || description.contains("banana") {
            return "fruit"
        } else if description.contains("vegetable") || description.contains("carrot") || description.contains("broccoli") {
            return "vegetable"
        } else if description.contains("meat") || description.contains("chicken") || description.contains("beef") {
            return "protein"
        } else if description.contains("grain") || description.contains("rice") || description.contains("bread") {
            return "grain"
        } else if description.contains("dairy") || description.contains("milk") || description.contains("cheese") {
            return "dairy"
        } else {
            return "other"
        }
    }
    
    private func getEstimatedMicronutrients(for category: String, servingSize: Double) -> MicronutrientData {
        // Return estimated micronutrients based on food category
        // This is a simplified version - in production, you'd have more detailed estimates
        switch category {
        case "fruit":
            return MicronutrientData(
                vitaminB9: 20.0 * servingSize, // Fixed: moved before vitaminC
                vitaminC: 50.0 * servingSize,
                potassium: 200.0 * servingSize
            )
        case "vegetable":
            return MicronutrientData(
                vitaminA: 100.0 * servingSize,
                vitaminB9: 40.0 * servingSize, // Fixed: moved before vitaminC
                vitaminC: 30.0 * servingSize,
                potassium: 300.0 * servingSize
            )
        case "protein":
            return MicronutrientData(
                vitaminB12: 1.0 * servingSize, // Fixed: moved before iron
                iron: 2.0 * servingSize,
                zinc: 3.0 * servingSize
            )
        case "grain":
            return MicronutrientData(
                vitaminB9: 30.0 * servingSize,
                iron: 1.0 * servingSize,
                magnesium: 50.0 * servingSize
            )
        case "dairy":
            return MicronutrientData(
                vitaminB12: 1.0 * servingSize,
                vitaminD: 2.0 * servingSize, // Fixed: moved before calcium
                calcium: 200.0 * servingSize
            )
        default:
            return MicronutrientData()
        }
    }
    
    private func getVitaminMicronutrients(_ supplementName: String, dosage: Double, unit: DosageUnit) -> MicronutrientData {
        let name = supplementName.lowercased()
        let convertedDosage = convertDosage(dosage, from: unit, to: .mg)
        
        if name.contains("vitamin d") {
            return MicronutrientData(vitaminD: convertedDosage)
        } else if name.contains("vitamin b12") {
            return MicronutrientData(vitaminB12: convertedDosage)
        } else if name.contains("vitamin c") {
            return MicronutrientData(vitaminC: convertedDosage)
        } else if name.contains("folate") || name.contains("folic acid") {
            return MicronutrientData(vitaminB9: convertedDosage) // Fixed: was folate
        }
        // Add more vitamin mappings as needed
        return MicronutrientData()
    }
    
    private func getMineralMicronutrients(_ supplementName: String, dosage: Double, unit: DosageUnit) -> MicronutrientData {
        let name = supplementName.lowercased()
        let convertedDosage = convertDosage(dosage, from: unit, to: .mg)
        
        if name.contains("iron") {
            return MicronutrientData(iron: convertedDosage)
        } else if name.contains("calcium") {
            return MicronutrientData(calcium: convertedDosage)
        } else if name.contains("zinc") {
            return MicronutrientData(zinc: convertedDosage)
        } else if name.contains("magnesium") {
            return MicronutrientData(magnesium: convertedDosage)
        }
        // Add more mineral mappings as needed
        return MicronutrientData()
    }
    
    private func getTraceElementMicronutrients(_ supplementName: String, dosage: Double, unit: DosageUnit) -> MicronutrientData {
        let name = supplementName.lowercased()
        let convertedDosage = convertDosage(dosage, from: unit, to: .mcg)
        
        if name.contains("selenium") {
            return MicronutrientData(selenium: convertedDosage)
        } else if name.contains("iodine") {
            return MicronutrientData(iodine: convertedDosage)
        } else if name.contains("chromium") {
            return MicronutrientData(chromium: convertedDosage)
        }
        // Add more trace element mappings as needed
        return MicronutrientData()
    }
    
    private func convertDosage(_ dosage: Double, from fromUnit: DosageUnit, to toUnit: DosageUnit) -> Double {
        // Convert between different dosage units
        // This is a simplified conversion - in production, you'd have more comprehensive conversions
        if fromUnit == toUnit {
            return dosage
        }
        
        switch (fromUnit, toUnit) {
        case (.mg, .mcg):
            return dosage * 1000
        case (.mcg, .mg):
            return dosage / 1000
        case (.g, .mg):
            return dosage * 1000
        case (.mg, .g):
            return dosage / 1000
        default:
            return dosage // No conversion available
        }
    }
}