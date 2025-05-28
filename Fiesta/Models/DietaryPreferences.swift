import Foundation

struct DietaryPreferences: Codable, Equatable {
    var vegetarian: Bool
    var vegan: Bool
    var glutenFree: Bool
    var nutFree: Bool
    var dairyFree: Bool
    var lowCarb: Bool
    var ketogenic: Bool
    var pescatarian: Bool
    var halal: Bool
    var kosher: Bool
    var additionalRestrictions: String
    
    static let empty = DietaryPreferences(
        vegetarian: false,
        vegan: false,
        glutenFree: false,
        nutFree: false,
        dairyFree: false,
        lowCarb: false,
        ketogenic: false,
        pescatarian: false,
        halal: false,
        kosher: false,
        additionalRestrictions: ""
    )
} 