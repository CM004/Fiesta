import SwiftUI

struct DietaryPreferencesView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var dietaryPreferences: DietaryPreferences
    @State private var showingSaveAlert = false
    
    // Dietary restrictions
    let dietaryCategories = [
        ("Vegetarian", "leaf.fill", "Excludes meat and fish, includes dairy and eggs"),
        ("Vegan", "leaf.circle.fill", "Excludes all animal products"),
        ("Gluten-Free", "allergens", "Excludes wheat, barley, rye"),
        ("Nut-Free", "exclamationmark.shield.fill", "No nuts or nut-derived products"),
        ("Dairy-Free", "drop.fill", "No milk or dairy products"),
        ("Low-Carb", "chart.bar.fill", "Reduced carbohydrate content"),
        ("Ketogenic", "flame.fill", "High-fat, adequate-protein, low-carbohydrate"),
        ("Pescatarian", "fish.fill", "Includes fish but not meat"),
        ("Halal", "checkmark.seal.fill", "Follows Islamic dietary laws"),
        ("Kosher", "star.fill", "Follows Jewish dietary laws")
    ]
    
    init() {
        // Initialize with current user preferences or empty defaults
        _dietaryPreferences = State(initialValue: DietaryPreferences.empty)
    }
    
    var body: some View {
        List {
            Section(header: Text("Dietary Restrictions")) {
                Toggle("Vegetarian", isOn: Binding(
                    get: { dietaryPreferences.vegetarian },
                    set: { dietaryPreferences.vegetarian = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Vegan", isOn: Binding(
                    get: { dietaryPreferences.vegan },
                    set: { dietaryPreferences.vegan = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Gluten-Free", isOn: Binding(
                    get: { dietaryPreferences.glutenFree },
                    set: { dietaryPreferences.glutenFree = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Nut-Free", isOn: Binding(
                    get: { dietaryPreferences.nutFree },
                    set: { dietaryPreferences.nutFree = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Dairy-Free", isOn: Binding(
                    get: { dietaryPreferences.dairyFree },
                    set: { dietaryPreferences.dairyFree = $0 }
                ))
                .tint(Color("FiestaPrimary"))
            }
            
            Section(header: Text("Diet Types")) {
                Toggle("Low-Carb", isOn: Binding(
                    get: { dietaryPreferences.lowCarb },
                    set: { dietaryPreferences.lowCarb = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Ketogenic", isOn: Binding(
                    get: { dietaryPreferences.ketogenic },
                    set: { dietaryPreferences.ketogenic = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Pescatarian", isOn: Binding(
                    get: { dietaryPreferences.pescatarian },
                    set: { dietaryPreferences.pescatarian = $0 }
                ))
                .tint(Color("FiestaPrimary"))
            }
            
            Section(header: Text("Religious Considerations")) {
                Toggle("Halal", isOn: Binding(
                    get: { dietaryPreferences.halal },
                    set: { dietaryPreferences.halal = $0 }
                ))
                .tint(Color("FiestaPrimary"))
                
                Toggle("Kosher", isOn: Binding(
                    get: { dietaryPreferences.kosher },
                    set: { dietaryPreferences.kosher = $0 }
                ))
                .tint(Color("FiestaPrimary"))
            }
            
            Section(header: Text("Additional Information")) {
                VStack(alignment: .leading) {
                    Text("Other Dietary Restrictions or Allergies")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: Binding(
                        get: { dietaryPreferences.additionalRestrictions },
                        set: { dietaryPreferences.additionalRestrictions = $0 }
                    ))
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }
                .padding(.vertical, 4)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color("FiestaPrimary"))
                        
                        Text("Your dietary preferences help us match you with suitable meal options and reduce food waste by connecting you with appropriate meals.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color("FiestaPrimary"))
                        
                        Text("This information is only used to improve your experience and is kept private.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Dietary Preferences")
        .toolbar {
            Button("Save") {
                savePreferences()
            }
        }
        .onAppear {
            // Load user preferences if available
            if let user = dataController.currentUser,
               let prefs = user.dietaryPreferences {
                dietaryPreferences = prefs
            }
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("Preferences Saved"),
                message: Text("Your dietary preferences have been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func savePreferences() {
        guard var user = dataController.currentUser else { return }
        user.dietaryPreferences = dietaryPreferences
        dataController.updateUser(user)
        showingSaveAlert = true
    }
}

#Preview {
    NavigationView {
        DietaryPreferencesView()
            .environmentObject(DataController())
    }
} 