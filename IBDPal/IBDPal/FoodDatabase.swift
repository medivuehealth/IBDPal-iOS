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
            DatabaseFoodItem(name: "Pancakes", category: "Breakfast", calories: 180, protein: 4, carbs: 30, fiber: 1, fat: 6, servingSize: "2 medium pancakes", region: "Global"),
            DatabaseFoodItem(name: "Waffles", category: "Breakfast", calories: 200, protein: 5, carbs: 32, fiber: 1, fat: 7, servingSize: "2 waffles", region: "Global"),
            DatabaseFoodItem(name: "French Toast", category: "Breakfast", calories: 220, protein: 8, carbs: 25, fiber: 1, fat: 10, servingSize: "2 slices", region: "Global"),
            DatabaseFoodItem(name: "Cereal", category: "Breakfast", calories: 120, protein: 3, carbs: 25, fiber: 3, fat: 1, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Yogurt", category: "Breakfast", calories: 150, protein: 8, carbs: 12, fiber: 0, fat: 8, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Smoothie", category: "Breakfast", calories: 200, protein: 5, carbs: 35, fiber: 4, fat: 2, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Bagel", category: "Breakfast", calories: 245, protein: 9, carbs: 48, fiber: 2, fat: 1, servingSize: "1 bagel", region: "Global"),
            DatabaseFoodItem(name: "Muffin", category: "Breakfast", calories: 180, protein: 3, carbs: 28, fiber: 1, fat: 7, servingSize: "1 muffin", region: "Global"),
            DatabaseFoodItem(name: "Croissant", category: "Breakfast", calories: 230, protein: 4, carbs: 25, fiber: 1, fat: 12, servingSize: "1 croissant", region: "Global"),
            DatabaseFoodItem(name: "Bacon", category: "Breakfast", calories: 45, protein: 3, carbs: 0, fiber: 0, fat: 3.5, servingSize: "1 slice", region: "Global"),
            DatabaseFoodItem(name: "Sausage", category: "Breakfast", calories: 85, protein: 5, carbs: 1, fiber: 0, fat: 7, servingSize: "1 link", region: "Global"),
            DatabaseFoodItem(name: "Hash Browns", category: "Breakfast", calories: 150, protein: 2, carbs: 20, fiber: 2, fat: 7, servingSize: "1/2 cup", region: "Global"),
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
            DatabaseFoodItem(name: "Pizza", category: "Fast Food", calories: 285, protein: 12, carbs: 36, fiber: 2, fat: 10, servingSize: "1 slice", region: "Europe"),
            DatabaseFoodItem(name: "Cheese", category: "Dairy", calories: 110, protein: 7, carbs: 1, fiber: 0, fat: 9, servingSize: "1 oz", region: "Europe"),
            DatabaseFoodItem(name: "Butter", category: "Fats", calories: 102, protein: 0.1, carbs: 0, fiber: 0, fat: 12, servingSize: "1 tbsp", region: "Europe"),
            
            // American Foods
            DatabaseFoodItem(name: "Hamburger", category: "Fast Food", calories: 354, protein: 17, carbs: 30, fiber: 1, fat: 17, servingSize: "1 burger", region: "America"),
            DatabaseFoodItem(name: "Cheeseburger", category: "Fast Food", calories: 415, protein: 20, carbs: 30, fiber: 1, fat: 22, servingSize: "1 burger", region: "America"),
            DatabaseFoodItem(name: "Hot Dog", category: "Fast Food", calories: 151, protein: 5, carbs: 2, fiber: 0, fat: 14, servingSize: "1 hot dog", region: "America"),
            DatabaseFoodItem(name: "French Fries", category: "Fast Food", calories: 365, protein: 4, carbs: 63, fiber: 4, fat: 17, servingSize: "1 medium order", region: "America"),
            DatabaseFoodItem(name: "Chicken Sandwich", category: "Fast Food", calories: 350, protein: 25, carbs: 30, fiber: 2, fat: 15, servingSize: "1 sandwich", region: "America"),
            DatabaseFoodItem(name: "Fish Sandwich", category: "Fast Food", calories: 380, protein: 18, carbs: 35, fiber: 2, fat: 18, servingSize: "1 sandwich", region: "America"),
            DatabaseFoodItem(name: "Chicken Nuggets", category: "Fast Food", calories: 250, protein: 14, carbs: 15, fiber: 1, fat: 15, servingSize: "6 pieces", region: "America"),
            DatabaseFoodItem(name: "Chicken Wings", category: "Fast Food", calories: 290, protein: 27, carbs: 0, fiber: 0, fat: 19, servingSize: "6 wings", region: "America"),
            DatabaseFoodItem(name: "Taco", category: "Fast Food", calories: 170, protein: 8, carbs: 18, fiber: 2, fat: 8, servingSize: "1 taco", region: "America"),
            DatabaseFoodItem(name: "Burrito", category: "Fast Food", calories: 320, protein: 15, carbs: 45, fiber: 6, fat: 10, servingSize: "1 burrito", region: "America"),
            DatabaseFoodItem(name: "Nachos", category: "Fast Food", calories: 346, protein: 8, carbs: 35, fiber: 3, fat: 20, servingSize: "1 serving", region: "America"),
            DatabaseFoodItem(name: "Chili", category: "Soup", calories: 250, protein: 18, carbs: 20, fiber: 6, fat: 12, servingSize: "1 cup", region: "America"),
            DatabaseFoodItem(name: "Mac and Cheese", category: "Pasta", calories: 300, protein: 12, carbs: 35, fiber: 2, fat: 15, servingSize: "1 cup", region: "America"),
            DatabaseFoodItem(name: "BBQ Ribs", category: "Protein", calories: 320, protein: 25, carbs: 5, fiber: 0, fat: 22, servingSize: "3 ribs", region: "America"),
            DatabaseFoodItem(name: "Fried Chicken", category: "Protein", calories: 320, protein: 25, carbs: 8, fiber: 1, fat: 20, servingSize: "1 piece", region: "America"),
            DatabaseFoodItem(name: "Meatloaf", category: "Protein", calories: 250, protein: 20, carbs: 8, fiber: 1, fat: 15, servingSize: "1 slice", region: "America"),
            DatabaseFoodItem(name: "Pot Roast", category: "Protein", calories: 280, protein: 25, carbs: 5, fiber: 1, fat: 18, servingSize: "3 oz", region: "America"),
            DatabaseFoodItem(name: "Cornbread", category: "Grains", calories: 173, protein: 3, carbs: 28, fiber: 1, fat: 6, servingSize: "1 piece", region: "America"),
            DatabaseFoodItem(name: "Biscuits", category: "Grains", calories: 150, protein: 3, carbs: 20, fiber: 1, fat: 7, servingSize: "1 biscuit", region: "America"),
            DatabaseFoodItem(name: "Gravy", category: "Sauces", calories: 45, protein: 1, carbs: 3, fiber: 0, fat: 3, servingSize: "1/4 cup", region: "America"),
            DatabaseFoodItem(name: "Mashed Potatoes", category: "Vegetables", calories: 120, protein: 2, carbs: 20, fiber: 2, fat: 4, servingSize: "1/2 cup", region: "America"),
            DatabaseFoodItem(name: "Green Beans", category: "Vegetables", calories: 31, protein: 2, carbs: 7, fiber: 3, fat: 0, servingSize: "1 cup", region: "America"),
            DatabaseFoodItem(name: "Corn on the Cob", category: "Vegetables", calories: 77, protein: 3, carbs: 17, fiber: 2, fat: 1, servingSize: "1 ear", region: "America"),
            DatabaseFoodItem(name: "Apple Pie", category: "Desserts", calories: 237, protein: 2, carbs: 34, fiber: 1, fat: 11, servingSize: "1 slice", region: "America"),
            DatabaseFoodItem(name: "Chocolate Chip Cookies", category: "Desserts", calories: 78, protein: 1, carbs: 10, fiber: 0, fat: 4, servingSize: "1 cookie", region: "America"),
            DatabaseFoodItem(name: "Ice Cream", category: "Desserts", calories: 137, protein: 2, carbs: 16, fiber: 0, fat: 7, servingSize: "1/2 cup", region: "America"),
            DatabaseFoodItem(name: "Brownies", category: "Desserts", calories: 112, protein: 1, carbs: 15, fiber: 1, fat: 6, servingSize: "1 brownie", region: "America"),
            DatabaseFoodItem(name: "Peanut Butter", category: "Spreads", calories: 94, protein: 4, carbs: 3, fiber: 1, fat: 8, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Jelly", category: "Spreads", calories: 50, protein: 0, carbs: 13, fiber: 0, fat: 0, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Ketchup", category: "Condiments", calories: 15, protein: 0, carbs: 4, fiber: 0, fat: 0, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Mustard", category: "Condiments", calories: 3, protein: 0, carbs: 0, fiber: 0, fat: 0, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Mayonnaise", category: "Condiments", calories: 94, protein: 0, carbs: 0, fiber: 0, fat: 10, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Ranch Dressing", category: "Condiments", calories: 73, protein: 0, carbs: 1, fiber: 0, fat: 8, servingSize: "1 tbsp", region: "America"),
            DatabaseFoodItem(name: "Soda", category: "Beverages", calories: 150, protein: 0, carbs: 39, fiber: 0, fat: 0, servingSize: "12 oz", region: "America"),
            DatabaseFoodItem(name: "Lemonade", category: "Beverages", calories: 99, protein: 0, carbs: 26, fiber: 0, fat: 0, servingSize: "1 cup", region: "America"),
            DatabaseFoodItem(name: "Iced Tea", category: "Beverages", calories: 2, protein: 0, carbs: 0, fiber: 0, fat: 0, servingSize: "1 cup", region: "America"),
            
            // Middle Eastern Foods
            DatabaseFoodItem(name: "Tahini", category: "Fats", calories: 89, protein: 2.6, carbs: 3.2, fiber: 1.4, fat: 8, servingSize: "1 tbsp", region: "Middle East"),
            DatabaseFoodItem(name: "Pita Bread", category: "Grains", calories: 165, protein: 5.5, carbs: 33, fiber: 1.2, fat: 0.8, servingSize: "1 piece", region: "Middle East"),
            DatabaseFoodItem(name: "Baba Ganoush", category: "Dips", calories: 35, protein: 1, carbs: 3, fiber: 1, fat: 2.5, servingSize: "2 tbsp", region: "Middle East"),
            
            // African Foods

            DatabaseFoodItem(name: "Sweet Potato", category: "Vegetables", calories: 103, protein: 2, carbs: 24, fiber: 4, fat: 0.2, servingSize: "1 medium", region: "Africa"),
            DatabaseFoodItem(name: "Plantains", category: "Fruits", calories: 122, protein: 1.3, carbs: 32, fiber: 2.3, fat: 0.4, servingSize: "1 medium", region: "Africa"),
            
            // South American Foods
            DatabaseFoodItem(name: "Amaranth", category: "Grains", calories: 125, protein: 4.7, carbs: 23, fiber: 2.6, fat: 2, servingSize: "1/2 cup cooked", region: "South America"),

            
            // Common Vegetables


            DatabaseFoodItem(name: "Carrots", category: "Vegetables", calories: 52, protein: 1.2, carbs: 12, fiber: 3.6, fat: 0.3, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Tomatoes", category: "Vegetables", calories: 22, protein: 1.1, carbs: 4.8, fiber: 1.2, fat: 0.2, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Cucumber", category: "Vegetables", calories: 16, protein: 0.7, carbs: 3.6, fiber: 0.5, fat: 0.2, servingSize: "1 cup", region: "Global"),
            
            // Common Fruits
            DatabaseFoodItem(name: "Apple", category: "Fruits", calories: 95, protein: 0.5, carbs: 25, fiber: 4, fat: 0.3, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Orange", category: "Fruits", calories: 62, protein: 1.2, carbs: 15, fiber: 3.1, fat: 0.2, servingSize: "1 medium", region: "Global"),
            DatabaseFoodItem(name: "Strawberries", category: "Fruits", calories: 49, protein: 1, carbs: 12, fiber: 3, fat: 0.5, servingSize: "1 cup", region: "Global"),
            
            // Proteins
            DatabaseFoodItem(name: "Chicken Breast", category: "Protein", calories: 165, protein: 31, carbs: 0, fiber: 0, fat: 3.6, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Salmon", category: "Protein", calories: 206, protein: 22, carbs: 0, fiber: 0, fat: 12, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Beef", category: "Protein", calories: 250, protein: 26, carbs: 0, fiber: 0, fat: 15, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Pork", category: "Protein", calories: 242, protein: 27, carbs: 0, fiber: 0, fat: 14, servingSize: "3 oz", region: "Global"),
            DatabaseFoodItem(name: "Turkey", category: "Protein", calories: 135, protein: 25, carbs: 0, fiber: 0, fat: 3, servingSize: "3 oz", region: "Global"),
            
            // Nuts and Seeds

            DatabaseFoodItem(name: "Walnuts", category: "Nuts", calories: 185, protein: 4, carbs: 4, fiber: 2, fat: 18, servingSize: "1/4 cup", region: "Global"),
            DatabaseFoodItem(name: "Peanuts", category: "Nuts", calories: 207, protein: 9, carbs: 6, fiber: 3, fat: 18, servingSize: "1/4 cup", region: "Global"),
            DatabaseFoodItem(name: "Sunflower Seeds", category: "Seeds", calories: 164, protein: 6, carbs: 6, fiber: 3, fat: 14, servingSize: "1/4 cup", region: "Global"),
            
            // Beverages
            DatabaseFoodItem(name: "Milk", category: "Dairy", calories: 103, protein: 8, carbs: 12, fiber: 0, fat: 2.4, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Orange Juice", category: "Beverages", calories: 111, protein: 1.7, carbs: 26, fiber: 0.5, fat: 0.5, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Green Tea", category: "Beverages", calories: 2, protein: 0, carbs: 0, fiber: 0, fat: 0, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Coffee", category: "Beverages", calories: 2, protein: 0.3, carbs: 0, fiber: 0, fat: 0, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Fruit Smoothie", category: "Beverages", calories: 180, protein: 3, carbs: 35, fiber: 4, fat: 1, servingSize: "1 cup", region: "Global"),
            DatabaseFoodItem(name: "Berry Smoothie", category: "Beverages", calories: 160, protein: 4, carbs: 30, fiber: 5, fat: 2, servingSize: "1 cup", region: "Global")
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