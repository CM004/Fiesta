import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var showingLogoutAlert = false
    @State private var notificationsEnabled = true
    @State private var locationServicesEnabled = true
    @State private var showingShareSheet = false
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                if let user = dataController.currentUser {
                    ProfileHeaderView(user: user)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                }
                
                // CQ Stats
                Section("Your Impact") {
                    if let user = dataController.currentUser {
                        HStack(spacing: 15) {
                            StatBoxView(title: "CQ Score", value: "\(Int(user.cqScore))", icon: "chart.bar.fill", color: .blue)
                            StatBoxView(title: "Meals Saved", value: "\(user.mealsSaved)", icon: "leaf.fill", color: .green)
                            StatBoxView(title: "Rank", value: "#\(user.leaderboardRank ?? 0)", icon: "trophy.fill", color: .orange)
                        }
                        
                        // Environmental Impact
                        EnvironmentalImpactView(mealsSaved: user.mealsSaved)
                    }
                }
                
                // App Settings
                Section("App Settings") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .tint(Color("FiestaPrimary"))
                    
                    Toggle("Location Services", isOn: $locationServicesEnabled)
                        .tint(Color("FiestaPrimary"))
                    
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .tint(Color("FiestaPrimary"))
                    
                    NavigationLink(destination: PreferencesView()) {
                        Label("Preferences", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink(destination: DietaryPreferencesView()) {
                        Label("Dietary Preferences", systemImage: "fork.knife")
                    }
                }
                
                // Help & Support
                Section("Help & Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Invite Friends", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: Text("About Fiesta")) {
                        Label("About Fiesta", systemImage: "info.circle")
                    }
                }
                
                // Account Actions
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Log Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    
                    if dataController.currentUser?.role == .admin {
                        NavigationLink(destination: Text("Admin Settings")) {
                            Label("Admin Settings", systemImage: "gear")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profile")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        // Logout logic
                        dataController.logout()
                        
                        // Find the root ContentView to set isAuthenticated to false
                        // We need to use NotificationCenter for communication between views
                        NotificationCenter.default.post(name: Notification.Name("LogoutUser"), object: nil)
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                ActivityView(activityItems: ["Join me on Fiesta to reduce food waste! Download now: https://fiesta-app.com"])
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack {
            // Profile image
            ZStack(alignment: .bottomTrailing) {
                if let profileImageURL = user.profileImageURL {
                    Image(profileImageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .shadow(radius: 3)
                }
                
                Image(systemName: "pencil.circle.fill")
                    .font(.title)
                    .foregroundColor(Color("FiestaPrimary"))
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(.top)
            
            // User info
            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 5)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // User role
            Text(user.role.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    user.role == .admin ? Color.purple.opacity(0.2) :
                    user.role == .cafeteriaStaff ? Color.orange.opacity(0.2) :
                    Color.blue.opacity(0.2)
                )
                .foregroundColor(
                    user.role == .admin ? .purple :
                    user.role == .cafeteriaStaff ? .orange :
                    .blue
                )
                .cornerRadius(20)
                .padding(.top, 2)
            
            // Badges
            HStack(spacing: 15) {
                if user.mealsSaved >= 10 {
                    Badge(title: "Green Saver", color: .green, icon: "leaf.fill")
                }
                
                if user.mealsSwapped >= 15 {
                    Badge(title: "Super Swapper", color: .blue, icon: "arrow.triangle.swap")
                }
                
                if user.mealsDistributed >= 5 {
                    Badge(title: "Distributor", color: .orange, icon: "hand.thumbsup.fill")
                }
            }
            .padding(.top)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct StatBoxView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 3)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

struct Badge: View {
    let title: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
}

struct EnvironmentalImpactView: View {
    let mealsSaved: Int
    
    // Environmental impact calculations
    var co2Saved: Double {
        return Double(mealsSaved) * 2.5 // kg of CO2
    }
    
    var waterSaved: Double {
        return Double(mealsSaved) * 100 // liters of water
    }
    
    var energySaved: Double {
        return Double(mealsSaved) * 3.0 // kWh of energy
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Environmental Impact")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Label {
                        Text("\(String(format: "%.1f", co2Saved)) kg")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                    } icon: {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.green)
                    }
                    Text("CO₂ Emissions Saved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Label {
                        Text("\(String(format: "%.0f", waterSaved)) L")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                    } icon: {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                    }
                    Text("Water Saved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            ProgressView(value: min(Double(mealsSaved) / 50.0, 1.0))
                .tint(Color("FiestaPrimary"))
                .padding(.top, 5)
            
            Text("You're \(Int(min(Double(mealsSaved) / 50.0 * 100, 100)))% of the way to saving the equivalent of a tree!")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
        .environmentObject(DataController())
} 