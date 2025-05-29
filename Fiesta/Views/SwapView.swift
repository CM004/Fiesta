import SwiftUI

// Import utilities
import Foundation

struct SwapView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataController: DataController
    @State private var currentIndex = 0
    @State private var translation: CGSize = .zero
    @State private var swipeStatus: SwipeStatus? = nil
    @State private var showingConfirmation = false
    @State private var currentMeal: Meal?
    @State private var swipeAction: SwipeAction?
    @State private var meals: [Meal] = []
    @State private var showingClaimSuccess = false
    @State private var offerSuccess = false
    @State private var loadingMeals = false
    
    enum SwipeStatus {
        case liked
        case disliked
    }
    
    enum SwipeAction {
        case offer
        case claim
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Top section showing whether we're in offer or claim mode
                HStack {
                    Button(action: {
                        swipeAction = .offer
                        loadMeals()
                    }) {
                        Text("Offer Meal")
                            .fontWeight(swipeAction == .offer ? .bold : .medium)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(swipeAction == .offer ? Color("FiestaPrimary") : Color.gray.opacity(0.1))
                            .foregroundColor(swipeAction == .offer ? .white : .primary)
                            .cornerRadius(20)
                    }
                    
                    Button(action: {
                        swipeAction = .claim
                        loadMeals()
                    }) {
                        Text("Claim Meal")
                            .fontWeight(swipeAction == .claim ? .bold : .medium)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(swipeAction == .claim ? Color("FiestaPrimary") : Color.gray.opacity(0.1))
                            .foregroundColor(swipeAction == .claim ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
                .padding()
                
                ZStack {
                    // Loading state
                    if loadingMeals {
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Loading meals...")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    // Empty state
                    else if meals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 70))
                                .foregroundColor(Color.gray)
                            
                            Text("No meals available to \(swipeAction == .offer ? "offer" : "claim")")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Refresh
                                loadMeals()
                            }) {
                                Text("Refresh")
                                    .fontWeight(.medium)
                                    .padding()
                                    .background(Color("FiestaPrimary"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                        .padding()
                    } else {
                        // Stack of meal cards
                        GeometryReader { geometry in
                            ZStack {
                                ForEach(meals.indices.reversed(), id: \.self) { index in
                                    let isTop = index == currentIndex
                                    let opacity = getCardOpacity(for: index, currentIndex: currentIndex, total: meals.count)
                                    let scale = getCardScale(for: index, currentIndex: currentIndex)
                                    let yOffset = getCardOffset(for: index, currentIndex: currentIndex)
                                    
                                    SwipeMealCardView(
                                        meal: meals[index],
                                        isTop: isTop,
                                        swipeAction: swipeAction ?? .offer,
                                        translation: isTop ? translation : .zero
                                    )
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: translation)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if isTop {
                                                    translation = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if isTop {
                                                    handleSwipe(with: value, meal: meals[index])
                                                }
                                            }
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .scaleEffect(scale)
                                    .offset(y: yOffset)
                                    .opacity(opacity)
                                    .zIndex(Double(meals.count - index))
                                    .accessibility(hidden: !isTop)
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .frame(height: 500)
                        .padding(.horizontal)
                    }
                    
                    // Action buttons at the bottom
                    VStack {
                        Spacer()
                        
                        if !meals.isEmpty && !loadingMeals {
                            HStack(spacing: 40) {
                                Button(action: {
                                    if currentIndex < meals.count {
                                        swipeStatus = .disliked
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            translation = CGSize(width: -500, height: 0)
                                        }
                                        handleReject(meals[currentIndex])
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .padding(20)
                                        .background(Circle().fill(Color.red))
                                        .shadow(radius: 5)
                                }
                                
                                Button(action: {
                                    if currentIndex < meals.count {
                                        swipeStatus = .liked
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            translation = CGSize(width: 500, height: 0)
                                        }
                                        
                                        currentMeal = meals[currentIndex]
                                        showingConfirmation = true
                                    }
                                }) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .padding(20)
                                        .background(Circle().fill(Color.green))
                                        .shadow(radius: 5)
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .alert(isPresented: $showingConfirmation) {
                    Alert(
                        title: Text(swipeAction == .offer ? "Offer Meal" : "Claim Meal"),
                        message: Text("Are you sure you want to \(swipeAction == .offer ? "offer" : "claim") this meal?"),
                        primaryButton: .default(Text("Yes")) {
                            if let meal = currentMeal {
                                if swipeAction == .offer {
                                    // Offer meal logic
                                    if dataController.offerMeal(meal) {
                                        offerSuccess = true
                                        
                                        // Remove the card and move to next one
                                        if currentIndex < meals.count {
                                            meals.remove(at: currentIndex)
                                            
                                            // If no more meals, reload with sample data
                                            if meals.isEmpty {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    createSampleAvailableMeals()
                                                    loadMeals()
                                                }
                                            } else {
                                                // Reset animation state for next card
                                                withAnimation(.spring()) {
                                                    translation = .zero
                                                    swipeStatus = nil
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    // Claim meal logic
                                    if dataController.claimMeal(meal) {
                                        // First remove the card from display
                                        if currentIndex < meals.count {
                                            meals.remove(at: currentIndex)
                                            
                                            // Reset for the next card if any
                                            if !meals.isEmpty {
                                                withAnimation(.spring()) {
                                                    translation = .zero
                                                    swipeStatus = nil
                                                }
                                            }
                                        }
                                        
                                        // Then show the claim success view after the card is gone
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            showingClaimSuccess = true
                                            
                                            // If no more meals, reload with sample data after claim view dismisses
                                            if meals.isEmpty {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    createSampleOfferedMeals()
                                                    loadMeals()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel {
                            // Reset the card position
                            withAnimation(.spring()) {
                                translation = .zero
                            }
                            swipeStatus = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showingClaimSuccess) {
                ClaimSuccessView(meal: currentMeal)
                    .environmentObject(dataController)
            }
            .navigationTitle(swipeAction == .offer ? "Swap My Meal" : "Claim a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadMeals()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            // Default to offer mode
            if swipeAction == nil {
                swipeAction = .offer
            }
            loadMeals()
        }
        .alert("Meal Offered!", isPresented: $offerSuccess) {
            Button("OK") {
                // This will auto-dismiss the alert
            }
        } message: {
            Text("Your meal has been offered successfully. Users nearby will now be able to claim it.")
        }
    }
    
    // Card stacking effect helpers
    private func getCardScale(for index: Int, currentIndex: Int) -> CGFloat {
        let difference = index - currentIndex
        if difference <= 0 {
            return 1.0
        } else if difference == 1 {
            return 0.95
        } else if difference == 2 {
            return 0.9
        } else {
            return 0.85
        }
    }
    
    private func getCardOffset(for index: Int, currentIndex: Int) -> CGFloat {
        let difference = index - currentIndex
        if difference <= 0 {
            return 0
        } else {
            // Each card below the top one moves down a bit
            return CGFloat(difference) * 10
        }
    }
    
    private func getCardOpacity(for index: Int, currentIndex: Int, total: Int) -> Double {
        let difference = index - currentIndex
        if difference <= 0 {
            return 1.0
        } else if difference == 1 {
            return 0.8
        } else if difference == 2 {
            return 0.6
        } else {
            return 0.4
        }
    }
    
    private func loadMeals() {
        loadingMeals = true
        
        // Force a data refresh before loading meals
        dataController.refreshData()
        
        // Create a slight delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Load appropriate meals based on the action type
            if swipeAction == .offer {
                // For offering, load user's available meals
                meals = dataController.availableMeals.filter {
                    $0.status == .available && Calendar.current.isDateInToday($0.date)
                }
                
                // If no meals to offer, create some sample ones
                if meals.isEmpty {
                    self.createSampleAvailableMeals()
                    meals = dataController.availableMeals.filter {
                        $0.status == .available && Calendar.current.isDateInToday($0.date)
                    }
                }
            } else {
                // For claiming, load meals offered by others
                meals = dataController.availableMeals.filter {
                    $0.status == .offered && 
                    $0.offeredBy != dataController.currentUser?.id && 
                    ($0.offerExpiryTime == nil || $0.offerExpiryTime! > Date())
                }
                
                // Always create sample offered meals for the claim view to ensure it's not empty
                self.createSampleOfferedMeals()
                
                // Reload after creating samples
                meals = dataController.availableMeals.filter {
                    $0.status == .offered && 
                    $0.offeredBy != dataController.currentUser?.id && 
                    ($0.offerExpiryTime == nil || $0.offerExpiryTime! > Date())
                }
                
                print("Loaded \(meals.count) meals for claiming")
            }
            
            print("Loaded \(meals.count) meals for \(swipeAction == .offer ? "offering" : "claiming")")
            currentIndex = 0
            translation = .zero
            loadingMeals = false
        }
    }
    
    // For demo purposes - creates sample meals that are available to offer
    private func createSampleAvailableMeals() {
        // Create some sample meals the user can offer
        let sampleAvailableMeals: [Meal] = [
            Meal(id: "sample-available1", 
                 name: "Chicken Sandwich", 
                 description: "Grilled chicken breast with lettuce, tomato and mayo in a whole wheat bun", 
                 imageURL: "chicken_sandwich", 
                 type: .lunch, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 420, protein: 28.0, carbs: 45.0, fat: 12.0, allergens: ["Gluten"], dietaryInfo: [])),
                 
            Meal(id: "sample-available2", 
                 name: "Fruit Salad", 
                 description: "Fresh seasonal fruits with a honey-lime dressing", 
                 imageURL: "fruit_salad", 
                 type: .snack, 
                 status: .available,
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 120, protein: 2.0, carbs: 28.0, fat: 0.5, allergens: [], dietaryInfo: ["Vegan", "Vegetarian"])),
                 
            // New meal with placeholder image
            Meal(id: "sample-available3", 
                 name: "Spinach Quiche", 
                 description: "Savory spinach and cheese quiche with flaky crust", 
                 imageURL: "vegetable_soup", // Placeholder asset
                 type: .lunch, 
                 status: .available,
                 date: Date(), 
                 location: "Faculty Lounge",
                 nutritionInfo: NutritionInfo(calories: 380, protein: 15.0, carbs: 22.0, fat: 28.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"])),
                 
            // Another new meal with placeholder image
            Meal(id: "sample-available4", 
                 name: "Quinoa Bowl", 
                 description: "Protein-packed quinoa with roasted vegetables and tahini", 
                 imageURL: "curry_rice", // Placeholder asset
                 type: .dinner, 
                 status: .available,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 340, protein: 12.0, carbs: 58.0, fat: 9.0, allergens: ["Sesame"], dietaryInfo: ["Vegan", "Vegetarian", "Gluten-Free"]))
        ]
        
        // Add these meals to the data controller
        for meal in sampleAvailableMeals {
            dataController.updateMeal(meal)
        }
        
        print("Created \(sampleAvailableMeals.count) sample meals for offering")
    }
    
    // For demo purposes only - creates sample meals that can be claimed
    private func createSampleOfferedMeals() {
        // Sample offered meals - always create these for demo purposes
        let sampleOfferedMeals: [Meal] = [
            Meal(id: "sample-offered1", 
                 name: "Chicken Caesar Wrap", 
                 description: "Fresh romaine lettuce with grilled chicken in a whole wheat wrap", 
                 imageURL: "caesar_salad", 
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "East Wing Cafe",
                 nutritionInfo: NutritionInfo(calories: 380, protein: 25.0, carbs: 35.0, fat: 12.0, allergens: ["Gluten", "Dairy"], dietaryInfo: []),
                 offeredBy: "2", // Offered by someone else
                 offerExpiryTime: Date().addingTimeInterval(3600)), // 1 hour from now
            
            Meal(id: "sample-offered2", 
                 name: "Vegetable Stir Fry", 
                 description: "Mixed vegetables stir-fried with tofu and teriyaki sauce", 
                 imageURL: "vegetable_soup", 
                 type: .dinner, 
                 status: .offered,
                 date: Date(), 
                 location: "Main Cafeteria",
                 nutritionInfo: NutritionInfo(calories: 320, protein: 15.0, carbs: 45.0, fat: 8.0, allergens: ["Soy"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by someone else
                 offerExpiryTime: Date().addingTimeInterval(2700)), // 45 minutes from now
            
            Meal(id: "sample-offered3", 
                 name: "Fruit Parfait", 
                 description: "Yogurt with fresh berries and granola", 
                 imageURL: "fruit_salad", 
                 type: .snack, 
                 status: .offered,
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 250, protein: 10.0, carbs: 40.0, fat: 6.0, allergens: ["Dairy", "Nuts"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by someone else
                 offerExpiryTime: Date().addingTimeInterval(1800)), // 30 minutes from now
                 
            // Adding more meals for claiming
            Meal(id: "sample-offered4", 
                 name: "Margherita Pizza", 
                 description: "Classic pizza with tomato sauce, fresh mozzarella, and basil", 
                 imageURL: "pasta", // Using pasta as placeholder
                 type: .lunch, 
                 status: .offered,
                 date: Date(), 
                 location: "Pizza Station",
                 nutritionInfo: NutritionInfo(calories: 450, protein: 18.0, carbs: 55.0, fat: 15.0, allergens: ["Gluten", "Dairy"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "3", 
                 offerExpiryTime: Date().addingTimeInterval(3300)),
                 
            Meal(id: "sample-offered5", 
                 name: "Teriyaki Bowl", 
                 description: "Rice bowl with teriyaki sauce, vegetables, and your choice of protein", 
                 imageURL: "curry_rice", 
                 type: .dinner, 
                 status: .offered,
                 date: Date(), 
                 location: "Asian Fusion Counter",
                 nutritionInfo: NutritionInfo(calories: 520, protein: 22.0, carbs: 65.0, fat: 12.0, allergens: ["Soy", "Gluten"], dietaryInfo: []),
                 offeredBy: "3", 
                 offerExpiryTime: Date().addingTimeInterval(4500))
        ]
        
        // Add these meals to the data controller
        for meal in sampleOfferedMeals {
            dataController.updateMeal(meal)
        }
        
        // Create swap records for these meals
        for meal in sampleOfferedMeals {
            let swap = MealSwap(
                mealId: meal.id,
                offeredBy: meal.offeredBy!,
                expiresAt: meal.offerExpiryTime ?? Date().addingTimeInterval(3600)
            )
            dataController.saveMealSwap(swap)
        }
        
        print("Created \(sampleOfferedMeals.count) sample meals for claiming")
    }
    
    private func handleSwipe(with gesture: DragGesture.Value, meal: Meal) {
        let threshold: CGFloat = 150
        
        // Determine if the swipe was strong enough for an action
        if gesture.translation.width > threshold {
            // Swipe right = like
            swipeStatus = .liked
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = CGSize(width: UIScreen.main.bounds.width, height: 0)
            }
            
            currentMeal = meal
            showingConfirmation = true
            
        } else if gesture.translation.width < -threshold {
            // Swipe left = dislike
            swipeStatus = .disliked
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = CGSize(width: -UIScreen.main.bounds.width, height: 0)
            }
            
            handleReject(meal)
            
        } else {
            // Not a strong enough swipe, return card to center
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = .zero
            }
        }
    }
    
    private func handleReject(_ meal: Meal) {
        // Animate card off screen first
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            translation = CGSize(width: -UIScreen.main.bounds.width, height: 0)
        }
        
        // After animation completes, remove the card and reset for next one
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentIndex < meals.count {
                // Move to next card instead of removing current one
                currentIndex += 1
                
                // If we've gone through all cards, reset the meals
                if currentIndex >= meals.count {
                    // Reset the meals list after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if swipeAction == .offer {
                            self.createSampleAvailableMeals()
                        } else {
                            self.createSampleOfferedMeals()
                        }
                        self.loadMeals()
                    }
                } else {
                    // Reset translation for the next card
                    withAnimation(.spring()) {
                        translation = .zero
                        swipeStatus = nil
                    }
                }
            }
        }
    }
    
    private func handleSuccess() {
        // No need to call nextCard() as we've already removed the card
        // Just make sure all animations and transitions are complete
    }
    
    private func nextCard() {
        if currentIndex < meals.count - 1 {
            currentIndex += 1
            // Reset for the next card
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                translation = .zero
                swipeStatus = nil
            }
        } else {
            // No more meals
            withAnimation {
                meals = []
            }
            
            // Reload meals after a short delay to avoid empty state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if swipeAction == .offer {
                    self.createSampleAvailableMeals()
                } else {
                    self.createSampleOfferedMeals()
                }
                self.loadMeals()
            }
        }
    }
}

struct SwipeMealCardView: View {
    let meal: Meal
    let isTop: Bool
    let swipeAction: SwapView.SwipeAction
    let translation: CGSize
    
    var body: some View {
        let dragAmount = Double(translation.width)
        let rotation = min(max(-10, dragAmount / 15), 10)
        let isRight = translation.width > 0
        let opacity = min(1, abs(translation.width) / 100)
        
        VStack(alignment: .leading) {
            ZStack(alignment: .topLeading) {
                if let imageURL = meal.imageURL {
                    Image(imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
                
                // Action indicator overlay
                if isTop && abs(translation.width) > 50 {
                    HStack {
                        if !isRight {
                            Text("NOPE")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                                .rotationEffect(Angle(degrees: -15))
                                .opacity(opacity)
                        }
                        
                        if isRight {
                            Spacer()
                            
                            Text(swipeAction == .offer ? "OFFER" : "CLAIM")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(10)
                                .rotationEffect(Angle(degrees: 15))
                                .opacity(opacity)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(meal.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(meal.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    Text(meal.location)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    
                    // Format time
                    Text(formatTime(meal.date))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                if let nutritionInfo = meal.nutritionInfo {
                    Divider()
                    
                    HStack {
                        NutritionBadge(value: "\(nutritionInfo.calories)", unit: "cal")
                        
                        NutritionBadge(value: "\(Int(nutritionInfo.protein))g", unit: "protein")
                        
                        NutritionBadge(value: "\(Int(nutritionInfo.carbs))g", unit: "carbs")
                        
                        NutritionBadge(value: "\(Int(nutritionInfo.fat))g", unit: "fat")
                        
                        Spacer()
                        
                        if let allergens = nutritionInfo.allergens, !allergens.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("\(allergens.count)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                if swipeAction == .claim {
                    HStack {
                        Spacer()
                        
                        // Time remaining indicator for claiming
                        if let expiryTime = meal.offerExpiryTime {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text(timeRemaining(expiryTime))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .rotationEffect(Angle(degrees: isTop ? rotation : 0))
        .offset(x: isTop ? translation.width : 0, y: isTop ? translation.height : 0)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeRemaining(_ expiryTime: Date) -> String {
        let remaining = Int(expiryTime.timeIntervalSince(Date()) / 60)
        
        if remaining <= 0 {
            return "Expired"
        } else if remaining == 1 {
            return "1 min left"
        } else if remaining < 60 {
            return "\(remaining) mins left"
        } else {
            let hours = remaining / 60
            let mins = remaining % 60
            if mins == 0 {
                return "\(hours)h left"
            } else {
                return "\(hours)h \(mins)m left"
            }
        }
    }
}

struct NutritionBadge: View {
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

struct EnvironmentalImpactItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SwapView()
        .environmentObject(DataController())
} 