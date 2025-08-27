import SwiftUI
import Charts

// MARK: - IBD Nutrition Analysis View
struct IBDNutritionAnalysisView: View {
    let analysis: IBDNutritionAnalysis
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Summary Card
                DailyNutritionSummaryCard(summary: analysis.dailyNutrition)
                
                // IBD-Specific Insights
                IBDSpecificInsightsCard(insights: analysis.ibdSpecificInsights)
                
                // Weekly Trends
                WeeklyTrendsCard(trends: analysis.weeklyTrends)
                
                // Flare Risk Assessment
                IBDNutritionFlareRiskCard(flareRisk: analysis.flareRiskFactors)
                
                // Gut Health Metrics
                GutHealthCard(gutHealth: analysis.gutHealthMetrics)
                
                // Recommendations
                NutritionRecommendationsCard(recommendations: analysis.recommendations)
            }
            .padding()
        }
        .background(Color.ibdBackground)
        .navigationTitle("Nutrition Analysis")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Daily Nutrition Summary Card
struct DailyNutritionSummaryCard: View {
    let summary: DailyNutritionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.ibdPrimary)
                Text("Today's Nutrition Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Key Metrics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NutritionMetricView(
                    title: "Calories",
                    value: "\(Int(summary.totalCalories))",
                    unit: "kcal",
                    color: .orange,
                    icon: "flame.fill"
                )
                
                NutritionMetricView(
                    title: "Protein",
                    value: "\(Int(summary.protein))",
                    unit: "g",
                    color: .blue,
                    icon: "dumbbell.fill"
                )
                
                NutritionMetricView(
                    title: "Fiber",
                    value: "\(Int(summary.fiber))",
                    unit: "g",
                    color: .green,
                    icon: "leaf.fill"
                )
                
                NutritionMetricView(
                    title: "Hydration",
                    value: "\(Int(summary.hydration))",
                    unit: "ml",
                    color: .cyan,
                    icon: "drop.fill"
                )
            }
            
            // IBD-Specific Indicators
            HStack(spacing: 16) {
                IBDFriendlyIndicator(score: summary.ibdFriendlyScore)
                FODMAPLevelIndicator(level: summary.fodmapLevel)
            }
            
            // Progress Bars
            VStack(spacing: 8) {
                ProgressBarView(
                    title: "Protein Goal",
                    current: summary.protein,
                    target: 84.0, // 1.2g/kg for 70kg
                    color: .blue
                )
                
                ProgressBarView(
                    title: "Fiber Goal",
                    current: summary.fiber,
                    target: 25.0,
                    color: .green
                )
                
                ProgressBarView(
                    title: "Hydration Goal",
                    current: summary.hydration,
                    target: 2000.0,
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - IBD-Specific Insights Card
struct IBDSpecificInsightsCard: View {
    let insights: IBDSpecificInsights
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.ibdPrimary)
                Text("IBD-Specific Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Fiber Analysis
            FiberAnalysisView(analysis: insights.fiberIntake)
            
            // Protein Analysis
            ProteinAnalysisView(analysis: insights.proteinIntake)
            
            // Vitamin Deficiencies
            if !insights.vitaminDeficiencies.isEmpty {
                VitaminDeficienciesView(deficiencies: insights.vitaminDeficiencies)
            }
            
            // Mineral Deficiencies
            if !insights.mineralDeficiencies.isEmpty {
                MineralDeficienciesView(deficiencies: insights.mineralDeficiencies)
            }
            
            // Hydration Status
            HydrationAnalysisView(analysis: insights.hydrationStatus)
            
            // FODMAP Compliance
            FODMAPAnalysisView(analysis: insights.fodmapCompliance)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Trends Card
struct WeeklyTrendsCard: View {
    let trends: WeeklyNutritionTrends
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.ibdPrimary)
                Text("Weekly Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Trend Indicators
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                TrendIndicatorView(
                    title: "Calories",
                    trend: trends.calorieTrend,
                    icon: "flame.fill"
                )
                
                TrendIndicatorView(
                    title: "Protein",
                    trend: trends.proteinTrend,
                    icon: "dumbbell.fill"
                )
                
                TrendIndicatorView(
                    title: "Fiber",
                    trend: trends.fiberTrend,
                    icon: "leaf.fill"
                )
                
                TrendIndicatorView(
                    title: "FODMAP",
                    trend: trends.fodmapTrend,
                    icon: "exclamationmark.triangle.fill"
                )
            }
            
            // Consistency Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Consistency")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Score:")
                    Text("\(Int(trends.consistencyScore * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(consistencyColor(trends.consistencyScore))
                    Spacer()
                }
                
                ProgressView(value: trends.consistencyScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: consistencyColor(trends.consistencyScore)))
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
    
    private func consistencyColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
}

// MARK: - Flare Risk Card
struct IBDNutritionFlareRiskCard: View {
    let flareRisk: FlareRiskFactors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(flareRiskColor(flareRisk.riskScore))
                Text("Flare Risk Assessment")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(Int(flareRisk.riskScore * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(flareRiskColor(flareRisk.riskScore))
            }
            
            // Risk Level Indicator
            RiskLevelIndicator(riskScore: flareRisk.riskScore)
            
            // High Risk Foods
            if !flareRisk.highRiskFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("High Risk Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(flareRisk.highRiskFoods.prefix(3), id: \.name) { food in
                        HStack {
                            Text("• \(food.name)")
                            Spacer()
                            Text(food.riskLevel.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(riskLevelColor(food.riskLevel))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Trigger Foods
            if !flareRisk.triggerFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(flareRisk.triggerFoods.prefix(3), id: \.name) { food in
                        HStack {
                            Text("• \(food.name)")
                            Spacer()
                            Text(food.triggerType)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Recommendations
            if !flareRisk.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prevention Actions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(flareRisk.recommendations.prefix(2), id: \.action) { action in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(action.action)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
    
    private func flareRiskColor(_ score: Double) -> Color {
        if score < 0.3 { return .green }
        else if score < 0.7 { return .orange }
        else { return .red }
    }
    
    private func riskLevelColor(_ level: RiskLevel) -> Color {
        switch level {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Gut Health Card
struct GutHealthCard: View {
    let gutHealth: GutHealthMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.ibdPrimary)
                Text("Gut Health Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Microbiome Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Microbiome Health")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Score:")
                    Text("\(Int(gutHealth.microbiomeScore * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(microbiomeColor(gutHealth.microbiomeScore))
                    Spacer()
                }
                
                ProgressView(value: gutHealth.microbiomeScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: microbiomeColor(gutHealth.microbiomeScore)))
            }
            
            // Gut Barrier Health
            HStack {
                Text("Gut Barrier:")
                Text(gutHealth.gutBarrierHealth)
                    .fontWeight(.medium)
                    .foregroundColor(gutBarrierColor(gutHealth.gutBarrierHealth))
                Spacer()
            }
            
            // Probiotic Foods
            if !gutHealth.probioticFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Probiotic Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(gutHealth.probioticFoods.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Prebiotic Foods
            if !gutHealth.prebioticFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prebiotic Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(gutHealth.prebioticFoods.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
    
    private func microbiomeColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
    
    private func gutBarrierColor(_ health: String) -> Color {
        switch health.lowercased() {
        case "excellent", "good": return .green
        case "fair": return .orange
        case "poor": return .red
        default: return .secondary
        }
    }
}

// MARK: - Nutrition Recommendations Card
struct NutritionRecommendationsCard: View {
    let recommendations: NutritionRecommendations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.ibdPrimary)
                Text("Dietician Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Immediate Actions
            if !recommendations.immediateActions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Immediate Actions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(recommendations.immediateActions.prefix(3), id: \.title) { action in
                        ImmediateActionView(action: action)
                    }
                }
            }
            
            // Weekly Goals
            if !recommendations.weeklyGoals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Goals")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(recommendations.weeklyGoals.prefix(2), id: \.category) { goal in
                        WeeklyGoalView(goal: goal)
                    }
                }
            }
            
            // Food Suggestions
            if !recommendations.foodSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended Foods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(recommendations.foodSuggestions.prefix(4), id: \.name) { food in
                            FoodSuggestionView(food: food)
                        }
                    }
                }
            }
            
            // Meal Timing
            MealTimingView(timing: recommendations.mealTiming)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Supporting View Components
struct NutritionMetricView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct IBDFriendlyIndicator: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text("IBD Friendly")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(score * 100))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ibdFriendlyColor(score))
        }
        .padding()
        .background(ibdFriendlyColor(score).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func ibdFriendlyColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
}

struct FODMAPLevelIndicator: View {
    let level: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("FODMAP")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(level.capitalized)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(fodmapColor(level))
        }
        .padding()
        .background(fodmapColor(level).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func fodmapColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .secondary
        }
    }
}

struct ProgressBarView: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(Int(current))/\(Int(target))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(current / target, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct TrendIndicatorView: View {
    let title: String
    let trend: TrendDirection
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(trendColor(trend))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Image(systemName: trendIcon(trend))
                .foregroundColor(trendColor(trend))
        }
        .padding()
        .background(trendColor(trend).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        case .fluctuating: return .orange
        }
    }
    
    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        case .fluctuating: return "arrow.up.arrow.down"
        }
    }
}

struct RiskLevelIndicator: View {
    let riskScore: Double
    
    var body: some View {
        HStack {
            Text("Risk Level:")
            Text(riskLevel(riskScore))
                .fontWeight(.semibold)
                .foregroundColor(riskColor(riskScore))
            Spacer()
        }
    }
    
    private func riskLevel(_ score: Double) -> String {
        if score < 0.3 { return "Low" }
        else if score < 0.7 { return "Medium" }
        else { return "High" }
    }
    
    private func riskColor(_ score: Double) -> Color {
        if score < 0.3 { return .green }
        else if score < 0.7 { return .orange }
        else { return .red }
    }
}

struct ImmediateActionView: View {
    let action: NutritionAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("• \(action.title)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(action.timeframe)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(action.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct WeeklyGoalView: View {
    let goal: NutritionGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(goal.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(goal.timeframe)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(Int(goal.currentValue)) → \(Int(goal.targetValue))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FoodSuggestionView: View {
    let food: FoodSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(food.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(food.category)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                if food.ibdFriendly {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                }
                
                Text(food.fodmapLevel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(6)
    }
}

struct MealTimingView: View {
    let timing: MealTimingRecommendations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Timing")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                MealTimingRow(title: "Breakfast", time: timing.breakfast)
                MealTimingRow(title: "Lunch", time: timing.lunch)
                MealTimingRow(title: "Dinner", time: timing.dinner)
                MealTimingRow(title: "Snacks", time: timing.snacks)
                MealTimingRow(title: "Hydration", time: timing.hydration)
            }
        }
    }
}

struct MealTimingRow: View {
    let title: String
    let time: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(time)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Analysis Component Views
struct FiberAnalysisView: View {
    let analysis: FiberAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fiber Intake")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Current: \(Int(analysis.currentIntake))g")
                Spacer()
                Text("Goal: \(Int(analysis.recommendedIntake))g")
            }
            .font(.caption)
            
            ProgressView(value: min(analysis.currentIntake / analysis.recommendedIntake, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text(analysis.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProteinAnalysisView: View {
    let analysis: ProteinAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Protein Intake")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Current: \(Int(analysis.currentIntake))g")
                Spacer()
                Text("Goal: \(Int(analysis.recommendedIntake))g")
            }
            .font(.caption)
            
            ProgressView(value: min(analysis.currentIntake / analysis.recommendedIntake, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text(analysis.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct VitaminDeficienciesView: View {
    let deficiencies: [VitaminDeficiency]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vitamin Deficiencies")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(deficiencies, id: \.vitamin) { deficiency in
                HStack {
                    Text("• \(deficiency.vitamin)")
                    Spacer()
                    Text("\(Int(deficiency.deficiency))")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
    }
}

struct MineralDeficienciesView: View {
    let deficiencies: [MineralDeficiency]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mineral Deficiencies")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(deficiencies, id: \.mineral) { deficiency in
                HStack {
                    Text("• \(deficiency.mineral)")
                    Spacer()
                    Text("\(Int(deficiency.deficiency))")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
    }
}

struct HydrationAnalysisView: View {
    let analysis: HydrationAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hydration Status")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Current: \(Int(analysis.currentIntake))ml")
                Spacer()
                Text("Goal: \(Int(analysis.recommendedIntake))ml")
            }
            .font(.caption)
            
            ProgressView(value: min(analysis.currentIntake / analysis.recommendedIntake, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
            
            Text(analysis.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FODMAPAnalysisView: View {
    let analysis: FODMAPAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FODMAP Compliance")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Compliance:")
                Text("\(Int(analysis.complianceScore))%")
                    .fontWeight(.semibold)
                    .foregroundColor(fodmapComplianceColor(analysis.complianceScore))
                Spacer()
            }
            .font(.caption)
            
            ProgressView(value: analysis.complianceScore / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: fodmapComplianceColor(analysis.complianceScore)))
            
            Text(analysis.recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func fodmapComplianceColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }
}

// MARK: - Preview
struct IBDNutritionAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        IBDNutritionAnalysisView(analysis: IBDNutritionAnalysis(
            dailyNutrition: DailyNutritionSummary(
                totalCalories: 1800,
                protein: 75,
                carbs: 200,
                fiber: 20,
                fat: 65,
                vitamins: ["D": 400, "B12": 2.0],
                minerals: ["Iron": 12, "Zinc": 8],
                hydration: 1800,
                fodmapLevel: "medium",
                ibdFriendlyScore: 0.8
            ),
            weeklyTrends: WeeklyNutritionTrends(
                calorieTrend: .stable,
                proteinTrend: .increasing,
                fiberTrend: .decreasing,
                fodmapTrend: .stable,
                symptomCorrelation: [:],
                consistencyScore: 0.75
            ),
            ibdSpecificInsights: IBDSpecificInsights(
                fiberIntake: FiberAnalysis(
                    currentIntake: 20,
                    recommendedIntake: 25,
                    solubleFiber: 6,
                    insolubleFiber: 14,
                    recommendation: "Gradually increase fiber intake",
                    ibdConsiderations: "Start with soluble fiber"
                ),
                proteinIntake: ProteinAnalysis(
                    currentIntake: 75,
                    recommendedIntake: 84,
                    qualityScore: 0.9,
                    sources: ["chicken", "fish", "eggs"],
                    recommendation: "Protein intake is adequate"
                ),
                fatIntake: FatAnalysis(
                    totalFat: 65,
                    saturatedFat: 20,
                    omega3: 0.5,
                    omega6: 10,
                    ratio: 20,
                    recommendation: "Increase omega-3 intake"
                ),
                vitaminDeficiencies: [],
                mineralDeficiencies: [],
                hydrationStatus: HydrationAnalysis(
                    currentIntake: 1800,
                    recommendedIntake: 2000,
                    dehydrationRisk: "Low",
                    electrolyteBalance: "Well balanced",
                    recommendation: "Maintain current hydration"
                ),
                fodmapCompliance: FODMAPAnalysis(
                    complianceScore: 85,
                    highFODMAPFoods: [],
                    lowFODMAPAlternatives: [],
                    symptomCorrelation: 0.7,
                    recommendation: "Good FODMAP compliance"
                )
            ),
            recommendations: NutritionRecommendations(
                immediateActions: [],
                weeklyGoals: [],
                longTermStrategies: [],
                foodSuggestions: [],
                mealTiming: MealTimingRecommendations(
                    breakfast: "Eat within 1 hour of waking",
                    lunch: "Consistent timing",
                    dinner: "Light meal 3 hours before bed",
                    snacks: "Small, frequent snacks",
                    hydration: "Drink throughout the day",
                    fasting: nil
                )
            ),
            flareRiskFactors: FlareRiskFactors(
                highRiskFoods: [],
                triggerFoods: [],
                inflammatoryFoods: [],
                riskScore: 0.3,
                recommendations: []
            ),
            gutHealthMetrics: GutHealthMetrics(
                microbiomeScore: 0.8,
                inflammationMarkers: [:],
                gutBarrierHealth: "Good",
                probioticFoods: ["yogurt", "kefir"],
                prebioticFoods: ["banana", "asparagus"]
            )
        ))
    }
} 