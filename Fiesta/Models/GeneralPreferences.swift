import Foundation

struct GeneralPreferences: Codable, Equatable {
    var automaticNotifications: Bool
    var mealReminderTime: Date?
    var preferredCuisines: [String]
    var spicePreference: SpiceLevel
    var portionSize: PortionSize
    var showNutritionalInfo: Bool
    var showEnvironmentalImpact: Bool
    
    enum SpiceLevel: String, Codable, CaseIterable {
        case mild = "Mild"
        case medium = "Medium"
        case spicy = "Spicy"
    }
    
    enum PortionSize: String, Codable, CaseIterable {
        case small = "Small"
        case regular = "Regular"
        case large = "Large"
    }
    
    static let empty = GeneralPreferences(
        automaticNotifications: true,
        mealReminderTime: nil,
        preferredCuisines: [],
        spicePreference: .medium,
        portionSize: .regular,
        showNutritionalInfo: true,
        showEnvironmentalImpact: true
    )
} 