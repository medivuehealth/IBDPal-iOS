import SwiftUI
import WebKit
import CoreLocation

struct SearchView: View {
    let userData: UserData?
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResults: [DatabaseFoodItem] = []
    @State private var selectedDiscoverCategory: DiscoverCategory = .nutrition
    @State private var articles: [Article] = []
    @State private var calculatedNutrition: SearchCalculatedNutrition?
    @State private var showingNutritionResults = false
    @State private var showingArticleViewer = false
    @State private var selectedArticle: Article?
    
    // Community features
    @State private var hospitals: [Hospital] = []
    @State private var specialists: [IBDSpecialist] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var locationManager = CLLocationManager()
    @State private var showingLocationPermission = false
    @State private var isLoadingCommunity = false
    
    private let discoverCategories: [DiscoverCategory] = [.nutrition, .medication, .lifestyle, .research, .community, .blogs]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
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
                    
                    // Learn & Discover & Connect Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Learn & Discover & Connect")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        // Category Cards (similar to Daily Log layout)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(discoverCategories, id: \.self) { category in
                                DiscoverCategoryCard(
                                    category: category,
                                    isSelected: selectedDiscoverCategory == category,
                                    action: {
                                        selectedDiscoverCategory = category
                                        loadArticles(for: category)
                                    }
                                )
                            }
                        }
                        
                        // Articles Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("\(selectedDiscoverCategory.displayName) Articles")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ibdPrimaryText)
                                
                                Spacer()
                                
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            if isLoading {
                                VStack(spacing: 16) {
                                    ProgressView("Loading articles...")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            } else if articles.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
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
                                if selectedDiscoverCategory == .blogs {
                                    VStack(spacing: 16) {
                                        Text("Share Your Story")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.ibdPrimaryText)
                                        
                                        Text("Connect with the IBD community by sharing your experiences and reading others' stories.")
                                            .font(.subheadline)
                                            .foregroundColor(.ibdSecondaryText)
                                            .multilineTextAlignment(.center)
                                        
                                        NavigationLink(destination: BlogView(userData: userData)) {
                                            HStack {
                                                Image(systemName: "square.and.pencil")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                
                                                Text("Go to Stories")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.ibdPrimary)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding()
                                    .background(Color.ibdSurfaceBackground)
                                    .cornerRadius(12)
                                } else if selectedDiscoverCategory == .community {
                                    CommunitySection(
                                        hospitals: hospitals,
                                        specialists: specialists,
                                        userLocation: userLocation,
                                        isLoading: isLoadingCommunity,
                                        onRequestLocation: requestLocationPermission,
                                        onLoadHospitals: loadNearbyHospitals,
                                        onLoadSpecialists: loadNearbySpecialists
                                    )
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(articles) { article in
                                            ArticleCard(article: article) {
                                                selectedArticle = article
                                                showingArticleViewer = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("SearchView appeared, loading articles...")
                loadArticles(for: selectedDiscoverCategory)
            }
            .sheet(isPresented: $showingArticleViewer) {
                if let article = selectedArticle {
                    ArticleViewerView(article: article)
                }
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
    
    private func loadArticles(for category: DiscoverCategory) {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.articles = self.getSampleArticles(for: category)
            self.isLoading = false
        }
    }
    
    // MARK: - Community Functions
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showingLocationPermission = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    private func loadNearbyHospitals() {
        guard let location = userLocation else { return }
        
        isLoadingCommunity = true
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/community/hospitals?latitude=\(location.latitude)&longitude=\(location.longitude)&radius=32.2&limit=20" // 20 miles = 32.2 km
        
        guard let url = URL(string: urlString) else {
            isLoadingCommunity = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingCommunity = false
                
                if let error = error {
                    print("🔍 SearchView: Error loading hospitals: \(error)")
                    return
                }
                
                if let data = data,
                   let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = response["success"] as? Bool,
                   success,
                   let dataDict = response["data"] as? [String: Any],
                   let hospitalsData = dataDict["hospitals"] as? [[String: Any]] {
                    
                    hospitals = hospitalsData.compactMap { hospitalData in
                        guard let id = hospitalData["id"] as? Int,
                              let name = hospitalData["name"] as? String,
                              let typeString = hospitalData["type"] as? String,
                              let type = HospitalType(rawValue: typeString),
                              let address = hospitalData["address"] as? String,
                              let city = hospitalData["city"] as? String,
                              let state = hospitalData["state"] as? String,
                              let zipCode = hospitalData["zip_code"] as? String,
                              let country = hospitalData["country"] as? String,
                              let latitude = hospitalData["latitude"] as? Double,
                              let longitude = hospitalData["longitude"] as? Double else {
                            return nil
                        }
                        
                        let phone = hospitalData["phone"] as? String
                        let website = hospitalData["website"] as? String
                        let email = hospitalData["email"] as? String
                        let description = hospitalData["description"] as? String
                        let specialties = hospitalData["specialties"] as? [String] ?? []
                        let ibdServices = hospitalData["ibd_services"] as? Bool ?? false
                        let emergencyServices = hospitalData["emergency_services"] as? Bool ?? false
                        let insuranceAccepted = hospitalData["insurance_accepted"] as? [String] ?? []
                        let hoursOfOperation = hospitalData["hours_of_operation"] as? [String: String] ?? [:]
                        let rating = hospitalData["rating"] as? Double
                        let reviewCount = hospitalData["review_count"] as? Int ?? 0
                        let distance = hospitalData["distance_km"] as? Double
                        
                        return Hospital(
                            id: id,
                            name: name,
                            type: type,
                            address: address,
                            city: city,
                            state: state,
                            zipCode: zipCode,
                            country: country,
                            latitude: latitude,
                            longitude: longitude,
                            phone: phone,
                            website: website,
                            email: email,
                            description: description,
                            specialties: specialties,
                            ibdServices: ibdServices,
                            emergencyServices: emergencyServices,
                            insuranceAccepted: insuranceAccepted,
                            hoursOfOperation: hoursOfOperation,
                            rating: rating,
                            reviewCount: reviewCount,
                            distance: distance
                        )
                    }
                }
            }
        }.resume()
    }
    
    private func loadNearbySpecialists() {
        guard let location = userLocation else { return }
        
        isLoadingCommunity = true
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/community/specialists?latitude=\(location.latitude)&longitude=\(location.longitude)&radius=32.2&limit=20" // 20 miles = 32.2 km
        
        guard let url = URL(string: urlString) else {
            isLoadingCommunity = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingCommunity = false
                
                if let error = error {
                    print("🔍 SearchView: Error loading specialists: \(error)")
                    return
                }
                
                if let data = data,
                   let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = response["success"] as? Bool,
                   success,
                   let dataDict = response["data"] as? [String: Any],
                   let specialistsData = dataDict["specialists"] as? [[String: Any]] {
                    
                    specialists = specialistsData.compactMap { specialistData in
                        guard let id = specialistData["id"] as? Int,
                              let name = specialistData["name"] as? String,
                              let title = specialistData["title"] as? String,
                              let specialty = specialistData["specialty"] as? String else {
                            return nil
                        }
                        
                        let medicalCenterId = specialistData["medical_center_id"] as? Int
                        let address = specialistData["address"] as? String
                        let city = specialistData["city"] as? String
                        let state = specialistData["state"] as? String
                        let zipCode = specialistData["zip_code"] as? String
                        let country = specialistData["country"] as? String
                        let latitude = specialistData["latitude"] as? Double
                        let longitude = specialistData["longitude"] as? Double
                        let phone = specialistData["phone"] as? String
                        let email = specialistData["email"] as? String
                        let website = specialistData["website"] as? String
                        let education = specialistData["education"] as? [String] ?? []
                        let certifications = specialistData["certifications"] as? [String] ?? []
                        let languages = specialistData["languages"] as? [String] ?? []
                        let insuranceAccepted = specialistData["insurance_accepted"] as? [String] ?? []
                        let consultationFee = specialistData["consultation_fee"] as? Double
                        let rating = specialistData["rating"] as? Double
                        let reviewCount = specialistData["review_count"] as? Int ?? 0
                        let yearsExperience = specialistData["years_experience"] as? Int
                        let ibdFocusAreas = specialistData["ibd_focus_areas"] as? [String] ?? []
                        let distance = specialistData["distance_km"] as? Double
                        
                        return IBDSpecialist(
                            id: id,
                            name: name,
                            title: title,
                            specialty: specialty,
                            medicalCenterId: medicalCenterId,
                            address: address,
                            city: city,
                            state: state,
                            zipCode: zipCode,
                            country: country,
                            latitude: latitude,
                            longitude: longitude,
                            phone: phone,
                            email: email,
                            website: website,
                            education: education,
                            certifications: certifications,
                            languages: languages,
                            insuranceAccepted: insuranceAccepted,
                            consultationFee: consultationFee,
                            rating: rating,
                            reviewCount: reviewCount,
                            yearsExperience: yearsExperience,
                            ibdFocusAreas: ibdFocusAreas,
                            distance: distance
                        )
                    }
                }
            }
        }.resume()
    }
    
    private func getArticles(for category: DiscoverCategory) -> [Article] {
        switch category {
        case .nutrition:
            return [
                Article(id: "1", title: "Anti-Inflammatory Diet for IBD", excerpt: "Learn about foods that can help reduce inflammation and manage IBD symptoms.", category: .nutrition, readTime: "5 min read", imageName: "leaf.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "2", title: "Foods to Avoid During Flares", excerpt: "Discover which foods might trigger symptoms and should be avoided during active periods.", category: .nutrition, readTime: "4 min read", imageName: "exclamationmark.triangle.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "3", title: "Hydration Tips for IBD Patients", excerpt: "Stay properly hydrated with these essential tips for managing IBD.", category: .nutrition, readTime: "3 min read", imageName: "drop.fill", url: "https://www.mayoclinic.org/diseases-conditions/dehydration/symptoms-causes/syc-20354086"),
                Article(id: "4", title: "Fiber and IBD: What You Need to Know", excerpt: "Understanding how fiber affects IBD and how to incorporate it safely.", category: .nutrition, readTime: "6 min read", imageName: "leaf.circle.fill", url: "https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/fiber/art-20043983"),
                Article(id: "5", title: "Low FODMAP Diet for IBS", excerpt: "A comprehensive guide to the low FODMAP diet for managing IBS symptoms.", category: .nutrition, readTime: "7 min read", imageName: "chart.bar.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "6", title: "Crohn's Disease Diet Plan", excerpt: "Specific dietary recommendations for managing Crohn's disease symptoms.", category: .nutrition, readTime: "8 min read", imageName: "fork.knife", url: "https://www.mayoclinic.org/diseases-conditions/crohns-disease/symptoms-causes/syc-20353317"),
                Article(id: "7", title: "Ulcerative Colitis Nutrition Guide", excerpt: "Nutritional strategies for managing ulcerative colitis and promoting healing.", category: .nutrition, readTime: "6 min read", imageName: "heart.fill", url: "https://www.mayoclinic.org/diseases-conditions/ulcerative-colitis/symptoms-causes/syc-20353326"),
                Article(id: "8", title: "Probiotics for IBD Management", excerpt: "How probiotics can help support gut health in IBD patients.", category: .nutrition, readTime: "5 min read", imageName: "bacteria", url: "https://www.mayoclinic.org/healthy-lifestyle/consumer-health/expert-answers/probiotics/faq-20058065")
            ]
        case .medication:
            return [
                Article(id: "9", title: "Understanding IBD Medications", excerpt: "A comprehensive guide to the different types of medications used to treat IBD.", category: .medication, readTime: "7 min read", imageName: "pills.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "10", title: "Medication Adherence Tips", excerpt: "Strategies to help you stay on track with your medication schedule.", category: .medication, readTime: "4 min read", imageName: "clock.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "11", title: "Biologic Therapies for IBD", excerpt: "Learn about biologic medications and their role in treating inflammatory bowel disease.", category: .medication, readTime: "8 min read", imageName: "syringe.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "12", title: "Side Effects Management", excerpt: "How to manage common medication side effects in IBD treatment.", category: .medication, readTime: "6 min read", imageName: "exclamationmark.triangle", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "13", title: "Alternative Therapies", excerpt: "Complementary and alternative approaches to IBD management.", category: .medication, readTime: "5 min read", imageName: "leaf.arrow.circlepath", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320")
            ]
        case .lifestyle:
            return [
                Article(id: "14", title: "Exercise and IBD", excerpt: "Safe and effective exercise routines for people living with IBD.", category: .lifestyle, readTime: "6 min read", imageName: "figure.walk", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "15", title: "Stress Management Techniques", excerpt: "Learn how to manage stress, which can significantly impact IBD symptoms.", category: .lifestyle, readTime: "5 min read", imageName: "brain.head.profile", url: "https://www.mayoclinic.org/healthy-lifestyle/stress-management/in-depth/stress/art-20046037"),
                Article(id: "16", title: "Sleep and IBD", excerpt: "How to improve your sleep quality when living with inflammatory bowel disease.", category: .lifestyle, readTime: "4 min read", imageName: "bed.double.fill", url: "https://www.mayoclinic.org/healthy-lifestyle/adult-health/in-depth/sleep/art-20048379"),
                Article(id: "17", title: "Travel Tips for IBD Patients", excerpt: "Essential advice for traveling safely and comfortably with IBD.", category: .lifestyle, readTime: "7 min read", imageName: "airplane", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "18", title: "Work and IBD", excerpt: "Managing IBD symptoms while maintaining a successful career.", category: .lifestyle, readTime: "6 min read", imageName: "briefcase.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "19", title: "Mental Health Support", excerpt: "Resources and strategies for maintaining mental health with IBD.", category: .lifestyle, readTime: "5 min read", imageName: "heart.circle.fill", url: "https://www.mayoclinic.org/healthy-lifestyle/stress-management/in-depth/stress/art-20046037")
            ]
        case .research:
            return [
                Article(id: "20", title: "Latest IBD Research Updates", excerpt: "Stay informed about the newest developments in IBD treatment and research.", category: .research, readTime: "8 min read", imageName: "microscope.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "21", title: "Clinical Trials for IBD", excerpt: "Information about current clinical trials and how to participate.", category: .research, readTime: "6 min read", imageName: "clipboard.fill", url: "https://clinicaltrials.gov/ct2/results?cond=Inflammatory+Bowel+Disease"),
                Article(id: "22", title: "New Treatment Options", excerpt: "Emerging therapies and treatment approaches for IBD patients.", category: .research, readTime: "7 min read", imageName: "staroflife.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "23", title: "Genetic Research in IBD", excerpt: "Understanding the genetic factors that contribute to IBD development.", category: .research, readTime: "6 min read", imageName: "dna", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320"),
                Article(id: "24", title: "Microbiome Research", excerpt: "Latest findings on the gut microbiome and its role in IBD.", category: .research, readTime: "7 min read", imageName: "bacteria.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/diagnosis-treatment/drc-20353320")
            ]
        case .community:
            return [
                Article(id: "25", title: "Connecting with the IBD Community", excerpt: "Find support groups and connect with others who understand your journey.", category: .community, readTime: "4 min read", imageName: "person.3.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "26", title: "Online Support Groups", excerpt: "Virtual communities and forums for IBD patients and caregivers.", category: .community, readTime: "3 min read", imageName: "network", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "27", title: "Patient Stories and Experiences", excerpt: "Read inspiring stories from others living with IBD.", category: .community, readTime: "5 min read", imageName: "book.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "28", title: "Caregiver Support Resources", excerpt: "Resources and support for family members and caregivers of IBD patients.", category: .community, readTime: "6 min read", imageName: "heart.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "29", title: "Advocacy and Awareness", excerpt: "How to get involved in IBD advocacy and raise awareness.", category: .community, readTime: "4 min read", imageName: "megaphone.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315")
            ]
        case .blogs:
            return [
                Article(id: "30", title: "Living Well with IBD", excerpt: "Personal stories and tips for managing life with inflammatory bowel disease.", category: .blogs, readTime: "5 min read", imageName: "square.and.pencil", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "31", title: "My Journey to Remission", excerpt: "Personal story of achieving remission through diet and lifestyle changes.", category: .blogs, readTime: "8 min read", imageName: "person.crop.circle.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "32", title: "Living with Crohn's: A Teen's Perspective", excerpt: "A young person's experience managing Crohn's disease in high school.", category: .blogs, readTime: "6 min read", imageName: "graduationcap.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "33", title: "Finding Strength Through Community", excerpt: "How connecting with other IBD patients changed my outlook on life.", category: .blogs, readTime: "5 min read", imageName: "person.2.fill", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "34", title: "Diet Success Stories", excerpt: "Real stories from people who found relief through dietary changes.", category: .blogs, readTime: "7 min read", imageName: "leaf.arrow.circlepath", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315"),
                Article(id: "35", title: "Mental Health and IBD", excerpt: "Personal experiences with managing mental health alongside IBD.", category: .blogs, readTime: "6 min read", imageName: "brain.head.profile", url: "https://www.mayoclinic.org/diseases-conditions/inflammatory-bowel-disease/symptoms-causes/syc-20353315")
            ]
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension SearchView: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location.coordinate
        locationManager.stopUpdatingLocation()
        
        // Load nearby hospitals and specialists when location is obtained
        if selectedDiscoverCategory == .community {
            loadNearbyHospitals()
            loadNearbySpecialists()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🔍 SearchView: Location error: \(error)")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showingLocationPermission = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Supporting Views

struct DiscoverCategoryCard: View {
    let category: DiscoverCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) { // Reduced spacing
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 24)) // Smaller icon
                        .foregroundColor(category.color)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16)) // Smaller checkmark
                            .foregroundColor(.green)
                    }
                }
                Text(category.displayName)
                    .font(.subheadline) // Smaller font
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60) // Reduced height
            .padding(8) // Less padding
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(12) // Slightly smaller radius
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : category.color.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    Image(systemName: "arrow.up.right.square")
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
        .buttonStyle(PlainButtonStyle())
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
    case blogs = "blogs"
    
    var displayName: String {
        switch self {
        case .nutrition: return "Nutrition"
        case .medication: return "Medication"
        case .lifestyle: return "Lifestyle"
        case .research: return "Research"
        case .community: return "Community"
        case .blogs: return "Blogs"
        }
    }
    
    var icon: String {
        switch self {
        case .nutrition: return "leaf.fill"
        case .medication: return "pills.fill"
        case .lifestyle: return "figure.walk"
        case .research: return "microscope.fill"
        case .community: return "person.3.fill"
        case .blogs: return "square.and.pencil"
        }
    }
    
    var color: Color {
        switch self {
        case .nutrition: return .green
        case .medication: return .blue
        case .lifestyle: return .orange
        case .research: return .purple
        case .community: return .red
        case .blogs: return .indigo
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
    let url: String
}

// MARK: - Article Viewer

struct ArticleViewerView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var retryKey = UUID()
    @State private var webViewReady = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Article Header
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
                    }
                    
                    Text(article.excerpt)
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .lineLimit(3)
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                
                // Content Area
                if let url = URL(string: article.url) {
                    ZStack {
                        WebView(url: url, isLoading: $isLoading, errorMessage: $errorMessage, retryKey: retryKey)
                            .onAppear {
                                // Ensure WebView is ready when view appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    webViewReady = true
                                }
                            }
                        
                        if isLoading || !webViewReady {
                            VStack(spacing: 12) {
                                ProgressView("Loading article...")
                                    .scaleEffect(1.2)
                                Text("Please wait while we load the content")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.ibdBackground.opacity(0.95))
                            .transition(.opacity)
                        }
                        
                        if let currentErrorMessage = errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                
                                Text("Unable to load article")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ibdPrimaryText)
                                
                                Text(currentErrorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.ibdSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 12) {
                                    Button("Try Again") {
                                        // Reset states and force WebView reload
                                        errorMessage = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isLoading = true
                                            retryKey = UUID()
                                        }
                                    }
                                    .foregroundColor(.ibdPrimary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.ibdPrimary.opacity(0.1))
                                    .cornerRadius(8)
                                    
                                    Button("Open in Browser") {
                                        UIApplication.shared.open(url)
                                        dismiss()
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.ibdPrimary)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.ibdBackground.opacity(0.95))
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
                    .animation(.easeInOut(duration: 0.3), value: errorMessage)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Invalid Article URL")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Text("This article has an invalid or missing URL. Please try a different article or contact support.")
                            .font(.subheadline)
                            .foregroundColor(.ibdSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ibdBackground)
                }
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = URL(string: article.url) {
                        Button("Open in Browser") {
                            UIApplication.shared.open(url)
                        }
                        .foregroundColor(.ibdPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let retryKey: UUID
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        
        // Pre-warm the WebView by loading a simple HTML page
        let prewarmHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background: white; }
            </style>
        </head>
        <body></body>
        </html>
        """
        webView.loadHTMLString(prewarmHTML, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Always load the URL when updateUIView is called
        // This ensures the WebView loads content even on first selection
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        
        // Add user agent to avoid some blocking
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        // Add a small delay to ensure WebView is ready, especially for first load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.errorMessage = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                let nsError = error as NSError
                // Don't show error for cancelled requests (user initiated retry)
                if nsError.code != NSURLErrorCancelled {
                    self.parent.errorMessage = self.getUserFriendlyErrorMessage(error)
                    print("🔴 WebView navigation failed: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                let nsError = error as NSError
                // Don't show error for cancelled requests (user initiated retry)
                if nsError.code != NSURLErrorCancelled {
                    self.parent.errorMessage = self.getUserFriendlyErrorMessage(error)
                    print("🔴 WebView provisional navigation failed: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Handle SSL challenges more gracefully
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
            completionHandler(.performDefaultHandling, nil)
        }
        

        

        
        private func getUserFriendlyErrorMessage(_ error: Error) -> String {
            let nsError = error as NSError
            
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network settings and try again."
            case NSURLErrorTimedOut:
                return "The article took too long to load. Please try again or open in browser."
            case NSURLErrorCannotFindHost:
                return "The article URL is not available. Please try a different article or open in browser."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to the article website. It might be temporarily unavailable."
            case NSURLErrorSecureConnectionFailed:
                return "Secure connection failed. The website's security certificate might be invalid."
            case NSURLErrorServerCertificateUntrusted:
                return "The website's security certificate is not trusted."
            case NSURLErrorCancelled:
                return "Article loading was cancelled. Please try again."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to the article website. It might be temporarily unavailable."
            case NSURLErrorBadServerResponse:
                return "The article server returned an error. Please try again later."
            default:
                return "Unable to load the article content. Please try opening it in your browser instead."
            }
        }
    }
}

// MARK: - Community Section

struct CommunitySection: View {
    let hospitals: [Hospital]
    let specialists: [IBDSpecialist]
    let userLocation: CLLocationCoordinate2D?
    let isLoading: Bool
    let onRequestLocation: () -> Void
    let onLoadHospitals: () -> Void
    let onLoadSpecialists: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Location Permission Section
            if userLocation == nil {
                VStack(spacing: 16) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.ibdPrimary)
                    
                    Text("Enable Location Services")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("To find nearby hospitals and specialists, we need your location.")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onRequestLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.title3)
                            Text("Enable Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ibdPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
            } else {
                // Hospitals Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Nearby Hospitals & Medical Centers")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if hospitals.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Text("No hospitals found nearby")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Button("Search Again") {
                                onLoadHospitals()
                            }
                            .font(.caption)
                            .foregroundColor(.ibdPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ibdSurfaceBackground.opacity(0.5))
                        .cornerRadius(8)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(hospitals) { hospital in
                                HospitalCard(hospital: hospital, userLocation: userLocation)
                            }
                        }
                    }
                }
                
                // Specialists Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("IBD Specialists")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if specialists.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Text("No specialists found nearby")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Button("Search Again") {
                                onLoadSpecialists()
                            }
                            .font(.caption)
                            .foregroundColor(.ibdPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ibdSurfaceBackground.opacity(0.5))
                        .cornerRadius(8)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(specialists) { specialist in
                                SpecialistCard(specialist: specialist, userLocation: userLocation)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hospital Card

struct HospitalCard: View {
    let hospital: Hospital
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(hospital.type.displayName)
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.ibdPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let distance = hospital.distance {
                    Text(String(format: "%.1f miles", distance * 0.621371)) // Convert km to miles
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            
            Text(hospital.address)
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
            
            if hospital.ibdServices {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("IBD Services Available")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                if let phone = hospital.phone {
                    Button(action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(phone)
                                .font(.caption)
                        }
                        .foregroundColor(.ibdPrimary)
                    }
                }
                
                Spacer()
                
                if let website = hospital.website {
                    Button(action: {
                        if let url = URL(string: website) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text("Website")
                                .font(.caption)
                        }
                        .foregroundColor(.ibdPrimary)
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Specialist Card

struct SpecialistCard: View {
    let specialist: IBDSpecialist
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(specialist.title) \(specialist.name)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(specialist.specialty)
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.ibdPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let distance = specialist.distance {
                    Text(String(format: "%.1f miles", distance * 0.621371)) // Convert km to miles
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            
            if let address = specialist.address {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            if let yearsExperience = specialist.yearsExperience {
                Text("\(yearsExperience) years experience")
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            HStack {
                if let phone = specialist.phone {
                    Button(action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(phone)
                                .font(.caption)
                        }
                        .foregroundColor(.ibdPrimary)
                    }
                }
                
                Spacer()
                
                if let website = specialist.website {
                    Button(action: {
                        if let url = URL(string: website) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text("Website")
                                .font(.caption)
                        }
                        .foregroundColor(.ibdPrimary)
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct Hospital: Identifiable, Codable {
    let id: Int
    let name: String
    let type: HospitalType
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let latitude: Double
    let longitude: Double
    let phone: String?
    let website: String?
    let email: String?
    let description: String?
    let specialties: [String]
    let ibdServices: Bool
    let emergencyServices: Bool
    let insuranceAccepted: [String]
    let hoursOfOperation: [String: String]
    let rating: Double?
    let reviewCount: Int
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, address, city, state, zipCode = "zip_code", country, latitude, longitude
        case phone, website, email, description, specialties, ibdServices = "ibd_services"
        case emergencyServices = "emergency_services", insuranceAccepted = "insurance_accepted"
        case hoursOfOperation = "hours_of_operation", rating, reviewCount = "review_count"
        case distance = "distance_km"
    }
}

enum HospitalType: String, Codable, CaseIterable {
    case hospital = "hospital"
    case clinic = "clinic"
    case medicalCenter = "medical_center"
    case specialtyCenter = "specialty_center"
    
    var displayName: String {
        switch self {
        case .hospital: return "Hospital"
        case .clinic: return "Clinic"
        case .medicalCenter: return "Medical Center"
        case .specialtyCenter: return "Specialty Center"
        }
    }
}

struct IBDSpecialist: Identifiable, Codable {
    let id: Int
    let name: String
    let title: String
    let specialty: String
    let medicalCenterId: Int?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let email: String?
    let website: String?
    let education: [String]
    let certifications: [String]
    let languages: [String]
    let insuranceAccepted: [String]
    let consultationFee: Double?
    let rating: Double?
    let reviewCount: Int
    let yearsExperience: Int?
    let ibdFocusAreas: [String]
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, title, specialty, medicalCenterId = "medical_center_id"
        case address, city, state, zipCode = "zip_code", country, latitude, longitude
        case phone, email, website, education, certifications, languages
        case insuranceAccepted = "insurance_accepted", consultationFee = "consultation_fee"
        case rating, reviewCount = "review_count", yearsExperience = "years_experience"
        case ibdFocusAreas = "ibd_focus_areas", distance = "distance_km"
    }
}

#Preview {
    SearchView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
} 