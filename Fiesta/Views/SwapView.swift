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
                    // Empty state
                    if meals.isEmpty {
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
                        ForEach(meals.indices.reversed(), id: \.self) { index in
                            SwipeMealCardView(
                                meal: meals[index],
                                isTop: index == currentIndex,
                                swipeAction: swipeAction ?? .offer,
                                translation: index == currentIndex ? translation : .zero
                            )
                            .animation(.spring(), value: translation)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if index == currentIndex {
                                            translation = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        if index == currentIndex {
                                            handleSwipe(with: value, meal: meals[index])
                                        }
                                    }
                            )
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3)
                            .offset(y: index == currentIndex ? 0 : 20)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                            .opacity(index == currentIndex ? 1.0 : 0.7)
                            .zIndex(Double(meals.count - index))
                        }
                    }
                    
                    // Action buttons at the bottom
                    VStack {
                        Spacer()
                        
                        if !meals.isEmpty {
                            HStack(spacing: 30) {
                                Button(action: {
                                    if currentIndex < meals.count {
                                        swipeStatus = .disliked
                                        withAnimation {
                                            translation = CGSize(width: -500, height: 0)
                                        }
                                        handleReject(meals[currentIndex])
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 25))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.red))
                                }
                                
                                Button(action: {
                                    if currentIndex < meals.count {
                                        swipeStatus = .liked
                                        withAnimation {
                                            translation = CGSize(width: 500, height: 0)
                                        }
                                        
                                        currentMeal = meals[currentIndex]
                                        showingConfirmation = true
                                    }
                                }) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 25))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.green))
                                }
                            }
                            .padding(.bottom, 30)
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
                                    Task {
                                        if await dataController.offerMeal(meal) {
                                            handleSuccess()
                                        }
                                    }
                                } else {
                                    // Claim meal logic
                                    Task {
                                        if await dataController.claimMeal(meal) {
                                            showingClaimSuccess = true
                                        }
                                    }
                                }
                            }
                            nextCard()
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
    }
    
    private func loadMeals() {
        // Load appropriate meals based on the action type
        if swipeAction == .offer {
            // For offering, load user's available meals
            meals = dataController.availableMeals.filter {
                $0.status == .available && Calendar.current.isDateInToday($0.date)
            }
        } else {
            // For claiming, load meals offered by others
            meals = dataController.availableMeals.filter {
                $0.status == .offered && 
                $0.offeredBy != dataController.currentUser?.id && 
                ($0.offerExpiryTime == nil || $0.offerExpiryTime! > Date())
            }
            
            // Force reload from data source if no meals are found 
            // (in case the DataController cached values need refreshing)
            if meals.isEmpty {
                dataController.refreshData()
                meals = dataController.availableMeals.filter {
                    $0.status == .offered && 
                    $0.offeredBy != dataController.currentUser?.id && 
                    ($0.offerExpiryTime == nil || $0.offerExpiryTime! > Date())
                }
                
                // If still empty after refresh, display an informative message
                if meals.isEmpty {
                    print("No claimable meals found after data refresh")
                    
                    // For demo purposes, create some sample meals to claim if none exist
                    if swipeAction == .claim {
                        createSampleOfferedMeals()
                        meals = dataController.availableMeals.filter {
                            $0.status == .offered && 
                            $0.offeredBy != dataController.currentUser?.id && 
                            ($0.offerExpiryTime == nil || $0.offerExpiryTime! > Date())
                        }
                    }
                }
            }
        }
        
        print("Loaded \(meals.count) meals for \(swipeAction == .offer ? "offering" : "claiming")")
        currentIndex = 0
        translation = .zero
    }
    
    // For demo purposes only - creates sample meals that can be claimed
    private func createSampleOfferedMeals() {
        // Only create sample meals if we're in claim mode and no meals are available
        guard swipeAction == .claim && meals.isEmpty else { return }
        
        // Sample offered meals
        let sampleOfferedMeals: [Meal] = [
            Meal(id: "sample1", 
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
            
            Meal(id: "sample2", 
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
            
            Meal(id: "sample3", 
                 name: "Fruit Parfait", 
                 description: "Yogurt with fresh berries and granola", 
                 imageURL: "fruit_salad", 
                 type: .snack, 
                 status: .offered,
                 date: Date(), 
                 location: "Snack Corner",
                 nutritionInfo: NutritionInfo(calories: 250, protein: 10.0, carbs: 40.0, fat: 6.0, allergens: ["Dairy", "Nuts"], dietaryInfo: ["Vegetarian"]),
                 offeredBy: "2", // Offered by someone else
                 offerExpiryTime: Date().addingTimeInterval(1800)) // 30 minutes from now
        ]
        
        // Add these meals to the data controller
        for meal in sampleOfferedMeals {
            Task {
                await dataController.updateMeal(meal)
            }
        }
        
        // Create swap records for these meals
        for meal in sampleOfferedMeals {
            let swap = MealSwap(
                mealId: meal.id,
                offeredBy: meal.offeredBy!,
                expiresAt: meal.offerExpiryTime ?? Date().addingTimeInterval(3600)
            )
            Task {
                await dataController.saveMealSwap(swap)
            }
        }
        
        print("Created \(sampleOfferedMeals.count) sample meals for claiming")
    }
    
    private func handleSwipe(with gesture: DragGesture.Value, meal: Meal) {
        let threshold: CGFloat = 150
        
        // Determine if the swipe was strong enough for an action
        if gesture.translation.width > threshold {
            // Swipe right = like
            swipeStatus = .liked
            withAnimation {
                translation = CGSize(width: UIScreen.main.bounds.width, height: 0)
            }
            
            currentMeal = meal
            showingConfirmation = true
            
        } else if gesture.translation.width < -threshold {
            // Swipe left = dislike
            swipeStatus = .disliked
            withAnimation {
                translation = CGSize(width: -UIScreen.main.bounds.width, height: 0)
            }
            
            handleReject(meal)
            
        } else {
            // Not a strong enough swipe, return card to center
            withAnimation(.spring()) {
                translation = .zero
            }
        }
    }
    
    private func handleReject(_ meal: Meal) {
        // Just move to next card for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            nextCard()
        }
    }
    
    private func handleSuccess() {
        // Handle success animations or feedback
        // For now, just go to the next card
        nextCard()
    }
    
    private func nextCard() {
        if currentIndex < meals.count - 1 {
            currentIndex += 1
        } else {
            // No more meals
            withAnimation {
                meals = []
            }
        }
        
        // Reset for the next card
        withAnimation(.spring()) {
            translation = .zero
            swipeStatus = nil
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
                        .padding(.vertical, 5)
                    
                    HStack(spacing: 15) {
                        HStack {
                            Text("\(nutritionInfo.calories)")
                                .font(.footnote)
                                .fontWeight(.bold)
                            Text("cal")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("\(Int(nutritionInfo.protein))g")
                                .font(.footnote)
                                .fontWeight(.bold)
                            Text("protein")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let dietaryInfo = nutritionInfo.dietaryInfo, !dietaryInfo.isEmpty {
                            ForEach(dietaryInfo.prefix(1), id: \.self) { info in
                                Text(info)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let allergens = nutritionInfo.allergens, !allergens.isEmpty {
                            HStack {
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
        .frame(width: 320, height: 450)
        .rotationEffect(Angle(degrees: isTop ? rotation : 0))
        .offset(x: isTop ? translation.width : 0, y: isTop ? translation.height : 0)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func timeRemaining(_ expiryTime: Date) -> String {
        let remaining = expiryTime.timeIntervalSince(Date())
        
        if remaining <= 0 {
            return "Expired"
        }
        
        let minutes = Int(remaining / 60)
        if minutes < 60 {
            return "\(minutes)m left"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m left"
        }
    }
}

struct ClaimSuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataController: DataController
    var meal: Meal?
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("Meal Successfully Claimed!")
                .font(.title)
                .fontWeight(.bold)
            
            if let meal = meal {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Pickup Details")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(meal.location)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Pickup by \(formatClaimTime(meal.claimDeadlineTime))")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Environmental Impact
                VStack(alignment: .leading, spacing: 10) {
                    Text("Environmental Impact")
                        .font(.headline)
                    
                    Text("By claiming this meal, you've helped save:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Calculate environmental impact of one meal
                    let impact = EnvironmentalImpactCalculator.calculateTotalImpact(mealCount: 1)
                    
                    HStack(spacing: 20) {
                        EnvironmentalImpactItem(
                            icon: "leaf.fill",
                            value: EnvironmentalImpactCalculator.formatImpact(type: "co2", value: impact["co2"] ?? 0),
                            label: "CO₂ Emissions",
                            color: .green
                        )
                        
                        EnvironmentalImpactItem(
                            icon: "drop.fill",
                            value: EnvironmentalImpactCalculator.formatImpact(type: "water", value: impact["water"] ?? 0),
                            label: "Water",
                            color: .blue
                        )
                        
                        EnvironmentalImpactItem(
                            icon: "bolt.fill",
                            value: EnvironmentalImpactCalculator.formatImpact(type: "energy", value: impact["energy"] ?? 0),
                            label: "Energy",
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // QR Code for pickup verification
                Image(systemName: "qrcode")
                    .font(.system(size: 150))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                
                Text("Show this QR code at the pickup location")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("FiestaPrimary"))
                    .cornerRadius(15)
                    .shadow(color: Color("FiestaPrimary").opacity(0.4), radius: 5)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func formatClaimTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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