import Foundation

struct MealSwap: Identifiable, Codable {
    var id: String
    let mealId: String
    let offeredBy: String
    var claimedBy: String?
    var claimedAt: Date?
    let expiresAt: Date
    var status: MealSwapStatus
    var cqPointsEarned: Double?
    
    init(
        id: String = UUID().uuidString,
        mealId: String,
        offeredBy: String,
        claimedBy: String? = nil,
        claimedAt: Date? = nil,
        expiresAt: Date,
        status: MealSwapStatus = .pending,
        cqPointsEarned: Double? = nil
    ) {
        self.id = id
        self.mealId = mealId
        self.offeredBy = offeredBy
        self.claimedBy = claimedBy
        self.claimedAt = claimedAt
        self.expiresAt = expiresAt
        self.status = status
        self.cqPointsEarned = cqPointsEarned
    }
}

enum MealSwapStatus: String, Codable {
    case pending
    case completed
    case expired
} 