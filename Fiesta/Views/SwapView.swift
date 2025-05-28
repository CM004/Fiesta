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
    @State private var swipeAction: SwipeAction = .offer
    @State private var meals: [Meal] = []
    @State private var showingClaimSuccess = false
    @State private var offerSuccess = false
    @State private var loadingMeals = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
            VStack(spacing: 0) {
                // Mode Selection
                HStack(spacing: 15) {
                    ModeButton(
                        title: "Offer Meal",
                        icon: "arrow.up.circle.fill",
                        isSelected: swipeAction == .offer,
                        action: {
                            withAnimation(.spring()) {
                                swipeAction = .offer
                                loadMeals()
                            }
                        }
                    )
                    
                    ModeButton(
                        title: "Claim Meal",
                        icon: "arrow.down.circle.fill",
                        isSelected: swipeAction == .claim,
                        action: {
                            withAnimation(.spring()) {
                                swipeAction = .claim
                                loadMeals()
                            }
                        }
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                
                // Main Content
                ZStack {
                    if loadingMeals {
                        LoadingView()
                    } else if meals.isEmpty {
                        EmptyStateView(
                            icon: swipeAction == .offer ? "arrow.up.circle" : "arrow.down.circle",
                            title: "No Meals Available",
                            message: swipeAction == .offer ? 
                                "There are no meals available to offer right now" :
                                "There are no meals available to claim right now"
                        )
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
                                        swipeAction: swipeAction,
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
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .frame(height: 500)
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack {
                            Spacer()
                            
                            if !meals.isEmpty {
                                HStack(spacing: 40) {
                                    ActionButton(
                                        icon: "xmark",
                                        color: .red,
                                        action: {
                                            if currentIndex < meals.count {
                                                withAnimation(.spring()) {
                                                    swipeStatus = .disliked
                                                    translation = CGSize(width: -500, height: 0)
                                                }
                                                handleReject(meals[currentIndex])
                                            }
                                        }
                                    )
                                    
                                    ActionButton(
                                        icon: "checkmark",
                                        color: .green,
                                        action: {
                                            if currentIndex < meals.count {
                                                withAnimation(.spring()) {
                                                    swipeStatus = .liked
                                                    translation = CGSize(width: 500, height: 0)
                                                }
                                                currentMeal = meals[currentIndex]
                                                showingConfirmation = true
                                            }
                                        }
                                    )
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(swipeAction == .offer ? "Offer a Meal" : "Claim a Meal")
                        .font(.headline)
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text(swipeAction == .offer ? "Offer Meal" : "Claim Meal"),
                    message: Text("Are you sure you want to \(swipeAction == .offer ? "offer" : "claim") this meal?"),
                    primaryButton: .default(Text("Yes")) {
                        if let meal = currentMeal {
                            handleAction(meal)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingClaimSuccess) {
                ClaimSuccessView(meal: currentMeal)
            }
            .onAppear {
                loadMeals()
            }
        }
    }
    
    private func loadMeals() {
        loadingMeals = true
        if swipeAction == .offer {
            // Meals available to offer: status == .available, today, and owned by current user (if needed)
            meals = dataController.availableMeals.filter { meal in
                Calendar.current.isDateInToday(meal.date)
                // Optionally, filter by current user if needed
            }
        } else {
            // Meals available to claim: status == .offered, not by current user, not expired
            let now = Date()
            meals = dataController.availableMeals.filter { meal in
                meal.status == .offered && meal.offeredBy != dataController.currentUser?.id && (meal.offerExpiryTime == nil || meal.offerExpiryTime! > now)
            }
        }
        currentIndex = 0
        translation = .zero
        loadingMeals = false
    }
    
    private func handleSwipe(with value: DragGesture.Value, meal: Meal) {
        let threshold: CGFloat = 100
        let horizontalAmount = value.translation.width
        
        withAnimation(.spring()) {
            if abs(horizontalAmount) > threshold {
                if horizontalAmount > 0 {
                    swipeStatus = .liked
                    translation = CGSize(width: 500, height: 0)
                    currentMeal = meal
                    showingConfirmation = true
                } else {
                    swipeStatus = .disliked
                    translation = CGSize(width: -500, height: 0)
                    handleReject(meal)
                }
            } else {
                translation = .zero
            }
        }
    }
    
    private func handleAction(_ meal: Meal) {
        let success: Bool
        if swipeAction == .offer {
            success = dataController.offerMeal(meal)
            if success {
                offerSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    moveToNextCard()
                }
            } else {
                showError("Failed to offer meal. Please try again.")
            }
        } else {
            success = dataController.claimMeal(meal)
            if success {
                showingClaimSuccess = true
            } else {
                showError("Failed to claim meal. It may have been claimed by someone else.")
            }
        }
    }
    
    private func handleReject(_ meal: Meal) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNextCard()
        }
    }
    
    private func moveToNextCard() {
        if currentIndex < meals.count - 1 {
            currentIndex += 1
            translation = .zero
        } else {
            // No more cards, reload
            loadMeals()
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        translation = .zero
    }
    
    // Helper functions for card animations
    private func getCardOpacity(for index: Int, currentIndex: Int, total: Int) -> Double {
        let distance = abs(index - currentIndex)
        return 1.0 - Double(distance) * 0.2
    }
    
    private func getCardScale(for index: Int, currentIndex: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        return 1.0 - CGFloat(distance) * 0.05
    }
    
    private func getCardOffset(for index: Int, currentIndex: Int) -> CGFloat {
        let distance = index - currentIndex
        return CGFloat(distance) * 10
    }
}

// MARK: - Supporting Views

struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color("FiestaPrimary") : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
                )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color("FiestaPrimary"))
            
            Text("Loading meals...")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

struct SwipeMealCardView: View {
    let meal: Meal
    let isTop: Bool
    let swipeAction: SwapView.SwipeAction
    let translation: CGSize
    
    private var swipePercentage: Double {
        let threshold: CGFloat = 100
        let percentage = Double(abs(translation.width) / threshold)
        return min(percentage, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Meal Image
            if let imageURL = meal.imageURL {
                Image(imageURL)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    )
            }
            
            // Meal Info
            VStack(alignment: .leading, spacing: 12) {
                Text(meal.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(meal.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Label(meal.location, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Label(formatTime(meal.date), systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .overlay(
            ZStack {
                // Like overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.3))
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                    )
                    .opacity(translation.width > 0 ? swipePercentage : 0)
                
                // Dislike overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.red)
                    )
                    .opacity(translation.width < 0 ? swipePercentage : 0)
            }
        )
        .rotationEffect(.degrees(Double(translation.width / 20)))
        .offset(x: translation.width, y: translation.height)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct OfferSuccessOverlay: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Dark semi-transparent background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            // Success card
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                    .padding(.top, 10)
                
                // Title with high contrast
                Text("Meal Offered!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                // Message with high contrast
                Text("Your meal has been offered successfully")
                    .font(.headline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Divider()
                    .padding(.horizontal, 30)
                
                // Information text
                Text("Users nearby will now be able to claim it")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Action button
                Button(action: {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }) {
                    Text("OK")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(.vertical, 14)
                        .background(Color("FiestaPrimary"))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 30)
        }
        .transition(.opacity)
        .onAppear {
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
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
