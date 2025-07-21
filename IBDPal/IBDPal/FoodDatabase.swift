import Foundation

struct DatabaseFoodItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let fat: Double
    let servingSize: String
    let region: String
    
    var displayName: String {
        return "\(name) (\(servingSize))"
    }
}

class FoodDatabase: ObservableObject {
    static let shared = FoodDatabase()
    
    @Published var allFoods: [DatabaseFoodItem]
    @Published var searchResults: [DatabaseFoodItem]
    
    private init() {
        self.allFoods = []
        self.searchResults = []
        loadFoodDatabase()
    }
    
    func searchFoods(query: String) -> [DatabaseFoodItem] {
        if query.isEmpty {
            return []
        }
        
        let lowercasedQuery = query.lowercased()
        return allFoods.filter { food in
            food.name.lowercased().contains(lowercasedQuery) ||
            food.category.lowercased().contains(lowercasedQuery) ||
            food.region.lowercased().contains(lowercasedQuery)
        }
    }
    
    private func loadFoodDatabase() {
        allFoods = [
            // Breakfast Foods
            DatabaseFoodItem(name: "Eggs", category: "Breakfast", calories: 155, protein: 12.6, carbs: 1.1, fiber: 0, fat: 10.6, servingSize: "2 large eggs", region: "Global"),
            DatabaseFoodItem(name: "Oatmeal", category: "Breakfast", calories: 150, protein: 5, carbs: 27, fiber: 4, fat: 3, servingSize: "1 cup cooked", region: "Global"),
            DatabaseFoodItem(name: "Greek Yogurt", category: "Breakfast", calories: 130, protein: 23, carbs: 9, fiber: 0, fat: 0.5, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Banana", category: "Fruits", calories: 105, protein: 1.3, carbs: 27, fiber: 3.1, fat: 0.4, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Toast", category: "Breakfast", calories: 75, protein: 3, carbs: 14, fiber: 1, fat: 1, servingSize: "1 slice", region: "Global"),
            DatabaseFoodItem(name: "Avocado", category: "Fruits", calories: 160, protein: 2, carbs: 9, fiber: 7, fat: 15, servingSize: "1 medium", region: "Global"),
            
            // Asian Foods
            DatabaseFoodItem(name: "Rice", category: "Grains", calories: 205, protein: 4.3, carbs: 45, fiber: 0.6, fat: 0.4, servingSize: "1 cup cooked", region: "Asia"),
            DatabaseFoodItem(name: "Noodles", category: "Grains", calories: 190, protein: 7, carbs: 37, fiber: 2, fat: 1, servingSize: "1 cup cooked", region: "Asia"),
            DatabaseFoodItem(name: "Tofu", category: "Protein", calories: 80, protein: 8, carbs: 2, fiber: 0.5, fat: 4.5, servingSize: "1/2 cup", region: "Asia"),
            DatabaseFoodItem(name: "Miso Soup", category: "Soup", calories: 35, protein: 2, carbs: 4, fiber: 1, fat: 1, servingSize: "1 cup", region: "Asia"),
            DatabaseFoodItem(name: "Sushi", category: "Seafood", calories: 150, protein: 6, carbs: 30, fiber: 0.5, fat: 0.5, servingSize: "1 roll", region: "Asia"),
            DatabaseFoodItem(name: "Kimchi", category: "Vegetables", calories: 23, protein: 2, carbs: 4, fiber: 2, fat: 0.5, servingSize: "1/2 cup", region: "Asia"),
            
            // Mediterranean Foods
            DatabaseFoodItem(name: "Olive Oil", category: "Fats", calories: 120, protein: 0, carbs: 0, fiber: 0, fat: 14, servingSize: "1 tbsp", region: "Mediterranean"),
            DatabaseFoodItem(name: "Hummus", category: "Dips", calories: 25, protein: 1.2, carbs: 3, fiber: 0.8, fat: 1.2, servingSize: "2 tbsp", region: "Mediterranean"),
            DatabaseFoodItem(name: "Falafel", category: "Protein", calories: 85, protein: 3, carbs: 12, fiber: 2, fat: 3, servingSize: "2 pieces", region: "Mediterranean"),
            DatabaseFoodItem(name: "Feta Cheese", category: "Dairy", calories: 75, protein: 4, carbs: 1, fiber: 0, fat: 6, servingSize: "1/4 cup", region: "Mediterranean"),
            DatabaseFoodItem(name: "Couscous", category: "Grains", calories: 175, protein: 6, carbs: 36, fiber: 2, fat: 0.3, servingSize: "1 cup cooked", region: "Mediterranean"),
            
            // Indian Foods
            DatabaseFoodItem(name: "Lentils", category: "Legumes", calories: 115, protein: 9, carbs: 20, fiber: 8, fat: 0.4, servingSize: "1/2 cup cooked", region: "India"),
            DatabaseFoodItem(name: "Chickpeas", category: "Legumes", calories: 135, protein: 7, carbs: 22, fiber: 6, fat: 2, servingSize: "1/2 cup cooked", region: "India"),
            DatabaseFoodItem(name: "Basmati Rice", category: "Grains", calories: 205, protein: 4.3, carbs: 45, fiber: 0.6, fat: 0.4, servingSize: "1 cup cooked", region: "India"),
            DatabaseFoodItem(name: "Paneer", category: "Dairy", calories: 100, protein: 4, carbs: 1, fiber: 0, fat: 8, servingSize: "1/4 cup", region: "India"),
            DatabaseFoodItem(name: "Yogurt", category: "Dairy", calories: 150, protein: 8, carbs: 12, fiber: 0, fat: 8, servingSize: "1 cup", region: "India"),
            
            // Mexican Foods
            DatabaseFoodItem(name: "Black Beans", category: "Legumes", calories: 114, protein: 7.6, carbs: 20, fiber: 7.5, fat: 0.5, servingSize: "1/2 cup cooked", region: "Mexico"),
            DatabaseFoodItem(name: "Corn Tortilla", category: "Grains", calories: 60, protein: 2, carbs: 12, fiber: 1, fat: 0.5, servingSize: "1 tortilla", region: "Mexico"),
            DatabaseFoodItem(name: "Guacamole", category: "Dips", calories: 45, protein: 1, carbs: 3, fiber: 2, fat: 4, servingSize: "2 tbsp", region: "Mexico"),
            DatabaseFoodItem(name: "Salsa", category: "Condiments", calories: 10, protein: 0.5, carbs: 2, fiber: 0.5, fat: 0, servingSize: "2 tbsp", region: "Mexico"),
            
            // European Foods
            DatabaseFoodItem(name: "Bread", category: "Grains", calories: 80, protein: 3, carbs: 15, fiber: 1, fat: 1, servingSize: "1 slice", region: "Europe"),
            DatabaseFoodItem(name: "Pasta", category: "Grains", calories: 200, protein: 7, carbs: 40, fiber: 2, fat: 1, servingSize: "1 cup cooked", region: "Europe"),
            DatabaseFoodItem(name: "Cheese", category: "Dairy", calories: 110, protein: 7, carbs: 1, fiber: 0, fat: 9, servingSize: "1 oz", region: "Europe"),
            DatabaseFoodItem(name: "Butter", category: "Fats", calories: 102, protein: 0.1, carbs: 0, fiber: 0, fat: 12, servingSize: "1 tbsp", region: "Europe"),
            
            // Middle Eastern Foods
            DatabaseFoodItem(name: "Tahini", category: "Fats", calories: 89, protein: 2.6, carbs: 3.2, fiber: 1.4, fat: 8, servingSize: "1 tbsp", region: "Middle East"),
            DatabaseFoodItem(name: "Pita Bread", category: "Grains", calories: 165, protein: 5.5, carbs: 33, fiber: 1.2, fat: 0.8, servingSize: "1 piece", region: "Middle East"),
            DatabaseFoodItem(name: "Baba Ganoush", category: "Dips", calories: 35, protein: 1, carbs: 3, fiber: 1, fat: 2.5, servingSize: "2 tbsp", region: "Middle East"),
            
            // African Foods
            DatabaseFoodItem(name: "Quinoa", category: "Grains", calories: 120, protein: 4.4, carbs: 22, fiber: 2.8, fat: 1.9, servingSize: "1/2 cup cooked", region: "Africa"),
            DatabaseFoodItem(name: "Sweet Potato", category: "Vegetables", calories: 103, protein: 2, carbs: 24, fiber: 4, fat: 0.2, servingSize: "1 medium", region: "Africa"),
            DatabaseFoodItem(name: "Plantains", category: "Fruits", calories: 122, protein: 1.3, carbs: 32, fiber: 2.3, fat: 0.4, servingSize: "1 medium", region: "Africa"),
            
            // South American Foods
            DatabaseFoodItem(name: "Amaranth", category: "Grains", calories: 125, protein: 4.7, carbs: 23, fiber: 2.6, fat: 2, servingSize: "1/2 cup cooked", region: "South America"),
            DatabaseFoodItem(name: "Chia Seeds", category: "Seeds", calories: 58, protein: 2, carbs: 5, fiber: 5, fat: 4.5, servingSize: "1 tbsp", region: "South America"),
            
            // Common Vegetables
            DatabaseFoodItem(name: "Broccoli", category: "Vegetables", calories: 55, protein: 3.7, carbs: 11, fiber: 5, fat: 0.6, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Spinach", category: "Vegetables", calories: 23, protein: 2.9, carbs: 3.6, fiber: 2.2, fat: 0.4, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Carrots", category: "Vegetables", calories: 52, protein: 1.2, carbs: 12, fiber: 3.6, fat: 0.3, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Tomatoes", category: "Vegetables", calories: 22, protein: 1.1, carbs: 4.8, fiber: 1.2, fat: 0.2, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Cucumber", category: "Vegetables", calories: 16, protein: 0.7, carbs: 3.6, fiber: 0.5, fat: 0.2, servingSize: "1 cup", region: "Global"),
            
            // Common Fruits
            DatabaseFoodItem(name: "Apple", category: "Fruits", calories: 95, protein: 0.5, carbs: 25, fiber: 4, fat: 0.3, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Orange", category: "Fruits", calories: 62, protein: 1.2, carbs: 15, fiber: 3.1, fat: 0.2, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Strawberries", category: "Fruits", calories: 49, protein: 1, carbs: 12, fiber: 3, fat: 0.5, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Blueberries", category: "Fruits", calories: 85, protein: 1.1, carbs: 21, fiber: 3.6, fat: 0.5, servingSize: "1 cup", region: "Global"),
            
            // Proteins
            DatabaseFoodItem(name: "Chicken Breast", category: "Protein", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Salmon", category: "Protein", calories: 206, protein: 22, carbs: 0, fiber: 0, fat: 12, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Beef", category: "Protein", calories: 250, protein: 26, carbs: 0, fiber: 0, fat: 15, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Pork", category: "Protein", calories: 242, protein: 27, carbs: 0, fiber: 0, fat: 14, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Turkey", category: "Protein", calories: 135, protein: 25, carbs: 0, fiber: 0, fat: 3, servingSize: "3 oz", region: "Global"),
            
            // Nuts and Seeds
            DatabaseFoodItem(name: "Almonds", category: "Nuts", calories: 164, protein: 6, carbs: 6, fiber: 3.5, fat: 14, servingSize: "1/4 cup", region: "Global"),
            DatabaseFoodItem(name: "Walnuts", category: "Nuts", calories: 185, protein: 4, carbs: 4, fiber: 2, fat: 18, servingSize: "1/4 cup", region: "Global"),
            DatabaseFoodItem(name: "Peanuts", category: "Nuts", calories: 207, protein: 9, carbs: 6, fiber: 3, fat: 18, servingSize: "1/4 cup", region: "Global"),
            DatabaseFoodItem(name: "Sunflower Seeds", category: "Seeds", calories: 164, protein: 6, carbs: 6, fiber: 3, fat: 14, servingSize: "1/4 cup", region: "Global"),
            
            // Beverages
            DatabaseFoodItem(name: "Milk", category: "Dairy", calories: 103, protein: 8, carbs: 12, fiber: 0, fat: 2.4, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Orange Juice", category: "Beverages", calories: 111, protein: 1.7, carbs: 26, fiber: 0.5, fat: 0.5, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Green Tea", category: "Beverages", calories: 2, protein: 0, carbs: 0, fiber: 0, fat: 0, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Coffee", category: "Beverages", calories: 2, protein: 0.3, carbs: 0, fiber: 0, fat: 0, servingSize: "1 cup", region: "Global")
        ]
    }
    
    func getFoodCategories() -> [String] {
        return Array(Set(allFoods.map { $0.category })).sorted()
    }
    
    func getFoodsByCategory(_ category: String) -> [DatabaseFoodItem] {
        return allFoods.filter { $0.category == category }
    }
    
    func getFoodsByRegion(_ region: String) -> [DatabaseFoodItem] {
        return allFoods.filter { $0.region == region }
    }
} 