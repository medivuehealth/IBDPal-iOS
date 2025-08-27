import Foundation

// MARK: - Advanced Food NLP Processor
class AdvancedFoodNLPProcessor: ObservableObject {
    static let shared = AdvancedFoodNLPProcessor()
    
    // MARK: - Comprehensive Food Patterns
    private let foodPatterns: [String: FoodPattern] = [
        // ASIAN CUISINE
        "miso soup": FoodPattern(name: "Miso Soup", category: "Soups", cuisine: "Japanese", confidence: 0.95),
        "ramen": FoodPattern(name: "Ramen", category: "Soups", cuisine: "Japanese", confidence: 0.95),
        "ramen soup": FoodPattern(name: "Ramen", category: "Soups", cuisine: "Japanese", confidence: 0.95),
        "sushi": FoodPattern(name: "Sushi Roll", category: "Seafood", cuisine: "Japanese", confidence: 0.9),
        "sushi roll": FoodPattern(name: "Sushi Roll", category: "Seafood", cuisine: "Japanese", confidence: 0.95),
        "pad thai": FoodPattern(name: "Pad Thai", category: "Noodles", cuisine: "Thai", confidence: 0.95),
        "padthai": FoodPattern(name: "Pad Thai", category: "Noodles", cuisine: "Thai", confidence: 0.9),
        "curry": FoodPattern(name: "Curry", category: "Main Dish", cuisine: "Indian", confidence: 0.85),
        "chicken curry": FoodPattern(name: "Chicken Curry", category: "Main Dish", cuisine: "Indian", confidence: 0.95),
        "beef curry": FoodPattern(name: "Beef Curry", category: "Main Dish", cuisine: "Indian", confidence: 0.95),
        "vegetable curry": FoodPattern(name: "Vegetable Curry", category: "Main Dish", cuisine: "Indian", confidence: 0.95),
        "biryani": FoodPattern(name: "Rice Biryani", category: "Rice", cuisine: "Indian", confidence: 0.9),
        "rice biryani": FoodPattern(name: "Rice Biryani", category: "Rice", cuisine: "Indian", confidence: 0.95),
        "dumplings": FoodPattern(name: "Dumplings", category: "Appetizer", cuisine: "Chinese", confidence: 0.9),
        "dumpling": FoodPattern(name: "Dumplings", category: "Appetizer", cuisine: "Chinese", confidence: 0.9),
        "noodles": FoodPattern(name: "Noodles", category: "Grains", cuisine: "Asian", confidence: 0.8),
        "fried rice": FoodPattern(name: "Fried Rice", category: "Rice", cuisine: "Chinese", confidence: 0.9),
        "stir fry": FoodPattern(name: "Stir Fry", category: "Main Dish", cuisine: "Chinese", confidence: 0.85),
        "stir-fry": FoodPattern(name: "Stir Fry", category: "Main Dish", cuisine: "Chinese", confidence: 0.85),
        "teriyaki": FoodPattern(name: "Teriyaki", category: "Main Dish", cuisine: "Japanese", confidence: 0.9),
        "tempura": FoodPattern(name: "Tempura", category: "Appetizer", cuisine: "Japanese", confidence: 0.9),
        "soba": FoodPattern(name: "Soba Noodles", category: "Noodles", cuisine: "Japanese", confidence: 0.9),
        "soba noodles": FoodPattern(name: "Soba Noodles", category: "Noodles", cuisine: "Japanese", confidence: 0.95),
        "udon": FoodPattern(name: "Udon Noodles", category: "Noodles", cuisine: "Japanese", confidence: 0.9),
        "udon noodles": FoodPattern(name: "Udon Noodles", category: "Noodles", cuisine: "Japanese", confidence: 0.95),
        "kimchi": FoodPattern(name: "Kimchi", category: "Fermented", cuisine: "Korean", confidence: 0.9),
        "pho": FoodPattern(name: "Pho", category: "Soups", cuisine: "Vietnamese", confidence: 0.9),
        "tom yum": FoodPattern(name: "Tom Yum Soup", category: "Soups", cuisine: "Thai", confidence: 0.9),
        "tom yum soup": FoodPattern(name: "Tom Yum Soup", category: "Soups", cuisine: "Thai", confidence: 0.95),
        
        // MEDITERRANEAN CUISINE
        "hummus": FoodPattern(name: "Hummus", category: "Dips", cuisine: "Middle Eastern", confidence: 0.95),
        "falafel": FoodPattern(name: "Falafel", category: "Appetizer", cuisine: "Middle Eastern", confidence: 0.95),
        "shawarma": FoodPattern(name: "Chicken Shawarma", category: "Sandwich", cuisine: "Middle Eastern", confidence: 0.9),
        "chicken shawarma": FoodPattern(name: "Chicken Shawarma", category: "Sandwich", cuisine: "Middle Eastern", confidence: 0.95),
        "tabbouleh": FoodPattern(name: "Tabbouleh", category: "Salad", cuisine: "Lebanese", confidence: 0.9),
        "tzatziki": FoodPattern(name: "Tzatziki", category: "Sauce", cuisine: "Greek", confidence: 0.9),
        "paella": FoodPattern(name: "Paella", category: "Rice", cuisine: "Spanish", confidence: 0.95),
        "risotto": FoodPattern(name: "Risotto", category: "Rice", cuisine: "Italian", confidence: 0.95),
        "ratatouille": FoodPattern(name: "Ratatouille", category: "Vegetables", cuisine: "French", confidence: 0.9),
        "bouillabaisse": FoodPattern(name: "Bouillabaisse", category: "Soups", cuisine: "French", confidence: 0.9),
        "greek salad": FoodPattern(name: "Greek Salad", category: "Salad", cuisine: "Greek", confidence: 0.95),
        
        // AMERICAN CUISINE
        "hamburger": FoodPattern(name: "Hamburger", category: "Sandwich", cuisine: "American", confidence: 0.95),
        "burger": FoodPattern(name: "Hamburger", category: "Sandwich", cuisine: "American", confidence: 0.9),
        "hot dog": FoodPattern(name: "Hot Dog", category: "Sandwich", cuisine: "American", confidence: 0.95),
        "hotdog": FoodPattern(name: "Hot Dog", category: "Sandwich", cuisine: "American", confidence: 0.9),
        "mac and cheese": FoodPattern(name: "Mac and Cheese", category: "Pasta", cuisine: "American", confidence: 0.95),
        "mac n cheese": FoodPattern(name: "Mac and Cheese", category: "Pasta", cuisine: "American", confidence: 0.9),
        "macaroni and cheese": FoodPattern(name: "Mac and Cheese", category: "Pasta", cuisine: "American", confidence: 0.9),
        "chicken wings": FoodPattern(name: "Chicken Wings", category: "Appetizer", cuisine: "American", confidence: 0.95),
        "bbq ribs": FoodPattern(name: "BBQ Ribs", category: "Meat", cuisine: "American", confidence: 0.9),
        "pizza": FoodPattern(name: "Pizza", category: "Bread", cuisine: "Italian", confidence: 0.95),
        "corn dog": FoodPattern(name: "Corn Dog", category: "Sandwich", cuisine: "American", confidence: 0.9),
        "chili": FoodPattern(name: "Chili", category: "Soups", cuisine: "American", confidence: 0.9),
        
        // INDIAN CUISINE
        "dal": FoodPattern(name: "Dal", category: "Legumes", cuisine: "Indian", confidence: 0.9),
        "dhal": FoodPattern(name: "Dal", category: "Legumes", cuisine: "Indian", confidence: 0.9),
        "naan": FoodPattern(name: "Naan Bread", category: "Bread", cuisine: "Indian", confidence: 0.9),
        "naan bread": FoodPattern(name: "Naan Bread", category: "Bread", cuisine: "Indian", confidence: 0.95),
        "tandoori chicken": FoodPattern(name: "Tandoori Chicken", category: "Meat", cuisine: "Indian", confidence: 0.95),
        "butter chicken": FoodPattern(name: "Butter Chicken", category: "Meat", cuisine: "Indian", confidence: 0.95),
        "palak paneer": FoodPattern(name: "Palak Paneer", category: "Vegetables", cuisine: "Indian", confidence: 0.9),
        "aloo gobi": FoodPattern(name: "Aloo Gobi", category: "Vegetables", cuisine: "Indian", confidence: 0.9),
        "chana masala": FoodPattern(name: "Chana Masala", category: "Legumes", cuisine: "Indian", confidence: 0.9),
        "roti": FoodPattern(name: "Roti", category: "Bread", cuisine: "Indian", confidence: 0.9),
        "paratha": FoodPattern(name: "Paratha", category: "Bread", cuisine: "Indian", confidence: 0.9),
        
        // MEXICAN CUISINE
        "taco": FoodPattern(name: "Taco", category: "Sandwich", cuisine: "Mexican", confidence: 0.95),
        "tacos": FoodPattern(name: "Taco", category: "Sandwich", cuisine: "Mexican", confidence: 0.9),
        "burrito": FoodPattern(name: "Burrito", category: "Sandwich", cuisine: "Mexican", confidence: 0.95),
        "enchilada": FoodPattern(name: "Enchilada", category: "Main Dish", cuisine: "Mexican", confidence: 0.9),
        "quesadilla": FoodPattern(name: "Quesadilla", category: "Sandwich", cuisine: "Mexican", confidence: 0.9),
        "fajita": FoodPattern(name: "Fajita", category: "Main Dish", cuisine: "Mexican", confidence: 0.9),
        "guacamole": FoodPattern(name: "Guacamole", category: "Dips", cuisine: "Mexican", confidence: 0.95),
        "guac": FoodPattern(name: "Guacamole", category: "Dips", cuisine: "Mexican", confidence: 0.9),
        "salsa": FoodPattern(name: "Salsa", category: "Sauce", cuisine: "Mexican", confidence: 0.9),
        "churro": FoodPattern(name: "Churro", category: "Dessert", cuisine: "Mexican", confidence: 0.9),
        "flan": FoodPattern(name: "Flan", category: "Dessert", cuisine: "Mexican", confidence: 0.9),
        "horchata": FoodPattern(name: "Horchata", category: "Beverage", cuisine: "Mexican", confidence: 0.9),
        
        // EUROPEAN CUISINE
        "crepe": FoodPattern(name: "Crepe", category: "Bread", cuisine: "French", confidence: 0.95),
        "crepes": FoodPattern(name: "Crepe", category: "Bread", cuisine: "French", confidence: 0.9),
        "bruschetta": FoodPattern(name: "Bruschetta", category: "Appetizer", cuisine: "Italian", confidence: 0.9),
        "gnocchi": FoodPattern(name: "Gnocchi", category: "Pasta", cuisine: "Italian", confidence: 0.9),
        "cassoulet": FoodPattern(name: "Cassoulet", category: "Main Dish", cuisine: "French", confidence: 0.9),
        "coq au vin": FoodPattern(name: "Coq au Vin", category: "Main Dish", cuisine: "French", confidence: 0.9),
        "beef bourguignon": FoodPattern(name: "Beef Bourguignon", category: "Main Dish", cuisine: "French", confidence: 0.9),
        
        // COMMON FOODS
        "sandwich": FoodPattern(name: "Sandwich", category: "Sandwich", cuisine: "International", confidence: 0.8),
        "sandwhich": FoodPattern(name: "Sandwich", category: "Sandwich", cuisine: "International", confidence: 0.9),
        "egg sandwich": FoodPattern(name: "Egg Sandwich", category: "Sandwich", cuisine: "International", confidence: 0.9),
        "chicken sandwich": FoodPattern(name: "Chicken Sandwich", category: "Sandwich", cuisine: "International", confidence: 0.9),
        "salad": FoodPattern(name: "Salad", category: "Salad", cuisine: "International", confidence: 0.7),
        "soup": FoodPattern(name: "Soup", category: "Soups", cuisine: "International", confidence: 0.7),
        "bread": FoodPattern(name: "Bread", category: "Bread", cuisine: "International", confidence: 0.8),
        "rice": FoodPattern(name: "Rice", category: "Grains", cuisine: "International", confidence: 0.8),
        "pasta": FoodPattern(name: "Pasta", category: "Grains", cuisine: "International", confidence: 0.8),
        "chicken": FoodPattern(name: "Chicken", category: "Meat", cuisine: "International", confidence: 0.8),
        "beef": FoodPattern(name: "Beef", category: "Meat", cuisine: "International", confidence: 0.8),
        "fish": FoodPattern(name: "Fish", category: "Seafood", cuisine: "International", confidence: 0.8),
        "salmon": FoodPattern(name: "Salmon", category: "Seafood", cuisine: "International", confidence: 0.9),
        "tuna": FoodPattern(name: "Tuna", category: "Seafood", cuisine: "International", confidence: 0.9),
        "eggs": FoodPattern(name: "Eggs", category: "Protein", cuisine: "International", confidence: 0.8),
        "egg": FoodPattern(name: "Eggs", category: "Protein", cuisine: "International", confidence: 0.8),
        "egg omelette": FoodPattern(name: "Egg Omelette", category: "Protein", cuisine: "International", confidence: 0.95),
        "egg omlete": FoodPattern(name: "Egg Omelette", category: "Protein", cuisine: "International", confidence: 0.9),
        "egg omlette": FoodPattern(name: "Egg Omelette", category: "Protein", cuisine: "International", confidence: 0.9),
        "omelette": FoodPattern(name: "Egg Omelette", category: "Protein", cuisine: "International", confidence: 0.9),
        "omelet": FoodPattern(name: "Egg Omelette", category: "Protein", cuisine: "International", confidence: 0.9),
        "cheese": FoodPattern(name: "Cheese", category: "Dairy", cuisine: "International", confidence: 0.8),
        "milk": FoodPattern(name: "Milk", category: "Dairy", cuisine: "International", confidence: 0.8),
        "yogurt": FoodPattern(name: "Yogurt", category: "Dairy", cuisine: "International", confidence: 0.8),
        "greek yogurt": FoodPattern(name: "Greek Yogurt", category: "Dairy", cuisine: "International", confidence: 0.9),
        "apple": FoodPattern(name: "Apple", category: "Fruits", cuisine: "International", confidence: 0.9),
        "banana": FoodPattern(name: "Banana", category: "Fruits", cuisine: "International", confidence: 0.9),
        "orange": FoodPattern(name: "Orange", category: "Fruits", cuisine: "International", confidence: 0.9),
        "strawberry": FoodPattern(name: "Strawberry", category: "Fruits", cuisine: "International", confidence: 0.9),
        "blueberry": FoodPattern(name: "Blueberry", category: "Fruits", cuisine: "International", confidence: 0.9),
        "broccoli": FoodPattern(name: "Broccoli", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "spinach": FoodPattern(name: "Spinach", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "carrot": FoodPattern(name: "Carrot", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "tomato": FoodPattern(name: "Tomato", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "lettuce": FoodPattern(name: "Lettuce", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "onion": FoodPattern(name: "Onion", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "garlic": FoodPattern(name: "Garlic", category: "Vegetables", cuisine: "International", confidence: 0.9),
        "almonds": FoodPattern(name: "Almonds", category: "Nuts", cuisine: "International", confidence: 0.9),
        "almond": FoodPattern(name: "Almonds", category: "Nuts", cuisine: "International", confidence: 0.8),
        "peanuts": FoodPattern(name: "Peanuts", category: "Nuts", cuisine: "International", confidence: 0.9),
        "peanut": FoodPattern(name: "Peanuts", category: "Nuts", cuisine: "International", confidence: 0.8),
        "walnuts": FoodPattern(name: "Walnuts", category: "Nuts", cuisine: "International", confidence: 0.9),
        "walnut": FoodPattern(name: "Walnuts", category: "Nuts", cuisine: "International", confidence: 0.8),
        "beans": FoodPattern(name: "Beans", category: "Legumes", cuisine: "International", confidence: 0.8),
        "lentils": FoodPattern(name: "Lentils", category: "Legumes", cuisine: "International", confidence: 0.9),
        "lentil": FoodPattern(name: "Lentils", category: "Legumes", cuisine: "International", confidence: 0.8),
        "chickpeas": FoodPattern(name: "Chickpeas", category: "Legumes", cuisine: "International", confidence: 0.9),
        "chickpea": FoodPattern(name: "Chickpeas", category: "Legumes", cuisine: "International", confidence: 0.8),
        "quinoa": FoodPattern(name: "Quinoa", category: "Grains", cuisine: "International", confidence: 0.9),
        "keenwa": FoodPattern(name: "Quinoa", category: "Grains", cuisine: "International", confidence: 0.8),
        "oats": FoodPattern(name: "Oats", category: "Grains", cuisine: "International", confidence: 0.9),
        "oatmeal": FoodPattern(name: "Oats", category: "Grains", cuisine: "International", confidence: 0.8),
        "brown rice": FoodPattern(name: "Brown Rice", category: "Grains", cuisine: "International", confidence: 0.9),
        "white rice": FoodPattern(name: "Rice", category: "Grains", cuisine: "International", confidence: 0.8),
        "butter": FoodPattern(name: "Butter", category: "Fats", cuisine: "International", confidence: 0.9),
        "oil": FoodPattern(name: "Oil", category: "Fats", cuisine: "International", confidence: 0.8),
        "olive oil": FoodPattern(name: "Olive Oil", category: "Fats", cuisine: "International", confidence: 0.9),
        "avocado": FoodPattern(name: "Avocado", category: "Fruits", cuisine: "International", confidence: 0.9),
        "avacado": FoodPattern(name: "Avocado", category: "Fruits", cuisine: "International", confidence: 0.8),
        
        // COMPOUND DISHES
        "baked red beans with pita": FoodPattern(name: "Baked Red Beans with Pita", category: "Main Dish", cuisine: "Mediterranean", confidence: 0.95),
        "baked red beans": FoodPattern(name: "Baked Red Beans", category: "Legumes", cuisine: "Mediterranean", confidence: 0.9),
        "red beans": FoodPattern(name: "Baked Red Beans", category: "Legumes", cuisine: "Mediterranean", confidence: 0.8),
        "pita bread": FoodPattern(name: "Pita Bread", category: "Bread", cuisine: "Middle Eastern", confidence: 0.9),
        "pita": FoodPattern(name: "Pita Bread", category: "Bread", cuisine: "Middle Eastern", confidence: 0.8)
    ]
    
    // MARK: - Spelling Corrections
    private let spellingCorrections: [String: String] = [
        // Common typos
        "sandwhich": "sandwich",
        "sandwiche": "sandwich",
        "sandwch": "sandwich",
        "omlete": "omelette",
        "omlette": "omelette",
        "omlet": "omelette",
        "avacado": "avocado",
        "keenwa": "quinoa",
        "quinoa": "quinoa",
        "padthai": "pad thai",
        "pad-thai": "pad thai",
        "biriyani": "biryani",
        "shawarma": "shawarma",
        "shwarma": "shawarma",
        "falafal": "falafel",
        "humus": "hummus",
        "tzaziki": "tzatziki",
        "bruscheta": "bruschetta",
        "ratatouile": "ratatouille",
        "bouillabaise": "bouillabaisse",
        "bourguignonne": "bourguignon",
        "dhal": "dal",
        "guac": "guacamole",
        "mac n cheese": "mac and cheese",
        "mac n c heese": "mac and cheese",
        "macaroni and cheese": "mac and cheese",
        "hotdog": "hot dog",
        "hot-dog": "hot dog",
        "chicken wings": "chicken wings",
        "bbq ribs": "bbq ribs",
        "corn dog": "corn dog",
        "greek yogurt": "greek yogurt",
        "brown rice": "brown rice",
        "white rice": "rice",
        "olive oil": "olive oil",
        "green onions": "green onions",
        "bean sprouts": "bean sprouts",
        "tamarind sauce": "tamarind sauce",
        "tahini sauce": "tahini sauce",
        "dashi stock": "dashi stock",
        "miso paste": "miso paste"
    ]
    
    // MARK: - Context Words (to be ignored)
    private let contextWords = Set([
        "with", "and", "or", "plus", "including", "served", "topped", "on", "in", "of", "the", "a", "an",
        "fresh", "cooked", "baked", "fried", "grilled", "roasted", "steamed", "boiled", "sauteed",
        "stir-fried", "raw", "organic", "homemade", "store-bought", "frozen", "canned", "dried",
        "large", "small", "medium", "big", "tiny", "huge", "extra", "double", "single", "half",
        "piece", "slice", "cup", "tbsp", "tsp", "oz", "lb", "gram", "pound", "ounce", "serving",
        "bowl", "plate", "container", "pack", "package", "bottle", "can", "jar", "box"
    ])
    
    // MARK: - Portion Indicators
    private let portionIndicators = [
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "half", "quarter", "third", "double", "triple", "single"
    ]
    
    private init() {}
    
    // MARK: - Main Processing Function
    func processFoodDescription(_ description: String) -> AdvancedFoodResult {
        let normalizedDescription = normalizeText(description)
        let correctedDescription = correctSpelling(normalizedDescription)
        
        // Try exact pattern matching first
        if let exactMatch = findExactPattern(correctedDescription) {
            return AdvancedFoodResult(
                originalText: description,
                normalizedText: correctedDescription,
                recognizedFood: exactMatch,
                confidence: exactMatch.confidence,
                processingMethod: "exact_pattern"
            )
        }
        
        // Try fuzzy matching
        if let fuzzyMatch = findFuzzyMatch(correctedDescription) {
            return AdvancedFoodResult(
                originalText: description,
                normalizedText: correctedDescription,
                recognizedFood: fuzzyMatch,
                confidence: fuzzyMatch.confidence * 0.8, // Reduce confidence for fuzzy matches
                processingMethod: "fuzzy_match"
            )
        }
        
        // Try ingredient parsing
        if let ingredientMatch = parseIngredients(correctedDescription) {
            return AdvancedFoodResult(
                originalText: description,
                normalizedText: correctedDescription,
                recognizedFood: ingredientMatch,
                confidence: ingredientMatch.confidence * 0.7, // Reduce confidence for parsed ingredients
                processingMethod: "ingredient_parsing"
            )
        }
        
        // No match found
        return AdvancedFoodResult(
            originalText: description,
            normalizedText: correctedDescription,
            recognizedFood: nil,
            confidence: 0.0,
            processingMethod: "no_match"
        )
    }
    
    // MARK: - Text Normalization
    private func normalizeText(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // Remove extra spaces and punctuation
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common context words
        let words = normalized.components(separatedBy: " ")
        let filteredWords = words.filter { !contextWords.contains($0) }
        normalized = filteredWords.joined(separator: " ")
        
        return normalized
    }
    
    // MARK: - Spelling Correction
    private func correctSpelling(_ text: String) -> String {
        var corrected = text
        
        for (incorrect, correct) in spellingCorrections {
            corrected = corrected.replacingOccurrences(of: incorrect, with: correct, options: .caseInsensitive)
        }
        
        return corrected
    }
    
    // MARK: - Exact Pattern Matching
    private func findExactPattern(_ text: String) -> FoodPattern? {
        // Sort patterns by length (longest first) for priority matching
        let sortedPatterns = foodPatterns.sorted { $0.key.count > $1.key.count }
        
        for (pattern, foodPattern) in sortedPatterns {
            if text.contains(pattern) {
                return foodPattern
            }
        }
        
        return nil
    }
    
    // MARK: - Fuzzy Matching
    private func findFuzzyMatch(_ text: String) -> FoodPattern? {
        var bestMatch: FoodPattern?
        var bestSimilarity: Double = 0.0
        
        for (pattern, foodPattern) in foodPatterns {
            let similarity = calculateSimilarity(text, pattern)
            if similarity > bestSimilarity && similarity > 0.7 { // Threshold for fuzzy matching
                bestSimilarity = similarity
                bestMatch = foodPattern
            }
        }
        
        return bestMatch
    }
    
    // MARK: - Similarity Calculation
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let set1 = Set(text1.components(separatedBy: " "))
        let set2 = Set(text2.components(separatedBy: " "))
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return union > 0 ? Double(intersection) / Double(union) : 0.0
    }
    
    // MARK: - Ingredient Parsing
    private func parseIngredients(_ text: String) -> FoodPattern? {
        let words = text.components(separatedBy: " ")
        var recognizedIngredients: [String] = []
        
        for word in words {
            if let ingredient = findIngredientMatch(word) {
                recognizedIngredients.append(ingredient)
            }
        }
        
        if recognizedIngredients.count > 0 {
            // Create a compound food pattern
            let compoundName = recognizedIngredients.joined(separator: " with ")
            return FoodPattern(
                name: compoundName,
                category: "Compound Dish",
                cuisine: "Mixed",
                confidence: 0.6
            )
        }
        
        return nil
    }
    
    // MARK: - Ingredient Matching
    private func findIngredientMatch(_ word: String) -> String? {
        for (pattern, foodPattern) in foodPatterns {
            if pattern == word {
                return foodPattern.name
            }
        }
        return nil
    }
}

// MARK: - Supporting Structures
struct FoodPattern {
    let name: String
    let category: String
    let cuisine: String
    let confidence: Double
}

struct AdvancedFoodResult {
    let originalText: String
    let normalizedText: String
    let recognizedFood: FoodPattern?
    let confidence: Double
    let processingMethod: String
} 