import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedPeriod = "Weekly"
    @State private var isRefreshing = false
    @State private var leaderboardUsers: [User] = []
    let periods = ["Weekly", "Monthly", "All Time"]
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                    
                    // Top 3 Podium (only show if we have at least 3 users)
                    if leaderboardUsers.count >= 3 {
                        PodiumView(
                            firstPlace: leaderboardUsers[0],
                            secondPlace: leaderboardUsers[1],
                            thirdPlace: leaderboardUsers[2]
                        )
                        .padding(.bottom, 12)
                        .background(Color(.systemBackground))
                    } else if leaderboardUsers.count == 2 {
                        // Show modified podium with just 2 users
                        HStack(spacing: 20) {
                            Spacer()
                            
                            // First place
                            VStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                    .padding(.bottom, -5)
                                
                                ProfileImage(user: leaderboardUsers[0], size: 80)
                                
                                Text(leaderboardUsers[0].name.split(separator: " ").first ?? "")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                
                                Text("\(Int(leaderboardUsers[0].cqScore))")
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
                            
                            // Second place
                            VStack(spacing: 4) {
                                ProfileImage(user: leaderboardUsers[1], size: 70)
                                
                                Text(leaderboardUsers[1].name.split(separator: " ").first ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text("\(Int(leaderboardUsers[1].cqScore))")
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
                            
                            Spacer()
                        }
                        .padding(.bottom, 12)
                        .background(Color(.systemBackground))
                    } else if leaderboardUsers.count == 1 {
                        // Show single winner podium
                        VStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .padding(.bottom, -5)
                            
                            ProfileImage(user: leaderboardUsers[0], size: 80)
                            
                            Text(leaderboardUsers[0].name.split(separator: " ").first ?? "")
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Text("\(Int(leaderboardUsers[0].cqScore))")
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
                    if leaderboardUsers.isEmpty {
                        VStack {
                            Text("No users on the leaderboard yet.")
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("Offer or claim meals to earn CQ points and appear on the leaderboard!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGroupedBackground))
                    } else if leaderboardUsers.count > 3 {
                        // Show all users in a standard list style for better scrolling
                        VStack(spacing: 0) {
                            ForEach(leaderboardUsers.dropFirst(3)) { user in
                                UserRankRow(user: user)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                
                                Divider()
                                    .padding(.leading)
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer(minLength: 50) // Add some space at bottom for better scrolling
                }
            }
            .refreshable {
                // Handle the refresh action
                isRefreshing = true
                await refreshLeaderboard()
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
                // Clean up sample users before loading leaderboard
                removeSampleUsers()
                
                // Update the leaderboard with only real users
                dataController.updateLeaderboard()
                
                // Update our local copy of the leaderboard
                leaderboardUsers = dataController.leaderboard
                
                print("Leaderboard loaded with \(leaderboardUsers.count) real users")
            }
        }
    }
    
    private func refreshLeaderboard() async {
        isRefreshing = true
        
        // Clean up sample users before refreshing
        removeSampleUsers()
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update leaderboard
        dataController.updateLeaderboard()
        
        // Update our local copy
        leaderboardUsers = dataController.leaderboard
        
        print("Leaderboard refreshed with \(leaderboardUsers.count) real users")
        
        isRefreshing = false
    }
    
    private func removeSampleUsers() {
        // Load all users from storage
        var existingUsers = dataController.loadUsers()
        let originalCount = existingUsers.count
        
        // Remove only the generated sample users with known patterns,
        // but preserve legitimate test users and accounts created during this session
        existingUsers.removeAll { user in
            // Keep users with test.com email domains (legitimate test users)
            if user.email.hasSuffix("@test.com") {
                return false
            }
            
            // Always keep the current user
            if user.id == dataController.currentUser?.id {
                return false
            }
            
            // Remove users with sample IDs
            if user.id.hasPrefix("sample") {
                return true
            }
            
            // Remove users with example.com emails (clearly fake)
            if user.email.hasSuffix("@example.com") {
                return true
            }
            
            // Remove users with these specific names that were in sample data
            // but only if they also have very specific CQ scores that match our sample data
            let sampleUsers = [
                ("Alice Johnson", 95.0),
                ("Bob Smith", 88.5),
                ("Carol Davis", 82.0),
                ("David Wilson", 75.5),
                ("Emma Brown", 70.0),
                ("Frank Miller", 65.5),
                ("Grace Lee", 60.0),
                ("Henry Wilson", 55.0),
                ("Isabel Garcia", 50.0),
                ("Jack Brown", 45.0)
            ]
            
            for (name, score) in sampleUsers {
                if user.name == name && abs(user.cqScore - score) < 0.1 {
                    return true
                }
            }
            
            // Keep other users by default
            return false
        }
        
        // Add the default test users if none exist
        // These are the legitimate test users from the app
        let testEmails = ["admin@test.com", "staff@test.com", "student1@test.com", "student2@test.com"]
        let existingEmails = existingUsers.map { $0.email }
        
        // Check if we need to create default users
        let missingTestEmails = testEmails.filter { !existingEmails.contains($0) }
        if !missingTestEmails.isEmpty {
            // For a real app, we'd create these users
            // In this demo, we'll just log it
            print("Missing test users: \(missingTestEmails.joined(separator: ", "))")
        }
        
        // If we removed any users, save the filtered list
        if existingUsers.count < originalCount {
            print("Removed \(originalCount - existingUsers.count) sample users")
            dataController.saveUsers(existingUsers)
        }
        
        print("Leaderboard now has \(existingUsers.count) users")
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
        .padding(.horizontal, 20) // Add horizontal padding to ensure all podiums are visible
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