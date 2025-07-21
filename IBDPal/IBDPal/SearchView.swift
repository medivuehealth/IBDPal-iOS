import SwiftUI

struct SearchView: View {
    let userData: UserData?
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResults: [DatabaseFoodItem] = []
    @State private var selectedCategory = "All"
    @State private var selectedDiscoverCategory: DiscoverCategory = .nutrition
    @State private var articles: [Article] = []
    @State private var calculatedNutrition: SearchCalculatedNutrition?
    @State private var showingNutritionResults = false
    
    private let categories = ["All", "Fruits", "Vegetables", "Proteins", "Grains", "Dairy", "Breakfast", "Legumes", "Nuts", "Beverages"]
    private let discoverCategories: [DiscoverCategory] = [.nutrition, .medication, .lifestyle, .research, .community]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Food Search Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Enter food (e.g., chicken pasta, eggs toast)...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: searchText) { _ in
                                    performAutoCalculation()
                                }
                            
                            if !searchText.isEmpty {
                                Button("Clear") {
                                    searchText = ""
                                    searchResults = []
                                    calculatedNutrition = nil
                                    showingNutritionResults = false
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        filterResults()
                                    }) {
                                        Text(category)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        // Auto-calculated Nutrition Results
                        if let nutrition = calculatedNutrition, showingNutritionResults {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Calculated Nutrition")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button("Hide") {
                                        showingNutritionResults = false
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Foods detected:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    
                                    ForEach(nutrition.detectedFoods, id: \.self) { food in
                                        HStack {
                                            Text("• \(food)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                    }
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    NutritionResultCard(title: "Calories", value: "\(Int(nutrition.totalCalories))", unit: "kcal", color: .green)
                                    NutritionResultCard(title: "Protein", value: String(format: "%.1f", nutrition.totalProtein), unit: "g", color: .blue)
                                    NutritionResultCard(title: "Carbs", value: String(format: "%.1f", nutrition.totalCarbs), unit: "g", color: .orange)
                                    NutritionResultCard(title: "Fiber", value: String(format: "%.1f", nutrition.totalFiber), unit: "g", color: .purple)
                                    NutritionResultCard(title: "Fat", value: String(format: "%.1f", nutrition.totalFat), unit: "g", color: .red)
                                    NutritionResultCard(title: "Serving", value: "Teen", unit: "Portion", color: .gray)
                                }
                            }
                            .padding()
                            .background(Color.ibdSurfaceBackground)
                            .cornerRadius(12)
                        }
                        
                        // Search Results
                        if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Matching Foods")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(searchResults) { food in
                                        SearchFoodRow(food: food) {
                                            addToCalculation(food)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Discover Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Learn & Discover")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        // Category Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(discoverCategories, id: \.self) { category in
                                    Button(action: {
                                        selectedDiscoverCategory = category
                                        loadArticles(for: category)
                                    }) {
                                        Text(category.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedDiscoverCategory == category ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                                            .foregroundColor(selectedDiscoverCategory == category ? .white : .ibdPrimaryText)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        // Articles Section
                        if isLoading {
                            ProgressView("Loading articles...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if articles.isEmpty {
                            VStack(spacing: 16) {
                                Text("No articles found")
                                    .font(.headline)
                                    .foregroundColor(.ibdSecondaryText)
                                
                                Text("Try selecting a different category or check back later.")
                                    .font(.subheadline)
                                    .foregroundColor(.ibdSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(articles) { article in
                                    ArticleCard(article: article)
                                }
                            }
                        }
                        
                        // Quick Tips Section
                        QuickTipsSection()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationTitle("Search & Discover")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("SearchView appeared, loading articles...")
                loadArticles(for: selectedDiscoverCategory)
            }
        }
    }
    
    private func performAutoCalculation() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            calculatedNutrition = nil
            showingNutritionResults = false
            return
        }
        
        // Parse food items from search text
        let foodWords = searchText.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let detectedFoods = parseFoodItems(from: foodWords)
        
        if !detectedFoods.isEmpty {
            calculatedNutrition = calculateNutrition(for: detectedFoods)
            showingNutritionResults = true
        }
    }
    
    private func parseFoodItems(from words: [String]) -> [String] {
        let foodDatabase = FoodDatabase.shared
        var detectedFoods: [String] = []
        
        for word in words {
            if word.count > 2 { // Only consider words with 3+ characters
                let matchingFoods = foodDatabase.allFoods.filter { food in
                    food.name.lowercased().contains(word) ||
                    food.category.lowercased().contains(word)
                }
                
                if !matchingFoods.isEmpty {
                    detectedFoods.append(matchingFoods.first!.name)
                }
            }
        }
        
        return Array(Set(detectedFoods)) // Remove duplicates
    }
    
    private func calculateNutrition(for foods: [String]) -> SearchCalculatedNutrition {
        let foodDatabase = FoodDatabase.shared
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalFat: Double = 0
        
        for foodName in foods {
            if let food = foodDatabase.allFoods.first(where: { $0.name.lowercased() == foodName.lowercased() }) {
                // Validate values before calculation to prevent NaN
                let calories = food.calories.isFinite ? food.calories : 0
                let protein = food.protein.isFinite ? food.protein : 0
                let carbs = food.carbs.isFinite ? food.carbs : 0
                let fiber = food.fiber.isFinite ? food.fiber : 0
                let fat = food.fat.isFinite ? food.fat : 0
                
                // Teen portion size (1.5x normal serving)
                totalCalories += calories * 1.5
                totalProtein += protein * 1.5
                totalCarbs += carbs * 1.5
                totalFiber += fiber * 1.5
                totalFat += fat * 1.5
            }
        }
        
        // Final validation to ensure no NaN values
        return SearchCalculatedNutrition(
            detectedFoods: foods,
            totalCalories: totalCalories.isFinite ? totalCalories : 0,
            totalProtein: totalProtein.isFinite ? totalProtein : 0,
            totalCarbs: totalCarbs.isFinite ? totalCarbs : 0,
            totalFiber: totalFiber.isFinite ? totalFiber : 0,
            totalFat: totalFat.isFinite ? totalFat : 0
        )
    }
    
    private func addToCalculation(_ food: DatabaseFoodItem) {
        let currentFoods = calculatedNutrition?.detectedFoods ?? []
        let newFoods = currentFoods + [food.name]
        calculatedNutrition = calculateNutrition(for: newFoods)
        showingNutritionResults = true
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let foodDatabase = FoodDatabase.shared
            searchResults = foodDatabase.searchFoods(query: searchText)
            isLoading = false
        }
    }
    
    private func filterResults() {
        if selectedCategory == "All" {
            performSearch()
        } else {
            let foodDatabase = FoodDatabase.shared
            searchResults = foodDatabase.allFoods.filter { food in
                food.category == selectedCategory
            }
        }
    }
    
    private func loadArticles(for category: DiscoverCategory) {
        isLoading = true
        print("Loading articles for category: \(category.displayName)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            articles = getArticles(for: category)
            print("Loaded \(articles.count) articles")
            isLoading = false
        }
    }
    
    private func getArticles(for category: DiscoverCategory) -> [Article] {
        switch category {
        case .nutrition:
            return [
                Article(id: "1", title: "Anti-Inflammatory Diet for IBD", excerpt: "Learn about foods that can help reduce inflammation and manage IBD symptoms.", category: .nutrition, readTime: "5 min read", imageName: "leaf.fill"),
                Article(id: "2", title: "Foods to Avoid During Flares", excerpt: "Discover which foods might trigger symptoms and should be avoided during active periods.", category: .nutrition, readTime: "4 min read", imageName: "exclamationmark.triangle.fill"),
                Article(id: "3", title: "Hydration Tips for IBD Patients", excerpt: "Stay properly hydrated with these essential tips for managing IBD.", category: .nutrition, readTime: "3 min read", imageName: "drop.fill")
            ]
        case .medication:
            return [
                Article(id: "4", title: "Understanding IBD Medications", excerpt: "A comprehensive guide to the different types of medications used to treat IBD.", category: .medication, readTime: "7 min read", imageName: "pills.fill"),
                Article(id: "5", title: "Medication Adherence Tips", excerpt: "Strategies to help you stay on track with your medication schedule.", category: .medication, readTime: "4 min read", imageName: "clock.fill")
            ]
        case .lifestyle:
            return [
                Article(id: "6", title: "Exercise and IBD", excerpt: "Safe and effective exercise routines for people living with IBD.", category: .lifestyle, readTime: "6 min read", imageName: "figure.walk"),
                Article(id: "7", title: "Stress Management Techniques", excerpt: "Learn how to manage stress, which can significantly impact IBD symptoms.", category: .lifestyle, readTime: "5 min read", imageName: "brain.head.profile")
            ]
        case .research:
            return [
                Article(id: "8", title: "Latest IBD Research Updates", excerpt: "Stay informed about the newest developments in IBD treatment and research.", category: .research, readTime: "8 min read", imageName: "microscope.fill")
            ]
        case .community:
            return [
                Article(id: "9", title: "Connecting with the IBD Community", excerpt: "Find support groups and connect with others who understand your journey.", category: .community, readTime: "4 min read", imageName: "person.3.fill")
            ]
        }
    }
}

// MARK: - Supporting Views

struct SearchFoodRow: View {
    let food: DatabaseFoodItem
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text(food.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(food.servingSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(food.calories)) cal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Button("Add") {
                    onAdd()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(8)
    }
}

struct NutritionResultCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: article.imageName)
                    .font(.title2)
                    .foregroundColor(.ibdPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(article.readTime)
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Text(article.excerpt)
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
                .lineLimit(3)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

struct QuickTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickTipCard(title: "Stay Hydrated", description: "Drink plenty of water throughout the day", icon: "drop.fill", color: .blue)
                    QuickTipCard(title: "Track Symptoms", description: "Keep a daily log of your symptoms", icon: "chart.line.uptrend.xyaxis", color: .green)
                    QuickTipCard(title: "Exercise Regularly", description: "Gentle exercise can help manage symptoms", icon: "figure.walk", color: .orange)
                }
            }
        }
    }
}

struct QuickTipCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .lineLimit(2)
        }
        .frame(width: 140)
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct SearchCalculatedNutrition {
    let detectedFoods: [String]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFiber: Double
    let totalFat: Double
}

enum DiscoverCategory: String, CaseIterable {
    case nutrition = "nutrition"
    case medication = "medication"
    case lifestyle = "lifestyle"
    case research = "research"
    case community = "community"
    
    var displayName: String {
        switch self {
        case .nutrition: return "Nutrition"
        case .medication: return "Medication"
        case .lifestyle: return "Lifestyle"
        case .research: return "Research"
        case .community: return "Community"
        }
    }
}

struct Article: Identifiable {
    let id: String
    let title: String
    let excerpt: String
    let category: DiscoverCategory
    let readTime: String
    let imageName: String
}

#Preview {
    SearchView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", token: "token"))
} 