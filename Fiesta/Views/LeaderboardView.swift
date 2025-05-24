import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedPeriod = "Weekly"
    let periods = ["Weekly", "Monthly", "All Time"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // Period selector
                HStack {
                    ForEach(periods, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                        }) {
                            Text(period)
                                .font(.subheadline)
                                .fontWeight(selectedPeriod == period ? .bold : .regular)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    selectedPeriod == period ? 
                                        Color("FiestaPrimary") : 
                                        Color.gray.opacity(0.1)
                                )
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.top)
                
                // User's personal rank card
                if let currentUser = dataController.currentUser,
                   let rank = currentUser.leaderboardRank {
                    PersonalRankView(user: currentUser, rank: rank)
                        .padding(.vertical)
                }
                
                // Leaderboard list
                List {
                    // Top 3 Users with visual distinction
                    if dataController.leaderboard.count >= 1 {
                        TopRankView(user: dataController.leaderboard[0], rank: 1)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                    }
                    
                    if dataController.leaderboard.count >= 2 {
                        TopRankView(user: dataController.leaderboard[1], rank: 2)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                    }
                    
                    if dataController.leaderboard.count >= 3 {
                        TopRankView(user: dataController.leaderboard[2], rank: 3)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                    }
                    
                    // Remaining Users
                    ForEach(dataController.leaderboard.dropFirst(3)) { user in
                        UserRankRow(user: user)
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    dataController.updateLeaderboard()
                }
            }
            .navigationTitle("CQ Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Refresh leaderboard
                        dataController.updateLeaderboard()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

struct TopRankView: View {
    let user: User
    let rank: Int
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                // Profile image with badge
                ZStack {
                    Circle()
                        .fill(
                            rank == 1 ? Color.yellow :
                            rank == 2 ? Color.gray :
                            rank == 3 ? Color.brown :
                            Color("FiestaPrimary")
                        )
                        .frame(width: 90, height: 90)
                    
                    if let profileImageURL = user.profileImageURL {
                        Image(profileImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    // Crown for first place
                    if rank == 1 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                            .offset(y: -50)
                    }
                }
                
                // Rank badge
                ZStack {
                    Circle()
                        .fill(
                            rank == 1 ? Color.yellow :
                            rank == 2 ? Color.gray :
                            rank == 3 ? Color.brown :
                            Color("FiestaPrimary")
                        )
                        .frame(width: 30, height: 30)
                    
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .offset(x: 10, y: -5)
                .shadow(radius: 3)
            }
            
            Text(user.name)
                .font(.headline)
                .fontWeight(.bold)
            
            Text("\(Int(user.cqScore)) points")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Badges
            HStack(spacing: 10) {
                if user.mealsSaved >= 10 {
                    BadgeView(icon: "leaf.fill", color: .green)
                }
                
                if user.mealsSwapped >= 15 {
                    BadgeView(icon: "arrow.triangle.swap", color: .blue)
                }
                
                if user.mealsDistributed >= 5 {
                    BadgeView(icon: "hand.thumbsup.fill", color: .orange)
                }
            }
            .padding(.top, 5)
            
            // Stats
            HStack(spacing: 15) {
                StatView(title: "Saved", value: "\(user.mealsSaved)")
                StatView(title: "Swapped", value: "\(user.mealsSwapped)")
                StatView(title: "Distributed", value: "\(user.mealsDistributed)")
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: 
                        rank == 1 ? Color.yellow.opacity(0.3) :
                        rank == 2 ? Color.gray.opacity(0.3) :
                        rank == 3 ? Color.brown.opacity(0.3) :
                        Color.black.opacity(0.3), 
                       radius: 10)
        )
        .padding(.horizontal)
    }
}

struct UserRankRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank number
            Text("#\(user.leaderboardRank ?? 0)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame(width: 35)
            
            // Profile image
            if let profileImageURL = user.profileImageURL {
                Image(profileImageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 45, height: 45)
                    .background(Color.blue.opacity(0.7))
                    .clipShape(Circle())
            }
            
            // User info
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                
                Text("\(Int(user.cqScore)) CQ points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Badges (simplified for row view)
            HStack(spacing: 8) {
                if user.mealsSaved >= 10 {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                        .padding(5)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if user.mealsSwapped >= 15 {
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                        .padding(5)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct PersonalRankView: View {
    let user: User
    let rank: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile image
            if let profileImageURL = user.profileImageURL {
                Image(profileImageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading) {
                Text("Your Rank")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("#\(rank)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("CQ Score")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(user.cqScore))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FiestaPrimary"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

struct BadgeView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .font(.system(size: 14))
            .padding(6)
            .background(color.opacity(0.1))
            .clipShape(Circle())
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(DataController())
} 