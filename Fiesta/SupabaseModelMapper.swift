import Foundation
import Supabase

/// A utility class to convert between app models and Supabase database formats
struct SupabaseModelMapper {
    // MARK: - User Mapping
    
    /// Convert User model to Supabase database format
    static func toSupabaseFormat(user: User) -> [String: Any] {
        var userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "cq_score": user.cqScore,
            "is_active": user.isActive,
            "meals_saved": user.mealsSaved,
            "meals_swapped": user.mealsSwapped,
            "meals_distributed": user.mealsDistributed,
            "created_at": ISO8601DateFormatter().string(from: user.createdAt)
        ]
        
        if let profileImageURL = user.profileImageURL {
            userData["profile_image_url"] = profileImageURL
        }
        
        return userData
    }
    
    /// Convert Supabase database format to User model
    static func toUser(from data: [String: Any]) -> User? {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let email = data["email"] as? String,
            let roleString = data["role"] as? String,
            let role = UserRole(rawValue: roleString)
        else {
            return nil
        }
        
        let cqScore = data["cq_score"] as? Double ?? 0.0
        let profileImageURL = data["profile_image_url"] as? String
        let leaderboardRank = data["leaderboard_rank"] as? Int
        let isActive = data["is_active"] as? Bool ?? true
        let mealsSaved = data["meals_saved"] as? Int ?? 0
        let mealsSwapped = data["meals_swapped"] as? Int ?? 0
        let mealsDistributed = data["meals_distributed"] as? Int ?? 0
        
        var createdAt = Date()
        if let createdAtString = data["created_at"] as? String {
            createdAt = ISO8601DateFormatter().date(from: createdAtString) ?? Date()
        }
        
        return User(
            id: id,
            name: name,
            email: email,
            role: role,
            cqScore: cqScore,
            leaderboardRank: leaderboardRank,
            profileImageURL: profileImageURL,
            createdAt: createdAt,
            isActive: isActive,
            mealsSaved: mealsSaved,
            mealsSwapped: mealsSwapped,
            mealsDistributed: mealsDistributed
        )
    }
    
    // MARK: - Meal Mapping
    
    /// Convert Meal model to Supabase database format
    static func toSupabaseFormat(meal: Meal) -> [String: Any] {
        var data: [String: Any] = [
            "id": meal.id,
            "name": meal.name,
            "description": meal.description,
            "type": meal.type.rawValue,
            "status": meal.status.rawValue,
            "date": meal.date.ISO8601Format(),
            "location": meal.location
        ]
        
        // Handle nutritionInfo which might be optional
        if let nutrition = meal.nutritionInfo {
            data["calories"] = nutrition.calories
            data["protein"] = nutrition.protein
            data["carbs"] = nutrition.carbs
            data["fat"] = nutrition.fat
            data["allergens"] = nutrition.allergens
            data["dietary_info"] = nutrition.dietaryInfo
        }
        
        if let imageURL = meal.imageURL {
            data["image_url"] = imageURL
        }
        
        if let offeredBy = meal.offeredBy {
            data["offered_by"] = offeredBy
        }
        
        if let claimedBy = meal.claimedBy {
            data["claimed_by"] = claimedBy
        }
        
        if let offerExpiryTime = meal.offerExpiryTime {
            data["offer_expiry_time"] = offerExpiryTime.ISO8601Format()
        }
        
        if let claimDeadlineTime = meal.claimDeadlineTime {
            data["claim_deadline_time"] = claimDeadlineTime.ISO8601Format()
        }
        
        if let actuallyConsumed = meal.actuallyConsumed {
            data["actually_consumed"] = actuallyConsumed
        }
        
        data["is_feedback_provided"] = meal.feedbackProvided
        
        return data
    }
    
    /// Convert Supabase database format to Meal model
    static func toMeal(from data: [String: Any]) -> Meal? {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let typeString = data["type"] as? String,
            let type = MealType(rawValue: typeString),
            let statusString = data["status"] as? String,
            let status = MealStatus(rawValue: statusString),
            let location = data["location"] as? String
        else {
            return nil
        }
        
        let imageURL = data["image_url"] as? String
        
        // Parse date
        var date = Date()
        if let dateString = data["date"] as? String {
            date = ISO8601DateFormatter().date(from: dateString) ?? Date()
        }
        
        // Nutrition info
        let calories = data["calories"] as? Int ?? 0
        let protein = data["protein"] as? Double ?? 0
        let carbs = data["carbs"] as? Double ?? 0
        let fat = data["fat"] as? Double ?? 0
        let allergens = data["allergens"] as? [String] ?? []
        let dietaryInfo = data["dietary_info"] as? [String] ?? []
        
        let nutritionInfo = NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            allergens: allergens,
            dietaryInfo: dietaryInfo
        )
        
        // Swap-related fields
        let offeredBy = data["offered_by"] as? String
        let claimedBy = data["claimed_by"] as? String
        
        var offerExpiryTime: Date?
        if let expiryString = data["offer_expiry_time"] as? String {
            offerExpiryTime = ISO8601DateFormatter().date(from: expiryString)
        }
        
        var claimDeadlineTime: Date?
        if let deadlineString = data["claim_deadline_time"] as? String {
            claimDeadlineTime = ISO8601DateFormatter().date(from: deadlineString)
        }
        
        let actuallyConsumed = data["actually_consumed"] as? Bool
        let feedbackProvided = data["is_feedback_provided"] as? Bool ?? false
        
        return Meal(
            id: id,
            name: name,
            description: description,
            imageURL: imageURL,
            type: type,
            status: status,
            date: date,
            location: location,
            nutritionInfo: nutritionInfo,
            offeredBy: offeredBy,
            claimedBy: claimedBy,
            offerExpiryTime: offerExpiryTime,
            claimDeadlineTime: claimDeadlineTime,
            actuallyConsumed: actuallyConsumed,
            feedbackProvided: feedbackProvided
        )
    }
} 