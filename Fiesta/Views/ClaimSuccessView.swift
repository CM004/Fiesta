import SwiftUI

struct ClaimSuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataController: DataController
    let meal: Meal?
    
    var body: some View {
        VStack(spacing: 25) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(Color.green)
                .padding(.top, 40)
            
            Text("Success!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've claimed this meal")
                .font(.title3)
                .foregroundColor(.gray)
            
            // Meal info
            if let meal = meal {
                VStack(alignment: .center, spacing: 5) {
                    Text(meal.name)
                        .font(.headline)
                    
                    Text(meal.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(meal.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
            }
            
            // CQ Points earned
            VStack {
                Text("You earned")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("+0.5 CQ Points")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FiestaPrimary"))
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            
            // Environmental impact
            HStack(spacing: 30) {
                VStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("1 meal saved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("100L water saved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Spacer()
            
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
        .padding()
    }
}

#Preview {
    ClaimSuccessView(meal: Meal(
        name: "Vegetable Stir Fry",
        description: "Mixed vegetables stir-fried with tofu and teriyaki sauce",
        type: .dinner,
        date: Date(),
        location: "Main Cafeteria"
    ))
} 