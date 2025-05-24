import Foundation

/// Utility class for calculating environmental impact of food waste reduction
class EnvironmentalImpactCalculator {
    // Constants for environmental impact calculations
    // These would ideally be based on scientific research
    private static let kgCO2PerMeal = 2.5  // kg of CO2 emissions per meal
    private static let litersWaterPerMeal = 100.0  // liters of water per meal
    private static let kWhEnergyPerMeal = 3.0  // kWh of energy per meal
    
    /// Calculate CO2 emissions saved
    /// - Parameter mealCount: Number of meals saved
    /// - Returns: CO2 emissions in kg
    static func calculateCO2Saved(mealCount: Int) -> Double {
        return Double(mealCount) * kgCO2PerMeal
    }
    
    /// Calculate water saved
    /// - Parameter mealCount: Number of meals saved
    /// - Returns: Water saved in liters
    static func calculateWaterSaved(mealCount: Int) -> Double {
        return Double(mealCount) * litersWaterPerMeal
    }
    
    /// Calculate energy saved
    /// - Parameter mealCount: Number of meals saved
    /// - Returns: Energy saved in kWh
    static func calculateEnergySaved(mealCount: Int) -> Double {
        return Double(mealCount) * kWhEnergyPerMeal
    }
    
    /// Calculate total environmental impact
    /// - Parameter mealCount: Number of meals saved
    /// - Returns: Dictionary with impact values
    static func calculateTotalImpact(mealCount: Int) -> [String: Double] {
        return [
            "co2": calculateCO2Saved(mealCount: mealCount),
            "water": calculateWaterSaved(mealCount: mealCount),
            "energy": calculateEnergySaved(mealCount: mealCount)
        ]
    }
    
    /// Format environmental impact values with appropriate units
    /// - Parameters:
    ///   - type: Impact type (co2, water, energy)
    ///   - value: Impact value
    /// - Returns: Formatted string with units
    static func formatImpact(type: String, value: Double) -> String {
        switch type {
        case "co2":
            return String(format: "%.1f kg", value)
        case "water":
            if value >= 1000 {
                return String(format: "%.1f m³", value / 1000.0)
            } else {
                return String(format: "%.0f L", value)
            }
        case "energy":
            return String(format: "%.1f kWh", value)
        default:
            return String(format: "%.1f", value)
        }
    }
} 