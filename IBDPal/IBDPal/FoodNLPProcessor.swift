import Foundation
import NaturalLanguage

// MARK: - Food NLP Processor
class FoodNLPProcessor: ObservableObject {
    static let shared = FoodNLPProcessor()
    

    
    // Food normalization mappings
    private let foodNormalizations: [String: String] = [
        // Mac and Cheese variations
        "mac n cheese": "mac and cheese",
        "mac n c heese": "mac and cheese", 
        "macaroni cheese": "mac and cheese",
        "macaroni and cheese": "mac and cheese",
        "pasta cheese": "mac and cheese",
        
        // Pasta variations
        "spaghetti": "pasta",
        "penne": "pasta",
        "rigatoni": "pasta",
        "fettuccine": "pasta",
        "linguine": "pasta",
        "noodles": "pasta",
        
        // Bread variations
        "pita": "pita bread",
        "pita bread": "pita bread",
        "flatbread": "pita bread",
        "naan": "naan",
        "parotta": "parotta",
        "paratha": "parotta",
        "roti": "roti",
        "chapati": "chapati",
        "chapatti": "chapati",
        "poori": "poori",
        "tortilla": "tortilla",
        "lavash": "lavash",
        "khubz": "khubz",
        "arabic bread": "khubz",
        "indian bread": "roti",
        "flat bread": "flatbread",
        
        // Bean variations
        "red beans": "baked red beans",
        "kidney beans": "baked red beans",
        "baked beans": "baked red beans",
        "beans": "baked red beans",
        
        // Meat variations
        "chicken breast": "chicken",
        "chicken thigh": "chicken",
        "ground beef": "beef",
        "beef": "beef",
        "pork": "pork",
        "lamb": "lamb",
        
        // Dairy variations
        "cheddar": "cheese",
        "mozzarella": "cheese",
        "parmesan": "cheese",
        "gouda": "cheese",
        "yogurt": "yogurt",
        "greek yogurt": "greek yogurt",
        
        // Vegetable variations
        "tomatoes": "tomato",
        "tomato": "tomato",
        "lettuce": "lettuce",
        "cucumber": "cucumber",
        "cucumbers": "cucumber",
        "onion": "onion",
        "onions": "onion",
        "garlic": "garlic",
        "carrot": "carrot",
        "carrots": "carrot",
        "broccoli": "broccoli",
        "spinach": "spinach",
        
        // Fruit variations
        "apple": "apple",
        "apples": "apple",
        "banana": "banana",
        "bananas": "banana",
        "orange": "orange",
        "oranges": "orange",
        "strawberry": "strawberry",
        "strawberries": "strawberry",
        "blueberry": "blueberry",
        "blueberries": "blueberry",
        
        // Grain variations
        "rice": "rice",
        "white rice": "rice",
        "brown rice": "brown rice",
        "quinoa": "quinoa",
        "oatmeal": "oats",
        "oats": "oats",
        
        // Legume variations
        "lentils": "lentils",
        "lentil": "lentils",
        "dal": "lentils",
        "dhal": "lentils",
        "chickpeas": "chickpeas",
        "chickpea": "chickpeas",
        "garbanzo": "chickpeas",
        "hummus": "hummus",
        "humus": "hummus",
        
        // Indian food variations
        "curry": "curry",
        "biryani": "biryani",
        "biriyani": "biryani",
        "tandoori": "tandoori",
        "butter chicken": "butter chicken",
        "chicken tikka": "chicken tikka",
        "samosa": "samosa",
        "pakora": "pakora",
        "bhaji": "bhaji",
        "masala": "masala",
        "tikka masala": "tikka masala",
        "vindaloo": "vindaloo",
        "korma": "korma",
        "jalfrezi": "jalfrezi",
        "rogan josh": "rogan josh",
        "saag": "saag",
        "palak": "palak",
        "aloo": "aloo",
        "gobi": "gobi",
        "mattar": "mattar",
        "paneer": "paneer",
        "lassi": "lassi",
        "raita": "raita",
        "chutney": "chutney",
        "pickle": "pickle",
        "papad": "papad",
        "papadum": "papad",
        
        // Middle Eastern food variations
        "falafel": "falafel",
        "shawarma": "shawarma",
        "kebab": "kebab",
        "kabob": "kebab",
        "gyro": "gyro",
        "tabbouleh": "tabbouleh",
        "fattoush": "fattoush",
        "baba ganoush": "baba ganoush",
        "baba ghanoush": "baba ganoush",
        "tahini": "tahini",
        "za'atar": "za'atar",
        "sumac": "sumac",
        "pomegranate": "pomegranate",
        "mint": "mint",
        "parsley": "parsley",
        "cilantro": "cilantro",
        "coriander": "cilantro",
        
        // Nut variations
        "almonds": "almonds",
        "almond": "almonds",
        "peanuts": "peanuts",
        
        // Smoothie variations
        "smoothie": "smoothie",
        "fruit smoothie": "fruit smoothie",
        "berry smoothie": "berry smoothie",
        "green smoothie": "green smoothie",
        "peanut": "peanuts",
        "walnuts": "walnuts",
        "walnut": "walnuts",
        
        // International foods
        "sushi": "sushi",
        "pad thai": "pad thai",
        "padthai": "pad thai",
        "shwarma": "chicken shawarma",
        "falafal": "falafel",
        "crepe": "crepe",
        "crepes": "crepe",
        "taco": "taco",
        "tacos": "taco",
                    "egg omelette": "egg omelette",
            "egg omlete": "egg omelette",
            "egg omlette": "egg omelette",
            "omelette": "egg omelette",
            "omelet": "egg omelette",
            "chicken curry": "chicken curry",
            "beef curry": "beef curry",
            "vegetable curry": "vegetable curry",
            "miso soup": "miso soup",
            "ramen": "ramen",
            "ramen soup": "ramen"
    ]
    
    // Common food connectors and prepositions to ignore
    private let connectors = Set([
        "with", "and", "or", "plus", "including", "served", "topped", "on", "in", "of", "the", "a", "an"
    ])
    
    // Cooking methods that might be part of food names
    private let cookingMethods = Set([
        "baked", "fried", "grilled", "roasted", "steamed", "boiled", "sauteed", "stir-fried", "cooked", "raw"
    ])
    
    private init() {}
    
    // MARK: - Main Processing Function
    func processFoodDescription(_ description: String) -> ProcessedFoodResult {
        let normalizedDescription = normalizeText(description)
        let foodEntities = extractFoodEntities(from: normalizedDescription)
        let compoundFoods = identifyCompoundFoods(from: normalizedDescription)
        
        return ProcessedFoodResult(
            originalText: description,
            normalizedText: normalizedDescription,
            individualFoods: foodEntities,
            compoundFoods: compoundFoods,
            confidence: calculateConfidence(foodEntities: foodEntities, compoundFoods: compoundFoods)
        )
    }
    
    // MARK: - Text Normalization
    private func normalizeText(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // Remove extra spaces and punctuation
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Apply food normalizations
        for (variation, standard) in foodNormalizations {
            normalized = normalized.replacingOccurrences(of: variation, with: standard)
        }
        
        return normalized
    }
    
    // MARK: - Food Entity Extraction
    private func extractFoodEntities(from text: String) -> [FoodEntity] {
        var entities: [FoodEntity] = []
        
        // Simple word splitting instead of complex tokenization
        let words = text.components(separatedBy: " ")
        
        var currentEntity = ""
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty words, connectors and common words
            if cleanWord.isEmpty || connectors.contains(cleanWord) || cleanWord.count < 2 {
                // Save current entity if it exists
                if !currentEntity.isEmpty {
                    if let foodEntity = createFoodEntity(from: currentEntity.trimmingCharacters(in: .whitespaces)) {
                        entities.append(foodEntity)
                    }
                    currentEntity = ""
                }
                continue
            }
            
            // Check if this word is part of a food name
            if isFoodWord(cleanWord) {
                currentEntity += (currentEntity.isEmpty ? "" : " ") + cleanWord
            } else {
                // Save current entity if it exists
                if !currentEntity.isEmpty {
                    if let foodEntity = createFoodEntity(from: currentEntity.trimmingCharacters(in: .whitespaces)) {
                        entities.append(foodEntity)
                    }
                    currentEntity = ""
                }
            }
        }
        
        // Don't forget the last entity
        if !currentEntity.isEmpty {
            if let foodEntity = createFoodEntity(from: currentEntity.trimmingCharacters(in: .whitespaces)) {
                entities.append(foodEntity)
            }
        }
        
        return entities
    }
    
    // MARK: - Compound Food Identification
    private func identifyCompoundFoods(from text: String) -> [NLPCompoundFood] {
        let compoundPatterns = [
            "baked red beans with pita": "Baked Red Beans with Pita",
            "mac and cheese": "Mac and Cheese",
            "mac n cheese": "Mac and Cheese",
            "chicken shawarma": "Chicken Shawarma",
            
            // Mixed meals with flatbreads
            "boiled egg and salad": "Egg and Salad with Flatbread",
            "egg and salad": "Egg and Salad with Flatbread",
            "tortillas with vegetables": "Tortillas with Vegetables",
            "tortilla with vegetables": "Tortillas with Vegetables",
            "parotta with curry": "Parotta with Curry",
            "naan with curry": "Naan with Curry",
            "roti with curry": "Roti with Curry",
            "chapati with curry": "Chapati with Curry",
            
            // Indian flatbread combinations
            "naan bread": "Naan",
            "parotta bread": "Parotta",
            "roti bread": "Roti",
            "chapati bread": "Chapati",
            "poori bread": "Poori",
            
            // Middle Eastern combinations
            "pita with hummus": "Pita with Hummus",
            "lavash with vegetables": "Lavash with Vegetables",
            "khubz with vegetables": "Khubz with Vegetables",
            "pad thai": "Pad Thai",
            "rice biryani": "Rice Biryani",
            "chicken curry": "Chicken Curry",
            "beef curry": "Beef Curry",
            "vegetable curry": "Vegetable Curry",
            "falafel wrap": "Falafel Wrap",
            "hummus with pita": "Hummus with Pita",
            "sushi roll": "Sushi Roll",
            "taco": "Taco",
            "crepe": "Crepe",
            "egg omelette": "Egg Omelette",
            "egg omelet": "Egg Omelette",
            "omelette": "Egg Omelette",
            "omelet": "Egg Omelette",
            "miso soup": "Miso Soup",
            "ramen": "Ramen",
            "ramen soup": "Ramen"
        ]
        
        var compoundFoods: [NLPCompoundFood] = []
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Sort patterns by length (longest first) to prioritize exact matches
        let sortedPatterns = compoundPatterns.sorted { $0.key.count > $1.key.count }
        
        for (pattern, foodName) in sortedPatterns {
            // Use exact word boundary matching instead of simple contains
            let patternWords = pattern.lowercased().components(separatedBy: " ")
            let textWords = normalizedText.components(separatedBy: " ")
            
            // Check if all pattern words are present in the text
            let allPatternWordsFound = patternWords.allSatisfy { patternWord in
                textWords.contains { textWord in
                    textWord == patternWord || textWord.contains(patternWord)
                }
            }
            
            if allPatternWordsFound {
                compoundFoods.append(NLPCompoundFood(
                    name: foodName,
                    pattern: pattern,
                    confidence: 0.9
                ))
                // Only return the first (most specific) match
                break
            }
        }
        
        return compoundFoods
    }
    
    // MARK: - Helper Functions
    private func isFoodWord(_ word: String) -> Bool {
        // Check if word is in our normalization mappings
        if foodNormalizations.keys.contains(word) || foodNormalizations.values.contains(word) {
            return true
        }
        
        // Check if it's a cooking method
        if cookingMethods.contains(word) {
            return true
        }
        
        // Check if it's a common food word (basic heuristic)
        let commonFoodWords = Set([
            "bread", "cheese", "meat", "fish", "chicken", "beef", "pork", "lamb",
            "vegetable", "fruit", "grain", "nut", "seed", "bean", "pasta", "rice",
            "soup", "salad", "sauce", "dressing", "oil", "butter", "milk", "yogurt",
            
            // International flatbreads
            "naan", "parotta", "paratha", "roti", "chapati", "chapatti", "poori",
            "pita", "lavash", "khubz", "tortilla", "flatbread",
            
            // Indian foods
            "curry", "biryani", "biriyani", "tandoori", "masala", "dal", "dhal",
            "samosa", "pakora", "bhaji", "lassi", "raita", "chutney", "pickle",
            "papad", "papadum", "paneer", "saag", "palak", "aloo", "gobi", "mattar",
            
            // Middle Eastern foods
            "falafel", "shawarma", "kebab", "kabob", "gyro", "tabbouleh", "fattoush",
            "baba", "ganoush", "ghanoush", "tahini", "za'atar", "sumac", "pomegranate",
            "mint", "parsley", "cilantro", "coriander",
            
            // Asian foods
            "sushi", "ramen", "miso", "kimchi", "tofu", "teriyaki", "tempura",
            "pad", "thai", "pho", "banh", "mi", "spring", "rolls", "bun", "cha",
            
            // Mexican foods
            "taco", "burrito", "enchilada", "quesadilla", "fajita", "guacamole",
            "tortilla", "salsa", "jalapeno", "cilantro", "lime", "avocado"
        ])
        
        return commonFoodWords.contains(word)
    }
    
    private func createFoodEntity(from text: String) -> FoodEntity? {
        guard !text.isEmpty else { return nil }
        
        // Find the best match in our database
        let bestMatch = findBestMatch(for: text)
        
        return FoodEntity(
            originalText: text,
            normalizedText: bestMatch.normalized,
            confidence: bestMatch.confidence,
            category: bestMatch.category
        )
    }
    
    private func findBestMatch(for text: String) -> (normalized: String, confidence: Double, category: String) {
        let normalized = foodNormalizations[text] ?? text
        
        // Calculate similarity score
        let similarity = calculateSimilarity(text, normalized)
        
        // Determine category based on normalized text
        let category = determineCategory(for: normalized)
        
        return (normalized, similarity, category)
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let set1 = Set(text1.lowercased().split(separator: " "))
        let set2 = Set(text2.lowercased().split(separator: " "))
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return union > 0 ? Double(intersection) / Double(union) : 0.0
    }
    
    private func determineCategory(for food: String) -> String {
        let categories: [String: Set<String>] = [
            "Grains": ["bread", "pasta", "rice", "quinoa", "oats", "pita", "naan", "parotta", "roti", "chapati", "poori", "lavash", "khubz", "tortilla", "flatbread"],
            "Protein": ["chicken", "beef", "pork", "lamb", "fish", "salmon", "tuna", "tofu", "tempeh", "seitan", "paneer"],
            "Dairy": ["cheese", "milk", "yogurt", "butter", "lassi", "raita"],
            "Vegetables": ["tomato", "lettuce", "cucumber", "onion", "garlic", "carrot", "broccoli", "spinach", "saag", "palak", "aloo", "gobi", "mattar"],
            "Fruits": ["apple", "banana", "orange", "strawberry", "blueberry", "pomegranate", "avocado"],
            "Legumes": ["beans", "lentils", "chickpeas", "hummus", "dal", "dhal", "falafel"],
            "Nuts": ["almonds", "peanuts", "walnuts"],
            "Fats": ["oil", "butter", "avocado", "tahini"],
            "Spices": ["masala", "curry", "tandoori", "za'atar", "sumac", "cilantro", "coriander", "mint", "parsley"],
            "Sauces": ["sauce", "dressing", "chutney", "pickle", "salsa", "guacamole"],
            "Bread": ["naan", "parotta", "roti", "chapati", "poori", "pita", "lavash", "khubz", "tortilla", "flatbread"]
        ]
        
        for (category, foods) in categories {
            if foods.contains(food.lowercased()) {
                return category
            }
        }
        
        return "Other"
    }
    
    private func calculateConfidence(foodEntities: [FoodEntity], compoundFoods: [NLPCompoundFood]) -> Double {
        let entityConfidence = foodEntities.map { $0.confidence }.reduce(0, +)
        let compoundConfidence = compoundFoods.map { $0.confidence }.reduce(0, +)
        
        let totalConfidence = entityConfidence + compoundConfidence
        let totalItems = foodEntities.count + compoundFoods.count
        
        return totalItems > 0 ? totalConfidence / Double(totalItems) : 0.0
    }
}

// MARK: - Data Models
struct ProcessedFoodResult {
    let originalText: String
    let normalizedText: String
    let individualFoods: [FoodEntity]
    let compoundFoods: [NLPCompoundFood]
    let confidence: Double
}

struct FoodEntity {
    let originalText: String
    let normalizedText: String
    let confidence: Double
    let category: String
}

struct NLPCompoundFood {
    let name: String
    let pattern: String
    let confidence: Double
} 