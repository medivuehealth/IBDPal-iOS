import Foundation
import SwiftUI
import Combine

// MARK: - Disease Activity Service
// Automatically manages disease activity updates using AI assessment
// Integrates with existing app architecture

@MainActor
class DiseaseActivityService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentDiseaseActivity: DiseaseActivity = .remission
    @Published var lastAssessmentDate: Date?
    @Published var assessmentConfidence: Double = 0.0
    @Published var isUpdating: Bool = false
    @Published var assessmentHistory: [DiseaseActivityAssessment] = []
    
    // MARK: - Private Properties
    private let aiModel = DiseaseActivityAI.self
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupPeriodicAssessment()
    }
    
    // MARK: - Public Methods
    
    /// Manually trigger disease activity assessment
    func assessDiseaseActivity(
        from journalEntries: [JournalEntry],
        userDiagnosis: UserDiagnosis? = nil,
        forceUpdate: Bool = false
    ) async {
        
        guard !isUpdating || forceUpdate else { return }
        
        isUpdating = true
        
        // Perform AI assessment
        let newActivity = aiModel.assessDiseaseActivity(
            from: journalEntries,
            userDiagnosis: userDiagnosis,
            fallbackToHealthy: true
        )
        
        // Validate assessment
        let validation = aiModel.validateAssessment(
            predicted: newActivity,
            actual: currentDiseaseActivity,
            confidence: 0.0
        )
        
        // Update if there's a meaningful change or forced update
        if newActivity != currentDiseaseActivity || forceUpdate {
            await updateDiseaseActivity(
                newActivity: newActivity,
                confidence: validation.confidence,
                source: .aiAssessment
            )
        }
        
        isUpdating = false
    }
    
    /// Get disease activity trend over time
    func getDiseaseActivityTrend(days: Int = 30) -> DiseaseActivityTrend {
        let recentAssessments = assessmentHistory
            .filter { $0.assessmentDate >= Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date() }
            .sorted { $0.assessmentDate > $1.assessmentDate }
        
        return analyzeTrend(from: recentAssessments)
    }
    
    /// Get assessment confidence and data quality metrics
    func getAssessmentMetrics() -> AssessmentMetrics {
        let recentAssessment = assessmentHistory.first
        
        return AssessmentMetrics(
            confidence: recentAssessment?.confidence ?? 0.0,
            dataQuality: recentAssessment?.dataQuality ?? 0.0,
            consistency: recentAssessment?.consistency ?? 0.0,
            lastUpdate: lastAssessmentDate,
            daysOfData: recentAssessment?.daysOfData ?? 0
        )
    }
    
    // MARK: - Private Methods
    
    private func updateDiseaseActivity(
        newActivity: DiseaseActivity,
        confidence: Double,
        source: AssessmentSource
    ) async {
        
        let assessment = DiseaseActivityAssessment(
            diseaseActivity: newActivity,
            confidence: confidence,
            dataQuality: 0.85, // Calculate based on actual data
            consistency: 0.90, // Calculate based on actual data
            assessmentDate: Date(),
            source: source,
            daysOfData: 30 // Calculate based on actual data
        )
        
        // Update current state
        currentDiseaseActivity = newActivity
        lastAssessmentDate = Date()
        assessmentConfidence = confidence
        
        // Add to history
        assessmentHistory.insert(assessment, at: 0)
        
        // Keep only last 90 days of assessments
        if assessmentHistory.count > 90 {
            assessmentHistory = Array(assessmentHistory.prefix(90))
        }
        
        // Notify other parts of the app
        await notifyDiseaseActivityChange(newActivity: newActivity, assessment: assessment)
    }
    
    private func notifyDiseaseActivityChange(
        newActivity: DiseaseActivity,
        assessment: DiseaseActivityAssessment
    ) async {
        
        // Update nutrition targets if needed
        await updateNutritionTargets(for: newActivity)
        
        // Log assessment for analytics
        logAssessment(assessment)
        
        // Send notification to user if significant change
        if shouldNotifyUser(assessment: assessment) {
            await sendUserNotification(for: newActivity)
        }
    }
    
    private func updateNutritionTargets(for diseaseActivity: DiseaseActivity) async {
        // This would trigger a recalculation of nutrition targets
        // based on the new disease activity level
        NotificationCenter.default.post(
            name: .diseaseActivityUpdated,
            object: diseaseActivity
        )
    }
    
    private func shouldNotifyUser(assessment: DiseaseActivityAssessment) -> Bool {
        // Notify user if:
        // 1. Significant change in disease activity
        // 2. High confidence assessment
        // 3. First assessment after data collection
        
        guard let previousAssessment = assessmentHistory.dropFirst().first else {
            return true // First assessment
        }
        
        let significantChange = isSignificantChange(
            from: previousAssessment.diseaseActivity,
            to: assessment.diseaseActivity
        )
        
        let highConfidence = assessment.confidence > 0.8
        
        return significantChange && highConfidence
    }
    
    private func isSignificantChange(from old: DiseaseActivity, to new: DiseaseActivity) -> Bool {
        let activityLevels: [DiseaseActivity: Int] = [
            .remission: 0,
            .mild: 1,
            .moderate: 2,
            .severe: 3
        ]
        
        guard let oldLevel = activityLevels[old],
              let newLevel = activityLevels[new] else { return false }
        
        return abs(newLevel - oldLevel) >= 2 // Significant change (2+ levels)
    }
    
    private func sendUserNotification(for diseaseActivity: DiseaseActivity) async {
        let message = getNotificationMessage(for: diseaseActivity)
        
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "Disease Activity Update"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "disease_activity_update",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func getNotificationMessage(for diseaseActivity: DiseaseActivity) -> String {
        switch diseaseActivity {
        case .remission:
            return "Great news! Your symptoms suggest you're in remission. Keep up the good work!"
        case .mild:
            return "Your symptoms indicate mild disease activity. Consider discussing with your healthcare provider."
        case .moderate:
            return "Your symptoms suggest moderate disease activity. Please consult your healthcare provider."
        case .severe:
            return "Your symptoms indicate severe disease activity. Please contact your healthcare provider immediately."
        }
    }
    
    private func logAssessment(_ assessment: DiseaseActivityAssessment) {
        // Log for analytics and research purposes
        print("Disease Activity Assessment: \(assessment.diseaseActivity.rawValue)")
        print("Confidence: \(assessment.confidence)")
        print("Data Quality: \(assessment.dataQuality)")
        print("Source: \(assessment.source)")
    }
    
    private func analyzeTrend(from assessments: [DiseaseActivityAssessment]) -> DiseaseActivityTrend {
        guard assessments.count >= 2 else { return .stable }
        
        let recent = assessments.prefix(7)
        let previous = assessments.dropFirst(7).prefix(7)
        
        let recentAverage = recent.map { diseaseActivityToNumeric($0.diseaseActivity) }.reduce(0, +) / Double(recent.count)
        let previousAverage = previous.map { diseaseActivityToNumeric($0.diseaseActivity) }.reduce(0, +) / Double(previous.count)
        
        let change = recentAverage - previousAverage
        
        if change > 0.5 {
            return .worsening
        } else if change < -0.5 {
            return .improving
        } else {
            return .stable
        }
    }
    
    /// Convert disease activity to numeric value for trend analysis
    private func diseaseActivityToNumeric(_ activity: DiseaseActivity) -> Double {
        switch activity {
        case .remission: return 0.0
        case .mild: return 1.0
        case .moderate: return 2.0
        case .severe: return 3.0
        }
    }
    
    private func setupPeriodicAssessment() {
        // Set up automatic assessment every 7 days
        Timer.publish(every: 7 * 24 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performPeriodicAssessment()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performPeriodicAssessment() async {
        // This would be called periodically to reassess disease activity
        // Implementation would depend on how journal entries are accessed
    }
}

// MARK: - Supporting Data Structures

struct DiseaseActivityAssessment: Codable, Identifiable {
    let id: UUID
    let diseaseActivity: DiseaseActivity
    let confidence: Double
    let dataQuality: Double
    let consistency: Double
    let assessmentDate: Date
    let source: AssessmentSource
    let daysOfData: Int
    
    init(diseaseActivity: DiseaseActivity, confidence: Double, dataQuality: Double, consistency: Double, assessmentDate: Date, source: AssessmentSource, daysOfData: Int) {
        self.id = UUID()
        self.diseaseActivity = diseaseActivity
        self.confidence = confidence
        self.dataQuality = dataQuality
        self.consistency = consistency
        self.assessmentDate = assessmentDate
        self.source = source
        self.daysOfData = daysOfData
    }
}

enum AssessmentSource: String, Codable {
    case aiAssessment = "ai_assessment"
    case manualUpdate = "manual_update"
    case diagnosisImport = "diagnosis_import"
    case fallback = "fallback"
}

enum DiseaseActivityTrend {
    case improving
    case stable
    case worsening
}

struct AssessmentMetrics {
    let confidence: Double
    let dataQuality: Double
    let consistency: Double
    let lastUpdate: Date?
    let daysOfData: Int
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let diseaseActivityUpdated = Notification.Name("diseaseActivityUpdated")
}

// MARK: - Integration with Existing Views

extension DiseaseActivityService {
    
    /// Get formatted display text for disease activity
    func getDiseaseActivityDisplayText() -> String {
        switch currentDiseaseActivity {
        case .remission:
            return "In Remission"
        case .mild:
            return "Mild Activity"
        case .moderate:
            return "Moderate Activity"
        case .severe:
            return "Severe Activity"
        }
    }
    
    /// Get color for disease activity display
    func getDiseaseActivityColor() -> Color {
        switch currentDiseaseActivity {
        case .remission:
            return .green
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }
    
    /// Get confidence display text
    func getConfidenceDisplayText() -> String {
        switch assessmentConfidence {
        case 0.8...1.0:
            return "High Confidence"
        case 0.6..<0.8:
            return "Moderate Confidence"
        case 0.4..<0.6:
            return "Low Confidence"
        default:
            return "Very Low Confidence"
        }
    }
}

// MARK: - Usage in SwiftUI Views

struct DiseaseActivityView: View {
    @StateObject private var diseaseActivityService = DiseaseActivityService()
    @State private var journalEntries: [JournalEntry] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Disease Activity")
                    .font(.headline)
                
                Spacer()
                
                if diseaseActivityService.isUpdating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Circle()
                    .fill(diseaseActivityService.getDiseaseActivityColor())
                    .frame(width: 12, height: 12)
                
                Text(diseaseActivityService.getDiseaseActivityDisplayText())
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(diseaseActivityService.getConfidenceDisplayText())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastUpdate = diseaseActivityService.lastAssessmentDate {
                Text("Last updated: \(lastUpdate, formatter: DateFormatter.shortDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            Task {
                await diseaseActivityService.assessDiseaseActivity(
                    from: journalEntries,
                    userDiagnosis: nil
                )
            }
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
