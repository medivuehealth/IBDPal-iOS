import SwiftUI

// MARK: - Advanced Food NLP Demo
struct AdvancedFoodNLPDemo: View {
    @State private var testInput = ""
    @State private var testResults: [AdvancedNLPDemoResult] = []
    @State private var showingResults = false
    
    // Comprehensive test cases covering different user entry patterns
    private let testCases = [
        // Perfect matches
        "miso soup",
        "ramen",
        "chicken curry",
        "egg omelette",
        "pad thai",
        "sushi roll",
        "hummus",
        "falafel",
        "shawarma",
        "pizza",
        "hamburger",
        "mac and cheese",
        "taco",
        "burrito",
        "guacamole",
        
        // Common typos and variations
        "sandwhich",
        "omlete",
        "omlette",
        "avacado",
        "keenwa",
        "padthai",
        "biriyani",
        "shwarma",
        "falafal",
        "humus",
        "tzaziki",
        "bruscheta",
        "ratatouile",
        "bouillabaise",
        "bourguignonne",
        "mac n cheese",
        "mac n c heese",
        "hotdog",
        "corn dog",
        "greek yogurt",
        
        // Free-form entries with context
        "fresh miso soup",
        "homemade ramen",
        "grilled chicken curry",
        "baked egg omelette",
        "authentic pad thai",
        "fresh sushi roll",
        "organic hummus",
        "crispy falafel",
        "spicy shawarma",
        "large pizza",
        "juicy hamburger",
        "creamy mac and cheese",
        "delicious taco",
        "big burrito",
        "fresh guacamole",
        
        // Compound descriptions
        "chicken with rice",
        "beef and noodles",
        "salmon with vegetables",
        "eggs with bread",
        "cheese with pasta",
        "fish with salad",
        "meat with potatoes",
        "vegetables with sauce",
        
        // Portion indicators
        "2 slices bread",
        "1 cup rice",
        "3 pieces chicken",
        "half apple",
        "large banana",
        "small salad",
        "medium pizza",
        "extra cheese",
        "double burger",
        
        // Cooking methods
        "fried chicken",
        "baked salmon",
        "grilled beef",
        "steamed rice",
        "roasted vegetables",
        "sauteed mushrooms",
        "boiled eggs",
        "raw vegetables",
        
        // Regional variations
        "japanese miso soup",
        "thai pad thai",
        "indian curry",
        "mexican taco",
        "italian pizza",
        "french crepe",
        "greek salad",
        "chinese dumplings",
        "korean kimchi",
        "vietnamese pho",
        
        // Complex descriptions
        "authentic japanese miso soup with tofu",
        "spicy thai pad thai with chicken",
        "traditional indian chicken curry",
        "fresh mexican taco with guacamole",
        "homemade italian pizza with cheese",
        "delicious french crepe with strawberries",
        "healthy greek salad with olive oil",
        "steamed chinese dumplings",
        "fermented korean kimchi",
        "aromatic vietnamese pho with beef",
        
        // Unknown foods (should return low confidence)
        "xyz food",
        "unknown dish",
        "random meal",
        "test food",
        "sample dish"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("Advanced Food NLP Testing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Test free-form food entries and see how the NLP system recognizes them")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Input section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter food description:")
                        .font(.headline)
                    
                    TextField("e.g., miso soup, chicken curry, egg omelette", text: $testInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    HStack {
                        Button("Test Input") {
                            processTestInput()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Clear Results") {
                            testResults.removeAll()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                
                // Quick test buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(testCases.prefix(10)), id: \.self) { testCase in
                            Button(testCase) {
                                testInput = testCase
                                processTestInput()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Results section
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Test Results (\(testResults.count))")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(testResults) { result in
                                    AdvancedNLPDemoResultView(result: result)
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Food NLP Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func processTestInput() {
        guard !testInput.isEmpty else { return }
        
        let advancedResult = AdvancedFoodNLPProcessor.shared.processFoodDescription(testInput)
        let nutritionResult = EnhancedNutritionCalculator.shared.calculateNutrition(for: testInput)
        
        let demoResult = AdvancedNLPDemoResult(
            id: UUID(),
            input: testInput,
            advancedNlpResult: advancedResult,
            nutritionResult: nutritionResult,
            timestamp: Date()
        )
        
        testResults.insert(demoResult, at: 0)
        testInput = ""
    }
}

// MARK: - Demo Result Structure
struct AdvancedNLPDemoResult: Identifiable {
    let id: UUID
    let input: String
    let advancedNlpResult: AdvancedFoodResult
    let nutritionResult: CalculatedNutrition
    let timestamp: Date
}

// MARK: - Demo Result View
struct AdvancedNLPDemoResultView: View {
    let result: AdvancedNLPDemoResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Input
            HStack {
                Text("Input:")
                    .fontWeight(.semibold)
                Text(result.input)
                    .italic()
                Spacer()
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Advanced NLP Result
            VStack(alignment: .leading, spacing: 8) {
                Text("Advanced NLP:")
                    .fontWeight(.semibold)
                
                if let recognizedFood = result.advancedNlpResult.recognizedFood {
                    HStack {
                        Text("✅ Recognized:")
                        Text(recognizedFood.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(result.advancedNlpResult.confidence * 100))%")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(confidenceColor(result.advancedNlpResult.confidence))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Category:")
                        Text(recognizedFood.category)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Cuisine:")
                        Text(recognizedFood.cuisine)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                } else {
                    Text("❌ No recognition")
                        .foregroundColor(.red)
                }
                
                Text("Method: \(result.advancedNlpResult.processingMethod)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Nutrition Result
            VStack(alignment: .leading, spacing: 8) {
                Text("Nutrition Calculation:")
                    .fontWeight(.semibold)
                
                if result.nutritionResult.totalCalories > 0 {
                    HStack {
                        Text("Calories:")
                        Text("\(Int(result.nutritionResult.totalCalories))")
                            .fontWeight(.medium)
                        Spacer()
                        Text("Protein:")
                        Text("\(Int(result.nutritionResult.totalProtein))g")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Carbs:")
                        Text("\(Int(result.nutritionResult.totalCarbs))g")
                            .fontWeight(.medium)
                        Spacer()
                        Text("Fat:")
                        Text("\(Int(result.nutritionResult.totalFat))g")
                            .fontWeight(.medium)
                    }
                    
                    if !result.nutritionResult.detectedFoods.isEmpty {
                        Text("Detected: \(result.nutritionResult.detectedFoods.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("❌ No nutrition data")
                        .foregroundColor(.red)
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Preview
struct AdvancedFoodNLPDemo_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedFoodNLPDemo()
    }
} 