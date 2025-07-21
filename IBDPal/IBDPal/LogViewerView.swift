import SwiftUI

struct LogViewerView: View {
    @ObservedObject var logger = NetworkLogger.shared
    @State private var selectedCategory: LogCategory = .all
    @State private var selectedLevel: LogLevel = .all
    @State private var searchText = ""
    
    var filteredLogs: [NetworkLogEntry] {
        logger.logs.filter { entry in
            let categoryMatch = selectedCategory == .all || entry.category == selectedCategory
            let levelMatch = selectedLevel == .all || entry.level == selectedLevel
            let searchMatch = searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && levelMatch && searchMatch
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    HStack {
                        Text("Category:")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag(LogCategory.all)
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized).tag(category)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Level:")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Picker("Level", selection: $selectedLevel) {
                            Text("All").tag(LogLevel.all)
                            ForEach(LogLevel.allCases, id: \.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color.ibdSurfaceBackground)
                
                // Logs
                List(filteredLogs) { entry in
                    LogEntryRow(entry: entry)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Network Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        logger.clearLogs()
                    }
                    .foregroundColor(.ibdPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Test Server") {
                        testServerConnection()
                    }
                    .foregroundColor(.ibdPrimary)
                }
            }
        }
    }
    
    private func testServerConnection() {
        logger.log("🧪 Starting server connection test...", level: .info, category: .network)
        logger.logServerConnectionTest(AppConfig.serverBaseURL)
    }
}

struct LogEntryRow: View {
    let entry: NetworkLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(entry.level.color)
                
                Spacer()
                
                Text(entry.category.rawValue.uppercased())
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(4)
            }
            
            HStack {
                Text(formatTimestamp(entry.timestamp))
                    .font(.caption2)
                    .foregroundColor(.ibdSecondaryText)
                
                Spacer()
                
                Text(entry.level.rawValue.uppercased())
                    .font(.caption2)
                    .foregroundColor(entry.level.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.level.color.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// Extensions for filtering
extension LogCategory {
    static let all = LogCategory(rawValue: "all")!
}

extension LogLevel {
    static let all = LogLevel(rawValue: "all")!
}

#Preview {
    LogViewerView()
} 