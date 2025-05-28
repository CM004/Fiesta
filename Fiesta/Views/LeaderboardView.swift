import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedPeriod = "Weekly"
    @State private var isRefreshing = false
    let periods = ["Weekly", "Monthly", "All Time"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period selector
                VStack(spacing: 0) {
                    HStack {
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(periods, id: \.self) { period in
                                Text(period).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                }
                
                // User's personal rank card
                if let currentUser = dataController.currentUser,
                   let rank = currentUser.leaderboardRank {
                    PersonalRankView(user: currentUser, rank: rank)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                
                // Top 3 Podium
                if dataController.leaderboard.count >= 3 {
                    PodiumView(
                        firstPlace: dataController.leaderboard[0],
                        secondPlace: dataController.leaderboard[1],
                        thirdPlace: dataController.leaderboard[2]
                    )
                    .padding(.bottom, 12)
                    .background(Color(.systemBackground))
                }
                
                // Leaderboard title
                HStack {
                    Text("Leaderboard")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
                
                // Leaderboard list
                List {
                    // Remaining Users (starting from 4th place)
                    ForEach(dataController.leaderboard.dropFirst(3)) { user in
                        UserRankRow(user: user)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await refreshLeaderboard()
                }
                .overlay(
                    Group {
                        if dataController.leaderboard.isEmpty {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                Text("Loading leaderboard...")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
            }
            .navigationTitle("CQ Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshLeaderboard()
                        }
                    }) {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .onAppear {
                dataController.updateLeaderboard()
            }
        }
    }
    
    private func refreshLeaderboard() async {
        isRefreshing = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update leaderboard
        dataController.updateLeaderboard()
        
        isRefreshing = false
    }
}

struct PodiumView: View {
    let firstPlace: User
    let secondPlace: User
    let thirdPlace: User
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Second place (left)
            VStack(spacing: 4) {
                ProfileImage(user: secondPlace, size: 70)
                    .overlay(
                        RankBadge(rank: 2)
                            .offset(x: 20, y: -10)
                    )
                
                Text(secondPlace.name.split(separator: " ").first ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(secondPlace.cqScore))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FiestaPrimary"))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 80, height: 60)
                    .cornerRadius(5, corners: [.topLeft, .topRight])
                    .overlay(
                        Text("2")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 100)
            .offset(y: 20)
            
            // First place (center)
            VStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .padding(.bottom, -5)
                
                ProfileImage(user: firstPlace, size: 80)
                    .overlay(
                        RankBadge(rank: 1)
                            .offset(x: 25, y: -10)
                    )
                
                Text(firstPlace.name.split(separator: " ").first ?? "")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text("\(Int(firstPlace.cqScore))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FiestaPrimary"))
                
                Rectangle()
                    .fill(Color.yellow.opacity(0.7))
                    .frame(width: 100, height: 80)
                    .cornerRadius(5, corners: [.topLeft, .topRight])
                    .overlay(
                        Text("1")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 120)
            
            // Third place (right)
            VStack(spacing: 4) {
                ProfileImage(user: thirdPlace, size: 70)
                    .overlay(
                        RankBadge(rank: 3)
                            .offset(x: 20, y: -10)
                    )
                
                Text(thirdPlace.name.split(separator: " ").first ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(thirdPlace.cqScore))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FiestaPrimary"))
                
                Rectangle()
                    .fill(Color.brown.opacity(0.7))
                    .frame(width: 80, height: 40)
                    .cornerRadius(5, corners: [.topLeft, .topRight])
                    .overlay(
                        Text("3")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 100)
            .offset(y: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

struct ProfileImage: View {
    let user: User
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let profileImageURL = user.profileImageURL {
                Image(profileImageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size/2.5))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(Color.blue.opacity(0.7))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
    }
}

struct RankBadge: View {
    let rank: Int
    
    var backgroundColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return Color("FiestaPrimary")
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 26, height: 26)
                .shadow(radius: 2)
            
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct PersonalRankView: View {
    let user: User
    let rank: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile image
            ProfileImage(user: user, size: 60)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Ranking")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("#\(rank)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    
                    Text("of \(user.leaderboardRank != nil ? "\(user.leaderboardRank!)" : "--")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("CQ Score")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(user.cqScore))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color("FiestaPrimary"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct UserRankRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank number
            Text("#\(user.leaderboardRank ?? 0)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(width: 40, alignment: .center)
                .foregroundColor(.gray)
            
            // Profile image
            ProfileImage(user: user, size: 45)
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Mini stats
                    StatIcon(count: user.mealsSaved, icon: "leaf.fill", color: .green)
                    StatIcon(count: user.mealsSwapped, icon: "arrow.triangle.swap", color: .blue)
                }
            }
            
            Spacer()
            
            // CQ Score
            Text("\(Int(user.cqScore))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("FiestaPrimary"))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct StatIcon: View {
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// Helper for custom rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(DataController())
} 