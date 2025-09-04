import Foundation

// MARK: - Micronutrient Profile Data Models

struct MicronutrientProfile: Codable, Identifiable {
    let id = UUID()
    let userId: String
    let age: Int
    let weight: Double // in kg
    let height: Double? // in cm, optional
    let gender: String? // optional
    let micronutrients: [MicronutrientSupplement]
    let lastUpdated: Date
    
    init(userId: String, age: Int, weight: Double, height: Double? = nil, gender: String? = nil, micronutrients: [MicronutrientSupplement] = []) {
        self.userId = userId
        self.age = age
        self.weight = weight
        self.height = height
        self.gender = gender
        self.micronutrients = micronutrients
        self.lastUpdated = Date()
    }
}

struct MicronutrientSupplement: Codable, Identifiable {
    let id = UUID()
    let name: String
    let category: MicronutrientCategory
    let dosage: String
    let unit: String
    let frequency: SupplementFrequency
    let startDate: Date?
    let notes: String?
    
    init(name: String, category: MicronutrientCategory, dosage: String, unit: String, frequency: SupplementFrequency, startDate: Date? = nil, notes: String? = nil) {
        self.name = name
        self.category = category
        self.dosage = dosage
        self.unit = unit
        self.frequency = frequency
        self.startDate = startDate
        self.notes = notes
    }
}

enum MicronutrientCategory: String, CaseIterable, Codable {
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case probiotics = "Probiotics"
    case omega3 = "Omega-3"
    case antioxidants = "Antioxidants"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .vitamins: return "pills.fill"
        case .minerals: return "diamond.fill"
        case .probiotics: return "leaf.fill"
        case .omega3: return "fish.fill"
        case .antioxidants: return "sparkles"
        case .other: return "plus.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .vitamins: return "orange"
        case .minerals: return "blue"
        case .probiotics: return "green"
        case .omega3: return "purple"
        case .antioxidants: return "yellow"
        case .other: return "gray"
        }
    }
}

enum SupplementFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case weekly = "Weekly"
    case asNeeded = "As Needed"
    case other = "Other"
}

// MARK: - Common Micronutrients for IBD

struct CommonMicronutrients {
    static let vitamins = [
        "Vitamin D3", "Vitamin B12", "Folic Acid", "Vitamin C", "Vitamin E",
        "Vitamin A", "Vitamin K", "Thiamine (B1)", "Riboflavin (B2)", "Niacin (B3)",
        "Pantothenic Acid (B5)", "Pyridoxine (B6)", "Biotin (B7)", "Choline"
    ]
    
    static let minerals = [
        "Iron", "Zinc", "Magnesium", "Calcium", "Selenium", "Chromium",
        "Manganese", "Copper", "Iodine", "Phosphorus", "Potassium", "Sodium"
    ]
    
    static let probiotics = [
        "Lactobacillus", "Bifidobacterium", "Saccharomyces boulardii", "Multi-strain Probiotic",
        "Lactobacillus acidophilus", "Bifidobacterium longum", "Lactobacillus rhamnosus"
    ]
    
    static let omega3 = [
        "Fish Oil", "EPA/DHA", "Algal Oil", "Flaxseed Oil", "Krill Oil"
    ]
    
    static let antioxidants = [
        "Coenzyme Q10", "Alpha-lipoic Acid", "Resveratrol", "Curcumin", "Green Tea Extract",
        "Grape Seed Extract", "Quercetin", "Lycopene"
    ]
}

// MARK: - Dosage Units

enum DosageUnit: String, CaseIterable {
    case mg = "mg"
    case mcg = "mcg"
    case g = "g"
    case ml = "ml"
    case iu = "IU"
    case capsules = "capsules"
    case tablets = "tablets"
    case drops = "drops"
    case tsp = "tsp"
    case tbsp = "tbsp"
}

// MARK: - API Response Models

struct MicronutrientProfileResponse: Codable {
    let success: Bool
    let data: MicronutrientProfile?
    let message: String?
}

struct MicronutrientProfileListResponse: Codable {
    let success: Bool
    let data: [MicronutrientProfile]?
    let message: String?
}
