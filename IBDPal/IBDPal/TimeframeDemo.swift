import Foundation

// MARK: - Timeframe Demo
// Shows exactly what timeframe data is fetched for medication adherence calculation

class TimeframeDemo {
    
    static func showCurrentTimeframe() {
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        print("📅 Medication Adherence Timeframe for Today:")
        print("Start Date: \(dateFormatter.string(from: threeMonthsAgo))")
        print("End Date: \(dateFormatter.string(from: today))")
        print("Total Days: \(Calendar.current.dateComponents([.day], from: threeMonthsAgo, to: today).day ?? 0)")
        print("Total Weeks: \(Calendar.current.dateComponents([.weekOfYear], from: threeMonthsAgo, to: today).weekOfYear ?? 0)")
        print("Total Months: 3")
        
        // Show expected doses for different medication types
        let totalDays = Calendar.current.dateComponents([.day], from: threeMonthsAgo, to: today).day ?? 0
        
        print("\n📊 Expected Doses for 3-Month Period:")
        print("Mesalamine (Daily): \(totalDays) doses")
        print("Infliximab (Weekly): \(max(1, totalDays / 7)) doses")
        print("Adalimumab (Bi-weekly): \(max(1, totalDays / 14)) doses")
        print("Vedolizumab (Monthly): \(max(1, totalDays / 30)) doses")
        
        // Show database query
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        
        print("\n🔍 Database Query:")
        print("SELECT entry_id, user_id, entry_date, medication_taken, medication_type")
        print("FROM journal_entries")
        print("WHERE user_id = $1")
        print("AND entry_date BETWEEN '\(dateFormatter2.string(from: threeMonthsAgo))' AND '\(dateFormatter2.string(from: today))'")
        print("AND medication_taken = true")
        print("ORDER BY entry_date ASC;")
    }
    
    static func showMonthlyBreakdown() {
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today
        
        let calendar = Calendar.current
        var currentMonth = threeMonthsAgo
        
        print("\n📈 Monthly Breakdown:")
        
        for i in 0..<3 {
            let monthStart = calendar.date(byAdding: .month, value: i, to: threeMonthsAgo) ?? threeMonthsAgo
            let monthEnd = calendar.date(byAdding: .month, value: i + 1, to: threeMonthsAgo) ?? today
            
            let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 0
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM yyyy"
            let monthName = dateFormatter.string(from: monthStart)
            
            print("\(monthName): \(daysInMonth) days")
            print("  - Mesalamine (Daily): \(daysInMonth) expected doses")
            print("  - Infliximab (Weekly): \(max(1, daysInMonth / 7)) expected doses")
            print("  - Adalimumab (Bi-weekly): \(max(1, daysInMonth / 14)) expected doses")
            print("  - Vedolizumab (Monthly): \(max(1, daysInMonth / 30)) expected doses")
        }
    }
}

// MARK: - Usage Example

// Call this to see the current timeframe
// TimeframeDemo.showCurrentTimeframe()
// TimeframeDemo.showMonthlyBreakdown()









