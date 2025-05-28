import Foundation
import Supabase

struct SupabaseUserMapper {
    /// Convert a SupabaseUser to the app's User model
    /// This handles the initial conversion after authentication
    static func toAppUser(from supabaseUser: SupabaseUser) -> User {
        return User(
            id: supabaseUser.id,
            name: supabaseUser.email.components(separatedBy: "@").first ?? "User",
            email: supabaseUser.email,
            role: .student, // Default role, can be updated later
            cqScore: 0.0,
            createdAt: Date(),
            isActive: true,
            mealsSaved: 0,
            mealsSwapped: 0,
            mealsDistributed: 0
        )
    }
    
    /// Updates app User with data from database
    /// Call this after fetching full user profile from database
    static func updateAppUser(appUser: User, with userData: [String: Any]) -> User {
        var updatedUser = appUser
        
        // Update fields from database
        if let name = userData["name"] as? String {
            updatedUser.name = name
        }
        
        if let role = userData["role"] as? String, 
           let userRole = UserRole(rawValue: role) {
            updatedUser.role = userRole
        }
        
        if let cqScore = userData["cq_score"] as? Double {
            updatedUser.cqScore = cqScore
        }
        
        if let rank = userData["leaderboard_rank"] as? Int {
            updatedUser.leaderboardRank = rank
        }
        
        if let profileImage = userData["profile_image_url"] as? String {
            updatedUser.profileImageURL = profileImage
        }
        
        if let mealsSaved = userData["meals_saved"] as? Int {
            updatedUser.mealsSaved = mealsSaved
        }
        
        if let mealsSwapped = userData["meals_swapped"] as? Int {
            updatedUser.mealsSwapped = mealsSwapped
        }
        
        if let mealsDistributed = userData["meals_distributed"] as? Int {
            updatedUser.mealsDistributed = mealsDistributed
        }
        
        return updatedUser
    }
} 