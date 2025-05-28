import SwiftUI

struct MainTabView: View {
    @StateObject private var dataController = DataController()
    @State private var selectedTab = 0
    @State private var userRole: UserRole = .student

    var body: some View {
        Group {
            // Check user role and display appropriate tabs
            if userRole == .admin {
                // Admin-specific tabs
                AdminTabView(dataController: dataController)
            } else if userRole == .cafeteriaStaff {
                // Cafeteria staff-specific tabs
                CafeteriaStaffTabView(dataController: dataController)
            } else {
                // Regular student tabs
                StudentTabView(dataController: dataController)
            }
        }
        .accentColor(Color("FiestaPrimary"))
        .onAppear {
            // Update userRole when view appears
            updateUserRole()
            
            // Set up notification for role changes
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserLoggedIn"),
                object: nil,
                queue: .main) { _ in
                    updateUserRole()
                }
        }
    }
    
    private func updateUserRole() {
        // Update the user role based on the current user in dataController
        if let currentUser = dataController.currentUser {
            self.userRole = currentUser.role
            print("User role set to: \(currentUser.role)")
        } else {
            self.userRole = .student
            print("No user found, defaulting to student role")
        }
    }
}

// Regular student tab view
struct StudentTabView: View {
    @ObservedObject var dataController: DataController
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            SwapView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Swap", systemImage: "arrow.left.arrow.right")
                }
                .tag(1)
            
            LeaderboardView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

// Admin-specific tab view
struct AdminTabView: View {
    @ObservedObject var dataController: DataController
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            MealDataAnalysisView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Analysis", systemImage: "chart.pie.fill")
                }
                .tag(1)
            
            LeaderboardView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

// Cafeteria staff tab view
struct CafeteriaStaffTabView: View {
    @ObservedObject var dataController: DataController
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            LeaderboardView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(1)
            
            ProfileView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
} 