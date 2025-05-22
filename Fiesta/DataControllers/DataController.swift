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
    
    // FileManager for data persistence
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init() {
        loadData()
        
        // If no data exists, create sample data for testing
        if availableMeals.isEmpty && currentUser == nil {
            createSampleData()
        }
    }
    
    // Public method to refresh data
    func refreshData() {
        loadData()
    }
    
    // MARK: - User Methods
    
    func login(email: String, password: String) -> Bool {
        // In a real app, this would authenticate with a server
        // For now, just simulate login with sample data
        if let user = loadUsers().first(where: { $0.email == email }) {
            self.currentUser = user
            return true
        }
        return false
    }
    
    func logout() {
        // Reset user state when logging out
        self.currentUser = nil
        
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
        self.availableMeals = allMeals.filter { $0.status == .available }
        self.offeredMeals = allMeals.filter { $0.status == .offered && $0.offeredBy == currentUser?.id }
        self.claimedMeals = allMeals.filter { $0.status == .claimed && $0.claimedBy == currentUser?.id }
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
        
        // Create sample meals
        let sampleMeals: [Meal] = [
            Meal(id: "1", 
                 name: "Vegetable Curry with Rice", 
                 description: "A hearty vegetable curry served with steamed rice", 
                 imageURL: "curry_rice", 
                 type: .lunch, 
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 450, protein: 12.0, carbs: 65.0, fat: 15.0, allergens: ["Nuts"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "2", 
                 name: "Pancakes with Maple Syrup", 
                 description: "Fluffy pancakes served with maple syrup and fresh berries", 
                 imageURL: "pancakes", 
                 type: .breakfast, 
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 550, protein: 8.0, carbs: 85.0, fat: 12.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "3", 
                 name: "Grilled Chicken Sandwich", 
                 description: "Grilled chicken breast with lettuce, tomato and mayo in a whole wheat bun", 
                 imageURL: "chicken_sandwich", 
                 type: .lunch, 
                 date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 420, protein: 28.0, carbs: 45.0, fat: 12.0, allergens: ["Gluten"], dietaryInfo: [])),
            
            Meal(id: "4", 
                 name: "Pasta with Tomato Sauce", 
                 description: "Penne pasta with homemade tomato sauce and parmesan cheese", 
                 imageURL: "pasta", 
                 type: .dinner, 
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 580, protein: 18.0, carbs: 90.0, fat: 10.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"])),
            
            Meal(id: "5", 
                 name: "Fruit Salad", 
                 description: "Fresh seasonal fruits with a honey-lime dressing", 
                 imageURL: "fruit_salad", 
                 type: .snack, 
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 120, protein: 2.0, carbs: 28.0, fat: 0.5, allergens: [], dietaryInfo: ["Vegan", "Vegetarian"]))
        ]
        
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
        
        // Save sample data
        saveUsers(sampleUsers)
        saveMeals(sampleMeals)
        savePredictions(samplePredictions)
        
        // Set the first user as the current user
        self.currentUser = sampleUsers[0]
        self.predictions = samplePredictions
        refreshMealLists()
        updateLeaderboard()
    }
} 