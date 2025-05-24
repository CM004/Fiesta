import Foundation

struct MealPrediction: Identifiable, Codable {
    var id: String
    var date: Date
    var mealType: MealType
    var location: String
    var predictedAttendance: Int
    var actualAttendance: Int?
    var weatherCondition: String?
    var isExamDay: Bool
    var isHoliday: Bool
    var isEventDay: Bool
    var confidenceScore: Double  // 0.0 to 1.0
    var factors: [PredictionFactor]
    var adjustedPreparationLevel: Int?
    var wasteReduction: Int?  // Estimated waste reduction in servings
    
    init(id: String = UUID().uuidString,
         date: Date,
         mealType: MealType,
         location: String,
         predictedAttendance: Int,
         actualAttendance: Int? = nil,
         weatherCondition: String? = nil,
         isExamDay: Bool = false,
         isHoliday: Bool = false,
         isEventDay: Bool = false,
         confidenceScore: Double,
         factors: [PredictionFactor] = [],
         adjustedPreparationLevel: Int? = nil,
         wasteReduction: Int? = nil) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.location = location
        self.predictedAttendance = predictedAttendance
        self.actualAttendance = actualAttendance
        self.weatherCondition = weatherCondition
        self.isExamDay = isExamDay
        self.isHoliday = isHoliday
        self.isEventDay = isEventDay
        self.confidenceScore = confidenceScore
        self.factors = factors
        self.adjustedPreparationLevel = adjustedPreparationLevel
        self.wasteReduction = wasteReduction
    }
}

struct PredictionFactor: Identifiable, Codable {
    var id: String
    var name: String
    var impact: Double  // -1.0 to 1.0, negative means reduces attendance
    var description: String
    
    init(id: String = UUID().uuidString,
         name: String,
         impact: Double,
         description: String) {
        self.id = id
        self.name = name
        self.impact = impact
        self.description = description
    }
} 