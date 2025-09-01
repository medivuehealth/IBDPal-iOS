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
    @State private var supportOrganizations: [IBDSupportOrganization] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showingLocationPermission = false
    @State private var isLoadingCommunity = false
    @State private var locationManager = LocationManager()
    
    private let discoverCategories: [DiscoverCategory] = [.nutrition, .medication, .lifestyle, .research, .community, .blogs]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchHeader(searchText: $searchText, onSearch: performSearch)
                
                // Discover Categories
                DiscoverCategoriesView(selectedCategory: $selectedDiscoverCategory, onCategorySelected: {
                    print("🔍 SearchView: Category selected: \(selectedDiscoverCategory)")
                    if selectedDiscoverCategory == .community {
                        print("🔍 SearchView: Community category selected, loading data...")
                        if let location = userLocation {
                            loadNearbyHospitals()
                            loadNearbySpecialists()
                            loadNearbySupportOrganizations()
                        } else {
                            print("🔍 SearchView: No location available yet for community data")
                        }
                    } else {
                        loadArticles(for: selectedDiscoverCategory)
                    }
                })
                
                // Content Area
                SearchContentView(
                    selectedCategory: selectedDiscoverCategory,
                    searchResults: searchResults,
                    articles: articles,
                    isLoading: isLoading,
                    userData: userData,
                    calculatedNutrition: $calculatedNutrition,
                    showingNutritionResults: $showingNutritionResults,
                    showingArticleViewer: $showingArticleViewer,
                    selectedArticle: $selectedArticle,
                    hospitals: hospitals,
                    specialists: specialists,
                    supportOrganizations: supportOrganizations,
                    userLocation: userLocation,
                    isLoadingCommunity: isLoadingCommunity,
                    authorizationStatus: locationManager.authorizationStatus,
                    locationManager: locationManager,
                    onRequestLocation: requestLocationPermission,
                    onLoadHospitals: loadNearbyHospitals,
                    onLoadSpecialists: loadNearbySpecialists,
                    onLoadSupportOrganizations: loadNearbySupportOrganizations
                )
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNutritionResults) {
                if let nutrition = calculatedNutrition {
                    NutritionResultsView(nutrition: nutrition)
                }
            }
            .sheet(isPresented: $showingArticleViewer) {
                if let article = selectedArticle {
                    ArticleViewerView(article: article)
                }
            }
            .onAppear {
                // Set up location callback
                locationManager.onLocationObtained = { location in
                    DispatchQueue.main.async {
                        print("🔍 SearchView: Location obtained: \(location.latitude), \(location.longitude)")
                        self.userLocation = location
                        if self.selectedDiscoverCategory == .community {
                            print("🔍 SearchView: Loading community data for location...")
                            self.loadNearbyHospitals()
                            self.loadNearbySpecialists()
                            self.loadNearbySupportOrganizations()
                        }
                    }
                }
                
                // Check if location permission is already granted
                let currentStatus = locationManager.authorizationStatus
                print("🔍 SearchView: Current authorization status on appear: \(currentStatus.rawValue)")
                if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
                    print("🔍 SearchView: Permission already granted, starting location updates...")
                    locationManager.startUpdatingLocation()
                    
                    // If we're already on community tab, load data
                    if selectedDiscoverCategory == .community {
                        print("🔍 SearchView: Already on community tab, will load data when location is available")
                    }
                }
            }
            .onReceive(locationManager.$authorizationStatus) { status in
                print("🔍 SearchView: Authorization status changed to: \(status.rawValue)")
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    print("🔍 SearchView: Permission granted, starting location updates...")
                    locationManager.startUpdatingLocation()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadNearbyHospitals() {
        guard let location = userLocation else { 
            print("🔍 SearchView: No user location available for hospitals")
            return 
        }
        
        print("🔍 SearchView: Loading hospitals for location: \(location.latitude), \(location.longitude)")
        isLoadingCommunity = true
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/community/hospitals?latitude=\(location.latitude)&longitude=\(location.longitude)&radius=80.5&limit=20" // 50 miles = 80.5 km
        
        print("🔍 SearchView: Hospitals API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("🔍 SearchView: Invalid hospitals URL")
            isLoadingCommunity = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingCommunity = false
                
                if let error = error {
                    print("🔍 SearchView: Error loading hospitals: \(error)")
                    return
                }
                
                print("🔍 SearchView: Hospitals API response received")
                
                if let data = data {
                    print("🔍 SearchView: Hospitals data received: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    
                    if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = response["success"] as? Bool,
                       success,
                       let dataDict = response["data"] as? [String: Any],
                       let hospitalsData = dataDict["hospitals"] as? [[String: Any]] {
                        
                        print("🔍 SearchView: Parsed \(hospitalsData.count) hospitals")
                        self.hospitals = hospitalsData.compactMap { hospitalData in
                            guard let idString = hospitalData["id"] as? String,
                                  let name = hospitalData["name"] as? String,
                                  let typeString = hospitalData["type"] as? String,
                                  let type = HospitalType(rawValue: typeString),
                                  let address = hospitalData["address"] as? String else {
                                print("🔍 SearchView: Failed to parse hospital data: \(hospitalData)")
                                return nil
                            }
                            
                            // Handle latitude and longitude as both String and Double
                            let latitude: Double
                            let longitude: Double
                            
                            if let latString = hospitalData["latitude"] as? String {
                                latitude = Double(latString) ?? 0.0
                            } else if let latDouble = hospitalData["latitude"] as? Double {
                                latitude = latDouble
                            } else {
                                print("🔍 SearchView: Failed to parse hospital latitude")
                                return nil
                            }
                            
                            if let lngString = hospitalData["longitude"] as? String {
                                longitude = Double(lngString) ?? 0.0
                            } else if let lngDouble = hospitalData["longitude"] as? Double {
                                longitude = lngDouble
                            } else {
                                print("🔍 SearchView: Failed to parse hospital longitude")
                                return nil
                            }
                            
                            // Use string ID directly
                            let id = idString
                            
                            let phone = hospitalData["phone"] as? String
                            let website = hospitalData["website"] as? String
                            let email = hospitalData["email"] as? String
                            let description = hospitalData["description"] as? String
                            let specialties = hospitalData["specialties"] as? [String] ?? []
                            
                            // Handle both boolean and integer values for services
                            let ibdServicesRaw = hospitalData["ibd_services"]
                            let ibdServices = (ibdServicesRaw as? Bool) ?? (ibdServicesRaw as? Int == 1) ?? false
                            
                            let emergencyServicesRaw = hospitalData["emergency_services"]
                            let emergencyServices = (emergencyServicesRaw as? Bool) ?? (emergencyServicesRaw as? Int == 1) ?? false
                            
                            // Optional fields with defaults
                            let city = hospitalData["city"] as? String ?? "Unknown"
                            let state = hospitalData["state"] as? String ?? "Unknown"
                            let zipCode = hospitalData["zip_code"] as? String ?? "Unknown"
                            let country = hospitalData["country"] as? String ?? "Unknown"
                            
                            let insuranceAccepted = hospitalData["insurance_accepted"] as? [String] ?? []
                            let hoursOfOperation = hospitalData["hours_of_operation"] as? [String: String] ?? [:]
                            let rating = hospitalData["rating"] as? Double
                            let reviewCount = hospitalData["review_count"] as? Int ?? 0
                            let distance = hospitalData["distance_km"] as? Double
                            
                            print("🔍 SearchView: Successfully parsed hospital: \(name)")
                            
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
            }
        }.resume()
    }
    
    private func loadNearbySpecialists() {
        guard let location = userLocation else { 
            print("🔍 SearchView: No user location available for specialists")
            return 
        }
        
        print("🔍 SearchView: Loading specialists for location: \(location.latitude), \(location.longitude)")
        isLoadingCommunity = true
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/community/specialists?latitude=\(location.latitude)&longitude=\(location.longitude)&radius=80.5&limit=20" // 50 miles = 80.5 km
        
        print("🔍 SearchView: Specialists API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("🔍 SearchView: Invalid specialists URL")
            isLoadingCommunity = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingCommunity = false
                
                if let error = error {
                    print("🔍 SearchView: Error loading specialists: \(error)")
                    return
                }
                
                print("🔍 SearchView: Specialists API response received")
                
                if let data = data {
                    print("🔍 SearchView: Specialists data received: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    
                    if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = response["success"] as? Bool,
                       success,
                       let dataDict = response["data"] as? [String: Any],
                       let specialistsData = dataDict["specialists"] as? [[String: Any]] {
                        
                        print("🔍 SearchView: Parsed \(specialistsData.count) specialists")
                        self.specialists = specialistsData.compactMap { specialistData in
                            guard let id = specialistData["id"] as? String,
                                  let name = specialistData["name"] as? String,
                                  let address = specialistData["address"] as? String else {
                                print("🔍 SearchView: Failed to parse specialist data: \(specialistData)")
                                return nil
                            }
                            
                            // Handle latitude and longitude as both String and Double
                            let latitude: Double
                            let longitude: Double
                            
                            if let latString = specialistData["latitude"] as? String {
                                latitude = Double(latString) ?? 0.0
                            } else if let latDouble = specialistData["latitude"] as? Double {
                                latitude = latDouble
                            } else {
                                print("🔍 SearchView: Failed to parse specialist latitude")
                                return nil
                            }
                            
                            if let lngString = specialistData["longitude"] as? String {
                                longitude = Double(lngString) ?? 0.0
                            } else if let lngDouble = specialistData["longitude"] as? Double {
                                longitude = lngDouble
                            } else {
                                print("🔍 SearchView: Failed to parse specialist longitude")
                                return nil
                            }
                            
                            let phone = specialistData["phone"] as? String
                            let website = specialistData["website"] as? String
                            let email = specialistData["email"] as? String
                            let specialty = specialistData["specialty"] as? String ?? "Gastroenterology"
                            
                            // Handle both boolean and integer values for ibd_focus
                            let ibdFocusRaw = specialistData["ibd_focus"]
                            let ibdFocus = (ibdFocusRaw as? Bool) ?? (ibdFocusRaw as? Int == 1) ?? false
                            
                            // Optional fields with defaults
                            let city = specialistData["city"] as? String ?? "Unknown"
                            let state = specialistData["state"] as? String ?? "Unknown"
                            let zipCode = specialistData["zip_code"] as? String ?? "Unknown"
                            let country = specialistData["country"] as? String ?? "Unknown"
                            
                            let rating = specialistData["rating"] as? Double
                            let reviewCount = specialistData["review_count"] as? Int ?? 0
                            let distance = specialistData["distance_km"] as? Double
                            
                            print("🔍 SearchView: Successfully parsed specialist: \(name)")
                            
                            return IBDSpecialist(
                                id: id,
                                name: name,
                                title: "Dr.",
                                specialty: specialty,
                                medicalCenterId: nil,
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
                                education: [],
                                certifications: [],
                                languages: [],
                                insuranceAccepted: [],
                                consultationFee: nil,
                                rating: rating,
                                reviewCount: reviewCount,
                                yearsExperience: nil,
                                ibdFocusAreas: ibdFocus ? ["IBD", "Crohn's Disease", "Ulcerative Colitis"] : [],
                                distance: distance
                            )
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func loadNearbySupportOrganizations() {
        guard let location = userLocation else { 
            print("🔍 SearchView: No user location available for support organizations")
            return 
        }
        
        print("🔍 SearchView: Loading support organizations for location: \(location.latitude), \(location.longitude)")
        isLoadingCommunity = true
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/community/support-organizations?latitude=\(location.latitude)&longitude=\(location.longitude)&radius=80.5&limit=20" // 50 miles = 80.5 km
        
        print("🔍 SearchView: Support Organizations API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("🔍 SearchView: Invalid support organizations URL")
            isLoadingCommunity = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingCommunity = false
                
                if let error = error {
                    print("🔍 SearchView: Error loading support organizations: \(error)")
                    return
                }
                
                print("🔍 SearchView: Support Organizations API response received")
                
                if let data = data {
                    print("🔍 SearchView: Support Organizations data received: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    
                    if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = response["success"] as? Bool,
                       success,
                       let dataDict = response["data"] as? [String: Any],
                       let organizationsData = dataDict["organizations"] as? [[String: Any]] {
                        
                        print("🔍 SearchView: Parsed \(organizationsData.count) support organizations")
                        self.supportOrganizations = organizationsData.compactMap { orgData in
                            guard let id = orgData["id"] as? Int,
                                  let name = orgData["name"] as? String,
                                  let type = orgData["type"] as? String,
                                  let address = orgData["address"] as? String,
                                  let city = orgData["city"] as? String,
                                  let state = orgData["state"] as? String,
                                  let zipCode = orgData["zip_code"] as? String,
                                  let country = orgData["country"] as? String,
                                  let latitudeString = orgData["latitude"] as? String,
                                  let longitudeString = orgData["longitude"] as? String,
                                  let description = orgData["description"] as? String,
                                  let services = orgData["services"] as? [String],
                                  let latitude = Double(latitudeString),
                                  let longitude = Double(longitudeString) else {
                                print("🔍 SearchView: Failed to parse support organization data: \(orgData)")
                                return nil
                            }
                            
                            let phone = orgData["phone"] as? String
                            let website = orgData["website"] as? String
                            let email = orgData["email"] as? String
                            let supportGroups = orgData["support_groups"] as? Bool ?? false
                            let educationalPrograms = orgData["educational_programs"] as? Bool ?? false
                            let advocacy = orgData["advocacy"] as? Bool ?? false
                            let researchFunding = orgData["research_funding"] as? Bool ?? false
                            let rating = orgData["rating"] as? Double
                            let reviewCount = orgData["review_count"] as? Int ?? 0
                            let distance = orgData["distance_km"] as? Double
                            
                            print("🔍 SearchView: Successfully parsed support organization: \(name)")
                            
                            return IBDSupportOrganization(
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
                                services: services,
                                supportGroups: supportGroups,
                                educationalPrograms: educationalPrograms,
                                advocacy: advocacy,
                                researchFunding: researchFunding,
                                rating: rating,
                                reviewCount: reviewCount,
                                distanceKm: distance
                            )
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        searchResults = [] // Clear previous results
        
        // Use FoodDatabase search method
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let foodDatabase = FoodDatabase.shared
            self.searchResults = foodDatabase.searchFoods(query: self.searchText)
            self.isLoading = false
        }
    }
    
    private func getSampleFoodItems(for searchTerm: String) -> [DatabaseFoodItem] {
        let foodDatabase = FoodDatabase.shared
        let allFoods = foodDatabase.allFoods
        
        return allFoods.filter { food in
            food.name.lowercased().contains(searchTerm.lowercased()) ||
            food.category.lowercased().contains(searchTerm.lowercased()) ||
            food.region.lowercased().contains(searchTerm.lowercased())
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
    
    private func getSampleArticles(for category: DiscoverCategory) -> [Article] {
        switch category {
        case .nutrition:
            return [
                Article(
                    id: "1",
                    title: "Nutrition Tips for IBD Management",
                    summary: "Learn about the best foods to eat and avoid when managing IBD symptoms.",
                    content: "Managing nutrition with IBD can be challenging...",
                    category: "nutrition",
                    author: "IBD Nutrition Team",
                    publishedDate: Date().addingTimeInterval(-86400 * 7),
                    readTime: 5,
                    imageURL: nil
                ),
                Article(
                    id: "2",
                    title: "Anti-Inflammatory Diet Guide",
                    summary: "Discover foods that can help reduce inflammation in your digestive system.",
                    content: "An anti-inflammatory diet focuses on...",
                    category: "nutrition",
                    author: "Dr. Sarah Johnson",
                    publishedDate: Date().addingTimeInterval(-86400 * 3),
                    readTime: 8,
                    imageURL: nil
                )
            ]
        case .medication:
            return [
                Article(
                    id: "3",
                    title: "Understanding IBD Medications",
                    summary: "A comprehensive guide to the different types of medications used to treat IBD.",
                    content: "There are several categories of medications...",
                    category: "medication",
                    author: "Dr. Michael Chen",
                    publishedDate: Date().addingTimeInterval(-86400 * 5),
                    readTime: 10,
                    imageURL: nil
                )
            ]
        case .lifestyle:
            return [
                Article(
                    id: "4",
                    title: "Exercise and IBD: Finding the Right Balance",
                    summary: "How to stay active while managing your IBD symptoms.",
                    content: "Exercise can be beneficial for IBD patients...",
                    category: "lifestyle",
                    author: "Fitness Expert",
                    publishedDate: Date().addingTimeInterval(-86400 * 2),
                    readTime: 6,
                    imageURL: nil
                )
            ]
        case .research:
            return [
                Article(
                    id: "5",
                    title: "Latest IBD Research Breakthroughs",
                    summary: "Stay updated with the newest developments in IBD treatment and research.",
                    content: "Recent studies have shown promising results...",
                    category: "research",
                    author: "Research Team",
                    publishedDate: Date().addingTimeInterval(-86400 * 1),
                    readTime: 12,
                    imageURL: nil
                )
            ]
        case .community:
            return [
                Article(
                    id: "6",
                    title: "Building Your IBD Support Network",
                    summary: "Connect with others who understand your journey with IBD.",
                    content: "Having a strong support network is crucial...",
                    category: "community",
                    author: "Community Team",
                    publishedDate: Date().addingTimeInterval(-86400 * 4),
                    readTime: 7,
                    imageURL: nil
                )
            ]
        case .blogs:
            return [
                Article(
                    id: "7",
                    title: "Personal Stories from the IBD Community",
                    summary: "Read inspiring stories from people living with IBD.",
                    content: "Every IBD journey is unique...",
                    category: "blogs",
                    author: "Community Members",
                    publishedDate: Date().addingTimeInterval(-86400 * 6),
                    readTime: 9,
                    imageURL: nil
                )
            ]
        }
    }
    
    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        print("🔍 SearchView: Current location authorization status: \(status.rawValue)")
        
        if !CLLocationManager.locationServicesEnabled() {
            print("🔍 SearchView: Location services are disabled on this device!")
            return
        }
        
        print("🔍 SearchView: Location services are enabled on device")
        
        switch status {
        case .notDetermined:
            print("🔍 SearchView: Requesting location permission...")
            // Move permission request to background thread to avoid UI unresponsiveness
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.locationManager.requestLocation()
                }
            }
        case .denied, .restricted:
            print("🔍 SearchView: Location permission denied/restricted. Opening settings...")
            // Open settings if permission is denied
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                print("🔍 SearchView: Settings URL: \(settingsUrl)")
                UIApplication.shared.open(settingsUrl) { success in
                    print("🔍 SearchView: Settings opened successfully: \(success)")
                    if success {
                        print("🔍 SearchView: Settings opened successfully")
                    } else {
                        print("🔍 SearchView: Failed to open settings")
                    }
                }
            } else {
                print("🔍 SearchView: Failed to create settings URL")
            }
        case .authorizedWhenInUse, .authorizedAlways:
            print("🔍 SearchView: Location permission already granted. Starting location updates...")
            // Permission already granted, start location updates
            locationManager.startUpdatingLocation()
        @unknown default:
            print("🔍 SearchView: Unknown authorization status: \(status)")
            break
        }
    }
}

// MARK: - Search Header

struct SearchHeader: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Search")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.ibdSecondaryText)
                
                TextField("Search for foods, articles, or topics...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { _, _ in
                        if !searchText.isEmpty {
                            onSearch()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
            }
            .padding()
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.ibdBackground)
    }
}

// MARK: - Discover Categories View

struct DiscoverCategoriesView: View {
    @Binding var selectedCategory: DiscoverCategory
    let onCategorySelected: () -> Void
    
    private let discoverCategories: [DiscoverCategory] = [.nutrition, .medication, .lifestyle, .research, .community, .blogs]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Discover")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(discoverCategories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        onCategorySelected()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedCategory == category ? .white : .ibdPrimary)
                            
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedCategory == category ? .white : .ibdPrimaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(selectedCategory == category ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.ibdBackground)
    }
}

// MARK: - Search Content View

struct SearchContentView: View {
    let selectedCategory: DiscoverCategory
    let searchResults: [DatabaseFoodItem]
    let articles: [Article]
    let isLoading: Bool
    let userData: UserData?
    @Binding var calculatedNutrition: SearchCalculatedNutrition?
    @Binding var showingNutritionResults: Bool
    @Binding var showingArticleViewer: Bool
    @Binding var selectedArticle: Article?
    let hospitals: [Hospital]
    let specialists: [IBDSpecialist]
    let supportOrganizations: [IBDSupportOrganization]
    let userLocation: CLLocationCoordinate2D?
    let isLoadingCommunity: Bool
    let authorizationStatus: CLAuthorizationStatus
    let locationManager: LocationManager
    let onRequestLocation: () -> Void
    let onLoadHospitals: () -> Void
    let onLoadSpecialists: () -> Void
    let onLoadSupportOrganizations: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if selectedCategory == .nutrition {
                    // Nutrition Search Results
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Search Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.ibdPrimaryText)
                            
                            ForEach(searchResults, id: \.id) { food in
                                FoodSearchResultCard(food: food) { nutrition in
                                    calculatedNutrition = nutrition
                                    showingNutritionResults = true
                                }
                            }
                        }
                        .padding()
                    } else if !searchResults.isEmpty && isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                } else if selectedCategory == .community {
                    CommunitySection(
                        hospitals: hospitals,
                        specialists: specialists,
                        supportOrganizations: supportOrganizations,
                        userLocation: userLocation,
                        isLoading: isLoadingCommunity,
                        authorizationStatus: authorizationStatus,
                        locationManager: locationManager,
                        onRequestLocation: onRequestLocation,
                        onLoadHospitals: onLoadHospitals,
                        onLoadSpecialists: onLoadSpecialists,
                        onLoadSupportOrganizations: onLoadSupportOrganizations
                    )
                    .padding()
                } else if selectedCategory == .blogs {
                    // Stories/Blogs Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("IBD Stories")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                            .padding(.horizontal)
                        
                        BlogView(userData: userData)
                    }
                } else {
                    // Articles for other categories
                    if !articles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Articles")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.ibdPrimaryText)
                            
                            ForEach(articles) { article in
                                ArticleCard(article: article, onTap: {
                                    selectedArticle = article
                                    showingArticleViewer = true
                                })
                            }
                        }
                        .padding()
                    } else if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading articles...")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Article Card

struct ArticleCard: View {
    let article: Article
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                    .multilineTextAlignment(.leading)
                
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.ibdSecondaryText)
                    .lineLimit(2)
                
                HStack {
                    Text("By \(article.author)")
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                    
                    Spacer()
                    
                    Text("\(article.readTime) min read")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            .padding()
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct NutritionResultCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.ibdSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(8)
    }
}

struct SearchFoodRow: View {
    let food: DatabaseFoodItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(food.category)
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(food.calories))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimary)
                    
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            .padding()
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscoverCategoryCard: View {
    let category: DiscoverCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .ibdPrimary)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .ibdPrimaryText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.ibdPrimary : Color.ibdSurfaceBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Community Section

struct CommunitySection: View {
    let hospitals: [Hospital]
    let specialists: [IBDSpecialist]
    let supportOrganizations: [IBDSupportOrganization]
    let userLocation: CLLocationCoordinate2D?
    let isLoading: Bool
    let authorizationStatus: CLAuthorizationStatus
    let locationManager: LocationManager
    let onRequestLocation: () -> Void
    let onLoadHospitals: () -> Void
    let onLoadSpecialists: () -> Void
    let onLoadSupportOrganizations: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Location Permission Section
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                VStack(spacing: 16) {
                    Image(systemName: "location.slash.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Location Access Required")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("To find nearby hospitals and specialists, please enable location services in Settings.")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onRequestLocation) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.title3)
                            Text("Open Settings")
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
            } else if authorizationStatus == .notDetermined {
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
                    
                    // Debug button for development builds
                    Button(action: {
                        print("🔍 SearchView: Debug - Force requesting location permission...")
                        print("🔍 SearchView: Debug - Current authorization status: \(self.locationManager.authorizationStatus.rawValue)")
                        print("🔍 SearchView: Debug - Location services enabled: \(CLLocationManager.locationServicesEnabled())")
                        print("🔍 SearchView: Debug - Bundle identifier: \(Bundle.main.bundleIdentifier ?? "unknown")")
                        
                        // Check if we're in a development build
                        #if DEBUG
                        print("🔍 SearchView: Debug - Running in DEBUG mode")
                        #endif
                        
                        // Try a different approach - start updating location which should trigger permission
                        DispatchQueue.main.async {
                            print("🔍 SearchView: Debug - Attempting to start location updates...")
                            self.locationManager.clLocationManager.requestWhenInUseAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.circle")
                                .font(.caption)
                            Text("Debug: Force Permission")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.ibdSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.ibdSurfaceBackground.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
            } else if userLocation == nil && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) {
                VStack(spacing: 16) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.ibdPrimary)
                    
                    Text("Getting Your Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Please wait while we determine your location...")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, 8)
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

                // Support Organizations Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Support Organizations")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if supportOrganizations.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Text("No support organizations found nearby")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Button("Search Again") {
                                onLoadSupportOrganizations()
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
                            ForEach(supportOrganizations) { org in
                                SupportOrganizationCard(organization: org, userLocation: userLocation)
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

// MARK: - Support Organization Card

struct SupportOrganizationCard: View {
    let organization: IBDSupportOrganization
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(organization.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(organization.type)
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.ibdPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let distance = organization.distanceKm {
                    Text(String(format: "%.1f miles", distance * 0.621371)) // Convert km to miles
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            
            Text(organization.address)
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
            
            if organization.supportGroups {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Support Groups Available")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if organization.educationalPrograms {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("Educational Programs")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            if organization.advocacy {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Advocacy")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if organization.researchFunding {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Research Funding")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                if let phone = organization.phone {
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
                
                if let website = organization.website {
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

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var onLocationObtained: ((CLLocationCoordinate2D) -> Void)?
    
    // Public accessor for debugging
    var clLocationManager: CLLocationManager {
        return locationManager
    }
    
    override init() {
        super.init()
        print("🔍 LocationManager: Initializing...")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
        print("🔍 LocationManager: Initial authorization status: \(authorizationStatus.rawValue)")
    }
    
    func requestLocation() {
        print("🔍 LocationManager: Requesting location permission...")
        // First check if we need to request authorization
        if locationManager.authorizationStatus == .notDetermined {
            print("🔍 LocationManager: Authorization not determined, requesting permission...")
            // Call requestWhenInUseAuthorization on the main thread but don't block
            DispatchQueue.main.async {
                print("🔍 LocationManager: Calling requestWhenInUseAuthorization...")
                self.locationManager.requestWhenInUseAuthorization()
            }
        } else {
            print("🔍 LocationManager: Authorization already determined: \(locationManager.authorizationStatus.rawValue)")
            // If already authorized, start updating location
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                print("🔍 LocationManager: Already authorized, starting location updates...")
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func startUpdatingLocation() {
        print("🔍 LocationManager: Starting location updates...")
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { 
            print("🔍 LocationManager: No location data received")
            return 
        }
        print("🔍 LocationManager: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        self.location = location.coordinate
        locationManager.stopUpdatingLocation()
        
        // Call the callback if provided
        onLocationObtained?(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🔍 LocationManager: Location error: \(error)")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔍 LocationManager: Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("🔍 LocationManager: Permission granted, starting location updates...")
            locationManager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            print("🔍 LocationManager: Permission denied/restricted")
        }
    }
}

// MARK: - Data Models

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
        case .blogs: return "Stories"
        }
    }
    
    var icon: String {
        switch self {
        case .nutrition: return "leaf.fill"
        case .medication: return "pills.fill"
        case .lifestyle: return "heart.fill"
        case .research: return "magnifyingglass"
        case .community: return "person.3.fill"
        case .blogs: return "book.fill"
        }
    }
}

struct Hospital: Identifiable, Codable {
    let id: String
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
    let id: String
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

struct IBDSupportOrganization: Identifiable, Codable {
    let id: Int
    let name: String
    let type: String
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
    let description: String
    let services: [String]
    let supportGroups: Bool
    let educationalPrograms: Bool
    let advocacy: Bool
    let researchFunding: Bool
    let rating: Double?
    let reviewCount: Int
    let distanceKm: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, address, city, state, zipCode = "zip_code", country, latitude, longitude, phone, website, email, description, services, supportGroups = "support_groups", educationalPrograms = "educational_programs", advocacy, researchFunding = "research_funding", rating, reviewCount = "review_count", distanceKm = "distance_km"
    }
}

struct Article: Identifiable {
    let id: String
    let title: String
    let summary: String
    let content: String
    let category: String
    let author: String
    let publishedDate: Date
    let readTime: Int
    let imageURL: String?
}

struct SearchCalculatedNutrition {
    let detectedFoods: [String]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFiber: Double
    let totalFat: Double
}

struct ArticleViewerView: View {
    let article: Article
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    HStack {
                        Text("By \(article.author)")
                            .font(.subheadline)
                            .foregroundColor(.ibdPrimary)
                        
                        Spacer()
                        
                        Text("\(article.readTime) min read")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    Text(article.content)
                        .font(.body)
                        .foregroundColor(.ibdPrimaryText)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SearchView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
}

// MARK: - Food Search Result Card

struct FoodSearchResultCard: View {
    let food: DatabaseFoodItem
    let onNutritionCalculated: (SearchCalculatedNutrition) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(food.category)
                        .font(.caption)
                        .foregroundColor(.ibdPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.ibdPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(food.servingSize)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            HStack(spacing: 16) {
                NutritionInfo(label: "Cal", value: "\(Int(food.calories))")
                NutritionInfo(label: "Protein", value: "\(String(format: "%.1f", food.protein))g")
                NutritionInfo(label: "Carbs", value: "\(String(format: "%.1f", food.carbs))g")
                NutritionInfo(label: "Fiber", value: "\(String(format: "%.1f", food.fiber))g")
                NutritionInfo(label: "Fat", value: "\(String(format: "%.1f", food.fat))g")
            }
            
            Button(action: {
                let nutrition = SearchCalculatedNutrition(
                    detectedFoods: [food.name],
                    totalCalories: food.calories,
                    totalProtein: food.protein,
                    totalCarbs: food.carbs,
                    totalFiber: food.fiber,
                    totalFat: food.fat
                )
                onNutritionCalculated(nutrition)
            }) {
                Text("Add to Nutrition")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.ibdPrimary)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Nutrition Info

struct NutritionInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.ibdSecondaryText)
        }
    }
}

// MARK: - Nutrition Results View

struct NutritionResultsView: View {
    let nutrition: SearchCalculatedNutrition
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Nutrition Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        Text("Detected Foods: \(nutrition.detectedFoods.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.ibdSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Nutrition Summary
                    VStack(spacing: 16) {
                        Text("Nutrition Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            NutritionCard(title: "Calories", value: "\(Int(nutrition.totalCalories))", unit: "kcal", color: .orange)
                            NutritionCard(title: "Protein", value: "\(String(format: "%.1f", nutrition.totalProtein))", unit: "g", color: .blue)
                            NutritionCard(title: "Carbs", value: "\(String(format: "%.1f", nutrition.totalCarbs))", unit: "g", color: .green)
                            NutritionCard(title: "Fiber", value: "\(String(format: "%.1f", nutrition.totalFiber))", unit: "g", color: .purple)
                            NutritionCard(title: "Fat", value: "\(String(format: "%.1f", nutrition.totalFat))", unit: "g", color: .red)
                        }
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Nutrition Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Card

struct NutritionCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ibdBackground)
        .cornerRadius(8)
    }
} 
