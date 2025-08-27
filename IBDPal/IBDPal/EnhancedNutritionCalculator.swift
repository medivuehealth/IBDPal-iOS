import Foundation

// Enhanced Nutrition Calculator that handles both individual foods and compound dishes
class EnhancedNutritionCalculator: ObservableObject {
    static let shared = EnhancedNutritionCalculator()
    
    private let enhancedFoodDB = EnhancedFoodDatabase.shared
    private let compoundFoodDB = CompoundFoodDatabase.shared
    private let originalFoodDB = FoodDatabase.shared
    
    private init() {}
    
    // Main calculation function that handles both individual and compound foods
    func calculateNutrition(for foodDescription: String) -> CalculatedNutrition {
        let correctedDescription = correctSpelling(foodDescription)
        
        // Use NLP processor for intelligent food recognition
        let nlpResult = FoodNLPProcessor.shared.processFoodDescription(correctedDescription)
        
        // Log the NLP processing results
        print("🧠 [NLP] Original: '\(nlpResult.originalText)'")
        print("🧠 [NLP] Normalized: '\(nlpResult.normalizedText)'")
        print("🧠 [NLP] Individual foods: \(nlpResult.individualFoods.map { $0.normalizedText })")
        print("🧠 [NLP] Compound foods: \(nlpResult.compoundFoods.map { $0.name })")
        print("🧠 [NLP] Confidence: \(nlpResult.confidence)")
        
        // First, try to find compound dishes using NLP results
        for compoundFood in nlpResult.compoundFoods {
            if let compoundFoodItem = findCompoundFood(in: compoundFood.name.lowercased()) {
                return calculateFromCompoundFood(compoundFoodItem)
            }
        }
        
        // Then try enhanced individual foods using NLP results
        for foodEntity in nlpResult.individualFoods {
            if let enhancedFood = findEnhancedFood(in: foodEntity.normalizedText) {
                return calculateFromEnhancedFood(enhancedFood)
            }
        }
        
        // Try original food database with NLP results
        for foodEntity in nlpResult.individualFoods {
            if let originalFood = findOriginalFood(in: foodEntity.normalizedText) {
                return calculateFromOriginalFood(originalFood)
            }
        }
        
        // If NLP didn't find anything, fall back to original method
        let lowercasedDescription = correctedDescription.lowercased()
        
        // First, try to find compound dishes
        if let compoundFood = findCompoundFood(in: lowercasedDescription) {
            return calculateFromCompoundFood(compoundFood)
        }
        
        // Then try enhanced individual foods
        if let enhancedFood = findEnhancedFood(in: lowercasedDescription) {
            return calculateFromEnhancedFood(enhancedFood)
        }
        
        // Finally, try original food database
        if let originalFood = findOriginalFood(in: lowercasedDescription) {
            return calculateFromOriginalFood(originalFood)
        }
        
        // If no exact match, try to parse compound descriptions
        return parseCompoundDescription(correctedDescription)
    }
    
    // Spelling correction for common food terms
    private func correctSpelling(_ text: String) -> String {
        let corrections: [String: String] = [
            "sandwhich": "sandwich",
            "sandwiche": "sandwich",
            "sandwitches": "sandwiches",
            "crepe": "crepe",
            "crepes": "crepes",
            "pad thai": "pad thai",
            "padthai": "pad thai",
            "biryani": "biryani",
            "biriyani": "biryani",
            "shawarma": "shawarma",
            "shwarma": "shawarma",
            "taco": "taco",
            "tacos": "tacos",
            "sushi": "sushi",
            "sashimi": "sashimi",
            "curry": "curry",
            "dal": "dal",
            "dhal": "dal",
            "hummus": "hummus",
            "humus": "hummus",
            "guacamole": "guacamole",
            "guac": "guacamole",
            "quinoa": "quinoa",
            "keenwa": "quinoa",
            "falafel": "falafel",
            "falafal": "falafel",
            "tabbouleh": "tabbouleh",
            "tabouleh": "tabbouleh",
            "tzatziki": "tzatziki",
            "tzaziki": "tzatziki",
            "paella": "paella",
            "risotto": "risotto",
            "gnocchi": "gnocchi",
            "bruschetta": "bruschetta",
            "bruscheta": "bruschetta",
            "ratatouille": "ratatouille",
            "ratatouile": "ratatouille",
            "bouillabaisse": "bouillabaisse",
            "bouillabaise": "bouillabaisse",
            "cassoulet": "cassoulet",
            "coq au vin": "coq au vin",
            "beef bourguignon": "beef bourguignon",
            "beef bourguignonne": "beef bourguignon",
            "mac n cheese": "mac and cheese",
            "mac n c heese": "mac and cheese",
            "macaroni and cheese": "mac and cheese",
            "baked red beans": "baked red beans",
            "red beans": "baked red beans",
            "pita bread": "pita bread",
            "pita": "pita bread",
            "egg omlete": "egg omelette",
            "egg omlette": "egg omelette",
            "omelete": "egg omelette",
            "omelette": "egg omelette",
            "chicken curry": "chicken curry"
        ]
        
        var correctedText = text
        for (incorrect, correct) in corrections {
            correctedText = correctedText.replacingOccurrences(of: incorrect, with: correct, options: .caseInsensitive)
        }
        
        return correctedText
    }
    
    // Find compound foods like "egg sandwich", "chicken salad", etc.
    private func findCompoundFood(in description: String) -> CompoundFoodItem? {
        let compoundFoods = compoundFoodDB.compoundFoods
        
        // Direct matches
        for food in compoundFoods {
            if description.contains(food.name.lowercased()) {
                return food
            }
        }
        
        // Partial matches for common compound dishes
        let compoundKeywords = [
            "sandwich": ["bread", "between", "sandwich"],
            "salad": ["salad", "bowl", "mixed"],
            "sushi": ["sushi", "roll", "nigiri"],
            "taco": ["taco", "tortilla", "wrapped"],
            "pasta": ["pasta", "noodles", "spaghetti"],
            "rice": ["rice", "bowl", "stir-fry"],
            "soup": ["soup", "broth", "miso"],
            "parfait": ["parfait", "yogurt", "layered"],
            "omelette": ["omelette", "omelet", "eggs"],
            "pizza": ["pizza", "slice", "toppings"]
        ]
        
        for (dishType, keywords) in compoundKeywords {
            if keywords.contains(where: { description.contains($0) }) {
                // Find the best matching compound food for this dish type
                let matchingFoods = compoundFoods.filter { $0.category.lowercased().contains(dishType) }
                return matchingFoods.first
            }
        }
        
        return nil
    }
    
    // Find enhanced individual foods
    private func findEnhancedFood(in description: String) -> EnhancedFoodItem? {
        return enhancedFoodDB.allFoods.first { food in
            description.contains(food.name.lowercased()) ||
            food.tags.contains { description.contains($0.lowercased()) }
        }
    }
    
    // Find original food database items
    private func findOriginalFood(in description: String) -> DatabaseFoodItem? {
        return originalFoodDB.allFoods.first { food in
            description.contains(food.name.lowercased())
        }
    }
    
    // Calculate nutrition from compound food
    private func calculateFromCompoundFood(_ food: CompoundFoodItem) -> CalculatedNutrition {
        return CalculatedNutrition(
            detectedFoods: [food.name],
            totalCalories: food.totalCalories * 1.5, // Teen portion size
            totalProtein: food.totalProtein * 1.5,
            totalCarbs: food.totalCarbs * 1.5,
            totalFiber: food.totalFiber * 1.5,
            totalFat: food.totalFat * 1.5
        )
    }
    
    // Calculate nutrition from enhanced individual food
    private func calculateFromEnhancedFood(_ food: EnhancedFoodItem) -> CalculatedNutrition {
        return CalculatedNutrition(
            detectedFoods: [food.name],
            totalCalories: food.calories * 1.5, // Teen portion size
            totalProtein: food.protein * 1.5,
            totalCarbs: food.carbs * 1.5,
            totalFiber: food.fiber * 1.5,
            totalFat: food.fat * 1.5
        )
    }
    
    // Calculate nutrition from original food database
    private func calculateFromOriginalFood(_ food: DatabaseFoodItem) -> CalculatedNutrition {
        return CalculatedNutrition(
            detectedFoods: [food.name],
            totalCalories: food.calories * 1.5, // Teen portion size
            totalProtein: food.protein * 1.5,
            totalCarbs: food.carbs * 1.5,
            totalFiber: food.fiber * 1.5,
            totalFat: food.fat * 1.5
        )
    }
    
    // Parse compound descriptions and estimate nutrition
    private func parseCompoundDescription(_ description: String) -> CalculatedNutrition {
        let words = description.lowercased().components(separatedBy: " ")
        var detectedFoods: [String] = []
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        // Common ingredient mappings
        let ingredientMappings: [String: (calories: Double, protein: Double, carbs: Double, fiber: Double, fat: Double)] = [
            "bread": (80, 3, 15, 1, 1),
            "toast": (80, 3, 15, 1, 1),
            "egg": (77, 6, 0, 0, 5),
            "eggs": (77, 6, 0, 0, 5),
            "chicken": (165, 31, 0, 0, 3.6),
            "turkey": (135, 25, 0, 0, 3),
            "cheese": (110, 7, 1, 0, 9),
            "lettuce": (8, 0.5, 1.5, 0.5, 0.1),
            "tomato": (11, 0.5, 2.4, 0.6, 0.1),
            "mayonnaise": (90, 0, 0, 0, 10),
            "mayo": (90, 0, 0, 0, 10),
            "avocado": (40, 0.5, 2.2, 1.7, 3.7),
            "bacon": (43, 3, 0, 0, 3),
            "ham": (46, 5, 0, 0, 2),
            "salmon": (206, 22, 0, 0, 12),
            "tuna": (99, 22, 0, 0, 0.5),
            "rice": (205, 4.3, 45, 0.6, 0.4),
            "pasta": (200, 7, 40, 2, 1),
            "noodles": (190, 7, 37, 2, 1),
            "potato": (110, 3, 26, 2, 0),
            "potatoes": (110, 3, 26, 2, 0),
            "broccoli": (55, 3.7, 11, 5, 0.6),
            "carrots": (52, 1.2, 12, 3.6, 0.3),
            "spinach": (23, 2.9, 3.6, 2.2, 0.4),
            "onion": (44, 1.2, 10, 1.9, 0.1),
            "onions": (44, 1.2, 10, 1.9, 0.1),
            "garlic": (4, 0.2, 1, 0.1, 0),
            "mushrooms": (15, 2.2, 2.3, 0.7, 0.2),
            "mushroom": (15, 2.2, 2.3, 0.7, 0.2),
            "pepper": (20, 0.9, 4.6, 1.7, 0.2),
            "peppers": (20, 0.9, 4.6, 1.7, 0.2),
            "cucumber": (16, 0.7, 3.6, 0.5, 0.2),
            "cucumbers": (16, 0.7, 3.6, 0.5, 0.2),
            "olive": (5, 0.1, 0.3, 0.1, 0.5),
            "olives": (5, 0.1, 0.3, 0.1, 0.5),
            "pickle": (4, 0.2, 0.8, 0.3, 0),
            "pickles": (4, 0.2, 0.8, 0.3, 0),
            "banana": (105, 1.3, 27, 3.1, 0.4),
            "apple": (95, 0.5, 25, 4, 0.3),
            "orange": (62, 1.2, 15, 3.1, 0.2),
            "strawberry": (49, 1, 12, 3, 0.5),
            "strawberries": (49, 1, 12, 3, 0.5),
            "blueberry": (85, 1.1, 21, 3.6, 0.5),
            "blueberries": (85, 1.1, 21, 3.6, 0.5),
            "yogurt": (150, 8, 12, 0, 8),
            "milk": (103, 8, 12, 0, 2.4),
            "butter": (102, 0.1, 0, 0, 12),
            "oil": (120, 0, 0, 0, 14),
            "sauce": (20, 0.5, 4, 0.5, 0),
            "ketchup": (15, 0.3, 3.7, 0.1, 0),
            "mustard": (3, 0.2, 0.3, 0.1, 0.2),
            "salt": (0, 0, 0, 0, 0),
            "black_pepper": (0, 0, 0, 0, 0),
            "sugar": (16, 0, 4, 0, 0),
            "honey": (21, 0, 5.5, 0, 0),
            "jam": (50, 0, 13, 0.2, 0),
            "jelly": (50, 0, 13, 0.2, 0),
            "peanut": (207, 9, 6, 3, 18),
            "peanuts": (207, 9, 6, 3, 18),
            "almond": (164, 6, 6, 3.5, 14),
            "almonds": (164, 6, 6, 3.5, 14),
            "walnut": (185, 4, 4, 2, 18),
            "walnuts": (185, 4, 4, 2, 18),
            "nut": (164, 6, 6, 3.5, 14),
            "nuts": (164, 6, 6, 3.5, 14),
            "seed": (164, 6, 6, 3, 14),
            "seeds": (164, 6, 6, 3, 14),
            "bean": (114, 7.6, 20, 7.5, 0.5),
            "beans": (114, 7.6, 20, 7.5, 0.5),
            "lentil": (115, 9, 20, 8, 0.4),
            "lentils": (115, 9, 20, 8, 0.4),
            "chickpea": (135, 7, 22, 6, 2),
            "chickpeas": (135, 7, 22, 6, 2),
            "hummus": (25, 1.2, 3, 0.8, 1.2),
            "guacamole": (45, 1, 3, 2, 4),
            "salsa": (10, 0.5, 2, 0.5, 0),
            "dressing": (60, 0.5, 2, 0.2, 5.5),
            "vinegar": (3, 0, 0.1, 0, 0),
            "lemon": (6, 0.2, 1.9, 0.3, 0.1),
            "lime": (6, 0.2, 1.9, 0.3, 0.1),
            "herb": (1, 0.1, 0.2, 0.1, 0),
            "herbs": (1, 0.1, 0.2, 0.1, 0),
            "spice": (1, 0.1, 0.2, 0.1, 0),
            "spices": (1, 0.1, 0.2, 0.1, 0)
        ]
        
        for word in words {
            if let nutrition = ingredientMappings[word] {
                detectedFoods.append(word)
                totalCalories += nutrition.calories
                totalProtein += nutrition.protein
                totalCarbs += nutrition.carbs
                totalFiber += nutrition.fiber
                totalFat += nutrition.fat
            }
        }
        
        // Apply teen portion size multiplier
        let multiplier = detectedFoods.isEmpty ? 1.0 : 1.5
        
        return CalculatedNutrition(
            detectedFoods: detectedFoods,
            totalCalories: totalCalories * multiplier,
            totalProtein: totalProtein * multiplier,
            totalCarbs: totalCarbs * multiplier,
            totalFiber: totalFiber * multiplier,
            totalFat: totalFat * multiplier
        )
    }
    
    // Get nutrition recommendations based on IBD status
    func getNutritionRecommendations(for ibdStatus: String = "remission") -> [String] {
        switch ibdStatus {
        case "flare":
            return [
                "Choose low-fiber, easy-to-digest foods",
                "Avoid raw vegetables and high-fiber foods",
                "Include lean proteins and cooked vegetables",
                "Stay hydrated with clear fluids",
                "Consider low-FODMAP options"
            ]
        case "remission":
            return [
                "Include a variety of fruits and vegetables",
                "Choose whole grains and high-fiber foods",
                "Include lean proteins and healthy fats",
                "Stay hydrated with water and healthy beverages",
                "Consider probiotic-rich foods"
            ]
        default:
            return [
                "Maintain a balanced diet",
                "Stay hydrated",
                "Listen to your body's signals",
                "Work with your healthcare team"
            ]
        }
    }
    
    // Get FODMAP-friendly food suggestions
    func getLowFODMAPSuggestions() -> [String] {
        return [
            "Banana",
            "Blueberries",
            "Strawberries",
            "Eggs",
            "Chicken",
            "Salmon",
            "Rice",
            "Quinoa",
            "Carrots",
            "Spinach",
            "Lettuce",
            "Cucumber",
            "Tomato",
            "Almonds",
            "Greek Yogurt"
        ]
    }
    
    // Get IBD-friendly food suggestions
    func getIBDFriendlySuggestions() -> [String] {
        return [
            "Oatmeal",
            "Banana",
            "Eggs",
            "Chicken Breast",
            "Salmon",
            "Rice",
            "Quinoa",
            "Sweet Potato",
            "Carrots",
            "Spinach",
            "Greek Yogurt",
            "Almonds",
            "Chia Seeds",
            "Hummus",
            "Avocado"
        ]
    }
} 