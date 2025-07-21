import SwiftUI
import Charts

struct DiscoverView: View {
    let userData: UserData?
    
    @State private var selectedTimePeriod: TimePeriod = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Period Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trend Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        HStack(spacing: 12) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                TimePeriodButton(
                                    period: period,
                                    isSelected: selectedTimePeriod == period
                                ) {
                                    selectedTimePeriod = period
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Enhanced Nutrition Trend Charts
                    VStack(spacing: 20) {
                        // IBD Nutrition Chart
                        IBDNutritionChartCard(
                            title: "IBD Nutrition Trends",
                            subtitle: "Fiber, protein, and calorie intake with research benchmarks",
                            data: getIBDNutritionData(for: selectedTimePeriod),
                            timePeriod: selectedTimePeriod
                        )
                        
                        // Crohn's Nutrition Chart
                        CrohnsNutritionChartCard(
                            title: "Crohn's Disease Nutrition Trends",
                            subtitle: "FODMAP-friendly nutrition with disease-specific targets",
                            data: getCrohnsNutritionData(for: selectedTimePeriod),
                            timePeriod: selectedTimePeriod
                        )
                        
                        // Pain Level Trend Chart
                        TrendChartCard(
                            title: "Pain Level Trends",
                            subtitle: "Daily pain levels and patterns",
                            data: getPainData(for: selectedTimePeriod),
                            chartType: .line,
                            color: .red
                        )
                        
                        // Flare Risk Trend Chart
                        TrendChartCard(
                            title: "Flare Risk Assessment",
                            subtitle: "Risk factors and flare probability",
                            data: getFlareRiskData(for: selectedTimePeriod),
                            chartType: .bar,
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.ibdBackground)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Enhanced Chart Data Methods
    
    private func getIBDNutritionData(for period: TimePeriod) -> [NutritionDataPoint] {
        switch period {
        case .week:
            return [
                NutritionDataPoint(date: "Mon", fiber: 18, protein: 65, calories: 1850),
                NutritionDataPoint(date: "Tue", fiber: 22, protein: 72, calories: 2100),
                NutritionDataPoint(date: "Wed", fiber: 15, protein: 58, calories: 1950),
                NutritionDataPoint(date: "Thu", fiber: 25, protein: 78, calories: 2200),
                NutritionDataPoint(date: "Fri", fiber: 12, protein: 55, calories: 1800),
                NutritionDataPoint(date: "Sat", fiber: 28, protein: 85, calories: 2300),
                NutritionDataPoint(date: "Sun", fiber: 20, protein: 68, calories: 2000)
            ]
        case .month:
            return generateMonthlyNutritionData()
        case .threeMonths:
            return generateThreeMonthNutritionData()
        }
    }
    
    private func getCrohnsNutritionData(for period: TimePeriod) -> [NutritionDataPoint] {
        switch period {
        case .week:
            return [
                NutritionDataPoint(date: "Mon", fiber: 12, protein: 70, calories: 1900),
                NutritionDataPoint(date: "Tue", fiber: 15, protein: 75, calories: 2050),
                NutritionDataPoint(date: "Wed", fiber: 10, protein: 65, calories: 1850),
                NutritionDataPoint(date: "Thu", fiber: 18, protein: 80, calories: 2150),
                NutritionDataPoint(date: "Fri", fiber: 8, protein: 60, calories: 1750),
                NutritionDataPoint(date: "Sat", fiber: 20, protein: 85, calories: 2250),
                NutritionDataPoint(date: "Sun", fiber: 14, protein: 72, calories: 1950)
            ]
        case .month:
            return generateMonthlyNutritionData()
        case .threeMonths:
            return generateThreeMonthNutritionData()
        }
    }
    
    private func generateMonthlyNutritionData() -> [NutritionDataPoint] {
        let weeks = ["Week 1", "Week 2", "Week 3", "Week 4"]
        return weeks.map { week in
            NutritionDataPoint(
                date: week,
                fiber: Double.random(in: 15...30),
                protein: Double.random(in: 60...90),
                calories: Double.random(in: 1800...2300)
            )
        }
    }
    
    private func generateThreeMonthNutritionData() -> [NutritionDataPoint] {
        let months = ["Jan", "Feb", "Mar"]
        return months.map { month in
            NutritionDataPoint(
                date: month,
                fiber: Double.random(in: 18...28),
                protein: Double.random(in: 65...85),
                calories: Double.random(in: 1900...2200)
            )
        }
    }
    
    private func getPainData(for period: TimePeriod) -> [TrendDataPoint] {
        switch period {
        case .week:
            return [
                TrendDataPoint(date: "Mon", value: 3, label: "Pain Level"),
                TrendDataPoint(date: "Tue", value: 5, label: "Pain Level"),
                TrendDataPoint(date: "Wed", value: 2, label: "Pain Level"),
                TrendDataPoint(date: "Thu", value: 4, label: "Pain Level"),
                TrendDataPoint(date: "Fri", value: 6, label: "Pain Level"),
                TrendDataPoint(date: "Sat", value: 3, label: "Pain Level"),
                TrendDataPoint(date: "Sun", value: 2, label: "Pain Level")
            ]
        case .month:
            return generateMonthlyData(baseValue: 4, variation: 0.5)
        case .threeMonths:
            return generateThreeMonthData(baseValue: 4, variation: 0.6)
        }
    }
    
    private func getFlareRiskData(for period: TimePeriod) -> [TrendDataPoint] {
        switch period {
        case .week:
            return [
                TrendDataPoint(date: "Mon", value: 25, label: "Risk %"),
                TrendDataPoint(date: "Tue", value: 35, label: "Risk %"),
                TrendDataPoint(date: "Wed", value: 20, label: "Risk %"),
                TrendDataPoint(date: "Thu", value: 30, label: "Risk %"),
                TrendDataPoint(date: "Fri", value: 45, label: "Risk %"),
                TrendDataPoint(date: "Sat", value: 25, label: "Risk %"),
                TrendDataPoint(date: "Sun", value: 20, label: "Risk %")
            ]
        case .month:
            return generateMonthlyData(baseValue: 30, variation: 0.4)
        case .threeMonths:
            return generateThreeMonthData(baseValue: 30, variation: 0.5)
        }
    }
    
    private func generateMonthlyData(baseValue: Double, variation: Double) -> [TrendDataPoint] {
        var data: [TrendDataPoint] = []
        let days = ["Week 1", "Week 2", "Week 3", "Week 4"]
        
        for day in days {
            let randomVariation = Double.random(in: -variation...variation)
            let value = baseValue * (1 + randomVariation)
            data.append(TrendDataPoint(date: day, value: value, label: "Value"))
        }
        
        return data
    }
    
    private func generateThreeMonthData(baseValue: Double, variation: Double) -> [TrendDataPoint] {
        var data: [TrendDataPoint] = []
        let months = ["Jan", "Feb", "Mar"]
        
        for month in months {
            let randomVariation = Double.random(in: -variation...variation)
            let value = baseValue * (1 + randomVariation)
            data.append(TrendDataPoint(date: month, value: value, label: "Value"))
        }
        
        return data
    }
}

// MARK: - Enhanced Nutrition Chart Components

struct IBDNutritionChartCard: View {
    let title: String
    let subtitle: String
    let data: [NutritionDataPoint]
    let timePeriod: TimePeriod
    
    // IBD Research Benchmarks
    private let ibdBenchmarks = IBDNutritionBenchmarks()
    
    // Convert data to chart series format
    private var chartData: [NutritionChartPoint] {
        data.flatMap { point in
            [
                NutritionChartPoint(date: point.date, value: point.fiber, type: "Fiber"),
                NutritionChartPoint(date: point.date, value: point.protein, type: "Protein"),
                NutritionChartPoint(date: point.date, value: point.calories / 10, type: "Calories")
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Chart(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Type", point.type))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .symbol(Circle().strokeBorder(lineWidth: 2))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: data.count))
            }
            .chartForegroundStyleScale([
                "Fiber": .green,
                "Protein": .blue,
                "Calories": .orange
            ])
            .overlay(
                // Benchmark lines
                VStack(spacing: 0) {
                    // Fiber benchmark line
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -ibdBenchmarks.fiberTarget * 2)
                    
                    // Protein benchmark line
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -ibdBenchmarks.proteinTarget * 2)
                    
                    // Calories benchmark line
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -ibdBenchmarks.calorieTarget / 10 * 2)
                }
            )
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: "Fiber (\(Int(ibdBenchmarks.fiberTarget))g)")
                LegendItem(color: .blue, label: "Protein (\(Int(ibdBenchmarks.proteinTarget))g)")
                LegendItem(color: .orange, label: "Calories (\(Int(ibdBenchmarks.calorieTarget))kcal)")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

struct CrohnsNutritionChartCard: View {
    let title: String
    let subtitle: String
    let data: [NutritionDataPoint]
    let timePeriod: TimePeriod
    
    // Crohn's Research Benchmarks
    private let crohnsBenchmarks = CrohnsNutritionBenchmarks()
    
    // Convert data to chart series format
    private var chartData: [NutritionChartPoint] {
        data.flatMap { point in
            [
                NutritionChartPoint(date: point.date, value: point.fiber, type: "Fiber"),
                NutritionChartPoint(date: point.date, value: point.protein, type: "Protein"),
                NutritionChartPoint(date: point.date, value: point.calories / 10, type: "Calories")
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Chart(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Type", point.type))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .symbol(Circle().strokeBorder(lineWidth: 2))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: data.count))
            }
            .chartForegroundStyleScale([
                "Fiber": .green,
                "Protein": .blue,
                "Calories": .orange
            ])
            .overlay(
                // Benchmark lines
                VStack(spacing: 0) {
                    // Fiber benchmark line
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -crohnsBenchmarks.fiberTarget * 2)
                    
                    // Protein benchmark line
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -crohnsBenchmarks.proteinTarget * 2)
                    
                    // Calories benchmark line
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -crohnsBenchmarks.calorieTarget / 10 * 2)
                }
            )
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: "Fiber (\(Int(crohnsBenchmarks.fiberTarget))g)")
                LegendItem(color: .blue, label: "Protein (\(Int(crohnsBenchmarks.proteinTarget))g)")
                LegendItem(color: .orange, label: "Calories (\(Int(crohnsBenchmarks.calorieTarget))kcal)")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.ibdSecondaryText)
        }
    }
}

// MARK: - Supporting Views

struct TimePeriodButton: View {
    let period: TimePeriod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                .foregroundColor(isSelected ? .white : .ibdPrimaryText)
                .cornerRadius(20)
        }
    }
}

struct TrendChartCard: View {
    let title: String
    let subtitle: String
    let data: [TrendDataPoint]
    let chartType: ChartType
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Chart(data) { point in
                if chartType == .line {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.opacity(0.1))
                } else {
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: data.count))
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

enum TimePeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        }
    }
}

enum ChartType {
    case line
    case bar
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Double
    let label: String
}

struct NutritionDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let fiber: Double
    let protein: Double
    let calories: Double
}

struct NutritionChartPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Double
    let type: String
}

// MARK: - Research-Based Nutrition Benchmarks

struct IBDNutritionBenchmarks {
    // Based on IBD research studies and FODMAP guidelines
    let fiberTarget: Double = 25.0 // Lower fiber tolerance in IBD
    let proteinTarget: Double = 84.0 // 1.2g/kg for 70kg person (higher for IBD)
    let calorieTarget: Double = 2000.0 // Baseline calorie target
    let fatTarget: Double = 65.0 // Moderate fat intake
    let carbTarget: Double = 250.0 // Moderate carb intake
}

struct CrohnsNutritionBenchmarks {
    // Based on Crohn's-specific research and FODMAP guidelines
    let fiberTarget: Double = 15.0 // Even lower fiber for Crohn's during flares
    let proteinTarget: Double = 91.0 // 1.3g/kg for 70kg person (higher for Crohn's)
    let calorieTarget: Double = 2200.0 // Higher calorie needs for Crohn's
    let fatTarget: Double = 70.0 // Slightly higher fat for calorie density
    let carbTarget: Double = 200.0 // Lower carb tolerance in Crohn's
} 