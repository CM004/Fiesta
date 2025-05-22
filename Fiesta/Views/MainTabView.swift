import SwiftUI

struct MainTabView: View {
    @StateObject private var dataController = DataController()
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
            
            // Show admin dashboard only for staff and admin users
            if dataController.currentUser?.role == .cafeteriaStaff || dataController.currentUser?.role == .admin {
                AdminDashboardView()
                    .environmentObject(dataController)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
            }
            
            ProfileView()
                .environmentObject(dataController)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(Color("PrimaryColor"))
    }
}

#Preview {
    MainTabView()
} 