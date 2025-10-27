import Foundation
import SwiftUI

// MARK: - Reminder Data Models

struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var type: ReminderType
    var time: Date
    var isEnabled: Bool
    var repeatDays: [Weekday]
    
    // Custom coding keys to handle server response format
    enum CodingKeys: String, CodingKey {
        case id, title, type, time, isEnabled, repeatDays
    }
    
    // Regular initializer for creating new reminders
    init(id: UUID = UUID(), title: String, type: ReminderType, time: Date, isEnabled: Bool = true, repeatDays: [Weekday] = []) {
        self.id = id
        self.title = title
        self.type = type
        self.time = time
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as string from server
        let idString = try container.decode(String.self, forKey: .id)
        guard let id = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
        }
        self.id = id
        
        self.title = try container.decode(String.self, forKey: .title)
        self.type = try container.decode(ReminderType.self, forKey: .type)
        
        // Handle time as ISO8601 string
        let timeString = try container.decode(String.self, forKey: .time)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var time: Date
        if let parsedTime = formatter.date(from: timeString) {
            time = parsedTime
        } else {
            // Try without fractional seconds as fallback
            formatter.formatOptions = [.withInternetDateTime]
            guard let parsedTime = formatter.date(from: timeString) else {
                throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid date format: \(timeString)")
            }
            time = parsedTime
        }
        self.time = time
        
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        
        // Handle repeatDays as string array from server
        let repeatDaysStrings = try container.decode([String].self, forKey: .repeatDays)
        self.repeatDays = repeatDaysStrings.compactMap { Weekday(rawValue: $0) }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: time), forKey: .time)
        
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(repeatDays.map { $0.rawValue }, forKey: .repeatDays)
    }
}

enum ReminderType: String, CaseIterable, Codable {
    case medication = "medication"
    case meal = "meal"
    case symptom = "symptom"
    case exercise = "exercise"
    case appointment = "appointment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .medication: return "Medication"
        case .meal: return "Meal"
        case .symptom: return "Symptom Check"
        case .exercise: return "Exercise"
        case .appointment: return "Appointment"
        case .other: return "Other"
        }
    }
    
    var color: Color {
        switch self {
        case .medication: return .blue
        case .meal: return .green
        case .symptom: return .orange
        case .exercise: return .purple
        case .appointment: return .red
        case .other: return .gray
        }
    }
}

enum Weekday: String, CaseIterable, Codable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
    
    var weekdayValue: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

enum ReminderPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Request/Response Models

struct CreateReminderRequest: Codable {
    let title: String
    let type: String
    let time: String
    let isEnabled: Bool
    let repeatDays: [String]
}

struct UpdateReminderRequest: Codable {
    let title: String
    let type: String
    let time: String
    let isEnabled: Bool
    let repeatDays: [String]
}

struct ToggleReminderRequest: Codable {
    let isEnabled: Bool
}

struct RemindersResponse: Codable {
    let success: Bool
    let reminders: [Reminder]
}

struct ReminderResponse: Codable {
    let success: Bool
    let reminder: Reminder
}

// MARK: - Error Types

enum ReminderError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
