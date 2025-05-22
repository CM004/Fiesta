import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

enum MealStatus: String, Codable {
    case available      // Default state, meal is available
    case offered        // Student offered for swap
    case claimed        // Another student claimed the meal
    case consumed       // Meal was consumed
    case unclaimed      // Meal was not claimed, wasted
}

struct Meal: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var imageURL: String?
    var type: MealType
    var status: MealStatus
    var date: Date
    var location: String
    var nutritionInfo: NutritionInfo?
    var offeredBy: String?   // User ID who offered the meal
    var claimedBy: String?   // User ID who claimed the meal
    var offerExpiryTime: Date?
    var claimDeadlineTime: Date?
    var actuallyConsumed: Bool?
    var feedbackProvided: Bool
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         imageURL: String? = nil,
         type: MealType,
         status: MealStatus = .available,
         date: Date,
         location: String,
         nutritionInfo: NutritionInfo? = nil,
         offeredBy: String? = nil,
         claimedBy: String? = nil,
         offerExpiryTime: Date? = nil,
         claimDeadlineTime: Date? = nil,
         actuallyConsumed: Bool? = nil,
         feedbackProvided: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.type = type
        self.status = status
        self.date = date
        self.location = location
        self.nutritionInfo = nutritionInfo
        self.offeredBy = offeredBy
        self.claimedBy = claimedBy
        self.offerExpiryTime = offerExpiryTime
        self.claimDeadlineTime = claimDeadlineTime
        self.actuallyConsumed = actuallyConsumed
        self.feedbackProvided = feedbackProvided
    }
}

struct NutritionInfo: Codable {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var allergens: [String]?
    var dietaryInfo: [String]? // vegan, vegetarian, etc.
} 