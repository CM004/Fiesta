import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var dietaryPreferences = DietaryPreferences.empty
    @State private var generalPreferences = GeneralPreferences.empty
    @State private var showingSkipAlert = false
    
    var onComplete: () -> Void
    
    var body: some View {
        VStack {
            // Header
            HStack {
                if currentStep > 0 {
                    Button(action: {
                        currentStep -= 1
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(Color("FiestaPrimary"))
                    }
                    .padding()
                } else {
                    Spacer()
                        .frame(width: 50)
                }
                
                Spacer()
                
                Button(action: {
                    showingSkipAlert = true
                }) {
                    Text("Skip")
                        .foregroundColor(Color("FiestaPrimary"))
                }
                .padding()
            }
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step == currentStep ? Color("FiestaPrimary") : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom)
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Step content
                    Group {
                        if currentStep == 0 {
                            WelcomeStepView()
                        } else if currentStep == 1 {
                            DietaryPreferencesStepView(preferences: $dietaryPreferences)
                        } else if currentStep == 2 {
                            GeneralPreferencesStepView(preferences: $generalPreferences)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
            }
            
            // Bottom navigation
            VStack {
                Button(action: {
                    if currentStep < 2 {
                        currentStep += 1
                    } else {
                        savePreferences()
                    }
                }) {
                    Text(currentStep < 2 ? "Continue" : "Complete Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FiestaPrimary"))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert(isPresented: $showingSkipAlert) {
            Alert(
                title: Text("Skip Preferences Setup?"),
                message: Text("You can always update your preferences later from the Profile screen."),
                primaryButton: .default(Text("Continue Setup")),
                secondaryButton: .destructive(Text("Skip")) {
                    onComplete()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func savePreferences() {
        guard var user = dataController.currentUser else { return }
        user.dietaryPreferences = dietaryPreferences
        user.generalPreferences = generalPreferences
        dataController.updateUser(user)
        
        onComplete()
        presentationMode.wrappedValue.dismiss()
    }
}

// Welcome screen
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "leaf.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(Color("FiestaPrimary"))
                .padding(.top, 20)
            
            Text("Welcome to Fiesta!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Let's personalize your experience")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(image: "fork.knife", title: "Dietary Preferences", description: "Tell us about your dietary needs so we can suggest suitable meals")
                
                FeatureRow(image: "bell.fill", title: "Notifications", description: "Get timely alerts about available meals and updates")
                
                FeatureRow(image: "leaf.fill", title: "Environmental Impact", description: "Track your contribution to reducing food waste")
            }
            .padding(.top, 20)
        }
    }
}

// Dietary preferences step
struct DietaryPreferencesStepView: View {
    @Binding var preferences: DietaryPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dietary Preferences")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Help us understand your dietary needs")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 15) {
                // Dietary Restrictions Section
                Group {
                    Text("Dietary Restrictions")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    DietaryToggle(title: "Vegetarian", isOn: $preferences.vegetarian)
                    DietaryToggle(title: "Vegan", isOn: $preferences.vegan)
                    DietaryToggle(title: "Gluten-Free", isOn: $preferences.glutenFree)
                    DietaryToggle(title: "Nut-Free", isOn: $preferences.nutFree)
                    DietaryToggle(title: "Dairy-Free", isOn: $preferences.dairyFree)
                }
                
                // Diet Types Section
                Group {
                    Text("Diet Types")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    DietaryToggle(title: "Low-Carb", isOn: $preferences.lowCarb)
                    DietaryToggle(title: "Ketogenic", isOn: $preferences.ketogenic)
                    DietaryToggle(title: "Pescatarian", isOn: $preferences.pescatarian)
                }
                
                // Religious Considerations
                Group {
                    Text("Religious Considerations")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    DietaryToggle(title: "Halal", isOn: $preferences.halal)
                    DietaryToggle(title: "Kosher", isOn: $preferences.kosher)
                }
                
                // Additional Restrictions
                Group {
                    Text("Additional Restrictions or Allergies")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    TextEditor(text: $preferences.additionalRestrictions)
                        .frame(height: 100)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

// General preferences step
struct GeneralPreferencesStepView: View {
    @Binding var preferences: GeneralPreferences
    @State private var cuisineToAdd = ""
    
    let commonCuisines = [
        "Italian", "Mexican", "Chinese", "Indian", "Japanese", 
        "Thai", "Mediterranean", "American", "French", "Middle Eastern"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("General Preferences")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Customize your app experience")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 15) {
                // Notifications
                Group {
                    Text("Notifications")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Toggle("Enable Automatic Notifications", isOn: $preferences.automaticNotifications)
                        .tint(Color("FiestaPrimary"))
                        .padding(.vertical, 5)
                }
                
                // Food Preferences
                Group {
                    Text("Food Preferences")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading) {
                        Text("Spice Level")
                            .font(.subheadline)
                        
                        Picker("Spice Level", selection: $preferences.spicePreference) {
                            ForEach(GeneralPreferences.SpiceLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Portion Size")
                            .font(.subheadline)
                        
                        Picker("Portion Size", selection: $preferences.portionSize) {
                            ForEach(GeneralPreferences.PortionSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                }
                
                // Cuisines
                Group {
                    Text("Preferred Cuisines")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonCuisines, id: \.self) { cuisine in
                                Button(action: {
                                    if !preferences.preferredCuisines.contains(cuisine) {
                                        preferences.preferredCuisines.append(cuisine)
                                    }
                                }) {
                                    Text(cuisine)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color("FiestaPrimary").opacity(0.1))
                                        .foregroundColor(Color("FiestaPrimary"))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    if !preferences.preferredCuisines.isEmpty {
                        Text("Your Selected Cuisines:")
                            .font(.subheadline)
                            .padding(.top, 5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(preferences.preferredCuisines, id: \.self) { cuisine in
                                    HStack {
                                        Text(cuisine)
                                            .font(.caption)
                                        
                                        Button(action: {
                                            preferences.preferredCuisines.removeAll { $0 == cuisine }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                // Display Options
                Group {
                    Text("Display Options")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Toggle("Show Nutritional Information", isOn: $preferences.showNutritionalInfo)
                        .tint(Color("FiestaPrimary"))
                        .padding(.vertical, 5)
                    
                    Toggle("Show Environmental Impact", isOn: $preferences.showEnvironmentalImpact)
                        .tint(Color("FiestaPrimary"))
                        .padding(.vertical, 5)
                }
            }
        }
    }
}

struct DietaryToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .tint(Color("FiestaPrimary"))
            .padding(.vertical, 5)
    }
}

struct FeatureRow: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: image)
                .font(.title2)
                .foregroundColor(Color("FiestaPrimary"))
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(DataController())
} 