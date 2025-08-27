import SwiftUI
import Charts

struct FlarePredictionView: View {
    @StateObject private var mlEngine = FlarePredictionMLEngine.shared
    @State private var prediction: FlarePredictionOutput?
    @State private var isLoading = false
    @State private var showingDetails = false
    @State private var timeRange: TimeRange = .week
    
    let userData: UserData
    let journalEntries: [JournalEntry]
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Flare Prediction")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("AI-powered risk assessment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: refreshPrediction) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            
            if isLoading {
                // Loading State
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Analyzing your data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else if let prediction = prediction {
                // Prediction Results
                VStack(spacing: 16) {
                    // Risk Level Card
                    RiskLevelCard(prediction: prediction)
                    
                    // Probability Chart
                    ProbabilityChart(prediction: prediction, timeRange: timeRange)
                    
                    // Contributing Factors
                    ContributingFactorsView(factors: prediction.contributingFactors)
                    
                    // Recommendations
                    RecommendationsView(recommendations: prediction.recommendations)
                    
                    // Details Button
                    Button("View Detailed Analysis") {
                        showingDetails = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // No Prediction State
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No prediction available")
                        .font(.headline)
                    
                    Text("Add more journal entries to get personalized flare predictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            if prediction == nil {
                refreshPrediction()
            }
        }
        .sheet(isPresented: $showingDetails) {
            FlarePredictionDetailView(prediction: prediction!)
        }
    }
    
    private func refreshPrediction() {
        isLoading = true
        
        Task {
            let newPrediction = await mlEngine.predictFlare(for: userData, journalEntries: journalEntries)
            
            await MainActor.run {
                prediction = newPrediction
                isLoading = false
            }
        }
    }
}

// MARK: - Risk Level Card
struct RiskLevelCard: View {
    let prediction: FlarePredictionOutput
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Risk Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(prediction.riskLevel.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(riskColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Probability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(prediction.flareProbability * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // Confidence Indicator
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(prediction.confidenceScore * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let predictedOnset = prediction.predictedOnset {
                    Text("Predicted: \(predictedOnset, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(riskColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var riskColor: Color {
        switch prediction.riskLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Probability Chart
struct ProbabilityChart: View {
    let prediction: FlarePredictionOutput
    let timeRange: FlarePredictionView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(generateChartData(), id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Risk", dataPoint.risk)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Risk", dataPoint.risk)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                
                RuleMark(y: .value("High Risk", 0.5))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .frame(height: 150)
            .chartYScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func generateChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ChartDataPoint] = []
        
        let days = timeRange == .day ? 1 : timeRange == .week ? 7 : 30
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let risk = prediction.flareProbability * (1.0 - Double(i) * 0.05) // Decreasing trend
            dataPoints.append(ChartDataPoint(date: date, risk: max(risk, 0.0)))
        }
        
        return dataPoints.reversed()
    }
}

struct ChartDataPoint {
    let date: Date
    let risk: Double
}

// MARK: - Contributing Factors View
struct ContributingFactorsView: View {
    let factors: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contributing Factors")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(sortedFactors, id: \.key) { factor in
                HStack {
                    Text(factor.key.capitalized)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(factor.value * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: factor.value)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var sortedFactors: [(key: String, value: Double)] {
        factors.sorted { $0.value > $1.value }
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    let recommendations: [FlarePreventionAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(recommendations, id: \.action) { recommendation in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.action)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(recommendation.priority.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(priorityColor(for: recommendation.priority))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(recommendation.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(recommendation.implementation)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private func priorityColor(for priority: ActionPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

// MARK: - Detail View
struct FlarePredictionDetailView: View {
    let prediction: FlarePredictionOutput
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Detailed Risk Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detailed Risk Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            DetailRow(title: "Flare Probability", value: "\(Int(prediction.flareProbability * 100))%")
                            DetailRow(title: "Confidence Score", value: "\(Int(prediction.confidenceScore * 100))%")
                            DetailRow(title: "Risk Level", value: prediction.riskLevel.rawValue)
                            
                            if let predictedOnset = prediction.predictedOnset {
                                DetailRow(title: "Predicted Onset", value: predictedOnset.formatted(date: .abbreviated, time: .shortened))
                            }
                            
                            DetailRow(title: "Next Prediction", value: prediction.nextPredictionDate.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contributing Factors Detail
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contributing Factors")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(prediction.contributingFactors.sorted(by: { $0.value > $1.value }), id: \.key) { factor in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(factor.key.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(factor.value * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: factor.value)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Detailed Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Action Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(prediction.recommendations, id: \.action) { recommendation in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(recommendation.action)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(recommendation.priority.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(priorityColor(for: recommendation.priority))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                
                                Text(recommendation.rationale)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(recommendation.implementation)
                                        .font(.subheadline)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 1)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Flare Prediction Details")
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
    
    private func priorityColor(for priority: ActionPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    FlarePredictionView(
        userData: UserData(id: "test-id", email: "test@example.com", name: "Test User", token: "test-token"),
        journalEntries: []
    )
} 