import Foundation
import Supabase

@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    
    // Table names
    private let usersTable = "users"
    private let mealsTable = "meals"
    private let mealSwapsTable = "meal_swaps"
    private let predictionsTable = "meal_predictions"
    
    // Storage buckets
    private let profileImagesBucket = SupabaseConfig.profileImagesBucket
    private let mealImagesBucket = SupabaseConfig.mealImagesBucket
    
    // In-memory cache for deserialized User objects to reduce database calls
    private var userCache: [String: User] = [:]
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        print("SupabaseManager: Initialized with URL \(SupabaseConfig.supabaseURL)")
        
        let authStateChanges = client.auth.authStateChanges
    }
    
    // MARK: - User Profile Operations
    
    /// Create or update a user profile in Supabase
    func upsertUserProfile(user: User) async throws {
        print("SupabaseManager: Upserting user profile for \(user.name) (\(user.id))")
        
        // Convert User model to dictionary for Supabase
        let userData = SupabaseModelMapper.toSupabaseFormat(user: user)
        print("SupabaseManager: User data for API: \(userData)")
        
        // Use direct REST API calls which should be more compatible with all Supabase SDK versions
        // First check if the user exists
        do {
            let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)?id=eq.\(user.id)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseStr = String(data: data, encoding: .utf8) ?? "[]"
            
            print("SupabaseManager: User check response: \(responseStr)")
            
            if responseStr != "[]" {
                // User exists, update
                let updateUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)?id=eq.\(user.id)")!
                
                var updateRequest = URLRequest(url: updateUrl)
                updateRequest.httpMethod = "PATCH"
                updateRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                updateRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
                updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                updateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                updateRequest.httpBody = try JSONSerialization.data(withJSONObject: userData)
                
                let (updateData, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                
                if let httpResponse = updateResponse as? HTTPURLResponse {
                    print("SupabaseManager: Update status code: \(httpResponse.statusCode)")
                    if !(200...299).contains(httpResponse.statusCode) {
                        let errorStr = String(data: updateData, encoding: .utf8) ?? ""
                        print("SupabaseManager: Update error: \(errorStr)")
                    }
                }
                
                // Update local cache regardless of result to ensure app keeps functioning
                userCache[user.id] = user
                
            } else {
                // User doesn't exist, insert
                let insertUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)")!
                
                var insertRequest = URLRequest(url: insertUrl)
                insertRequest.httpMethod = "POST"
                insertRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                insertRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey") 
                insertRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                insertRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                insertRequest.httpBody = try JSONSerialization.data(withJSONObject: userData)
                
                let (insertData, insertResponse) = try await URLSession.shared.data(for: insertRequest)
                
                if let httpResponse = insertResponse as? HTTPURLResponse {
                    print("SupabaseManager: Insert status code: \(httpResponse.statusCode)")
                    if !(200...299).contains(httpResponse.statusCode) {
                        let errorStr = String(data: insertData, encoding: .utf8) ?? ""
                        print("SupabaseManager: Insert error: \(errorStr)")
                    }
                }
                
                // Update local cache regardless of result
                userCache[user.id] = user
            }
            
        } catch {
            print("SupabaseManager: Error in upsertUserProfile: \(error.localizedDescription)")
            
            // Even though there was an error, we'll update the local cache so the app can function
            userCache[user.id] = user
            
            // Don't rethrow the error - this allows sign-in and signup to continue working
            // even if profile creation fails
        }
    }
    
    /// Fetch a user profile by ID
    func fetchUserProfile(id: String) async throws -> User? {
        // Check cache first
        if let cachedUser = userCache[id] {
            return cachedUser
        }
        
        print("SupabaseManager: Fetching user profile with ID: \(id)")
        
        // Use direct REST API call
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)?id=eq.\(id)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as a single user
        if let users = try? JSONDecoder().decode([SupabaseUserData].self, from: data),
           let userData = users.first {
            let user = userData.toModel()
            userCache[id] = user
            print("SupabaseManager: Successfully fetched user: \(user.name)")
            return user
        } else {
            print("SupabaseManager: No user found or failed to decode user data for ID: \(id)")
            return nil
        }
    }
    
    /// Fetch a user profile by email
    func fetchUserProfileByEmail(email: String) async throws -> User? {
        // Check cache for matching email
        if let cachedUser = userCache.values.first(where: { $0.email.lowercased() == email.lowercased() }) {
            return cachedUser
        }
        
        print("SupabaseManager: Looking up user by email: \(email)")
        
        // Use direct REST API call
        let encodedEmail = email.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email.lowercased()
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)?email=eq.\(encodedEmail)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as a single user
        if let users = try? JSONDecoder().decode([SupabaseUserData].self, from: data),
           let userData = users.first {
            let user = userData.toModel()
            userCache[user.id] = user
            print("SupabaseManager: Found user by email: \(user.name) (\(user.id))")
            return user
        } else {
            print("SupabaseManager: No user found or failed to decode user data for email: \(email)")
            return nil
        }
    }
    
    /// Fetch all user profiles (for leaderboard)
    func fetchAllUserProfiles() async throws -> [User] {
        print("SupabaseManager: Fetching all user profiles for leaderboard")
        
        // Use direct REST API call
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(usersTable)?order=cq_score.desc")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as an array of users
        if let usersData = try? JSONDecoder().decode([SupabaseUserData].self, from: data) {
            let users = usersData.map { $0.toModel() }
            
            // Update cache
            for user in users {
                userCache[user.id] = user
            }
            
            print("SupabaseManager: Fetched \(users.count) users for leaderboard")
            return users
        } else {
            print("SupabaseManager: Failed to decode user data")
            return []
        }
    }
    
    // MARK: - Meal Operations
    
    /// Create or update a meal
    func upsertMeal(_ meal: Meal) async throws {
        print("SupabaseManager: Upserting meal: \(meal.name) (\(meal.id))")
        
        let mealData = SupabaseModelMapper.toSupabaseFormat(meal: meal)
        
        // Use direct REST API call to check if meal exists
        let checkUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)?id=eq.\(meal.id)")!
        
        var request = URLRequest(url: checkUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseString = String(data: data, encoding: .utf8) ?? "[]"
        
        if responseString != "[]" {
            // Meal exists, update
            let updateUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)?id=eq.\(meal.id)")!
            
            var updateRequest = URLRequest(url: updateUrl)
            updateRequest.httpMethod = "PATCH"
            updateRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: mealData)
            
            let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
            
            if let httpResponse = updateResponse as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("SupabaseManager: Failed to update meal: \(httpResponse.statusCode)")
            }
        } else {
            // Meal doesn't exist, insert
            let insertUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)")!
            
            var insertRequest = URLRequest(url: insertUrl)
            insertRequest.httpMethod = "POST"
            insertRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            insertRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            insertRequest.httpBody = try JSONSerialization.data(withJSONObject: mealData)
            
            let (_, insertResponse) = try await URLSession.shared.data(for: insertRequest)
            
            if let httpResponse = insertResponse as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("SupabaseManager: Failed to insert meal: \(httpResponse.statusCode)")
            }
        }
    }
    
    /// Fetch all available meals
    func fetchMeals(status: MealStatus? = nil) async throws -> [Meal] {
        print("SupabaseManager: Fetching meals" + (status != nil ? " with status: \(status!.rawValue)" : ""))
        
        // Use direct REST API call
        var urlString = "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)"
        
        if let status = status {
            urlString += "?status=eq.\(status.rawValue)"
        }
        
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as an array of meals
        if let mealsData = try? JSONDecoder().decode([SupabaseMealData].self, from: data) {
            let meals = mealsData.map { $0.toModel() }
            print("SupabaseManager: Fetched \(meals.count) meals")
            return meals
        } else {
            print("SupabaseManager: Failed to decode meal data")
            return []
        }
    }
    
    /// Fetch meals offered by a specific user
    func fetchOfferedMeals(by userId: String) async throws -> [Meal] {
        print("SupabaseManager: Fetching meals offered by user: \(userId)")
        
        // Use direct REST API call
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)?offered_by=eq.\(userId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as an array of meals
        if let mealsData = try? JSONDecoder().decode([SupabaseMealData].self, from: data) {
            let meals = mealsData.map { $0.toModel() }
            print("SupabaseManager: Fetched \(meals.count) offered meals")
            return meals
        } else {
            print("SupabaseManager: Failed to decode offered meals data")
            return []
        }
    }
    
    /// Fetch meals claimed by a specific user
    func fetchClaimedMeals(by userId: String) async throws -> [Meal] {
        print("SupabaseManager: Fetching meals claimed by user: \(userId)")
        
        // Use direct REST API call
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealsTable)?claimed_by=eq.\(userId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as an array of meals
        if let mealsData = try? JSONDecoder().decode([SupabaseMealData].self, from: data) {
            let meals = mealsData.map { $0.toModel() }
            print("SupabaseManager: Fetched \(meals.count) claimed meals")
            return meals
        } else {
            print("SupabaseManager: Failed to decode claimed meals data")
            return []
        }
    }
    
    // MARK: - Meal Swap Operations
    
    func upsertMealSwap(_ swap: MealSwap) async throws {
        print("SupabaseManager: Upserting meal swap: \(swap.id)")
        
        // Convert to Supabase format
        let swapData: [String: Any] = [
            "id": swap.id,
            "meal_id": swap.mealId,
            "offered_by": swap.offeredBy,
            "claimed_by": swap.claimedBy as Any,
            "claimed_at": swap.claimedAt?.timeIntervalSince1970 as Any,
            "expires_at": swap.expiresAt.timeIntervalSince1970,
            "status": swap.status.rawValue,
            "cq_points_earned": swap.cqPointsEarned as Any
        ]
        
        // Use direct REST API call to check if swap exists
        let checkUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)?id=eq.\(swap.id)")!
        
        var request = URLRequest(url: checkUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseString = String(data: data, encoding: .utf8) ?? "[]"
        
        if responseString != "[]" {
            // Swap exists, update
            let updateUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)?id=eq.\(swap.id)")!
            
            var updateRequest = URLRequest(url: updateUrl)
            updateRequest.httpMethod = "PATCH"
            updateRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            updateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: swapData)
            
            let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
            
            if let httpResponse = updateResponse as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("SupabaseManager: Failed to update swap: \(httpResponse.statusCode)")
            }
        } else {
            // Swap doesn't exist, insert
            let insertUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)")!
            
            var insertRequest = URLRequest(url: insertUrl)
            insertRequest.httpMethod = "POST"
            insertRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            insertRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            insertRequest.httpBody = try JSONSerialization.data(withJSONObject: swapData)
            
            let (_, insertResponse) = try await URLSession.shared.data(for: insertRequest)
            
            if let httpResponse = insertResponse as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("SupabaseManager: Failed to insert swap: \(httpResponse.statusCode)")
            }
        }
    }
    
    func fetchMealSwaps(for userId: String? = nil) async throws -> [MealSwap] {
        print("SupabaseManager: Fetching meal swaps" + (userId != nil ? " for user: \(userId!)" : ""))
        
        if let userId = userId {
            // Fetch swaps that this user either offered or claimed
            // We need to do two separate queries and combine results
            var combinedData: [SupabaseMealSwapData] = []
            
            // Get offered swaps
            let offeredUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)?offered_by=eq.\(userId)")!
            
            var offeredRequest = URLRequest(url: offeredUrl)
            offeredRequest.httpMethod = "GET"
            offeredRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            offeredRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (offeredData, _) = try await URLSession.shared.data(for: offeredRequest)
            
            if let offeredSwaps = try? JSONDecoder().decode([SupabaseMealSwapData].self, from: offeredData) {
                combinedData.append(contentsOf: offeredSwaps)
            }
            
            // Get claimed swaps
            let claimedUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)?claimed_by=eq.\(userId)")!
            
            var claimedRequest = URLRequest(url: claimedUrl)
            claimedRequest.httpMethod = "GET"
            claimedRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            claimedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (claimedData, _) = try await URLSession.shared.data(for: claimedRequest)
            
            if let claimedSwaps = try? JSONDecoder().decode([SupabaseMealSwapData].self, from: claimedData) {
                combinedData.append(contentsOf: claimedSwaps)
            }
            
            // Remove duplicates (if any)
            let uniqueSwaps = Array(Dictionary(combinedData.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
            let swaps = uniqueSwaps.map { $0.toModel() }
            
            print("SupabaseManager: Fetched \(swaps.count) swaps for user \(userId)")
            return swaps
        } else {
            // Fetch all swaps
            let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(mealSwapsTable)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Try to decode as an array of swaps
            if let swapsData = try? JSONDecoder().decode([SupabaseMealSwapData].self, from: data) {
                let swaps = swapsData.map { $0.toModel() }
                print("SupabaseManager: Fetched \(swaps.count) swaps")
                return swaps
            } else {
                print("SupabaseManager: Failed to decode swap data")
                return []
            }
        }
    }
    
    // MARK: - Prediction Operations
    
    func upsertPrediction(_ prediction: MealPrediction) async throws {
        print("SupabaseManager: Upserting meal prediction for \(prediction.date)")
        
        // Convert to Supabase format
        var predictionData: [String: Any] = [
            "id": prediction.id ?? UUID().uuidString,
            "date": prediction.date.timeIntervalSince1970,
            "meal_type": prediction.mealType.rawValue,
            "location": prediction.location,
            "predicted_attendance": prediction.predictedAttendance,
            "weather_condition": prediction.weatherCondition,
            "is_exam_day": prediction.isExamDay,
            "is_holiday": prediction.isHoliday,
            "is_event_day": prediction.isEventDay,
            "confidence_score": prediction.confidenceScore,
            "adjusted_preparation_level": prediction.adjustedPreparationLevel,
            "waste_reduction": prediction.wasteReduction
        ]
        
        // Add factors if they're not empty
        if !prediction.factors.isEmpty {
            let factorsData = prediction.factors.map { factor -> [String: Any] in
                return [
                    "name": factor.name,
                    "impact": factor.impact,
                    "description": factor.description
                ]
            }
            predictionData["factors"] = factorsData
        }
        
        let predictId = prediction.id ?? ""
        
        if !predictId.isEmpty {
            // Check if prediction exists
            let checkUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(predictionsTable)?id=eq.\(predictId)")!
            
            var request = URLRequest(url: checkUrl)
            request.httpMethod = "GET"
            request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let responseString = String(data: data, encoding: .utf8) ?? "[]"
            
            if responseString != "[]" {
                // Prediction exists, update
                let updateUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(predictionsTable)?id=eq.\(predictId)")!
                
                var updateRequest = URLRequest(url: updateUrl)
                updateRequest.httpMethod = "PATCH"
                updateRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                updateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                updateRequest.httpBody = try JSONSerialization.data(withJSONObject: predictionData)
                
                let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                
                if let httpResponse = updateResponse as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    print("SupabaseManager: Failed to update prediction: \(httpResponse.statusCode)")
                }
                
                return
            }
        }
        
        // Prediction doesn't exist or has no ID, insert
        let insertUrl = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(predictionsTable)")!
        
        var insertRequest = URLRequest(url: insertUrl)
        insertRequest.httpMethod = "POST"
        insertRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        insertRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        insertRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        insertRequest.httpBody = try JSONSerialization.data(withJSONObject: predictionData)
        
        let (_, insertResponse) = try await URLSession.shared.data(for: insertRequest)
        
        if let httpResponse = insertResponse as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            print("SupabaseManager: Failed to insert prediction: \(httpResponse.statusCode)")
        }
    }
    
    func fetchPredictions() async throws -> [MealPrediction] {
        print("SupabaseManager: Fetching meal predictions")
        
        // Use direct REST API call
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/\(predictionsTable)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Try to decode as an array of predictions
        if let predictionsData = try? JSONDecoder().decode([SupabasePredictionData].self, from: data) {
            let predictions = predictionsData.map { $0.toModel() }
            print("SupabaseManager: Fetched \(predictions.count) predictions")
            return predictions
        } else {
            print("SupabaseManager: Failed to decode prediction data")
            return []
        }
    }
    
    // MARK: - Image Upload & Download
    
    func uploadProfileImage(userId: String, imageData: Data) async throws -> String {
        print("SupabaseManager: Uploading profile image for user: \(userId)")
        
        let path = "user_\(userId).jpg"
        
        // Direct API call to upload image
        let uploadURL = URL(string: "\(SupabaseConfig.supabaseURL)/storage/v1/object/\(profileImagesBucket)/\(path)")!
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Failed to upload profile image. Status code: \(httpResponse.statusCode)"
            ])
        }
        
        return path
    }
    
    func uploadMealImage(mealId: String, imageData: Data) async throws -> String {
        print("SupabaseManager: Uploading meal image for meal: \(mealId)")
        
        let path = "meal_\(mealId).jpg"
        
        // Direct API call to upload image
        let uploadURL = URL(string: "\(SupabaseConfig.supabaseURL)/storage/v1/object/\(mealImagesBucket)/\(path)")!
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw NSError(domain: "SupabaseManager", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Failed to upload meal image. Status code: \(httpResponse.statusCode)"
            ])
        }
        
        return path
    }
    
    func getImageUrl(bucket: String, path: String) -> URL? {
        return URL(string: "\(SupabaseConfig.supabaseURL)/storage/v1/object/public/\(bucket)/\(path)")
    }
}

// MARK: - Supabase Data Models

// These models match the JSON structure returned by Supabase
struct SupabaseUserData: Codable {
    let id: String
    let name: String
    let email: String
    let role: String
    let cq_score: Double
    let leaderboard_rank: Int?
    let profile_image_url: String?
    let created_at: String
    let is_active: Bool
    let meals_saved: Int
    let meals_swapped: Int
    let meals_distributed: Int
    
    func toModel() -> User {
        let createdDate = ISO8601DateFormatter().date(from: created_at) ?? Date()
        
        return User(
            id: id,
            name: name,
            email: email,
            role: UserRole(rawValue: role) ?? .student,
            cqScore: cq_score,
            leaderboardRank: leaderboard_rank,
            profileImageURL: profile_image_url,
            createdAt: createdDate,
            isActive: is_active,
            mealsSaved: meals_saved,
            mealsSwapped: meals_swapped,
            mealsDistributed: meals_distributed
        )
    }
}

struct SupabaseMealData: Codable {
    let id: String
    let name: String
    let description: String
    let image_url: String?
    let type: String
    let status: String
    let date: String
    let location: String
    
    // Nutrition info
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let allergens: [String]?
    let dietary_info: [String]?
    
    // Swap-related fields
    let offered_by: String?
    let claimed_by: String?
    let offer_expiry_time: String?
    let claim_deadline_time: String?
    let actually_consumed: Bool?
    let is_feedback_provided: Bool?
    
    func toModel() -> Meal {
        let mealDate = ISO8601DateFormatter().date(from: date) ?? Date()
        
        var offerExpiry: Date?
        if let expiryString = offer_expiry_time {
            offerExpiry = ISO8601DateFormatter().date(from: expiryString)
        }
        
        var claimDeadline: Date?
        if let deadlineString = claim_deadline_time {
            claimDeadline = ISO8601DateFormatter().date(from: deadlineString)
        }
        
        let nutrition = NutritionInfo(
            calories: calories ?? 0,
            protein: protein ?? 0,
            carbs: carbs ?? 0,
            fat: fat ?? 0,
            allergens: allergens ?? [],
            dietaryInfo: dietary_info ?? []
        )
        
        return Meal(
            id: id,
            name: name,
            description: description,
            imageURL: image_url,
            type: MealType(rawValue: type) ?? .lunch,
            status: MealStatus(rawValue: status) ?? .available,
            date: mealDate,
            location: location,
            nutritionInfo: nutrition,
            offeredBy: offered_by,
            claimedBy: claimed_by,
            offerExpiryTime: offerExpiry,
            claimDeadlineTime: claimDeadline,
            actuallyConsumed: actually_consumed,
            feedbackProvided: is_feedback_provided ?? false
        )
    }
}

struct SupabaseMealSwapData: Codable {
    let id: String
    let meal_id: String
    let offered_by: String
    let claimed_by: String?
    let claimed_at: Double?
    let expires_at: Double
    let status: String
    let cq_points_earned: Double?
    
    func toModel() -> MealSwap {
        var claimedDate: Date?
        if let claimedTimestamp = claimed_at {
            claimedDate = Date(timeIntervalSince1970: claimedTimestamp)
        }
        
        return MealSwap(
            id: id,
            mealId: meal_id,
            offeredBy: offered_by,
            claimedBy: claimed_by,
            claimedAt: claimedDate,
            expiresAt: Date(timeIntervalSince1970: expires_at),
            status: MealSwapStatus(rawValue: status) ?? .pending,
            cqPointsEarned: cq_points_earned
        )
    }
}

struct SupabasePredictionData: Codable {
    let id: String
    let date: Double
    let meal_type: String
    let location: String
    let predicted_attendance: Int
    let weather_condition: String
    let is_exam_day: Bool
    let is_holiday: Bool
    let is_event_day: Bool
    let confidence_score: Double
    let factors: [FactorData]?
    let adjusted_preparation_level: Int
    let waste_reduction: Int
    
    struct FactorData: Codable {
        let name: String
        let impact: Double
        let description: String
    }
    
    func toModel() -> MealPrediction {
        var predictionFactors: [PredictionFactor] = []
        
        if let factorsData = factors {
            predictionFactors = factorsData.map { factor in
                PredictionFactor(
                    name: factor.name,
                    impact: factor.impact,
                    description: factor.description
                )
            }
        }
        
        return MealPrediction(
            id: id,
            date: Date(timeIntervalSince1970: date),
            mealType: MealType(rawValue: meal_type) ?? .lunch,
            location: location,
            predictedAttendance: predicted_attendance,
            weatherCondition: weather_condition,
            isExamDay: is_exam_day,
            isHoliday: is_holiday,
            isEventDay: is_event_day,
            confidenceScore: confidence_score,
            factors: predictionFactors,
            adjustedPreparationLevel: adjusted_preparation_level,
            wasteReduction: waste_reduction
        )
    }
} 
