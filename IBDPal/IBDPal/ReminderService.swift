import Foundation
import Combine

class ReminderService: ObservableObject {
    static let shared = ReminderService()
    
    private let baseURL = AppConfig.apiBaseURL
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - API Methods
    
    func fetchReminders(userId: String, token: String) -> AnyPublisher<[Reminder], Error> {
        guard let url = URL(string: "\(baseURL)/reminders") else {
            return Fail(error: ReminderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response in
                print("🔍 [ReminderService] Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                return data
            }
            .decode(type: RemindersResponse.self, decoder: JSONDecoder())
            .map { response in
                print("🔍 [ReminderService] Parsed response: \(response)")
                return response.reminders
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func createReminder(_ reminder: Reminder, userId: String, token: String) -> AnyPublisher<Reminder, Error> {
        guard let url = URL(string: "\(baseURL)/reminders") else {
            return Fail(error: ReminderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let requestBody = CreateReminderRequest(
            title: reminder.title,
            type: reminder.type.rawValue,
            time: ISO8601DateFormatter().string(from: reminder.time),
            isEnabled: reminder.isEnabled,
            repeatDays: reminder.repeatDays.map { $0.rawValue }
        )
        
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ReminderResponse.self, decoder: JSONDecoder())
            .map(\.reminder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateReminder(_ reminder: Reminder, userId: String, token: String) -> AnyPublisher<Reminder, Error> {
        guard let url = URL(string: "\(baseURL)/reminders/\(reminder.id.uuidString)") else {
            return Fail(error: ReminderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let requestBody = UpdateReminderRequest(
            title: reminder.title,
            type: reminder.type.rawValue,
            time: ISO8601DateFormatter().string(from: reminder.time),
            isEnabled: reminder.isEnabled,
            repeatDays: reminder.repeatDays.map { $0.rawValue }
        )
        
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ReminderResponse.self, decoder: JSONDecoder())
            .map(\.reminder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func deleteReminder(id: UUID, userId: String, token: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/reminders/\(id.uuidString)") else {
            return Fail(error: ReminderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func toggleReminder(id: UUID, isEnabled: Bool, userId: String, token: String) -> AnyPublisher<Reminder, Error> {
        guard let url = URL(string: "\(baseURL)/reminders/\(id.uuidString)/toggle") else {
            return Fail(error: ReminderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ToggleReminderRequest(
            isEnabled: isEnabled
        )
        
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ReminderResponse.self, decoder: JSONDecoder())
            .map(\.reminder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Request/Response Models
// All request/response models are now defined in ReminderTypes.swift
