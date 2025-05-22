import Foundation

enum SwapStatus: String, Codable {
    case pending
    case completed
    case canceled
    case expired
}

struct MealSwap: Identifiable, Codable {
    var id: String
    var mealId: String
    var offeredBy: String  // User ID
    var claimedBy: String? // User ID (if claimed)
    var offeredAt: Date
    var claimedAt: Date?
    var expiresAt: Date
    var status: SwapStatus
    var isEventMode: Bool  // For batch swaps during events
    var batchSize: Int?    // Number of meals in batch (for event mode)
    var cqPointsEarned: Double?
    
    init(id: String = UUID().uuidString,
         mealId: String,
         offeredBy: String,
         claimedBy: String? = nil,
         offeredAt: Date = Date(),
         claimedAt: Date? = nil,
         expiresAt: Date,
         status: SwapStatus = .pending,
         isEventMode: Bool = false,
         batchSize: Int? = nil,
         cqPointsEarned: Double? = nil) {
        self.id = id
        self.mealId = mealId
        self.offeredBy = offeredBy
        self.claimedBy = claimedBy
        self.offeredAt = offeredAt
        self.claimedAt = claimedAt
        self.expiresAt = expiresAt
        self.status = status
        self.isEventMode = isEventMode
        self.batchSize = batchSize
        self.cqPointsEarned = cqPointsEarned
    }
} 