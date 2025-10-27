import SwiftUI
import UserNotifications
import Combine

struct RemindersView: View {
    let userData: UserData?
    
    @State private var reminders: [Reminder] = []
    @State private var showingAddReminder = false
    @State private var notificationPermissionGranted = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var reminderService = ReminderService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack {
                // Notification permission banner
                if !notificationPermissionGranted && !isLoading {
                    NotificationPermissionBanner {
                        requestNotificationPermission()
                    }
                }
                
                if isLoading {
                    ProgressView("Loading reminders...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage) {
                        loadReminders()
                    }
                } else if reminders.isEmpty {
                    EmptyRemindersView {
                        showingAddReminder = true
                    }
                } else {
                    List {
                        ForEach(reminders) { reminder in
                            ReminderRow(reminder: reminder) {
                                toggleReminder(reminder)
                            } onEdit: {
                                // TODO: Implement edit functionality
                            } onDelete: {
                                deleteReminder(reminder)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReminder = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView { newReminder in
                    addReminder(newReminder)
                }
            }
            .onAppear {
                checkNotificationPermission()
                loadReminders()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Reschedule notifications when app becomes active
                rescheduleAllNotifications()
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
                self.isLoading = false
                
                // If not authorized, request permission
                if settings.authorizationStatus == .notDetermined {
                    self.requestNotificationPermission()
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    private func loadReminders() {
        guard let userEmail = userData?.email, let token = userData?.token else {
            errorMessage = "User email or token not available"
            isLoading = false
            return
        }
        
        reminderService.fetchReminders(userId: userEmail, token: token)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    switch completion {
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("❌ [RemindersView] Error loading reminders: \(error)")
                        if let decodingError = error as? DecodingError {
                            print("❌ [RemindersView] Decoding error details: \(decodingError)")
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { fetchedReminders in
                    reminders = fetchedReminders
                    errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    private func addReminder(_ reminder: Reminder) {
        guard let userEmail = userData?.email, let token = userData?.token else { return }
        
        reminderService.createReminder(reminder, userId: userEmail, token: token)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("❌ [RemindersView] Error creating reminder: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { createdReminder in
                    reminders.append(createdReminder)
                    scheduleNotification(for: createdReminder)
                }
            )
            .store(in: &cancellables)
    }
    
    private func toggleReminder(_ reminder: Reminder) {
        guard let userEmail = userData?.email, let token = userData?.token else { return }
        
        reminderService.toggleReminder(id: reminder.id, isEnabled: !reminder.isEnabled, userId: userEmail, token: token)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("❌ [RemindersView] Error toggling reminder: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { updatedReminder in
                    if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                        reminders[index] = updatedReminder
                        if updatedReminder.isEnabled {
                            scheduleNotification(for: updatedReminder)
                        } else {
                            cancelNotification(for: updatedReminder)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func deleteReminder(_ reminder: Reminder) {
        guard let userEmail = userData?.email, let token = userData?.token else { return }
        
        reminderService.deleteReminder(id: reminder.id, userId: userEmail, token: token)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        print("❌ [RemindersView] Error deleting reminder: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { _ in
                    reminders.removeAll { $0.id == reminder.id }
                    cancelNotification(for: reminder)
                }
            )
            .store(in: &cancellables)
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        guard notificationPermissionGranted && reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "IBDPal Reminder"
        content.body = reminder.title
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        // Create notification for each selected day
        for day in reminder.repeatDays {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: reminder.time)
            components.weekday = day.weekdayValue
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(reminder.id.uuidString)_\(day.rawValue)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(day.displayName): \(error)")
                }
            }
        }
    }
    
    private func cancelNotification(for reminder: Reminder) {
        // Cancel all notifications for this reminder (one for each day)
        let identifiers = reminder.repeatDays.map { "\(reminder.id.uuidString)_\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func rescheduleAllNotifications() {
        // Cancel all existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Reschedule all enabled reminders
        for reminder in reminders where reminder.isEnabled {
            scheduleNotification(for: reminder)
        }
    }
}

struct NotificationPermissionBanner: View {
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.slash")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Disabled")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Enable notifications to receive reminder alerts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Enable") {
                    onRequestPermission()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Retry") {
                onRetry()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyRemindersView: View {
    let onAddReminder: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Reminders")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Set up reminders for medications, meals, and other important activities to help manage your IBD.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onAddReminder) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Reminder")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(reminder.time, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(reminder.type.displayName)
                    .font(.caption)
                    .foregroundColor(reminder.type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(reminder.type.color.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
}

struct AddReminderView: View {
    @Environment(\.presentationMode) var presentationMode
    let onSave: (Reminder) -> Void
    
    @State private var title = ""
    @State private var selectedType = ReminderType.medication
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Repeat") {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        HStack {
                            Text(day.displayName)
                            Spacer()
                            if selectedDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newReminder = Reminder(
                        id: UUID(),
                        title: title,
                        type: selectedType,
                        time: selectedTime,
                        isEnabled: true,
                        repeatDays: Array(selectedDays)
                    )
                    onSave(newReminder)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Data Models
// Reminder, ReminderType, and Weekday are now defined in ReminderTypes.swift

#Preview {
    RemindersView(userData: nil)
}
