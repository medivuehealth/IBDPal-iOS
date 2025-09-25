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
        print("🔍 [NLP DEBUG] Processing: '\(correctedDescription)'")
        
        // Use simple serving size parsing (remove IntelligentServingSizeParser reference)
        let servingSize = parseServingSize(from: correctedDescription)
        print("🔍 [NLP DEBUG] Serving size: \(servingSize) cups")
        
        // Enhanced NLP-based food recognition
        let recognizedFoods = enhancedFoodRecognition(from: correctedDescription)
        print("🔍 [NLP DEBUG] Recognized foods: \(recognizedFoods)")
        
        // Try to find compound dishes first
        for compoundFood in recognizedFoods.compoundFoods {
            if let compoundFoodItem = findCompoundFood(in: compoundFood.lowercased()) {
                print("🔍 [NLP DEBUG] Found compound food: \(compoundFood)")
                return calculateFromCompoundFood(compoundFoodItem, servingSize: servingSize)
            }
        }
        
        // Then try enhanced individual foods
        for foodEntity in recognizedFoods.individualFoods {
            if let enhancedFood = findEnhancedFood(in: foodEntity.lowercased()) {
                print("🔍 [NLP DEBUG] Found enhanced food: \(foodEntity)")
                return calculateFromEnhancedFood(enhancedFood, servingSize: servingSize)
            }
        }
        
        // Enhanced fallback with better categorization
        return enhancedEstimateMicronutrients(for: correctedDescription, servingSize: servingSize)
    }
    
    /// Calculate micronutrients from a meal with actual serving size data
    func calculateMicronutrients(for meal: Meal, userProfile: MicronutrientProfile) -> MicronutrientData {
        let correctedDescription = correctSpelling(meal.description)
        print("🔍 [MEAL NLP DEBUG] Processing: '\(correctedDescription)'")
        
        // Use actual serving size from meal data if available
        let servingSize: Double
        if let mealServingSize = meal.serving_size, let mealServingUnit = meal.serving_unit {
            servingSize = convertServingSize(mealServingSize, from: mealServingUnit)
            print("🔍 [MEAL SERVING SIZE] Using meal data: \(mealServingSize) \(mealServingUnit) = \(servingSize) cups")
        } else {
            // Fallback to parsing from description
            servingSize = parseServingSize(from: correctedDescription)
            print("🔍 [MEAL SERVING SIZE] Parsed from description: \(servingSize) cups")
        }
        
        // Enhanced NLP-based food recognition
        let recognizedFoods = enhancedFoodRecognition(from: correctedDescription)
        print("🔍 [MEAL NLP DEBUG] Recognized foods: \(recognizedFoods)")
        
        // Try to find compound dishes first
        for compoundFood in recognizedFoods.compoundFoods {
            if let compoundFoodItem = findCompoundFood(in: compoundFood.lowercased()) {
                print("🔍 [MEAL NLP DEBUG] Found compound food: \(compoundFood)")
                return calculateFromCompoundFood(compoundFoodItem, servingSize: servingSize)
            }
        }
        
        // Then try enhanced individual foods
        for foodEntity in recognizedFoods.individualFoods {
            if let enhancedFood = findEnhancedFood(in: foodEntity.lowercased()) {
                print("🔍 [MEAL NLP DEBUG] Found enhanced food: \(foodEntity)")
                return calculateFromEnhancedFood(enhancedFood, servingSize: servingSize)
            }
        }
        
        // Enhanced fallback with better categorization
        return enhancedEstimateMicronutrients(for: correctedDescription, servingSize: servingSize)
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
        
        print("🔍 [MICRONUTRIENT DEBUG] Starting calculation with \(journalEntries.count) journal entries")
        
        // Calculate from food intake using intelligent serving size parsing
        for entry in journalEntries {
            if let meals = entry.meals {
                print("🔍 [MICRONUTRIENT DEBUG] Processing entry with \(meals.count) meals")
                for meal in meals {
                    let foodName = meal.description
                    print("🔍 [MICRONUTRIENT DEBUG] Processing food: '\(foodName)'")
                    
                    // Use meal-based calculation with actual serving size data
                    let micronutrients = calculateMicronutrients(for: meal, userProfile: userProfile)
                    
                    print("🔍 [MICRONUTRIENT DEBUG] Calculated micronutrients for '\(foodName)':")
                    print("🔍 [MICRONUTRIENT DEBUG]   Vitamin C: \(micronutrients.vitaminC) mg")
                    print("🔍 [MICRONUTRIENT DEBUG]   Iron: \(micronutrients.iron) mg")
                    print("🔍 [MICRONUTRIENT DEBUG]   Vitamin D: \(micronutrients.vitaminD) mcg")
                    print("🔍 [MICRONUTRIENT DEBUG]   Calcium: \(micronutrients.calcium) mg")
                    
                    totalMicronutrients = addMicronutrients(totalMicronutrients, micronutrients)
                    foodSources[foodName] = micronutrients
                }
            } else {
                print("🔍 [MICRONUTRIENT DEBUG] Entry has no meals")
            }
        }
        
        print("🔍 [MICRONUTRIENT DEBUG] Final food sources count: \(foodSources.count)")
        print("🔍 [MICRONUTRIENT DEBUG] Food sources: \(Array(foodSources.keys))")
        
        // Calculate from supplements
        for supplement in userProfile.supplements where supplement.isActive {
            let supplementMicronutrients = calculateSupplementMicronutrients(supplement)
            totalMicronutrients = addMicronutrients(totalMicronutrients, supplementMicronutrients)
            supplementSources[supplement.name] = supplementMicronutrients
        }
        
        // Create evidence-based requirements with disease type consideration
        // Determine disease type from user profile or default to IBD
        let diseaseType = userProfile.diseaseType ?? "IBD"
        
        let requirements = IBDMicronutrientRequirements(
            age: userProfile.age,
            gender: userProfile.gender ?? "Unknown",
            weight: userProfile.weight,
            height: userProfile.height,
            diseaseActivity: userProfile.diseaseActivity,
            medications: [], // TODO: Add medications to user profile
            diseaseType: diseaseType
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
        // Convert vitamins and minerals dictionaries to MicronutrientData
        let micronutrientData = createMicronutrientDataFromEnhancedFood(food)
        return scaleMicronutrients(micronutrientData, by: servingSize)
    }
    
    private func calculateFromCompoundFood(_ food: CompoundFoodItem, servingSize: Double) -> MicronutrientData {
        var totalMicronutrients = MicronutrientData()
        
        for ingredient in food.ingredients {
            if let enhancedFood = findEnhancedFood(in: ingredient.name.lowercased()) {
                let ingredientMicronutrientData = createMicronutrientDataFromEnhancedFood(enhancedFood)
                let ingredientMicronutrients = scaleMicronutrients(ingredientMicronutrientData, by: ingredient.quantity * servingSize)
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
    
    // MARK: - Enhanced Food Recognition
    
    /// Enhanced food recognition that handles complex descriptions
    private func enhancedFoodRecognition(from description: String) -> (compoundFoods: [String], individualFoods: [String]) {
        let normalizedDescription = description.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 [ENHANCED NLP] Analyzing: '\(normalizedDescription)'")
        
        var compoundFoods: [String] = []
        
        // Enhanced compound food patterns for complex descriptions
        let compoundPatterns = [
            // Rice-based dishes
            "white rice with sweet pudding": "White Rice with Sweet Pudding",
            "white rice with pudding": "White Rice with Sweet Pudding", 
            "rice with pudding": "White Rice with Sweet Pudding",
            "rice pudding": "Rice Pudding",
            "sweet rice pudding": "Rice Pudding",
            
            // Omelette variations
            "omelette white rice": "Omelette with White Rice",
            "omelette with rice": "Omelette with White Rice",
            "egg omelette rice": "Omelette with White Rice",
            "omelette": "Egg Omelette",
            "omelet": "Egg Omelette",
            
            // Smoothie variations
            "banana smoothie egg": "Banana Smoothie with Egg",
            "banana smoothie": "Banana Smoothie",
            "egg with fruit smoothie": "Egg with Fruit Smoothie",
            "fruit smoothie": "Fruit Smoothie",
            
            // Protein dishes
            "chicken breast": "Chicken Breast",
            "chicken": "Chicken",
            "egg": "Egg",
            "eggs": "Egg",
            
            // Snacks
            "chips": "Potato Chips",
            "potato chips": "Potato Chips",
            "french fries": "French Fries",
            "fries": "French Fries"
        ]
        
        // Check for compound patterns (longest first for better matching)
        let sortedPatterns = compoundPatterns.sorted { $0.key.count > $1.key.count }
        
        for (pattern, foodName) in sortedPatterns {
            if normalizedDescription.contains(pattern) {
                compoundFoods.append(foodName)
                print("🔍 [ENHANCED NLP] Found compound pattern: '\(pattern)' -> '\(foodName)'")
                break // Use the first (most specific) match
            }
        }
        
        // If no compound food found, try to extract individual food components
        if compoundFoods.isEmpty {
            let individualFoods = extractIndividualFoods(from: normalizedDescription)
            print("🔍 [ENHANCED NLP] Extracted individual foods: \(individualFoods)")
            return (compoundFoods: [], individualFoods: individualFoods)
        }
        
        return (compoundFoods: compoundFoods, individualFoods: [])
    }
    
    /// Extract individual food components from complex descriptions
    private func extractIndividualFoods(from description: String) -> [String] {
        var foods: [String] = []
        
        // Common food keywords to look for
        let foodKeywords = [
            "rice", "white rice", "brown rice", "pudding", "sweet pudding",
            "omelette", "omelet", "egg", "eggs", "chicken", "chicken breast",
            "banana", "smoothie", "fruit", "chips", "fries", "potato",
            "bread", "pasta", "noodles", "soup", "salad", "vegetables",
            "cheese", "milk", "yogurt", "butter", "oil", "salt", "sugar"
        ]
        
        let words = description.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        for word in words {
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if foodKeywords.contains(cleanWord) {
                foods.append(cleanWord.capitalized)
            }
        }
        
        return foods
    }
    
    /// Enhanced micronutrient estimation for complex food descriptions
    private func enhancedEstimateMicronutrients(for description: String, servingSize: Double) -> MicronutrientData {
        let normalizedDescription = description.lowercased()
        print("🔍 [ENHANCED ESTIMATE] Analyzing: '\(normalizedDescription)' with serving size: \(servingSize)")
        
        // Enhanced food categorization with better patterns
        let category = enhancedDetermineFoodCategory(normalizedDescription)
        print("🔍 [ENHANCED ESTIMATE] Category: \(category)")
        
        // Get micronutrient estimates based on enhanced category
        let micronutrients = getEnhancedEstimatedMicronutrients(for: category, servingSize: servingSize)
        print("🔍 [ENHANCED ESTIMATE] Micronutrients: C=\(micronutrients.vitaminC), Iron=\(micronutrients.iron), D=\(micronutrients.vitaminD), Ca=\(micronutrients.calcium)")
        
        return micronutrients
    }
    
    /// Enhanced food categorization that handles complex descriptions
    private func enhancedDetermineFoodCategory(_ description: String) -> String {
        print("🔍 [ENHANCED CATEGORY] Analyzing: '\(description)'")
        
        // Enhanced keyword patterns for better categorization
        let enhancedPatterns = [
            // Rice and grain dishes
            "rice": "grain",
            "white rice": "grain", 
            "brown rice": "grain",
            "pudding": "dairy",
            "sweet pudding": "dairy",
            "rice pudding": "dairy",
            
            // Egg dishes
            "omelette": "protein",
            "omelet": "protein",
            "egg": "protein",
            "eggs": "protein",
            
            // Smoothies and beverages
            "smoothie": "fruit",
            "banana smoothie": "fruit",
            "fruit smoothie": "fruit",
            
            // Protein dishes
            "chicken": "protein",
            "chicken breast": "protein",
            "beef": "protein",
            "pork": "protein",
            "fish": "protein",
            
            // Snacks and processed foods
            "chips": "grain",
            "fries": "grain",
            "potato chips": "grain",
            "french fries": "grain",
            
            // Dairy products
            "milk": "dairy",
            "cheese": "dairy",
            "yogurt": "dairy",
            "butter": "dairy",
            "cream": "dairy",
            
            // Fruits
            "banana": "fruit",
            "apple": "fruit",
            "orange": "fruit",
            "berry": "fruit",
            "grape": "fruit",
            
            // Vegetables
            "salad": "vegetable",
            "soup": "vegetable",
            "vegetable": "vegetable",
            "broccoli": "vegetable",
            "carrot": "vegetable",
            "tomato": "vegetable",
            
            // Nuts and seeds
            "nut": "nuts",
            "almond": "nuts",
            "walnut": "nuts",
            "seed": "nuts"
        ]
        
        // Check patterns (longest first for better matching)
        let sortedPatterns = enhancedPatterns.sorted { $0.key.count > $1.key.count }
        
        for (pattern, category) in sortedPatterns {
            if description.contains(pattern) {
                print("🔍 [ENHANCED CATEGORY] Matched pattern '\(pattern)' -> \(category)")
                return category
            }
        }
        
        // Fallback to original categorization
        return determineFoodCategory(description)
    }
    
    /// Enhanced micronutrient estimates with better values for complex foods
    private func getEnhancedEstimatedMicronutrients(for category: String, servingSize: Double) -> MicronutrientData {
        print("🔍 [ENHANCED MICRONUTRIENTS] Category: \(category), Serving: \(servingSize)")
        
        switch category {
        case "fruit":
            let result = MicronutrientData(
                vitaminA: 50.0 * servingSize,
                vitaminB1: 0.1 * servingSize,
                vitaminB2: 0.1 * servingSize,
                vitaminB3: 0.5 * servingSize,
                vitaminB5: 0.3 * servingSize,
                vitaminB6: 0.2 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 25.0 * servingSize,
                vitaminB12: 0.0 * servingSize,
                vitaminC: 60.0 * servingSize,
                vitaminD: 0.0 * servingSize,
                vitaminE: 1.0 * servingSize,
                vitaminK: 5.0 * servingSize,
                calcium: 20.0 * servingSize,
                iron: 0.5 * servingSize,
                magnesium: 15.0 * servingSize,
                phosphorus: 20.0 * servingSize,
                potassium: 200.0 * servingSize,
                sodium: 2.0 * servingSize,
                zinc: 0.2 * servingSize,
                omega3: 0.1 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 0.0 * servingSize,
                prebiotics: 2.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Fruit result: C=\(result.vitaminC), B9=\(result.vitaminB9), K=\(result.potassium)")
            return result
            
        case "vegetable":
            let result = MicronutrientData(
                vitaminA: 100.0 * servingSize,
                vitaminB1: 0.1 * servingSize,
                vitaminB2: 0.1 * servingSize,
                vitaminB3: 0.5 * servingSize,
                vitaminB5: 0.2 * servingSize,
                vitaminB6: 0.3 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 40.0 * servingSize,
                vitaminB12: 0.0 * servingSize,
                vitaminC: 50.0 * servingSize,
                vitaminD: 0.0 * servingSize,
                vitaminE: 0.5 * servingSize,
                vitaminK: 80.0 * servingSize,
                calcium: 50.0 * servingSize,
                iron: 1.0 * servingSize,
                magnesium: 25.0 * servingSize,
                phosphorus: 30.0 * servingSize,
                potassium: 300.0 * servingSize,
                sodium: 5.0 * servingSize,
                zinc: 0.5 * servingSize,
                omega3: 0.1 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 0.0 * servingSize,
                prebiotics: 3.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Vegetable result: C=\(result.vitaminC), K=\(result.vitaminK), Fe=\(result.iron)")
            return result
            
        case "protein":
            let result = MicronutrientData(
                vitaminA: 20.0 * servingSize,
                vitaminB1: 0.1 * servingSize,
                vitaminB2: 0.2 * servingSize,
                vitaminB3: 5.0 * servingSize,
                vitaminB5: 1.0 * servingSize,
                vitaminB6: 0.5 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 10.0 * servingSize,
                vitaminB12: 2.0 * servingSize,
                vitaminC: 0.0 * servingSize,
                vitaminD: 1.0 * servingSize,
                vitaminE: 0.5 * servingSize,
                vitaminK: 0.0 * servingSize,
                calcium: 20.0 * servingSize,
                iron: 2.0 * servingSize,
                magnesium: 25.0 * servingSize,
                phosphorus: 200.0 * servingSize,
                potassium: 300.0 * servingSize,
                sodium: 100.0 * servingSize,
                zinc: 3.0 * servingSize,
                omega3: 0.5 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 0.0 * servingSize,
                prebiotics: 0.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Protein result: B12=\(result.vitaminB12), Fe=\(result.iron), Zn=\(result.zinc)")
            return result
            
        case "grain":
            let result = MicronutrientData(
                vitaminA: 0.0 * servingSize,
                vitaminB1: 0.3 * servingSize,
                vitaminB2: 0.1 * servingSize,
                vitaminB3: 2.0 * servingSize,
                vitaminB5: 0.5 * servingSize,
                vitaminB6: 0.2 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 20.0 * servingSize,
                vitaminB12: 0.0 * servingSize,
                vitaminC: 0.0 * servingSize,
                vitaminD: 0.0 * servingSize,
                vitaminE: 0.5 * servingSize,
                vitaminK: 0.0 * servingSize,
                calcium: 20.0 * servingSize,
                iron: 1.5 * servingSize,
                magnesium: 50.0 * servingSize,
                phosphorus: 100.0 * servingSize,
                potassium: 100.0 * servingSize,
                sodium: 200.0 * servingSize,
                zinc: 1.0 * servingSize,
                omega3: 0.1 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 0.0 * servingSize,
                prebiotics: 2.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Grain result: B1=\(result.vitaminB1), Fe=\(result.iron), Mg=\(result.magnesium)")
            return result
            
        case "dairy":
            let result = MicronutrientData(
                vitaminA: 50.0 * servingSize,
                vitaminB1: 0.1 * servingSize,
                vitaminB2: 0.3 * servingSize,
                vitaminB3: 0.1 * servingSize,
                vitaminB5: 0.5 * servingSize,
                vitaminB6: 0.1 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 5.0 * servingSize,
                vitaminB12: 1.0 * servingSize,
                vitaminC: 0.0 * servingSize,
                vitaminD: 2.0 * servingSize,
                vitaminE: 0.1 * servingSize,
                vitaminK: 0.0 * servingSize,
                calcium: 200.0 * servingSize,
                iron: 0.1 * servingSize,
                magnesium: 20.0 * servingSize,
                phosphorus: 150.0 * servingSize,
                potassium: 150.0 * servingSize,
                sodium: 50.0 * servingSize,
                zinc: 0.5 * servingSize,
                omega3: 0.1 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 1.0 * servingSize,
                prebiotics: 0.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Dairy result: Ca=\(result.calcium), B12=\(result.vitaminB12), D=\(result.vitaminD)")
            return result
            
        case "nuts":
            let result = MicronutrientData(
                vitaminA: 0.0 * servingSize,
                vitaminB1: 0.2 * servingSize,
                vitaminB2: 0.1 * servingSize,
                vitaminB3: 1.0 * servingSize,
                vitaminB5: 0.5 * servingSize,
                vitaminB6: 0.2 * servingSize,
                vitaminB7: 0.0 * servingSize,
                vitaminB9: 10.0 * servingSize,
                vitaminB12: 0.0 * servingSize,
                vitaminC: 0.0 * servingSize,
                vitaminD: 0.0 * servingSize,
                vitaminE: 5.0 * servingSize,
                vitaminK: 0.0 * servingSize,
                calcium: 50.0 * servingSize,
                iron: 2.0 * servingSize,
                magnesium: 100.0 * servingSize,
                phosphorus: 200.0 * servingSize,
                potassium: 300.0 * servingSize,
                sodium: 5.0 * servingSize,
                zinc: 2.0 * servingSize,
                omega3: 1.0 * servingSize,
                glutamine: 0.0 * servingSize,
                probiotics: 0.0 * servingSize,
                prebiotics: 1.0 * servingSize
            )
            print("🔍 [ENHANCED MICRONUTRIENTS] Nuts result: E=\(result.vitaminE), Mg=\(result.magnesium), Zn=\(result.zinc)")
            return result
            
        default:
            print("🔍 [ENHANCED MICRONUTRIENTS] Unknown category, using default")
            return MicronutrientData() // Return empty data for unknown categories
        }
    }
    
    private func correctSpelling(_ text: String) -> String {
        // Basic spelling correction - can be enhanced with more sophisticated algorithms
        return text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func determineFoodCategory(_ foodDescription: String) -> String {
        let description = foodDescription.lowercased()
        
        print("🔍 [FOOD CATEGORY] Analyzing: '\(description)'")
        
        // Comprehensive food categorization for international cuisines
        let fruitKeywords = [
            "fruit", "apple", "banana", "orange", "grape", "berry", "strawberry", "blueberry", "raspberry",
            "mango", "pineapple", "papaya", "kiwi", "peach", "pear", "plum", "cherry", "lemon", "lime",
            "smoothie", "juice", "fresh", "citrus", "tropical", "melon", "watermelon", "cantaloupe",
            "avocado", "coconut", "date", "fig", "pomegranate", "passion", "guava", "lychee"
        ]
        
        let vegetableKeywords = [
            "vegetable", "carrot", "broccoli", "spinach", "lettuce", "cabbage", "cauliflower", "pepper",
            "tomato", "cucumber", "onion", "garlic", "potato", "sweet potato", "corn", "peas", "beans",
            "salad", "soup", "stew", "curry", "stir fry", "sauteed", "roasted", "grilled", "steamed",
            "asparagus", "zucchini", "eggplant", "mushroom", "radish", "beet", "turnip", "parsnip",
            "kale", "chard", "arugula", "bok choy", "napa", "daikon", "okra", "artichoke", "brussels"
        ]
        
        let proteinKeywords = [
            "meat", "chicken", "beef", "pork", "lamb", "turkey", "duck", "fish", "salmon", "tuna",
            "shrimp", "crab", "lobster", "egg", "eggs", "tofu", "tempeh", "seitan", "beans", "lentils",
            "chickpea", "quinoa", "protein", "steak", "chop", "cutlet", "fillet", "breast", "thigh",
            "wing", "leg", "rib", "sausage", "bacon", "ham", "deli", "cold cut", "jerky", "pate",
            "teriyaki", "kebab", "satay", "gyro", "taco", "burrito", "enchilada", "fajita", "quesadilla"
        ]
        
        let grainKeywords = [
            "grain", "rice", "bread", "pasta", "noodle", "quinoa", "barley", "oats", "wheat", "rye",
            "corn", "millet", "buckwheat", "bulgur", "couscous", "polenta", "grits", "cereal", "granola",
            "pudding", "porridge", "congee", "risotto", "paella", "fried rice", "sushi", "roll",
            "wrap", "sandwich", "burger", "pizza", "flatbread", "naan", "pita", "tortilla", "bagel",
            "muffin", "pancake", "waffle", "crepe", "dumpling", "ravioli", "lasagna", "spaghetti"
        ]
        
        let dairyKeywords = [
            "dairy", "milk", "cheese", "yogurt", "butter", "cream", "sour cream", "buttermilk",
            "kefir", "cottage", "ricotta", "mozzarella", "cheddar", "parmesan", "feta", "goat",
            "sheep", "buffalo", "camel", "soy milk", "almond milk", "coconut milk", "oat milk",
            "ice cream", "gelato", "sorbet", "pudding", "custard", "flan", "cheesecake", "tiramisu"
        ]
        
        let nutKeywords = [
            "nut", "almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut", "macadamia",
            "peanut", "seed", "sunflower", "pumpkin", "sesame", "chia", "flax", "hemp", "chia seed",
            "trail mix", "granola", "nut butter", "tahini", "hummus", "guacamole", "pesto"
        ]
        
        // Check for fruit keywords
        for keyword in fruitKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> fruit (matched: \(keyword))")
                return "fruit"
            }
        }
        
        // Check for vegetable keywords
        for keyword in vegetableKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> vegetable (matched: \(keyword))")
                return "vegetable"
            }
        }
        
        // Check for protein keywords
        for keyword in proteinKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> protein (matched: \(keyword))")
                return "protein"
            }
        }
        
        // Check for grain keywords
        for keyword in grainKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> grain (matched: \(keyword))")
                return "grain"
            }
        }
        
        // Check for dairy keywords
        for keyword in dairyKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> dairy (matched: \(keyword))")
                return "dairy"
            }
        }
        
        // Check for nut keywords
        for keyword in nutKeywords {
            if description.contains(keyword) {
                print("🔍 [FOOD CATEGORY] -> nuts (matched: \(keyword))")
                return "nuts"
            }
        }
        
        // Default fallback - try to guess based on common patterns
        if description.contains("soup") || description.contains("stew") || description.contains("broth") {
            print("🔍 [FOOD CATEGORY] -> vegetable (soup/stew pattern)")
            return "vegetable"
        } else if description.contains("salad") || description.contains("fresh") {
            print("🔍 [FOOD CATEGORY] -> vegetable (salad pattern)")
            return "vegetable"
        } else if description.contains("smoothie") || description.contains("juice") {
            print("🔍 [FOOD CATEGORY] -> fruit (beverage pattern)")
            return "fruit"
        } else {
            print("🔍 [FOOD CATEGORY] -> other (no match found)")
            return "other"
        }
    }
    
    private func getEstimatedMicronutrients(for category: String, servingSize: Double) -> MicronutrientData {
        // Return estimated micronutrients based on food category
        // This is a simplified version - in production, you'd have more detailed estimates
        print("🔍 [ESTIMATED MICRONUTRIENTS] Category: \(category), Serving Size: \(servingSize)")
        
        switch category {
        case "fruit":
            let result = MicronutrientData(
                vitaminB9: 20.0 * servingSize, // Fixed: moved before vitaminC
                vitaminC: 50.0 * servingSize,
                potassium: 200.0 * servingSize
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Fruit result: C=\(result.vitaminC), B9=\(result.vitaminB9), K=\(result.potassium)")
            return result
        case "vegetable":
            let result = MicronutrientData(
                vitaminA: 100.0 * servingSize,
                vitaminB9: 40.0 * servingSize, // Fixed: moved before vitaminC
                vitaminC: 30.0 * servingSize,
                potassium: 300.0 * servingSize
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Vegetable result: A=\(result.vitaminA), C=\(result.vitaminC), B9=\(result.vitaminB9), K=\(result.potassium)")
            return result
        case "protein":
            let result = MicronutrientData(
                vitaminB12: 1.0 * servingSize, // Fixed: moved before iron
                iron: 2.0 * servingSize,
                zinc: 3.0 * servingSize
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Protein result: B12=\(result.vitaminB12), Iron=\(result.iron), Zn=\(result.zinc)")
            return result
        case "grain":
            let result = MicronutrientData(
                vitaminB9: 30.0 * servingSize,
                iron: 1.0 * servingSize,
                magnesium: 50.0 * servingSize
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Grain result: B9=\(result.vitaminB9), Iron=\(result.iron), Mg=\(result.magnesium)")
            return result
        case "dairy":
            let result = MicronutrientData(
                vitaminB12: 1.0 * servingSize,
                vitaminD: 2.0 * servingSize, // Fixed: moved before calcium
                calcium: 200.0 * servingSize
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Dairy result: B12=\(result.vitaminB12), D=\(result.vitaminD), Ca=\(result.calcium)")
            return result
        case "nuts":
            let result = MicronutrientData(
                vitaminA: 0.0,
                vitaminB1: 0.0,
                vitaminB2: 0.0,
                vitaminB3: 0.0,
                vitaminB5: 0.0,
                vitaminB6: 0.0,
                vitaminB7: 0.0,
                vitaminB9: 0.0,
                vitaminB12: 0.0,
                vitaminC: 0.0,
                vitaminD: 0.0,
                vitaminE: 5.0 * servingSize,
                vitaminK: 0.0,
                calcium: 0.0,
                iron: 1.5 * servingSize,
                magnesium: 100.0 * servingSize,
                phosphorus: 0.0,
                potassium: 200.0 * servingSize,
                sodium: 0.0,
                zinc: 2.0 * servingSize,
                omega3: 1.0 * servingSize,
                glutamine: 0.0,
                probiotics: 0.0,
                prebiotics: 0.0
            )
            print("🔍 [ESTIMATED MICRONUTRIENTS] Nuts result: E=\(result.vitaminE), Mg=\(result.magnesium), Zn=\(result.zinc), Fe=\(result.iron), K=\(result.potassium), Omega3=\(result.omega3)")
            return result
        default:
            print("🔍 [ESTIMATED MICRONUTRIENTS] Unknown category: \(category)")
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

    // Add helper function to convert EnhancedFoodItem to MicronutrientData
    private func createMicronutrientDataFromEnhancedFood(_ food: EnhancedFoodItem) -> MicronutrientData {
        return MicronutrientData(
            vitaminA: food.vitamins["vitaminA"] ?? 0,
            vitaminB1: food.vitamins["vitaminB1"] ?? 0,
            vitaminB2: food.vitamins["vitaminB2"] ?? 0,
            vitaminB3: food.vitamins["vitaminB3"] ?? 0,
            vitaminB5: food.vitamins["vitaminB5"] ?? 0,
            vitaminB6: food.vitamins["vitaminB6"] ?? 0,
            vitaminB7: food.vitamins["vitaminB7"] ?? 0,
            vitaminB9: food.vitamins["vitaminB9"] ?? 0,
            vitaminB12: food.vitamins["vitaminB12"] ?? 0,
            vitaminC: food.vitamins["vitaminC"] ?? 0,
            vitaminD: food.vitamins["vitaminD"] ?? 0,
            vitaminE: food.vitamins["vitaminE"] ?? 0,
            vitaminK: food.vitamins["vitaminK"] ?? 0,
            calcium: food.minerals["calcium"] ?? 0,
            iron: food.minerals["iron"] ?? 0,
            magnesium: food.minerals["magnesium"] ?? 0,
            phosphorus: food.minerals["phosphorus"] ?? 0,
            potassium: food.minerals["potassium"] ?? 0,
            sodium: food.minerals["sodium"] ?? 0,
            zinc: food.minerals["zinc"] ?? 0,
            copper: food.minerals["copper"] ?? 0,
            manganese: food.minerals["manganese"] ?? 0,
            selenium: food.minerals["selenium"] ?? 0,
            iodine: food.minerals["iodine"] ?? 0,
            chromium: food.minerals["chromium"] ?? 0,
            molybdenum: food.minerals["molybdenum"] ?? 0,
            boron: food.minerals["boron"] ?? 0,
            silicon: food.minerals["silicon"] ?? 0
        )
    }

    // Convert serving size from various units to cups
    private func convertServingSize(_ amount: Double, from unit: String) -> Double {
        let unitLower = unit.lowercased()
        
        switch unitLower {
        // Volume measurements
        case "cup", "cups":
            return amount
        case "tablespoon", "tbsp", "tbs":
            return amount * 0.0625 // 16 tbsp = 1 cup
        case "teaspoon", "tsp":
            return amount * 0.0208 // 48 tsp = 1 cup
        case "liter", "litre", "l":
            return amount * 4.2 // 1 liter ≈ 4.2 cups
        case "ml", "milliliter":
            return amount * 0.0042 // 1000 ml = 1 liter
        case "fl oz", "fluid ounce", "oz":
            return amount * 0.125 // 8 fl oz = 1 cup
        case "pint", "pt":
            return amount * 2.0 // 1 pint = 2 cups
        case "quart", "qt":
            return amount * 4.0 // 1 quart = 4 cups
        case "gallon", "gal":
            return amount * 16.0 // 1 gallon = 16 cups
        
        // Weight measurements (approximate conversions)
        case "pound", "lb", "lbs":
            return amount * 2.0 // Approximate: 1 lb ≈ 2 cups
        case "ounce", "oz":
            return amount * 0.125 // 8 oz ≈ 1 cup
        case "gram", "g", "grams":
            return amount * 0.0042 // Approximate: 240g ≈ 1 cup
        case "kg", "kilogram", "kilograms":
            return amount * 4.2 // Approximate: 1 kg ≈ 4.2 cups
        
        // Count-based measurements
        case "slice", "slices":
            return amount * 0.125 // Assume 8 slices per cup
        case "piece", "pieces":
            return amount * 0.125 // Assume 8 pieces per cup
        case "serving", "servings":
            return amount // 1 serving = 1 cup (default)
        case "portion", "portions":
            return amount // 1 portion = 1 cup (default)
        
        // International measurements
        case "taza", "tazas": // Spanish
            return amount
        case "bol", "bols": // French
            return amount
        case "schale", "schalen": // German
            return amount
        case "碗": // Chinese (bowl)
            return amount * 1.5 // Chinese bowls are typically larger
        case "杯": // Chinese (cup)
            return amount
        case "皿": // Japanese (plate)
            return amount * 0.8 // Japanese plates are typically smaller
        case "盛り": // Japanese (serving)
            return amount
        
        default:
            print("⚠️ [SERVING SIZE] Unknown unit: \(unit), using default 1.0 cups")
            return amount // Default to 1 cup if unit is unknown
        }
    }
    
    // Add simple serving size parser to replace IntelligentServingSizeParser
    func parseServingSize(from description: String) -> Double {
        // Enhanced serving size parsing for international foods
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for (index, word) in words.enumerated() {
            if let number = Double(word) {
                // Look for common serving size indicators
                if index + 1 < words.count {
                    let nextWord = words[index + 1]
                    
                    // Volume measurements
                    if nextWord.contains("cup") || nextWord.contains("cups") {
                        return number
                    } else if nextWord.contains("tablespoon") || nextWord.contains("tbsp") {
                        return number * 0.0625 // Convert tbsp to cups
                    } else if nextWord.contains("teaspoon") || nextWord.contains("tsp") {
                        return number * 0.0208 // Convert tsp to cups
                    } else if nextWord.contains("liter") || nextWord.contains("litre") {
                        return number * 4.2 // Convert liters to cups
                    } else if nextWord.contains("ml") || nextWord.contains("milliliter") {
                        return number * 0.0042 // Convert ml to cups
                    } else if nextWord.contains("fl oz") || nextWord.contains("fluid ounce") {
                        return number * 0.125 // Convert fl oz to cups
                    }
                    
                    // Weight measurements
                    else if nextWord.contains("pound") || nextWord.contains("lb") {
                        return number * 2.0 // Convert pounds to cups (approximate)
                    } else if nextWord.contains("ounce") || nextWord.contains("oz") {
                        return number * 0.125 // Convert oz to cups
                    } else if nextWord.contains("gram") || nextWord.contains("g") {
                        return number * 0.0042 // Convert grams to cups (approximate)
                    } else if nextWord.contains("kg") || nextWord.contains("kilogram") {
                        return number * 4.2 // Convert kg to cups (approximate)
                    }
                    
                    // Count-based measurements
                    else if nextWord.contains("slice") || nextWord.contains("slices") {
                        return number * 0.125 // Assume 8 slices per cup
                    } else if nextWord.contains("piece") || nextWord.contains("pieces") {
                        return number * 0.125 // Assume 8 pieces per cup
                    } else if nextWord.contains("serving") || nextWord.contains("servings") {
                        return number
                    } else if nextWord.contains("portion") || nextWord.contains("portions") {
                        return number
                    }
                }
            }
        }
        
        // Default serving size based on food type
        let description = description.lowercased()
        if description.contains("soup") || description.contains("stew") || description.contains("broth") {
            return 1.5 // Soups are typically larger servings
        } else if description.contains("salad") || description.contains("fresh") {
            return 1.0 // Standard salad serving
        } else if description.contains("smoothie") || description.contains("juice") {
            return 1.0 // Standard beverage serving
        } else if description.contains("rice") || description.contains("pasta") || description.contains("noodle") {
            return 1.0 // Standard grain serving
        } else if description.contains("meat") || description.contains("chicken") || description.contains("fish") {
            return 0.5 // Protein servings are typically smaller
        } else {
            return 1.0 // Default serving size
        }
    }
}