import SwiftUI

struct IBDColors {
    // Primary IBD colors - Crohn's disease focused (purple theme)
    static let primary = Color(red: 0.6, green: 0.2, blue: 0.8) // Deep purple for Crohn's
    static let secondary = Color(red: 0.9, green: 0.4, blue: 0.2) // Orange for alerts
    static let accent = Color(red: 0.3, green: 0.7, blue: 0.5) // Green for success
    
    // Status colors
    static let success = Color(red: 0.2, green: 0.7, blue: 0.3) // Green
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.1) // Orange
    static let error = Color(red: 0.8, green: 0.2, blue: 0.2) // Red
    static let info = Color(red: 0.6, green: 0.2, blue: 0.8) // Deep purple for Crohn's info
    
    // Background colors
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98) // Light gray
    static let cardBackground = Color.white
    static let surfaceBackground = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // Text colors
    static let primaryText = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark gray
    static let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4) // Medium gray
    static let disabledText = Color(red: 0.6, green: 0.6, blue: 0.6) // Light gray
    
    // Symptom-specific colors
    static let painColor = Color(red: 0.8, green: 0.2, blue: 0.2) // Red for pain
    static let bowelColor = Color(red: 0.9, green: 0.6, blue: 0.1) // Orange for bowel
    static let nutritionColor = Color(red: 0.2, green: 0.7, blue: 0.3) // Green for nutrition
    static let medicationColor = Color(red: 0.5, green: 0.3, blue: 0.8) // Purple for medication
}

extension Color {
    static let ibdPrimary = IBDColors.primary
    static let ibdSecondary = IBDColors.secondary
    static let ibdAccent = IBDColors.accent
    static let ibdSuccess = IBDColors.success
    static let ibdWarning = IBDColors.warning
    static let ibdError = IBDColors.error
    static let ibdInfo = IBDColors.info
    static let ibdBackground = IBDColors.background
    static let ibdCardBackground = IBDColors.cardBackground
    static let ibdSurfaceBackground = IBDColors.surfaceBackground
    static let ibdPrimaryText = IBDColors.primaryText
    static let ibdSecondaryText = IBDColors.secondaryText
    static let ibdDisabledText = IBDColors.disabledText
    static let ibdPainColor = IBDColors.painColor
    static let ibdBowelColor = IBDColors.bowelColor
    static let ibdNutritionColor = IBDColors.nutritionColor
    static let ibdMedicationColor = IBDColors.medicationColor
} 