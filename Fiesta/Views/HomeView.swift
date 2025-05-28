import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var showingSwapView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Meal Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Meals")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let todayMeal = dataController.availableMeals.first(where: {
                            Calendar.current.isDateInToday($0.date)
                        }) {
                            MealCardView(meal: todayMeal)
                        } else {
                            Text("No meals available for today")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 15) {
                            StatsCardView(
                                title: "Meals Saved",
                                value: "\(dataController.currentUser?.mealsSaved ?? 0)",
                                icon: "leaf.fill",
                                color: .green
                            )
                            
                            StatsCardView(
                                title: "CQ Score",
                                value: "\(Int(dataController.currentUser?.cqScore ?? 0))",
                                icon: "brain.fill",
                                color: .blue
                            )
                            
                            if let rank = dataController.currentUser?.leaderboardRank {
                                StatsCardView(
                                    title: "Rank",
                                    value: "#\(rank)",
                                    icon: "trophy.fill",
                                    color: .orange
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Call-to-Action Button
                    Button(action: {
                        showingSwapView = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.title)
                            
                            Text("Swap My Meal")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FiestaPrimary"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Meals Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Meals")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(dataController.availableMeals.filter {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            return $0.date > Date() && Calendar.current.isDate($0.date, inSameDayAs: tomorrow)
                        }) { meal in
                            MealCardView(meal: meal, isCompact: true)
                        }
                        
                        if !dataController.availableMeals.contains(where: { 
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            return $0.date > Date() && Calendar.current.isDate($0.date, inSameDayAs: tomorrow)
                        }) {
                            Text("No upcoming meals")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Swapped/Claimed Meals Section
                    if !dataController.claimedMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Claimed Meals")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(dataController.claimedMeals) { meal in
                                ClaimedMealView(meal: meal)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Fiesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Refresh data action
                        dataController.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSwapView) {
                SwapView()
                    .environmentObject(dataController)
            }
        }
        .onAppear {
            // Refresh data when view appears
            dataController.refreshData()
        }
    }
}

struct MealCardView: View {
    let meal: Meal
    var isCompact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if !isCompact {
                if let imageURL = meal.imageURL {
                    Image(imageURL)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 50))
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(meal.name)
                        .font(isCompact ? .headline : .title3)
                        .fontWeight(.bold)
                    
                    if !isCompact {
                        Text(meal.description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
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
                        Text(formatMealTime(meal.date))
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
                
                if isCompact {
                    Spacer()
                    
                    if let imageURL = meal.imageURL {
                        Image(imageURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 30))
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            
            if let nutritionInfo = meal.nutritionInfo, !isCompact {
                Divider()
                    .padding(.vertical, 5)
                
                HStack(spacing: 15) {
                    VStack {
                        Text("\(nutritionInfo.calories)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text("\(Int(nutritionInfo.protein))g")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Protein")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Text("\(Int(nutritionInfo.carbs))g")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Carbs")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let allergens = nutritionInfo.allergens, !allergens.isEmpty {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Allergens")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    private func formatMealTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct StatsCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct ClaimedMealView: View {
    let meal: Meal
    @State private var showingClaimDetails = false
    
    var body: some View {
        HStack {
            if let imageURL = meal.imageURL {
                Image(imageURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 25))
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading) {
                Text(meal.name)
                    .font(.headline)
                
                Text(meal.location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .font(.footnote)
                    Text("\(timeUntilPickup(meal)) remaining")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingClaimDetails = true
            }) {
                Text("View")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("FiestaPrimary"))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .sheet(isPresented: $showingClaimDetails) {
            ClaimDetailsView(meal: meal)
        }
    }
    
    private func timeUntilPickup(_ meal: Meal) -> String {
        guard let deadline = meal.claimDeadlineTime else {
            return "Unknown"
        }
        
        let remaining = deadline.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Expired"
        }
        
        let minutes = Int(remaining / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

struct ClaimDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    let meal: Meal
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with image
                if let imageURL = meal.imageURL {
                    Image(imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(12)
                }
                
                // Meal name and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(meal.description)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Pickup details
                    Text("Pickup Details")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(meal.location)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 2)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Pickup by \(formatPickupTime(meal.claimDeadlineTime))")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // QR Code for pickup
                    VStack(alignment: .center, spacing: 12) {
                        Text("Show this code when collecting your meal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Image(systemName: "qrcode")
                            .font(.system(size: 150))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                .padding(.horizontal)
                
                // Done button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FiestaPrimary"))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Claimed Meal")
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
        }
    }
    
    private func formatPickupTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataController())
} 