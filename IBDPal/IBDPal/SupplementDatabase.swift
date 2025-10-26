import Foundation

// MARK: - Predefined Supplement Database
struct SupplementDatabase {
    static let supplements: [SupplementOption] = [
        // VITAMINS
        SupplementOption(
            name: "Vitamin D3 (Cholecalciferol)",
            category: .vitamins,
            commonDosages: [1000, 2000, 4000, 5000, 10000],
            unit: .iu,
            description: "Essential for bone health and immune function"
        ),
        SupplementOption(
            name: "Vitamin B12 (Methylcobalamin)",
            category: .vitamins,
            commonDosages: [500, 1000, 2500, 5000],
            unit: .mcg,
            description: "Supports nerve function and red blood cell formation"
        ),
        SupplementOption(
            name: "Vitamin B12 (Cyanocobalamin)",
            category: .vitamins,
            commonDosages: [500, 1000, 2500, 5000],
            unit: .mcg,
            description: "Synthetic form of B12, commonly used in supplements"
        ),
        SupplementOption(
            name: "Folate (Folic Acid)",
            category: .vitamins,
            commonDosages: [400, 800, 1000, 5000],
            unit: .mcg,
            description: "Essential for DNA synthesis and cell division"
        ),
        SupplementOption(
            name: "Vitamin C (Ascorbic Acid)",
            category: .vitamins,
            commonDosages: [500, 1000, 2000, 5000],
            unit: .mg,
            description: "Antioxidant that supports immune function"
        ),
        SupplementOption(
            name: "Vitamin C Liquid",
            category: .vitamins,
            commonDosages: [1000, 2000, 5000],
            unit: .ml,
            description: "Liquid form of Vitamin C for better absorption"
        ),
        SupplementOption(
            name: "Vitamin A (Retinol)",
            category: .vitamins,
            commonDosages: [5000, 10000, 25000],
            unit: .iu,
            description: "Important for vision and immune function"
        ),
        SupplementOption(
            name: "Vitamin E (Tocopherol)",
            category: .vitamins,
            commonDosages: [200, 400, 800, 1000],
            unit: .iu,
            description: "Antioxidant that protects cells from damage"
        ),
        SupplementOption(
            name: "Multivitamin",
            category: .vitamins,
            commonDosages: [1, 2],
            unit: .tablets,
            description: "Comprehensive vitamin and mineral supplement"
        ),
        
        // MINERALS
        SupplementOption(
            name: "Iron (Ferrous Sulfate)",
            category: .minerals,
            commonDosages: [18, 28, 65, 100],
            unit: .mg,
            description: "Essential for oxygen transport and energy production"
        ),
        SupplementOption(
            name: "Iron Liquid",
            category: .minerals,
            commonDosages: [15, 30, 50],
            unit: .ml,
            description: "Liquid iron supplement for better absorption"
        ),
        SupplementOption(
            name: "Calcium (Calcium Carbonate)",
            category: .minerals,
            commonDosages: [500, 600, 1000, 1200],
            unit: .mg,
            description: "Essential for bone health and muscle function"
        ),
        SupplementOption(
            name: "Calcium Liquid",
            category: .minerals,
            commonDosages: [500, 1000],
            unit: .ml,
            description: "Liquid calcium for better absorption"
        ),
        SupplementOption(
            name: "Magnesium (Magnesium Glycinate)",
            category: .minerals,
            commonDosages: [200, 400, 500, 800],
            unit: .mg,
            description: "Supports muscle and nerve function"
        ),
        SupplementOption(
            name: "Zinc (Zinc Gluconate)",
            category: .minerals,
            commonDosages: [15, 30, 50, 100],
            unit: .mg,
            description: "Supports immune function and wound healing"
        ),
        SupplementOption(
            name: "Selenium",
            category: .minerals,
            commonDosages: [50, 100, 200],
            unit: .mcg,
            description: "Antioxidant that supports thyroid function"
        ),
        
        // TRACE ELEMENTS
        SupplementOption(
            name: "Iodine",
            category: .other,
            commonDosages: [150, 300, 500],
            unit: .mcg,
            description: "Essential for thyroid hormone production"
        ),
        SupplementOption(
            name: "Chromium",
            category: .other,
            commonDosages: [50, 100, 200],
            unit: .mcg,
            description: "Supports blood sugar regulation"
        ),
        SupplementOption(
            name: "Molybdenum",
            category: .other,
            commonDosages: [45, 75, 150],
            unit: .mcg,
            description: "Essential for enzyme function"
        ),
        
        // PROBIOTICS
        SupplementOption(
            name: "Lactobacillus Acidophilus",
            category: .other,
            commonDosages: [1, 5, 10, 50],
            unit: .capsules,
            description: "Beneficial bacteria for gut health"
        ),
        SupplementOption(
            name: "Bifidobacterium",
            category: .other,
            commonDosages: [1, 5, 10, 50],
            unit: .capsules,
            description: "Probiotic that supports digestive health"
        ),
        SupplementOption(
            name: "Probiotic Blend",
            category: .other,
            commonDosages: [1, 2, 3],
            unit: .capsules,
            description: "Multi-strain probiotic supplement"
        ),
        SupplementOption(
            name: "Probiotic Liquid",
            category: .other,
            commonDosages: [5, 10, 15],
            unit: .ml,
            description: "Liquid probiotic for better absorption"
        ),
        
        // PREBIOTICS
        SupplementOption(
            name: "Inulin",
            category: .other,
            commonDosages: [5, 10, 15],
            unit: .g,
            description: "Prebiotic fiber that feeds beneficial bacteria"
        ),
        SupplementOption(
            name: "FOS (Fructooligosaccharides)",
            category: .other,
            commonDosages: [5, 10, 15],
            unit: .g,
            description: "Prebiotic that supports gut microbiome"
        ),
        SupplementOption(
            name: "Psyllium Husk",
            category: .other,
            commonDosages: [5, 10, 15],
            unit: .g,
            description: "Soluble fiber that supports digestive health"
        ),
        
        // IBD-SPECIFIC
        SupplementOption(
            name: "Omega-3 (Fish Oil)",
            category: .other,
            commonDosages: [1000, 2000, 3000],
            unit: .mg,
            description: "Anti-inflammatory fatty acids"
        ),
        SupplementOption(
            name: "Omega-3 Liquid",
            category: .other,
            commonDosages: [5, 10, 15],
            unit: .ml,
            description: "Liquid omega-3 for better absorption"
        ),
        SupplementOption(
            name: "Glutamine",
            category: .other,
            commonDosages: [5, 10, 15, 20],
            unit: .g,
            description: "Amino acid that supports gut healing"
        ),
        SupplementOption(
            name: "Curcumin (Turmeric)",
            category: .other,
            commonDosages: [500, 1000, 1500],
            unit: .mg,
            description: "Anti-inflammatory compound from turmeric"
        ),
        SupplementOption(
            name: "Boswellia",
            category: .other,
            commonDosages: [300, 600, 900],
            unit: .mg,
            description: "Herbal anti-inflammatory for IBD"
        )
    ]
    
    // MARK: - Search and Filter Functions
    
    static func searchSupplements(query: String) -> [SupplementOption] {
        if query.isEmpty {
            return supplements
        }
        
        return supplements.filter { supplement in
            supplement.name.localizedCaseInsensitiveContains(query) ||
            supplement.description.localizedCaseInsensitiveContains(query) ||
            supplement.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    static func supplementsForCategory(_ category: MicronutrientCategory) -> [SupplementOption] {
        return supplements.filter { $0.category == category }
    }
    
    static func commonSupplements() -> [SupplementOption] {
        // Return most commonly used supplements
        return Array(supplements.prefix(10))
    }
}

// MARK: - Supplement Option Model
struct SupplementOption: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let category: MicronutrientCategory
    let commonDosages: [Int]
    let unit: DosageUnit
    let description: String
    
    var displayName: String {
        return name
    }
    
    var categoryIcon: String {
        switch category {
        case .vitamins:
            return "pills.fill"
        case .minerals:
            return "diamond.fill"
        case .probiotics:
            return "bacteria.fill"
        case .omega3:
            return "fish.fill"
        case .antioxidants:
            return "leaf.fill"
        case .other:
            return "leaf.fill"
        }
    }
    
    var categoryColor: String {
        switch category {
        case .vitamins:
            return "orange"
        case .minerals:
            return "blue"
        case .probiotics:
            return "green"
        case .omega3:
            return "cyan"
        case .antioxidants:
            return "purple"
        case .other:
            return "gray"
        }
    }
}
