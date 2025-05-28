import Foundation

enum UserRole: String, Codable {
    case student
    case cafeteriaStaff
    case admin
}

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var role: UserRole
    var cqScore: Double
    var leaderboardRank: Int?
    var profileImageURL: String?
    var createdAt: Date
    var isActive: Bool
    var dietaryPreferences: DietaryPreferences?
    var generalPreferences: GeneralPreferences?
    
    // For students
    var mealsSaved: Int
    var mealsSwapped: Int
    var mealsDistributed: Int
    
    init(id: String = UUID().uuidString, 
         name: String, 
         email: String, 
         role: UserRole = .student, 
         cqScore: Double = 0.0,
         leaderboardRank: Int? = nil,
         profileImageURL: String? = nil,
         createdAt: Date = Date(),
         isActive: Bool = true,
         dietaryPreferences: DietaryPreferences? = nil,
         generalPreferences: GeneralPreferences? = nil,
         mealsSaved: Int = 0,
         mealsSwapped: Int = 0,
         mealsDistributed: Int = 0) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.cqScore = cqScore
        self.leaderboardRank = leaderboardRank
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.isActive = isActive
        self.dietaryPreferences = dietaryPreferences
        self.generalPreferences = generalPreferences
        self.mealsSaved = mealsSaved
        self.mealsSwapped = mealsSwapped
        self.mealsDistributed = mealsDistributed
    }
} 