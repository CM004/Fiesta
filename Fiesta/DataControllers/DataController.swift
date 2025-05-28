import Foundation
import Combine

class DataController: ObservableObject {
    // Published properties for UI binding
    @Published var currentUser: User?
    @Published var availableMeals: [Meal] = []
    @Published var offeredMeals: [Meal] = []
    @Published var claimedMeals: [Meal] = []
    @Published var mealSwaps: [MealSwap] = []
    @Published var predictions: [MealPrediction] = []
    @Published var leaderboard: [User] = []
    
    // Store paths for data persistence
    private let usersStorePath = "users.json"
    private let mealsStorePath = "meals.json"
    private let swapsStorePath = "swaps.json" 
    private let predictionsStorePath = "predictions.json"
    
    // Keys for UserDefaults
    private let currentUserIdKey = "com.fiesta.currentUserId"
    
    // FileManager for data persistence
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init() {
        // Try to restore user session first
        restoreUserSession()
        
        // If no user session, load regular data
        if currentUser == nil {
            loadData()
        }
        
        // If no data exists, create sample data for testing
        if availableMeals.isEmpty && currentUser == nil {
            createSampleData()
        }
    }
    
    // Public method to refresh data
    func refreshData() {
        loadData()
    }
    
    // MARK: - User Session Management
    
    private func restoreUserSession() {
        // Check if we have a saved user ID
        if let userId = UserDefaults.standard.string(forKey: currentUserIdKey) {
            let users = loadUsers()
            if let savedUser = users.first(where: { $0.id == userId }) {
                self.currentUser = savedUser
                
                // Load other data related to this user
                let allMeals = loadMeals()
                self.availableMeals = allMeals.filter { $0.status == .available }
                self.offeredMeals = allMeals.filter { $0.status == .offered && $0.offeredBy == currentUser?.id }
                self.claimedMeals = allMeals.filter { $0.status == .claimed && $0.claimedBy == currentUser?.id }
                self.mealSwaps = loadMealSwaps()
                self.predictions = loadPredictions()
                self.leaderboard = users.sorted { $0.cqScore > $1.cqScore }
                
                print("Restored session for user: \(savedUser.name)")
            }
        }
    }
    
    private func saveUserSession() {
        if let user = currentUser {
            UserDefaults.standard.set(user.id, forKey: currentUserIdKey)
            print("Saved session for user: \(user.name)")
        } else {
            UserDefaults.standard.removeObject(forKey: currentUserIdKey)
            print("Cleared user session")
        }
    }
    
    // MARK: - User Methods
    
    func login(email: String, password: String) -> Bool {
        // In a real app, this would authenticate with a server
        // For now, just simulate login with sample data
        if let user = loadUsers().first(where: { $0.email == email }) {
            self.currentUser = user
            saveUserSession()
            return true
        }
        return false
    }
    
    func logout() {
        // Reset user state when logging out
        self.currentUser = nil
        
        // Clear the saved user session
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        
        // Optionally clear any user-specific cached data
        self.claimedMeals = []
        self.offeredMeals = []
        
        // Refresh available meals to show general meals only
        refreshMealLists()
    }
    
    func registerUser(name: String, email: String, password: String) -> Bool {
        // In a real app, this would validate email format, password strength, etc.
        // and communicate with a backend server
        
        // Check if user already exists
        let users = loadUsers()
        if users.contains(where: { $0.email == email }) {
            return false // Email already registered
        }
        
        // Create new user
        let newUser = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: .student, // Default to student role
            cqScore: 0.0,   // Start with zero score
            createdAt: Date(),
            isActive: true,
            mealsSaved: 0,
            mealsSwapped: 0,
            mealsDistributed: 0
        )
        
        // Save the user
        var updatedUsers = users
        updatedUsers.append(newUser)
        saveUsers(updatedUsers)
        
        // Set as current user - auto login after registration
        self.currentUser = newUser
        saveUserSession()
        
        updateLeaderboard() // Update leaderboard to include the new user
        
        return true
    }
    
    func updateUser(_ user: User) {
        guard let index = loadUsers().firstIndex(where: { $0.id == user.id }) else {
            return
        }
        
        var users = loadUsers()
        users[index] = user
        
        if user.id == currentUser?.id {
            currentUser = user
        }
        
        saveUsers(users)
        updateLeaderboard()
    }
    
    // MARK: - Meal Methods
    
    func offerMeal(_ meal: Meal) -> Bool {
        guard currentUser != nil else { return false }
        
        var updatedMeal = meal
        updatedMeal.status = .offered
        updatedMeal.offeredBy = currentUser?.id
        updatedMeal.offerExpiryTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        
        // Create swap record
        let swap = MealSwap(
            mealId: meal.id,
            offeredBy: currentUser!.id,
            expiresAt: updatedMeal.offerExpiryTime ?? Date().addingTimeInterval(3600)
        )
        
        // Save meal and swap
        updateMeal(updatedMeal)
        saveMealSwap(swap)
        
        // Update current user stats
        if let user = currentUser {
            let updatedUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                cqScore: user.cqScore + 1.0,  // Add points for offering
                profileImageURL: user.profileImageURL,
                createdAt: user.createdAt,
                mealsSaved: user.mealsSaved + 1,
                mealsSwapped: user.mealsSwapped + 1,
                mealsDistributed: user.mealsDistributed
            )
            updateUser(updatedUser)
        }
        
        return true
    }
    
    func claimMeal(_ meal: Meal) -> Bool {
        guard let userId = currentUser?.id else { return false }
        guard meal.status == .offered else { return false }
        
        var updatedMeal = meal
        updatedMeal.status = .claimed
        updatedMeal.claimedBy = userId
        updatedMeal.claimDeadlineTime = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        
        // Update swap record
        if var swap = mealSwaps.first(where: { $0.mealId == meal.id && $0.status == .pending }) {
            swap.claimedBy = userId
            swap.claimedAt = Date()
            swap.status = .completed
            swap.cqPointsEarned = 1.0
            
            updateMealSwap(swap)
        }
        
        updateMeal(updatedMeal)
        
        // Update current user stats
        if let user = currentUser {
            let updatedUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                cqScore: user.cqScore + 0.5,  // Add points for claiming
                profileImageURL: user.profileImageURL,
                createdAt: user.createdAt,
                mealsSaved: user.mealsSaved,
                mealsSwapped: user.mealsSwapped,
                mealsDistributed: user.mealsDistributed + 1
            )
            updateUser(updatedUser)
        }
        
        return true
    }
    
    func confirmMealConsumption(_ meal: Meal, wasConsumed: Bool) {
        var updatedMeal = meal
        updatedMeal.actuallyConsumed = wasConsumed
        updatedMeal.status = wasConsumed ? .consumed : .unclaimed
        updatedMeal.feedbackProvided = true
        
        updateMeal(updatedMeal)
        
        // Update CQ score based on feedback
        if let user = currentUser, wasConsumed {
            let updatedUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                cqScore: user.cqScore + 0.5,  // Add points for confirming consumption
                profileImageURL: user.profileImageURL,
                createdAt: user.createdAt,
                mealsSaved: user.mealsSaved,
                mealsSwapped: user.mealsSwapped,
                mealsDistributed: user.mealsDistributed
            )
            updateUser(updatedUser)
        }
    }
    
    func updateMeal(_ meal: Meal) {
        var meals = loadMeals()
        
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
        } else {
            meals.append(meal)
        }
        
        saveMeals(meals)
        refreshMealLists()
    }
    
    // MARK: - Prediction Methods
    
    func getPredictionForMeal(date: Date, type: MealType, location: String) -> MealPrediction? {
        return predictions.first { prediction in
            let sameDay = Calendar.current.isDate(prediction.date, inSameDayAs: date)
            return sameDay && prediction.mealType == type && prediction.location == location
        }
    }
    
    func savePrediction(_ prediction: MealPrediction) {
        var predictions = loadPredictions()
        
        if let index = predictions.firstIndex(where: { $0.id == prediction.id }) {
            predictions[index] = prediction
        } else {
            predictions.append(prediction)
        }
        
        savePredictions(predictions)
        self.predictions = predictions
    }
    
    // MARK: - Swap Methods
    
    func updateMealSwap(_ swap: MealSwap) {
        var swaps = loadMealSwaps()
        
        if let index = swaps.firstIndex(where: { $0.id == swap.id }) {
            swaps[index] = swap
        } else {
            swaps.append(swap)
        }
        
        saveMealSwaps(swaps)
        self.mealSwaps = swaps
    }
    
    func saveMealSwap(_ swap: MealSwap) {
        var swaps = loadMealSwaps()
        swaps.append(swap)
        saveMealSwaps(swaps)
        self.mealSwaps = swaps
    }
    
    // MARK: - Leaderboard
    
    func updateLeaderboard() {
        let users = loadUsers().sorted { $0.cqScore > $1.cqScore }
        
        var rankedUsers = [User]()
        for (index, user) in users.enumerated() {
            var updatedUser = user
            updatedUser.leaderboardRank = index + 1
            rankedUsers.append(updatedUser)
        }
        
        self.leaderboard = rankedUsers
        saveUsers(rankedUsers)
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        let users = loadUsers()
        if let firstUser = users.first {
            self.currentUser = firstUser // For demo purposes
        }
        
        refreshMealLists()
        self.mealSwaps = loadMealSwaps()
        self.predictions = loadPredictions()
        self.leaderboard = users.sorted { $0.cqScore > $1.cqScore }
    }
    
    private func refreshMealLists() {
        let allMeals = loadMeals()
        
        // Check if there are any meals for today
        let hasTodayMeals = allMeals.contains { Calendar.current.isDateInToday($0.date) }
        let hasUpcomingMeals = allMeals.contains { 
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return Calendar.current.isDate($0.date, inSameDayAs: tomorrow) 
        }
        
        // If no meals for today or upcoming, create sample meals
        if !hasTodayMeals || !hasUpcomingMeals {
            createSampleMealsForCurrentPeriod()
        }
        
        // Refresh the lists with potentially updated meals
        let updatedMeals = loadMeals()
        self.availableMeals = updatedMeals.filter { $0.status == .available }
        self.offeredMeals = updatedMeals.filter { $0.status == .offered && $0.offeredBy == currentUser?.id }
        self.claimedMeals = updatedMeals.filter { $0.status == .claimed && $0.claimedBy == currentUser?.id }
    }
    
    // Create sample meals for current day if none exist
    private func createSampleMealsForCurrentPeriod() {
        print("Creating sample meals for current period")
        
        // Today's meals
        let todayMeals: [Meal] = [
            Meal(id: "today1", 
                 name: "Vegetable Curry with Rice", 
                 description: "A hearty vegetable curry served with steamed rice", 
                 imageURL: "curry_rice", 
                 type: .lunch, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 450, protein: 12.0, carbs: 65.0, fat: 15.0, allergens: ["Nuts"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "today2", 
                 name: "Pasta with Tomato Sauce", 
                 description: "Penne pasta with homemade tomato sauce and parmesan cheese", 
                 imageURL: "pasta", 
                 type: .dinner, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 580, protein: 18.0, carbs: 90.0, fat: 10.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"]))
        ]
        
        // Tomorrow's meals
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let upcomingMeals: [Meal] = [
            Meal(id: "upcoming1", 
                 name: "Grilled Chicken Sandwich", 
                 description: "Grilled chicken breast with lettuce, tomato and mayo in a whole wheat bun", 
                 imageURL: "chicken_sandwich", 
                 type: .lunch, 
                 status: .available,
                 date: tomorrowDate, 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 420, protein: 28.0, carbs: 45.0, fat: 12.0, allergens: ["Gluten"], dietaryInfo: []))
        ]
        
        // Offered meals (for swap tab)
        let offeredMeals: [Meal] = [
            Meal(id: "offered1", 
                 name: "Caesar Salad", 
                 description: "Fresh romaine lettuce with grilled chicken, croutons, and caesar dressing", 
                 imageURL: "caesar_salad", 
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "East Wing Cafe",
                 nutritionInfo: NutritionInfo(calories: 320, protein: 22.0, carbs: 15.0, fat: 18.0, allergens: ["Gluten", "Dairy"], dietaryInfo: []),
                 offeredBy: "2", // Offered by another user
                 offerExpiryTime: Date().addingTimeInterval(3600)), // 1 hour from now
            
            Meal(id: "offered2", 
                 name: "Vegetable Soup", 
                 description: "Hearty vegetable soup with fresh bread roll", 
                 imageURL: "vegetable_soup", 
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 220, protein: 8.0, carbs: 35.0, fat: 5.0, allergens: ["Celery"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by another user
                 offerExpiryTime: Date().addingTimeInterval(2700)) // 45 minutes from now
        ]
        
        // Swaps for the offered meals
        let newSwaps: [MealSwap] = [
            MealSwap(
                id: "newswap1",
                mealId: "offered1",
                offeredBy: "2",
                expiresAt: Date().addingTimeInterval(3600)
            ),
            MealSwap(
                id: "newswap2",
                mealId: "offered2",
                offeredBy: "2",
                expiresAt: Date().addingTimeInterval(2700)
            )
        ]
        
        // Get existing meals and add the new ones
        var existingMeals = loadMeals()
        var existingSwaps = loadMealSwaps()
        
        // Remove any conflicting IDs (prevent duplicates)
        existingMeals.removeAll { meal in
            todayMeals.contains { $0.id == meal.id } || 
            upcomingMeals.contains { $0.id == meal.id } || 
            offeredMeals.contains { $0.id == meal.id }
        }
        
        existingSwaps.removeAll { swap in
            newSwaps.contains { $0.id == swap.id }
        }
        
        // Add the new meals and swaps
        existingMeals.append(contentsOf: todayMeals)
        existingMeals.append(contentsOf: upcomingMeals)
        existingMeals.append(contentsOf: offeredMeals)
        existingSwaps.append(contentsOf: newSwaps)
        
        // Save the updated data
        saveMeals(existingMeals)
        saveMealSwaps(existingSwaps)
    }
    
    // MARK: - File Operations
    
    private func loadUsers() -> [User] {
        return loadFromFile(usersStorePath, defaultValue: [User]())
    }
    
    private func saveUsers(_ users: [User]) {
        saveToFile(users, filePath: usersStorePath)
    }
    
    private func loadMeals() -> [Meal] {
        return loadFromFile(mealsStorePath, defaultValue: [Meal]())
    }
    
    private func saveMeals(_ meals: [Meal]) {
        saveToFile(meals, filePath: mealsStorePath)
    }
    
    private func loadMealSwaps() -> [MealSwap] {
        return loadFromFile(swapsStorePath, defaultValue: [MealSwap]())
    }
    
    private func saveMealSwaps(_ swaps: [MealSwap]) {
        saveToFile(swaps, filePath: swapsStorePath)
    }
    
    private func loadPredictions() -> [MealPrediction] {
        return loadFromFile(predictionsStorePath, defaultValue: [MealPrediction]())
    }
    
    private func savePredictions(_ predictions: [MealPrediction]) {
        saveToFile(predictions, filePath: predictionsStorePath)
    }
    
    private func loadFromFile<T: Decodable>(_ filename: String, defaultValue: T) -> T {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return defaultValue
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading data: \(error)")
            return defaultValue
        }
    }
    
    private func saveToFile<T: Encodable>(_ data: T, filePath: String) {
        let fileURL = documentsDirectory.appendingPathComponent(filePath)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(data)
            try data.write(to: fileURL)
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    // MARK: - Sample Data Generation
    
    private func createSampleData() {
        // Create sample users
        let sampleUsers: [User] = [
            User(id: "1", name: "Student One", email: "student1@test.com", role: .student, cqScore: 85.0, mealsSaved: 12, mealsSwapped: 15, mealsDistributed: 3),
            User(id: "2", name: "Student Two", email: "student2@test.com", role: .student, cqScore: 72.5, mealsSaved: 8, mealsSwapped: 10, mealsDistributed: 5),
            User(id: "3", name: "Cafeteria Staff", email: "staff@test.com", role: .cafeteriaStaff, cqScore: 0.0),
            User(id: "4", name: "Admin User", email: "admin@test.com", role: .admin, cqScore: 0.0)
        ]
        
        // Create sample meals - Available meals
        let sampleMeals: [Meal] = [
            Meal(id: "1", 
                 name: "Vegetable Curry with Rice", 
                 description: "A hearty vegetable curry served with steamed rice", 
                 imageURL: "curry_rice", 
                 type: .lunch, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 450, protein: 12.0, carbs: 65.0, fat: 15.0, allergens: ["Nuts"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "2", 
                 name: "Pancakes with Maple Syrup", 
                 description: "Fluffy pancakes served with maple syrup and fresh berries", 
                 imageURL: "pancakes", 
                 type: .breakfast, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 550, protein: 8.0, carbs: 85.0, fat: 12.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "3", 
                 name: "Grilled Chicken Sandwich", 
                 description: "Grilled chicken breast with lettuce, tomato and mayo in a whole wheat bun", 
                 imageURL: "chicken_sandwich", 
                 type: .lunch, 
                 status: .available,
                 date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 420, protein: 28.0, carbs: 45.0, fat: 12.0, allergens: ["Gluten"], dietaryInfo: [])),
            
            Meal(id: "4", 
                 name: "Pasta with Tomato Sauce", 
                 description: "Penne pasta with homemade tomato sauce and parmesan cheese", 
                 imageURL: "pasta", 
                 type: .dinner, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 580, protein: 18.0, carbs: 90.0, fat: 10.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "5", 
                 name: "Fruit Salad", 
                 description: "Fresh seasonal fruits with a honey-lime dressing", 
                 imageURL: "fruit_salad", 
                 type: .snack, 
                 status: .available,
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 120, protein: 2.0, carbs: 28.0, fat: 0.5, allergens: [], dietaryInfo: ["Vegan", "Vegetarian"]))
        ]
        
        // Create sample offered meals (ready to be claimed)
        let sampleOfferedMeals: [Meal] = [
            Meal(id: "6", 
                 name: "Caesar Salad", 
                 description: "Fresh romaine lettuce with grilled chicken, croutons, and caesar dressing", 
                 imageURL: "caesar_salad", 
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "East Wing Cafe",
                 nutritionInfo: NutritionInfo(calories: 320, protein: 22.0, carbs: 15.0, fat: 18.0, allergens: ["Gluten", "Dairy"], dietaryInfo: []),
                 offeredBy: "2", // Offered by Student Two
                 offerExpiryTime: Date().addingTimeInterval(3600)), // 1 hour from now
            
            Meal(id: "7", 
                 name: "Vegetable Soup", 
                 description: "Hearty vegetable soup with fresh bread roll", 
                 imageURL: "vegetable_soup", 
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 220, protein: 8.0, carbs: 35.0, fat: 5.0, allergens: ["Celery"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by Student Two
                 offerExpiryTime: Date().addingTimeInterval(2700)), // 45 minutes from now
            
            Meal(id: "8", 
                 name: "Chocolate Brownie", 
                 description: "Rich chocolate brownie with walnuts", 
                 imageURL: "brownie", 
                 type: .snack, 
                 status: .offered,
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 280, protein: 4.0, carbs: 32.0, fat: 16.0, allergens: ["Gluten", "Dairy", "Nuts"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by Student Two
                 offerExpiryTime: Date().addingTimeInterval(1800)) // 30 minutes from now
        ]
        
        // Add some claimed meals for sample history
        let sampleClaimedMeals: [Meal] = [
            Meal(id: "9", 
                 name: "Quinoa Bowl", 
                 description: "Quinoa with roasted vegetables and tahini dressing", 
                 imageURL: "quinoa_bowl", 
                 type: .lunch, 
                 status: .claimed,
                 date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 380, protein: 12.0, carbs: 58.0, fat: 10.0, allergens: ["Sesame"], dietaryInfo: ["Vegan", "Vegetarian", "Gluten-Free"]),
                 offeredBy: "2",
                 claimedBy: "1",
                 claimDeadlineTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)
        ]
        
        // Combine all meal types
        var allMeals = sampleMeals
        allMeals.append(contentsOf: sampleOfferedMeals)
        allMeals.append(contentsOf: sampleClaimedMeals)
        
        // Create sample predictions
        let samplePredictions: [MealPrediction] = [
            MealPrediction(
                date: Date(),
                mealType: .lunch,
                location: "Main Cafeteria",
                predictedAttendance: 250,
                weatherCondition: "Sunny",
                isExamDay: false,
                isHoliday: false,
                isEventDay: false,
                confidenceScore: 0.85,
                factors: [
                    PredictionFactor(name: "Weather", impact: 0.2, description: "Good weather increases attendance"),
                    PredictionFactor(name: "Day of Week", impact: 0.1, description: "Midweek has higher attendance")
                ],
                adjustedPreparationLevel: 260,
                wasteReduction: 15
            ),
            
            MealPrediction(
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                mealType: .lunch,
                location: "Main Cafeteria",
                predictedAttendance: 200,
                weatherCondition: "Rainy",
                isExamDay: true,
                isHoliday: false,
                isEventDay: false,
                confidenceScore: 0.78,
                factors: [
                    PredictionFactor(name: "Weather", impact: -0.15, description: "Bad weather decreases attendance"),
                    PredictionFactor(name: "Exam Day", impact: -0.25, description: "Exam days have lower cafeteria attendance")
                ],
                adjustedPreparationLevel: 190,
                wasteReduction: 30
            )
        ]
        
        // Create sample swaps
        let sampleSwaps: [MealSwap] = [
            MealSwap(
                id: "swap1",
                mealId: "6",
                offeredBy: "2",
                expiresAt: Date().addingTimeInterval(3600)
            ),
            MealSwap(
                id: "swap2",
                mealId: "7",
                offeredBy: "2",
                expiresAt: Date().addingTimeInterval(2700)
            ),
            MealSwap(
                id: "swap3",
                mealId: "8",
                offeredBy: "2",
                expiresAt: Date().addingTimeInterval(1800)
            ),
            MealSwap(
                id: "swap4",
                mealId: "9",
                offeredBy: "2",
                claimedBy: "1",
                claimedAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!,
                expiresAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
                status: .completed,
                cqPointsEarned: 1.5
            )
        ]
        
        // Save sample data
        saveUsers(sampleUsers)
        saveMeals(allMeals)
        savePredictions(samplePredictions)
        saveMealSwaps(sampleSwaps)
        
        // Set the first user as the current user
        self.currentUser = sampleUsers[0]
        self.predictions = samplePredictions
        refreshMealLists()
        updateLeaderboard()
    }
} 