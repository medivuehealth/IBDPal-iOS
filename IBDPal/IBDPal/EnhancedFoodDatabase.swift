import Foundation

// Enhanced Food Item with comprehensive nutritional and cultural information
struct EnhancedFoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let fat: Double
    
    // Enhanced nutritional information
    let vitamins: [String: Double] // Vitamin content in mg/mcg
    let minerals: [String: Double] // Mineral content in mg
    let servingSize: String
    let region: String
    let cuisine: String
    
    // IBD and digestive health specific
    let ibdFriendly: Bool
    let fodmapLevel: String // "low", "medium", "high"
    let preparationMethods: [String]
    let benefits: String
    let tags: [String]
    
    // Cultural and dietary information
    let allergens: [String]
    let dietaryRestrictions: [String] // "vegan", "gluten-free", etc.
    let seasonalAvailability: [String]
    
    init(id: UUID = UUID(), name: String, category: String, calories: Double, protein: Double, carbs: Double, fiber: Double, fat: Double, vitamins: [String: Double], minerals: [String: Double], servingSize: String, region: String, cuisine: String, ibdFriendly: Bool, fodmapLevel: String, preparationMethods: [String], benefits: String, tags: [String], allergens: [String], dietaryRestrictions: [String], seasonalAvailability: [String]) {
        self.id = id
        self.name = name
        self.category = category
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fiber = fiber
        self.fat = fat
        self.vitamins = vitamins
        self.minerals = minerals
        self.servingSize = servingSize
        self.region = region
        self.cuisine = cuisine
        self.ibdFriendly = ibdFriendly
        self.fodmapLevel = fodmapLevel
        self.preparationMethods = preparationMethods
        self.benefits = benefits
        self.tags = tags
        self.allergens = allergens
        self.dietaryRestrictions = dietaryRestrictions
        self.seasonalAvailability = seasonalAvailability
    }
    
    var displayName: String {
        return "\(name) (\(servingSize))"
    }
    
    var nutritionSummary: String {
        return "Cal: \(Int(calories)), P: \(protein)g, C: \(carbs)g, F: \(fiber)g, Fat: \(fat)g"
    }
}

class EnhancedFoodDatabase: ObservableObject {
    static let shared = EnhancedFoodDatabase()
    
    @Published var allFoods: [EnhancedFoodItem]
    @Published var searchResults: [EnhancedFoodItem]
    
    private init() {
        self.allFoods = []
        self.searchResults = []
        loadEnhancedFoodDatabase()
    }
    
    func searchFoods(query: String) -> [EnhancedFoodItem] {
        if query.isEmpty {
            return []
        }
        
        let lowercasedQuery = query.lowercased()
        return allFoods.filter { food in
            food.name.lowercased().contains(lowercasedQuery) ||
            food.category.lowercased().contains(lowercasedQuery) ||
            food.region.lowercased().contains(lowercasedQuery) ||
            food.cuisine.lowercased().contains(lowercasedQuery) ||
            food.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func getIBDFriendlyFoods() -> [EnhancedFoodItem] {
        return allFoods.filter { $0.ibdFriendly }
    }
    
    func getLowFODMAPFoods() -> [EnhancedFoodItem] {
        return allFoods.filter { $0.fodmapLevel == "low" }
    }
    
    func getFoodsByRegion(_ region: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.region == region }
    }
    
    func getFoodsByCuisine(_ cuisine: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.cuisine == cuisine }
    }
    
    func getFoodsByCategory(_ category: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.category == category }
    }
    
    private func loadEnhancedFoodDatabase() {
        allFoods = [
            // ASIAN CUISINE
            EnhancedFoodItem(
                name: "Sushi (Salmon Nigiri)",
                category: "Seafood",
                calories: 45,
                protein: 6,
                carbs: 8,
                fiber: 0.2,
                fat: 0.5,
                vitamins: ["D": 2.5, "B12": 1.8],
                minerals: ["Selenium": 15, "Iodine": 25],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Japanese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["raw", "vinegared_rice"],
                benefits: "Omega-3 fatty acids, lean protein, easy to digest",
                tags: ["omega3", "protein", "seafood", "japanese"],
                allergens: ["fish", "soy"],
                dietaryRestrictions: ["gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Miso Soup",
                category: "Soup",
                calories: 35,
                protein: 2,
                carbs: 4,
                fiber: 1,
                fat: 1,
                vitamins: ["B12": 0.1, "K": 2.5],
                minerals: ["Sodium": 700, "Copper": 0.1],
                servingSize: "1 cup",
                region: "Asia",
                cuisine: "Japanese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["fermented", "boiled"],
                benefits: "Probiotics, anti-inflammatory, gut health",
                tags: ["probiotics", "anti-inflammatory", "soup", "fermented"],
                allergens: ["soy"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Kimchi",
                category: "Fermented",
                calories: 23,
                protein: 2,
                carbs: 4,
                fiber: 2,
                fat: 0.5,
                vitamins: ["C": 15, "K": 43, "B6": 0.2],
                minerals: ["Iron": 1.2, "Calcium": 33],
                servingSize: "1/2 cup",
                region: "Asia",
                cuisine: "Korean",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["fermented", "spiced"],
                benefits: "Probiotics, vitamin C, anti-inflammatory",
                tags: ["probiotics", "vitamin_c", "fermented", "spicy"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Tofu (Silken)",
                category: "Protein",
                calories: 80,
                protein: 8,
                carbs: 2,
                fiber: 0.5,
                fat: 4.5,
                vitamins: ["B1": 0.1, "B6": 0.1, "E": 0.1],
                minerals: ["Calcium": 130, "Iron": 1.8, "Magnesium": 27],
                servingSize: "1/2 cup",
                region: "Asia",
                cuisine: "Chinese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["steamed", "stir-fried", "raw"],
                benefits: "Complete protein, calcium, easy to digest",
                tags: ["complete_protein", "calcium", "soy", "vegetarian"],
                allergens: ["soy"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // INDIAN CUISINE
            EnhancedFoodItem(
                name: "Lentil Dal",
                category: "Legumes",
                calories: 115,
                protein: 9,
                carbs: 20,
                fiber: 8,
                fat: 0.4,
                vitamins: ["B1": 0.2, "B6": 0.2, "Folate": 90],
                minerals: ["Iron": 3.3, "Magnesium": 36, "Zinc": 1.3],
                servingSize: "1/2 cup cooked",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["boiled", "spiced", "tempered"],
                benefits: "High fiber, protein, iron, gut-friendly",
                tags: ["fiber", "protein", "iron", "vegetarian"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // INDIAN FLATBREADS
            EnhancedFoodItem(
                name: "Naan",
                category: "Bread",
                calories: 320,
                protein: 8,
                carbs: 50,
                fiber: 2,
                fat: 8,
                vitamins: ["B1": 0.1, "B6": 0.1, "E": 0.2],
                minerals: ["Iron": 2.1, "Magnesium": 20, "Zinc": 0.8],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["baked", "tandoor", "leavened"],
                benefits: "Soft texture, easy to digest, good with curries",
                tags: ["flatbread", "leavened", "indian", "soft"],
                allergens: ["gluten", "dairy"],
                dietaryRestrictions: ["vegetarian"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Parotta",
                category: "Bread",
                calories: 280,
                protein: 6,
                carbs: 45,
                fiber: 1.5,
                fat: 6,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.8, "Magnesium": 15, "Zinc": 0.6],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["layered", "pan-fried", "flaky"],
                benefits: "Layered texture, flaky, good with curries",
                tags: ["flatbread", "layered", "flaky", "indian"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegetarian"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Roti",
                category: "Bread",
                calories: 120,
                protein: 3,
                carbs: 22,
                fiber: 1,
                fat: 2,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.2, "Magnesium": 12, "Zinc": 0.4],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["griddle-cooked", "unleavened", "whole_wheat"],
                benefits: "Whole wheat, unrefined, good fiber content",
                tags: ["flatbread", "whole_wheat", "unleavened", "healthy"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegan"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Chapati",
                category: "Bread",
                calories: 100,
                protein: 3,
                carbs: 20,
                fiber: 1.5,
                fat: 1.5,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.0, "Magnesium": 10, "Zinc": 0.3],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["griddle-cooked", "unleavened", "whole_wheat"],
                benefits: "Light, easy to digest, whole wheat nutrition",
                tags: ["flatbread", "whole_wheat", "light", "digestible"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegan"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Poori",
                category: "Bread",
                calories: 180,
                protein: 4,
                carbs: 25,
                fiber: 1,
                fat: 6,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.5, "Magnesium": 15, "Zinc": 0.5],
                servingSize: "1 piece",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["deep-fried", "puffed", "unleavened"],
                benefits: "Puffed texture, crispy, good with curries",
                tags: ["flatbread", "puffed", "crispy", "indian"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegetarian"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Basmati Rice",
                category: "Grains",
                calories: 205,
                protein: 4.3,
                carbs: 45,
                fiber: 0.6,
                fat: 0.4,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 0.8, "Magnesium": 12],
                servingSize: "1 cup cooked",
                region: "Asia",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["steamed", "boiled"],
                benefits: "Easy to digest, aromatic, low fat",
                tags: ["easy_digest", "aromatic", "gluten_free"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // MEDITERRANEAN CUISINE
            EnhancedFoodItem(
                name: "Hummus",
                category: "Dips",
                calories: 25,
                protein: 1.2,
                carbs: 3,
                fiber: 0.8,
                fat: 1.2,
                vitamins: ["B6": 0.1, "C": 1, "E": 0.3],
                minerals: ["Iron": 0.6, "Magnesium": 15, "Zinc": 0.4],
                servingSize: "2 tbsp",
                region: "Mediterranean",
                cuisine: "Middle Eastern",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["blended", "chickpea_based"],
                benefits: "Fiber, protein, healthy fats, anti-inflammatory",
                tags: ["fiber", "protein", "healthy_fats", "anti-inflammatory"],
                allergens: ["sesame"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // MIDDLE EASTERN FLATBREADS
            EnhancedFoodItem(
                name: "Pita Bread",
                category: "Bread",
                calories: 165,
                protein: 5.5,
                carbs: 33,
                fiber: 1.5,
                fat: 1,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.8, "Magnesium": 15, "Zinc": 0.6],
                servingSize: "1 piece",
                region: "Mediterranean",
                cuisine: "Middle Eastern",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["baked", "pocket", "leavened"],
                benefits: "Pocket bread, versatile, good with dips",
                tags: ["flatbread", "pocket", "versatile", "middle_eastern"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegan"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Lavash",
                category: "Bread",
                calories: 140,
                protein: 4,
                carbs: 28,
                fiber: 1,
                fat: 1.5,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.5, "Magnesium": 12, "Zinc": 0.5],
                servingSize: "1 piece",
                region: "Mediterranean",
                cuisine: "Middle Eastern",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["baked", "thin", "unleavened"],
                benefits: "Thin, flexible, good for wraps",
                tags: ["flatbread", "thin", "flexible", "wrap"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegan"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Khubz",
                category: "Bread",
                calories: 150,
                protein: 4.5,
                carbs: 30,
                fiber: 1.2,
                fat: 1.8,
                vitamins: ["B1": 0.1, "B6": 0.1],
                minerals: ["Iron": 1.6, "Magnesium": 13, "Zinc": 0.5],
                servingSize: "1 piece",
                region: "Mediterranean",
                cuisine: "Middle Eastern",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["baked", "traditional", "leavened"],
                benefits: "Traditional bread, soft texture, versatile",
                tags: ["flatbread", "traditional", "soft", "versatile"],
                allergens: ["gluten"],
                dietaryRestrictions: ["vegan"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Olive Oil (Extra Virgin)",
                category: "Fats",
                calories: 120,
                protein: 0,
                carbs: 0,
                fiber: 0,
                fat: 14,
                vitamins: ["E": 1.9, "K": 8.1],
                minerals: ["Iron": 0.1],
                servingSize: "1 tbsp",
                region: "Mediterranean",
                cuisine: "Mediterranean",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["cold_pressed", "raw"],
                benefits: "Monounsaturated fats, anti-inflammatory, heart health",
                tags: ["monounsaturated", "anti-inflammatory", "heart_health"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // MEXICAN CUISINE
            EnhancedFoodItem(
                name: "Black Beans",
                category: "Legumes",
                calories: 114,
                protein: 7.6,
                carbs: 20,
                fiber: 7.5,
                fat: 0.5,
                vitamins: ["B1": 0.2, "B6": 0.2, "Folate": 128],
                minerals: ["Iron": 2.1, "Magnesium": 60, "Zinc": 1.0],
                servingSize: "1/2 cup cooked",
                region: "Americas",
                cuisine: "Mexican",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["boiled", "spiced", "refried"],
                benefits: "High fiber, protein, iron, folate",
                tags: ["fiber", "protein", "iron", "folate"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Guacamole",
                category: "Dips",
                calories: 45,
                protein: 1,
                carbs: 3,
                fiber: 2,
                fat: 4,
                vitamins: ["C": 6, "E": 1.3, "K": 8.5],
                minerals: ["Potassium": 250, "Magnesium": 15],
                servingSize: "2 tbsp",
                region: "Americas",
                cuisine: "Mexican",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["mashed", "seasoned"],
                benefits: "Healthy fats, fiber, potassium, anti-inflammatory",
                tags: ["healthy_fats", "fiber", "potassium", "anti-inflammatory"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // EUROPEAN CUISINE
            EnhancedFoodItem(
                name: "Greek Yogurt",
                category: "Dairy",
                calories: 130,
                protein: 23,
                carbs: 9,
                fiber: 0,
                fat: 0.5,
                vitamins: ["B12": 0.6, "B2": 0.2, "D": 0.1],
                minerals: ["Calcium": 200, "Phosphorus": 135, "Zinc": 0.5],
                servingSize: "1 cup",
                region: "Europe",
                cuisine: "Greek",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["strained", "cultured"],
                benefits: "High protein, probiotics, calcium, easy to digest",
                tags: ["protein", "probiotics", "calcium", "dairy"],
                allergens: ["milk"],
                dietaryRestrictions: ["vegetarian", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // AFRICAN CUISINE
            EnhancedFoodItem(
                name: "Quinoa",
                category: "Grains",
                calories: 120,
                protein: 4.4,
                carbs: 22,
                fiber: 2.8,
                fat: 1.9,
                vitamins: ["B1": 0.1, "B6": 0.1, "E": 0.6],
                minerals: ["Iron": 1.5, "Magnesium": 64, "Zinc": 1.1],
                servingSize: "1/2 cup cooked",
                region: "South America",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["boiled", "steamed"],
                benefits: "Complete protein, gluten-free, high fiber",
                tags: ["complete_protein", "gluten_free", "fiber"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // COMMON VEGETABLES (Global)
            EnhancedFoodItem(
                name: "Broccoli",
                category: "Vegetables",
                calories: 55,
                protein: 3.7,
                carbs: 11,
                fiber: 5,
                fat: 0.6,
                vitamins: ["C": 89, "K": 101, "A": 623],
                minerals: ["Iron": 0.7, "Calcium": 47, "Potassium": 316],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["steamed", "roasted", "raw"],
                benefits: "High vitamin C, fiber, anti-inflammatory, cancer-fighting",
                tags: ["vitamin_c", "fiber", "anti-inflammatory", "cruciferous"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["fall", "winter", "spring"]
            ),
            
            EnhancedFoodItem(
                name: "Spinach",
                category: "Vegetables",
                calories: 23,
                protein: 2.9,
                carbs: 3.6,
                fiber: 2.2,
                fat: 0.4,
                vitamins: ["A": 2813, "C": 28, "K": 145, "Folate": 58],
                minerals: ["Iron": 3.6, "Calcium": 99, "Magnesium": 79],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["steamed", "sauteed", "raw"],
                benefits: "Iron, vitamin K, folate, anti-inflammatory",
                tags: ["iron", "vitamin_k", "folate", "leafy_greens"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["spring", "fall"]
            ),
            
            // COMMON FRUITS (Global)
            EnhancedFoodItem(
                name: "Banana",
                category: "Fruits",
                calories: 105,
                protein: 1.3,
                carbs: 27,
                fiber: 3.1,
                fat: 0.4,
                vitamins: ["B6": 0.4, "C": 10, "Folate": 24],
                minerals: ["Potassium": 422, "Magnesium": 32, "Manganese": 0.3],
                servingSize: "1 medium",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["raw", "frozen"],
                benefits: "Potassium, easy to digest, natural sugars, prebiotic",
                tags: ["potassium", "easy_digest", "prebiotic", "energy"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Blueberries",
                category: "Fruits",
                calories: 85,
                protein: 1.1,
                carbs: 21,
                fiber: 3.6,
                fat: 0.5,
                vitamins: ["C": 14, "K": 29, "E": 0.6],
                minerals: ["Manganese": 0.5, "Potassium": 114],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["raw", "frozen"],
                benefits: "Antioxidants, anti-inflammatory, fiber, vitamin C",
                tags: ["antioxidants", "anti-inflammatory", "fiber", "vitamin_c"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["summer", "fall"]
            ),
            
            // PROTEINS (Global)
            EnhancedFoodItem(
                name: "Salmon (Wild)",
                category: "Protein",
                calories: 206,
                protein: 22,
                carbs: 0,
                fiber: 0,
                fat: 12,
                vitamins: ["D": 11.1, "B12": 2.6, "B6": 0.9],
                minerals: ["Selenium": 36, "Phosphorus": 240, "Potassium": 363],
                servingSize: "3 oz",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["grilled", "baked", "poached"],
                benefits: "Omega-3 fatty acids, high protein, vitamin D",
                tags: ["omega3", "protein", "vitamin_d", "seafood"],
                allergens: ["fish"],
                dietaryRestrictions: ["gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Chicken Breast (Skinless)",
                category: "Protein",
                calories: 165,
                protein: 31,
                carbs: 0,
                fiber: 0,
                fat: 3.6,
                vitamins: ["B6": 0.6, "B12": 0.3, "Niacin": 13.7],
                minerals: ["Selenium": 22, "Phosphorus": 200, "Potassium": 256],
                servingSize: "3 oz",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["grilled", "baked", "poached"],
                benefits: "Lean protein, easy to digest, versatile",
                tags: ["lean_protein", "easy_digest", "versatile"],
                allergens: ["none"],
                dietaryRestrictions: ["gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // NUTS AND SEEDS (Global)
            EnhancedFoodItem(
                name: "Almonds",
                category: "Nuts",
                calories: 164,
                protein: 6,
                carbs: 6,
                fiber: 3.5,
                fat: 14,
                vitamins: ["E": 7.3, "B2": 0.3, "B1": 0.1],
                minerals: ["Magnesium": 76, "Calcium": 76, "Iron": 1.1],
                servingSize: "1/4 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["raw", "roasted"],
                benefits: "Vitamin E, healthy fats, protein, magnesium",
                tags: ["vitamin_e", "healthy_fats", "protein", "magnesium"],
                allergens: ["tree_nuts"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Chia Seeds",
                category: "Seeds",
                calories: 58,
                protein: 2,
                carbs: 5,
                fiber: 5,
                fat: 4.5,
                vitamins: ["B1": 0.1, "B3": 0.9],
                minerals: ["Calcium": 77, "Iron": 1.0, "Magnesium": 26],
                servingSize: "1 tbsp",
                region: "South America",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["raw", "soaked"],
                benefits: "Omega-3, fiber, protein, calcium",
                tags: ["omega3", "fiber", "protein", "calcium"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            // BEVERAGES
            EnhancedFoodItem(
                name: "Fruit Smoothie",
                category: "Beverages",
                calories: 180,
                protein: 3,
                carbs: 35,
                fiber: 4,
                fat: 1,
                vitamins: ["C": 45, "A": 120, "B6": 0.3],
                minerals: ["Potassium": 350, "Magnesium": 25],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["blended", "cold"],
                benefits: "Vitamins, antioxidants, hydration, easy to digest",
                tags: ["vitamins", "antioxidants", "hydration", "fruit"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Berry Smoothie",
                category: "Beverages",
                calories: 160,
                protein: 4,
                carbs: 30,
                fiber: 5,
                fat: 2,
                vitamins: ["C": 60, "K": 25, "E": 2],
                minerals: ["Potassium": 280, "Manganese": 0.8],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["blended", "cold"],
                benefits: "Antioxidants, fiber, vitamins, anti-inflammatory",
                tags: ["antioxidants", "fiber", "vitamins", "berries"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            ),
            
            EnhancedFoodItem(
                name: "Green Smoothie",
                category: "Beverages",
                calories: 120,
                protein: 3,
                carbs: 20,
                fiber: 6,
                fat: 1,
                vitamins: ["C": 35, "K": 150, "A": 200],
                minerals: ["Iron": 2.5, "Calcium": 80, "Magnesium": 40],
                servingSize: "1 cup",
                region: "Global",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["blended", "cold"],
                benefits: "Chlorophyll, vitamins, minerals, detoxifying",
                tags: ["chlorophyll", "vitamins", "minerals", "greens"],
                allergens: ["none"],
                dietaryRestrictions: ["vegan", "gluten-free"],
                seasonalAvailability: ["year-round"]
            )
        ]
    }
    
    func getFoodCategories() -> [String] {
        return Array(Set(allFoods.map { $0.category })).sorted()
    }
    
    func getCuisines() -> [String] {
        return Array(Set(allFoods.map { $0.cuisine })).sorted()
    }
    
    func getRegions() -> [String] {
        return Array(Set(allFoods.map { $0.region })).sorted()
    }
    
    func getFODMAPLevels() -> [String] {
        return Array(Set(allFoods.map { $0.fodmapLevel })).sorted()
    }
    
    func getFoodsByFODMAPLevel(_ level: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.fodmapLevel == level }
    }
    
    func getFoodsByPreparationMethod(_ method: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.preparationMethods.contains(method) }
    }
    
    func getFoodsByBenefit(_ benefit: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.benefits.lowercased().contains(benefit.lowercased()) }
    }
    
    func getFoodsByTag(_ tag: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.tags.contains(tag) }
    }
    
    func getFoodsByDietaryRestriction(_ restriction: String) -> [EnhancedFoodItem] {
        return allFoods.filter { $0.dietaryRestrictions.contains(restriction) }
    }
    
    func getFoodsByAllergen(_ allergen: String) -> [EnhancedFoodItem] {
        return allFoods.filter { !$0.allergens.contains(allergen) }
    }
    
    func calculateNutritionTotals(for foods: [EnhancedFoodItem]) -> (calories: Double, protein: Double, carbs: Double, fiber: Double, fat: Double) {
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        for food in foods {
            totalCalories += food.calories
            totalProtein += food.protein
            totalCarbs += food.carbs
            totalFiber += food.fiber
            totalFat += food.fat
        }
        
        return (totalCalories, totalProtein, totalCarbs, totalFiber, totalFat)
    }
    
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
} 