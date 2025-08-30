import Foundation

// Compound Food Item that contains multiple ingredients
struct CompoundFoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let ingredients: [FoodIngredient]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFiber: Double
    let totalFat: Double
    let servingSize: String
    let cuisine: String
    let ibdFriendly: Bool
    let fodmapLevel: String
    let preparationMethods: [String]
    let benefits: String
    let tags: [String]
    
    init(id: UUID = UUID(), name: String, category: String, ingredients: [FoodIngredient], totalCalories: Double, totalProtein: Double, totalCarbs: Double, totalFiber: Double, totalFat: Double, servingSize: String, cuisine: String, ibdFriendly: Bool, fodmapLevel: String, preparationMethods: [String], benefits: String, tags: [String]) {
        self.id = id
        self.name = name
        self.category = category
        self.ingredients = ingredients
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFiber = totalFiber
        self.totalFat = totalFat
        self.servingSize = servingSize
        self.cuisine = cuisine
        self.ibdFriendly = ibdFriendly
        self.fodmapLevel = fodmapLevel
        self.preparationMethods = preparationMethods
        self.benefits = benefits
        self.tags = tags
    }
    
    var displayName: String {
        return "\(name) (\(servingSize))"
    }
    
    var nutritionSummary: String {
        return "Cal: \(Int(totalCalories)), P: \(totalProtein)g, C: \(totalCarbs)g, F: \(totalFiber)g, Fat: \(totalFat)g"
    }
}

// Individual food ingredient within a compound dish
struct FoodIngredient: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let fat: Double
    let category: String
    
    init(id: UUID = UUID(), name: String, quantity: Double, unit: String, calories: Double, protein: Double, carbs: Double, fiber: Double, fat: Double, category: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fiber = fiber
        self.fat = fat
        self.category = category
    }
}

class CompoundFoodDatabase: ObservableObject {
    static let shared = CompoundFoodDatabase()
    
    @Published var compoundFoods: [CompoundFoodItem]
    @Published var searchResults: [CompoundFoodItem]
    
    private init() {
        self.compoundFoods = []
        self.searchResults = []
        loadCompoundFoodDatabase()
    }
    
    func searchCompoundFoods(query: String) -> [CompoundFoodItem] {
        if query.isEmpty {
            return []
        }
        
        let lowercasedQuery = query.lowercased()
        return compoundFoods.filter { food in
            food.name.lowercased().contains(lowercasedQuery) ||
            food.category.lowercased().contains(lowercasedQuery) ||
            food.cuisine.lowercased().contains(lowercasedQuery) ||
            food.tags.contains { $0.lowercased().contains(lowercasedQuery) } ||
            food.ingredients.contains { $0.name.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func getCompoundFoodsByCategory(_ category: String) -> [CompoundFoodItem] {
        return compoundFoods.filter { $0.category == category }
    }
    
    func getCompoundFoodsByCuisine(_ cuisine: String) -> [CompoundFoodItem] {
        return compoundFoods.filter { $0.cuisine == cuisine }
    }
    
    private func loadCompoundFoodDatabase() {
        compoundFoods = [
            // SANDWICHES
            CompoundFoodItem(
                name: "Egg Sandwich",
                category: "Sandwiches",
                ingredients: [
                    FoodIngredient(name: "Bread", quantity: 2, unit: "slices", calories: 160, protein: 6, carbs: 30, fiber: 2, fat: 2, category: "Grains"),
                    FoodIngredient(name: "Eggs", quantity: 2, unit: "large", calories: 155, protein: 12.6, carbs: 1.1, fiber: 0, fat: 10.6, category: "Protein"),
                    FoodIngredient(name: "Mayonnaise", quantity: 1, unit: "tbsp", calories: 90, protein: 0, carbs: 0, fiber: 0, fat: 10, category: "Fats"),
                    FoodIngredient(name: "Lettuce", quantity: 0.5, unit: "cup", calories: 8, protein: 0.5, carbs: 1.5, fiber: 0.5, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 2, unit: "slices", calories: 10, protein: 0.5, carbs: 2, fiber: 0.5, fat: 0.1, category: "Vegetables")
                ],
                totalCalories: 423,
                totalProtein: 19.6,
                totalCarbs: 34.6,
                totalFiber: 3.0,
                totalFat: 22.8,
                servingSize: "1 sandwich",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["toasted", "grilled"],
                benefits: "Complete protein, fiber, vitamins from vegetables",
                tags: ["protein", "fiber", "breakfast", "lunch"]
            ),
            
            CompoundFoodItem(
                name: "Chicken Sandwich",
                category: "Sandwiches",
                ingredients: [
                    FoodIngredient(name: "Bread", quantity: 2, unit: "slices", calories: 160, protein: 6, carbs: 30, fiber: 2, fat: 2, category: "Grains"),
                    FoodIngredient(name: "Chicken Breast", quantity: 3, unit: "oz", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, category: "Protein"),
                    FoodIngredient(name: "Mayonnaise", quantity: 1, unit: "tbsp", calories: 90, protein: 0, carbs: 0, fiber: 0, fat: 10, category: "Fats"),
                    FoodIngredient(name: "Lettuce", quantity: 0.5, unit: "cup", calories: 8, protein: 0.5, carbs: 1.5, fiber: 0.5, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 2, unit: "slices", calories: 10, protein: 0.5, carbs: 2, fiber: 0.5, fat: 0.1, category: "Vegetables")
                ],
                totalCalories: 433,
                totalProtein: 37.5,
                totalCarbs: 33.5,
                totalFiber: 3.0,
                totalFat: 15.8,
                servingSize: "1 sandwich",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["grilled", "toasted"],
                benefits: "High protein, lean meat, fiber from vegetables",
                tags: ["protein", "lean_meat", "lunch", "dinner"]
            ),
            
            CompoundFoodItem(
                name: "Turkey Sandwich",
                category: "Sandwiches",
                ingredients: [
                    FoodIngredient(name: "Bread", quantity: 2, unit: "slices", calories: 160, protein: 6, carbs: 30, fiber: 2, fat: 2, category: "Grains"),
                    FoodIngredient(name: "Turkey", quantity: 3, unit: "oz", calories: 135, protein: 25, carbs: 0, fiber: 0, fat: 3, category: "Protein"),
                    FoodIngredient(name: "Cheese", quantity: 1, unit: "slice", calories: 110, protein: 7, carbs: 1, fiber: 0, fat: 9, category: "Dairy"),
                    FoodIngredient(name: "Lettuce", quantity: 0.5, unit: "cup", calories: 8, protein: 0.5, carbs: 1.5, fiber: 0.5, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Mayonnaise", quantity: 1, unit: "tbsp", calories: 90, protein: 0, carbs: 0, fiber: 0, fat: 10, category: "Fats")
                ],
                totalCalories: 503,
                totalProtein: 38.5,
                totalCarbs: 32.5,
                totalFiber: 2.5,
                totalFat: 24.1,
                servingSize: "1 sandwich",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["toasted", "cold"],
                benefits: "Lean protein, calcium from cheese, fiber",
                tags: ["lean_protein", "calcium", "lunch", "dinner"]
            ),
            
            // SALADS
            CompoundFoodItem(
                name: "Chicken Salad",
                category: "Salads",
                ingredients: [
                    FoodIngredient(name: "Chicken Breast", quantity: 3, unit: "oz", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, category: "Protein"),
                    FoodIngredient(name: "Lettuce", quantity: 2, unit: "cups", calories: 16, protein: 1, carbs: 3, fiber: 1, fat: 0.2, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 1, unit: "medium", calories: 22, protein: 1.1, carbs: 4.8, fiber: 1.2, fat: 0.2, category: "Vegetables"),
                    FoodIngredient(name: "Cucumber", quantity: 0.5, unit: "cup", calories: 8, protein: 0.4, carbs: 1.8, fiber: 0.3, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Olive Oil", quantity: 1, unit: "tbsp", calories: 120, protein: 0, carbs: 0, fiber: 0, fat: 14, category: "Fats")
                ],
                totalCalories: 331,
                totalProtein: 33.5,
                totalCarbs: 9.6,
                totalFiber: 2.5,
                totalFat: 17.9,
                servingSize: "1 bowl",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["mixed", "fresh"],
                benefits: "High protein, fiber, healthy fats, vitamins",
                tags: ["protein", "fiber", "healthy_fats", "vitamins"]
            ),
            
            CompoundFoodItem(
                name: "Greek Salad",
                category: "Salads",
                ingredients: [
                    FoodIngredient(name: "Lettuce", quantity: 2, unit: "cups", calories: 16, protein: 1, carbs: 3, fiber: 1, fat: 0.2, category: "Vegetables"),
                    FoodIngredient(name: "Feta Cheese", quantity: 0.25, unit: "cup", calories: 75, protein: 4, carbs: 1, fiber: 0, fat: 6, category: "Dairy"),
                    FoodIngredient(name: "Olives", quantity: 0.25, unit: "cup", calories: 40, protein: 0.5, carbs: 1, fiber: 0.5, fat: 4, category: "Fats"),
                    FoodIngredient(name: "Tomato", quantity: 1, unit: "medium", calories: 22, protein: 1.1, carbs: 4.8, fiber: 1.2, fat: 0.2, category: "Vegetables"),
                    FoodIngredient(name: "Cucumber", quantity: 0.5, unit: "cup", calories: 8, protein: 0.4, carbs: 1.8, fiber: 0.3, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Olive Oil", quantity: 1, unit: "tbsp", calories: 120, protein: 0, carbs: 0, fiber: 0, fat: 14, category: "Fats")
                ],
                totalCalories: 281,
                totalProtein: 7.0,
                totalCarbs: 11.6,
                totalFiber: 3.0,
                totalFat: 24.5,
                servingSize: "1 bowl",
                cuisine: "Mediterranean",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["mixed", "fresh"],
                benefits: "Healthy fats, calcium, fiber, anti-inflammatory",
                tags: ["healthy_fats", "calcium", "fiber", "anti-inflammatory"]
            ),
            
            // BREAKFAST DISHES
            CompoundFoodItem(
                name: "Oatmeal with Berries",
                category: "Breakfast",
                ingredients: [
                    FoodIngredient(name: "Oatmeal", quantity: 1, unit: "cup cooked", calories: 150, protein: 5, carbs: 27, fiber: 4, fat: 3, category: "Grains"),
                    FoodIngredient(name: "Blueberries", quantity: 0.5, unit: "cup", calories: 42, protein: 0.5, carbs: 10.5, fiber: 1.8, fat: 0.2, category: "Fruits"),
                    FoodIngredient(name: "Strawberries", quantity: 0.5, unit: "cup", calories: 24, protein: 0.5, carbs: 6, fiber: 1.5, fat: 0.2, category: "Fruits"),
                    FoodIngredient(name: "Honey", quantity: 1, unit: "tsp", calories: 21, protein: 0, carbs: 5.5, fiber: 0, fat: 0, category: "Sweeteners")
                ],
                totalCalories: 237,
                totalProtein: 6.0,
                totalCarbs: 49.0,
                totalFiber: 7.3,
                totalFat: 3.4,
                servingSize: "1 bowl",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["cooked", "topped"],
                benefits: "High fiber, antioxidants, sustained energy",
                tags: ["fiber", "antioxidants", "energy", "breakfast"]
            ),
            
            CompoundFoodItem(
                name: "Yogurt Parfait",
                category: "Breakfast",
                ingredients: [
                    FoodIngredient(name: "Greek Yogurt", quantity: 1, unit: "cup", calories: 130, protein: 23, carbs: 9, fiber: 0, fat: 0.5, category: "Dairy"),
                    FoodIngredient(name: "Granola", quantity: 0.25, unit: "cup", calories: 120, protein: 3, carbs: 18, fiber: 2, fat: 4, category: "Grains"),
                    FoodIngredient(name: "Banana", quantity: 0.5, unit: "medium", calories: 52, protein: 0.6, carbs: 13.5, fiber: 1.5, fat: 0.2, category: "Fruits"),
                    FoodIngredient(name: "Honey", quantity: 1, unit: "tsp", calories: 21, protein: 0, carbs: 5.5, fiber: 0, fat: 0, category: "Sweeteners")
                ],
                totalCalories: 323,
                totalProtein: 26.6,
                totalCarbs: 46.0,
                totalFiber: 3.5,
                totalFat: 4.7,
                servingSize: "1 parfait",
                cuisine: "International",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["layered", "chilled"],
                benefits: "High protein, probiotics, fiber, potassium",
                tags: ["protein", "probiotics", "fiber", "potassium"]
            ),
            
            // ASIAN DISHES
            CompoundFoodItem(
                name: "Sushi Roll (California)",
                category: "Asian",
                ingredients: [
                    FoodIngredient(name: "Sushi Rice", quantity: 0.5, unit: "cup", calories: 102, protein: 2.1, carbs: 22.5, fiber: 0.3, fat: 0.2, category: "Grains"),
                    FoodIngredient(name: "Crab Meat", quantity: 1, unit: "oz", calories: 25, protein: 5, carbs: 0, fiber: 0, fat: 0.5, category: "Seafood"),
                    FoodIngredient(name: "Avocado", quantity: 0.25, unit: "medium", calories: 40, protein: 0.5, carbs: 2.2, fiber: 1.7, fat: 3.7, category: "Fruits"),
                    FoodIngredient(name: "Cucumber", quantity: 0.25, unit: "cup", calories: 4, protein: 0.2, carbs: 0.9, fiber: 0.1, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Nori", quantity: 1, unit: "sheet", calories: 5, protein: 1, carbs: 0.5, fiber: 0.5, fat: 0, category: "Seaweed")
                ],
                totalCalories: 176,
                totalProtein: 8.8,
                totalCarbs: 26.1,
                totalFiber: 2.6,
                totalFat: 4.5,
                servingSize: "1 roll (6 pieces)",
                cuisine: "Japanese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["rolled", "fresh"],
                benefits: "Omega-3, fiber, protein, vitamins",
                tags: ["omega3", "fiber", "protein", "seafood"]
            ),
            
            CompoundFoodItem(
                name: "Buddha Bowl",
                category: "Asian",
                ingredients: [
                    FoodIngredient(name: "Quinoa", quantity: 0.5, unit: "cup cooked", calories: 120, protein: 4.4, carbs: 22, fiber: 2.8, fat: 1.9, category: "Grains"),
                    FoodIngredient(name: "Tofu", quantity: 0.25, unit: "cup", calories: 40, protein: 4, carbs: 1, fiber: 0.2, fat: 2.2, category: "Protein"),
                    FoodIngredient(name: "Broccoli", quantity: 0.5, unit: "cup", calories: 27, protein: 1.8, carbs: 5.5, fiber: 2.5, fat: 0.3, category: "Vegetables"),
                    FoodIngredient(name: "Carrots", quantity: 0.5, unit: "cup", calories: 26, protein: 0.6, carbs: 6, fiber: 1.8, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Sesame Oil", quantity: 1, unit: "tsp", calories: 40, protein: 0, carbs: 0, fiber: 0, fat: 4.5, category: "Fats")
                ],
                totalCalories: 253,
                totalProtein: 10.8,
                totalCarbs: 34.5,
                totalFiber: 7.8,
                totalFat: 9.0,
                servingSize: "1 bowl",
                cuisine: "Asian",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["steamed", "mixed"],
                benefits: "Complete protein, fiber, vitamins, minerals",
                tags: ["complete_protein", "fiber", "vitamins", "minerals"]
            ),
            
            // MEXICAN DISHES
            CompoundFoodItem(
                name: "Taco Bowl",
                category: "Mexican",
                ingredients: [
                    FoodIngredient(name: "Brown Rice", quantity: 0.5, unit: "cup cooked", calories: 108, protein: 2.5, carbs: 22, fiber: 1.8, fat: 0.9, category: "Grains"),
                    FoodIngredient(name: "Black Beans", quantity: 0.25, unit: "cup", calories: 57, protein: 3.8, carbs: 10, fiber: 3.7, fat: 0.2, category: "Legumes"),
                    FoodIngredient(name: "Ground Turkey", quantity: 2, unit: "oz", calories: 90, protein: 17, carbs: 0, fiber: 0, fat: 2, category: "Protein"),
                    FoodIngredient(name: "Lettuce", quantity: 1, unit: "cup", calories: 8, protein: 0.5, carbs: 1.5, fiber: 0.5, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 0.5, unit: "medium", calories: 11, protein: 0.5, carbs: 2.4, fiber: 0.6, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Avocado", quantity: 0.25, unit: "medium", calories: 40, protein: 0.5, carbs: 2.2, fiber: 1.7, fat: 3.7, category: "Fruits")
                ],
                totalCalories: 314,
                totalProtein: 24.3,
                totalCarbs: 38.1,
                totalFiber: 8.3,
                totalFat: 7.0,
                servingSize: "1 bowl",
                cuisine: "Mexican",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["layered", "mixed"],
                benefits: "High protein, fiber, healthy fats, vitamins",
                tags: ["protein", "fiber", "healthy_fats", "vitamins"]
            ),
            
            // MEDITERRANEAN DISHES
            CompoundFoodItem(
                name: "Mediterranean Plate",
                category: "Mediterranean",
                ingredients: [
                    FoodIngredient(name: "Hummus", quantity: 2, unit: "tbsp", calories: 50, protein: 2.4, carbs: 6, fiber: 1.6, fat: 2.4, category: "Dips"),
                    FoodIngredient(name: "Pita Bread", quantity: 1, unit: "piece", calories: 165, protein: 5.5, carbs: 33, fiber: 1.2, fat: 0.8, category: "Grains"),
                    FoodIngredient(name: "Feta Cheese", quantity: 0.25, unit: "cup", calories: 75, protein: 4, carbs: 1, fiber: 0, fat: 6, category: "Dairy"),
                    FoodIngredient(name: "Olives", quantity: 0.25, unit: "cup", calories: 40, protein: 0.5, carbs: 1, fiber: 0.5, fat: 4, category: "Fats"),
                    FoodIngredient(name: "Cucumber", quantity: 0.5, unit: "cup", calories: 8, protein: 0.4, carbs: 1.8, fiber: 0.3, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 0.5, unit: "medium", calories: 11, protein: 0.5, carbs: 2.4, fiber: 0.6, fat: 0.1, category: "Vegetables")
                ],
                totalCalories: 349,
                totalProtein: 12.8,
                totalCarbs: 44.2,
                totalFiber: 4.2,
                totalFat: 13.4,
                servingSize: "1 plate",
                cuisine: "Mediterranean",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["assembled", "fresh"],
                benefits: "Fiber, protein, healthy fats, calcium",
                tags: ["fiber", "protein", "healthy_fats", "calcium"]
            ),
            
            // INTERNATIONAL COMPOUND DISHES
            CompoundFoodItem(
                name: "Crepe",
                category: "French",
                ingredients: [
                    FoodIngredient(name: "Flour", quantity: 0.5, unit: "cup", calories: 200, protein: 6, carbs: 42, fiber: 1.5, fat: 0.5, category: "Grains"),
                    FoodIngredient(name: "Eggs", quantity: 1, unit: "large", calories: 77, protein: 6, carbs: 0, fiber: 0, fat: 5, category: "Protein"),
                    FoodIngredient(name: "Milk", quantity: 0.5, unit: "cup", calories: 51, protein: 4, carbs: 6, fiber: 0, fat: 1.2, category: "Dairy"),
                    FoodIngredient(name: "Butter", quantity: 1, unit: "tbsp", calories: 102, protein: 0.1, carbs: 0, fiber: 0, fat: 12, category: "Fats")
                ],
                totalCalories: 430,
                totalProtein: 16.1,
                totalCarbs: 48,
                totalFiber: 1.5,
                totalFat: 18.7,
                servingSize: "1 crepe",
                cuisine: "French",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["batter", "cooked", "filled"],
                benefits: "Light, versatile, easy to digest",
                tags: ["french", "breakfast", "dessert", "versatile"]
            ),
            
            CompoundFoodItem(
                name: "Pad Thai",
                category: "Thai",
                ingredients: [
                    FoodIngredient(name: "Rice Noodles", quantity: 1, unit: "cup", calories: 190, protein: 7, carbs: 37, fiber: 2, fat: 1, category: "Grains"),
                    FoodIngredient(name: "Chicken", quantity: 2, unit: "oz", calories: 110, protein: 20.7, carbs: 0, fiber: 0, fat: 2.4, category: "Protein"),
                    FoodIngredient(name: "Eggs", quantity: 1, unit: "large", calories: 77, protein: 6, carbs: 0, fiber: 0, fat: 5, category: "Protein"),
                    FoodIngredient(name: "Bean Sprouts", quantity: 0.5, unit: "cup", calories: 8, protein: 1, carbs: 1.5, fiber: 0.5, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Peanuts", quantity: 0.25, unit: "cup", calories: 207, protein: 9, carbs: 6, fiber: 3, fat: 18, category: "Nuts"),
                    FoodIngredient(name: "Tamarind Sauce", quantity: 1, unit: "tbsp", calories: 20, protein: 0.5, carbs: 4, fiber: 0.5, fat: 0, category: "Sauces")
                ],
                totalCalories: 612,
                totalProtein: 43.2,
                totalCarbs: 54.5,
                totalFiber: 6,
                totalFat: 26.5,
                servingSize: "1 serving",
                cuisine: "Thai",
                ibdFriendly: true,
                fodmapLevel: "medium",
                preparationMethods: ["stir-fried", "noodles", "sauce"],
                benefits: "Protein, vegetables, balanced meal",
                tags: ["thai", "noodles", "stir-fry", "protein"]
            ),
            
            CompoundFoodItem(
                name: "Rice Biryani",
                category: "Indian",
                ingredients: [
                    FoodIngredient(name: "Basmati Rice", quantity: 1, unit: "cup", calories: 205, protein: 4.3, carbs: 45, fiber: 0.6, fat: 0.4, category: "Grains"),
                    FoodIngredient(name: "Chicken", quantity: 3, unit: "oz", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, category: "Protein"),
                    FoodIngredient(name: "Yogurt", quantity: 0.25, unit: "cup", calories: 37.5, protein: 2, carbs: 3, fiber: 0, fat: 2, category: "Dairy"),
                    FoodIngredient(name: "Onions", quantity: 0.5, unit: "medium", calories: 22, protein: 0.6, carbs: 5, fiber: 0.9, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Ghee", quantity: 1, unit: "tbsp", calories: 120, protein: 0, carbs: 0, fiber: 0, fat: 14, category: "Fats"),
                    FoodIngredient(name: "Spices", quantity: 1, unit: "tsp", calories: 5, protein: 0.2, carbs: 1, fiber: 0.5, fat: 0.1, category: "Spices")
                ],
                totalCalories: 554.5,
                totalProtein: 38.1,
                totalCarbs: 54,
                totalFiber: 2,
                totalFat: 20.2,
                servingSize: "1 serving",
                cuisine: "Indian",
                ibdFriendly: true,
                fodmapLevel: "medium",
                preparationMethods: ["layered", "spiced", "steamed"],
                benefits: "Aromatic, flavorful, complete meal",
                tags: ["indian", "rice", "spices", "aromatic"]
            ),
            
            CompoundFoodItem(
                name: "Chicken Shawarma",
                category: "Middle Eastern",
                ingredients: [
                    FoodIngredient(name: "Pita Bread", quantity: 1, unit: "piece", calories: 165, protein: 5.5, carbs: 33, fiber: 1.2, fat: 0.8, category: "Grains"),
                    FoodIngredient(name: "Chicken", quantity: 3, unit: "oz", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, category: "Protein"),
                    FoodIngredient(name: "Tahini Sauce", quantity: 1, unit: "tbsp", calories: 89, protein: 2.6, carbs: 3.2, fiber: 1.4, fat: 8, category: "Sauces"),
                    FoodIngredient(name: "Lettuce", quantity: 0.25, unit: "cup", calories: 4, protein: 0.2, carbs: 0.8, fiber: 0.2, fat: 0.1, category: "Vegetables"),
                    FoodIngredient(name: "Tomato", quantity: 0.25, unit: "medium", calories: 5.5, protein: 0.3, carbs: 1.2, fiber: 0.3, fat: 0.1, category: "Vegetables")
                ],
                totalCalories: 428.5,
                totalProtein: 39.6,
                totalCarbs: 38.2,
                totalFiber: 3.1,
                totalFat: 12.6,
                servingSize: "1 wrap",
                cuisine: "Lebanese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["marinated", "grilled", "wrapped"],
                benefits: "High protein, flavorful, portable",
                tags: ["middle_eastern", "chicken", "wrap", "protein"]
            ),
            
            CompoundFoodItem(
                name: "Baked Red Beans with Pita",
                category: "Mediterranean",
                ingredients: [
                    FoodIngredient(name: "Baked Red Beans", quantity: 1, unit: "cup", calories: 225, protein: 15, carbs: 40, fiber: 15, fat: 1, category: "Legumes"),
                    FoodIngredient(name: "Pita Bread", quantity: 1, unit: "piece", calories: 165, protein: 5.5, carbs: 33, fiber: 1.2, fat: 0.8, category: "Grains")
                ],
                totalCalories: 390,
                totalProtein: 20.5,
                totalCarbs: 73,
                totalFiber: 16.2,
                totalFat: 1.8,
                servingSize: "1 serving",
                cuisine: "Mediterranean",
                ibdFriendly: true,
                fodmapLevel: "medium",
                preparationMethods: ["baked", "served", "traditional"],
                benefits: "High protein, fiber, iron, traditional",
                tags: ["mediterranean", "beans", "pita", "protein", "fiber"]
            ),
            
            CompoundFoodItem(
                name: "Miso Soup",
                category: "Soups",
                ingredients: [
                    FoodIngredient(name: "Miso Paste", quantity: 1, unit: "tbsp", calories: 25, protein: 2, carbs: 3, fiber: 1, fat: 1, category: "Fermented"),
                    FoodIngredient(name: "Dashi Stock", quantity: 1, unit: "cup", calories: 5, protein: 0, carbs: 0, fiber: 0, fat: 0, category: "Broth"),
                    FoodIngredient(name: "Tofu", quantity: 0.25, unit: "cup", calories: 50, protein: 5, carbs: 1, fiber: 0, fat: 3, category: "Protein"),
                    FoodIngredient(name: "Seaweed", quantity: 0.1, unit: "cup", calories: 5, protein: 1, carbs: 0, fiber: 0, fat: 0, category: "Vegetables")
                ],
                totalCalories: 85,
                totalProtein: 8,
                totalCarbs: 4,
                totalFiber: 1,
                totalFat: 4,
                servingSize: "1 bowl",
                cuisine: "Japanese",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["fermented", "soup", "traditional"],
                benefits: "Probiotics, low calorie, easy to digest",
                tags: ["japanese", "soup", "fermented", "probiotic"]
            ),
            
            CompoundFoodItem(
                name: "Ramen",
                category: "Soups",
                ingredients: [
                    FoodIngredient(name: "Ramen Noodles", quantity: 1, unit: "pack", calories: 300, protein: 10, carbs: 55, fiber: 2, fat: 8, category: "Grains"),
                    FoodIngredient(name: "Broth", quantity: 1, unit: "cup", calories: 50, protein: 2, carbs: 2, fiber: 0, fat: 2, category: "Broth"),
                    FoodIngredient(name: "Egg", quantity: 1, unit: "piece", calories: 70, protein: 6, carbs: 0, fiber: 0, fat: 5, category: "Protein"),
                    FoodIngredient(name: "Green Onions", quantity: 0.1, unit: "cup", calories: 5, protein: 0, carbs: 1, fiber: 0, fat: 0, category: "Vegetables")
                ],
                totalCalories: 425,
                totalProtein: 18,
                totalCarbs: 58,
                totalFiber: 2,
                totalFat: 15,
                servingSize: "1 bowl",
                cuisine: "Japanese",
                ibdFriendly: false,
                fodmapLevel: "high",
                preparationMethods: ["noodles", "soup", "toppings"],
                benefits: "High energy, protein, warming",
                tags: ["japanese", "noodles", "soup", "comfort"]
            ),
            
            CompoundFoodItem(
                name: "Mac and Cheese",
                category: "American",
                ingredients: [
                    FoodIngredient(name: "Macaroni", quantity: 1, unit: "cup", calories: 200, protein: 7, carbs: 40, fiber: 2, fat: 1, category: "Grains"),
                    FoodIngredient(name: "Cheese", quantity: 0.5, unit: "cup", calories: 110, protein: 7, carbs: 1, fiber: 0, fat: 9, category: "Dairy"),
                    FoodIngredient(name: "Milk", quantity: 0.25, unit: "cup", calories: 26, protein: 2, carbs: 3, fiber: 0, fat: 1.2, category: "Dairy"),
                    FoodIngredient(name: "Butter", quantity: 1, unit: "tbsp", calories: 102, protein: 0.1, carbs: 0, fiber: 0, fat: 12, category: "Fats")
                ],
                totalCalories: 438,
                totalProtein: 16.1,
                totalCarbs: 44,
                totalFiber: 2,
                totalFat: 23.2,
                servingSize: "1 cup",
                cuisine: "American",
                ibdFriendly: true,
                fodmapLevel: "low",
                preparationMethods: ["boiled", "creamy", "baked"],
                benefits: "Comfort food, calcium, protein",
                tags: ["american", "comfort_food", "pasta", "cheese"]
            )
        ]
    }
    
    func getCompoundFoodCategories() -> [String] {
        return Array(Set(compoundFoods.map { $0.category })).sorted()
    }
    
    func getCompoundFoodCuisines() -> [String] {
        return Array(Set(compoundFoods.map { $0.cuisine })).sorted()
    }
    

    

    
    func getCompoundFoodsByTag(_ tag: String) -> [CompoundFoodItem] {
        return compoundFoods.filter { $0.tags.contains(tag) }
    }
    
    func getCompoundFoodsByFODMAPLevel(_ level: String) -> [CompoundFoodItem] {
        return compoundFoods.filter { $0.fodmapLevel == level }
    }
    
    func getIBDFriendlyCompoundFoods() -> [CompoundFoodItem] {
        return compoundFoods.filter { $0.ibdFriendly }
    }
    
    func calculateNutritionTotals(for foods: [CompoundFoodItem]) -> (calories: Double, protein: Double, carbs: Double, fiber: Double, fat: Double) {
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        for food in foods {
            totalCalories += food.totalCalories
            totalProtein += food.totalProtein
            totalCarbs += food.totalCarbs
            totalFiber += food.totalFiber
            totalFat += food.totalFat
        }
        
        return (totalCalories, totalProtein, totalCarbs, totalFiber, totalFat)
    }
    
    func getIngredientsForCompoundFood(_ foodName: String) -> [FoodIngredient]? {
        if let food = compoundFoods.first(where: { $0.name.lowercased() == foodName.lowercased() }) {
            return food.ingredients
        }
        return nil
    }
    
    func searchByIngredient(_ ingredientName: String) -> [CompoundFoodItem] {
        return compoundFoods.filter { food in
            food.ingredients.contains { $0.name.lowercased().contains(ingredientName.lowercased()) }
        }
    }
} 