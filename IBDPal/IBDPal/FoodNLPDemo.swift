import Foundation
import SwiftUI

// MARK: - Food NLP Demo
struct FoodNLPDemo: View {
    @State private var testInput = ""
    @State private var nlpResults: [NLPDemoResult] = []
    
    private let testCases = [
        "mac n c heese",
        "baked red beans with pita bread",
        "chicken shawarma",
        "pad thai with vegetables",
        "rice biryani",
        "falafel wrap",
        "sushi roll",
        "crepe with strawberries",
        "taco with beef",
        "curry with chicken",
        "hummus with pita",
        "spaghetti with tomato sauce",
        "grilled chicken with rice",
        "salad with lettuce and tomato",
        "yogurt with berries"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Test Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Food Recognition")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter food description...", text: $testInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Process with NLP") {
                        processTestInput()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testInput.isEmpty)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Test Cases Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Test Cases")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(testCases, id: \.self) { testCase in
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
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Results Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("NLP Processing Results")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(nlpResults, id: \.id) { result in
                                NLPDemoResultView(result: result)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Food NLP Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func processTestInput() {
        let nlpResult = FoodNLPProcessor.shared.processFoodDescription(testInput)
        let nutritionResult = EnhancedNutritionCalculator.shared.calculateNutrition(for: testInput)
        
        let demoResult = NLPDemoResult(
            id: UUID(),
            input: testInput,
            nlpResult: nlpResult,
            nutritionResult: nutritionResult
        )
        
        nlpResults.insert(demoResult, at: 0)
    }
}

// MARK: - Demo Result Models
struct NLPDemoResult: Identifiable {
    let id: UUID
    let input: String
    let nlpResult: ProcessedFoodResult
    let nutritionResult: CalculatedNutrition
}

struct NLPDemoResultView: View {
    let result: NLPDemoResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Input
            Text("Input: \(result.input)")
                .font(.headline)
                .foregroundColor(.primary)
            
            // NLP Results
            VStack(alignment: .leading, spacing: 4) {
                Text("NLP Processing:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Normalized: \(result.nlpResult.normalizedText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !result.nlpResult.individualFoods.isEmpty {
                    Text("Individual Foods: \(result.nlpResult.individualFoods.map { $0.normalizedText }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !result.nlpResult.compoundFoods.isEmpty {
                    Text("Compound Foods: \(result.nlpResult.compoundFoods.map { $0.name }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Confidence: \(String(format: "%.2f", result.nlpResult.confidence))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Nutrition Results
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition Calculation:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Detected Foods: \(result.nutritionResult.detectedFoods.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Calories: \(Int(result.nutritionResult.totalCalories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Protein: \(String(format: "%.1f", result.nutritionResult.totalProtein))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Carbs: \(String(format: "%.1f", result.nutritionResult.totalCarbs))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Fiber: \(String(format: "%.1f", result.nutritionResult.totalFiber))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Fat: \(String(format: "%.1f", result.nutritionResult.totalFat))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct FoodNLPDemo_Previews: PreviewProvider {
    static var previews: some View {
        FoodNLPDemo()
    }
} 