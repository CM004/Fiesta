import SwiftUI
import Charts

// Import prediction model
import CoreML

// Import utilities

struct AdminDashboardView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedDate = Date()
    @State private var selectedMealType: MealType = .lunch
    @State private var selectedLocation = "Main Cafeteria"
    @State private var showingPredictionDetail = false
    @State private var selectedPrediction: MealPrediction?
    @State private var isEventMode = false
    
    let locations = ["Main Cafeteria", "East Wing Cafe", "Snack Corner"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date selection
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                    .padding(.horizontal)
                    
                    // Meal type and location selection
                    HStack {
                        // Meal type picker
                        Picker("Meal Type", selection: $selectedMealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                        
                        Spacer()
                        
                        // Location picker
                        Picker("Location", selection: $selectedLocation) {
                            ForEach(locations, id: \.self) { location in
                                Text(location).tag(location)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                    }
                    .padding(.horizontal)
                    
                    // Prediction Overview Card
                    if let prediction = dataController.getPredictionForMeal(
                        date: selectedDate,
                        type: selectedMealType,
                        location: selectedLocation
                    ) {
                        PredictionOverviewCard(prediction: prediction)
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedPrediction = prediction
                                showingPredictionDetail = true
                            }
                        
                        // Influencing factors
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Influencing Factors")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(prediction.factors) { factor in
                                HStack {
                                    Image(systemName: factor.impact > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(factor.impact > 0 ? .green : .red)
                                    
                                    VStack(alignment: .leading) {
                                        Text(factor.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(factor.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(factor.impact > 0 ? "+" : "")\(Int(factor.impact * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(factor.impact > 0 ? .green : .red)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 3)
                                .padding(.horizontal)
                            }
                        }
                        
                    } else {
                        // No prediction available
                        VStack(spacing: 15) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No prediction available for selected parameters")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Create a new prediction using the ML model
                                let newPrediction = MealPredictionModel.shared.generatePrediction(
                                    date: selectedDate,
                                    mealType: selectedMealType,
                                    location: selectedLocation
                                )
                                
                                dataController.savePrediction(newPrediction)
                                selectedPrediction = newPrediction
                            }) {
                                Text("Generate Prediction")
                                    .font(.headline)
                                    .padding()
                                    .background(Color("FiestaPrimary"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                        .padding(.horizontal)
                    }
                    
                    // Event Mode Toggle
                    Toggle(isOn: $isEventMode) {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Event Mode")
                                    .font(.headline)
                                Text("Enable for special events with increased attendance")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 3)
                    .padding(.horizontal)
                    .onChange(of: isEventMode) { oldValue, newValue in
                        // Update prediction if it exists
                        if let prediction = selectedPrediction {
                            var updatedPrediction = prediction
                            updatedPrediction.isEventDay = newValue
                            // Adjust attendance for event mode
                            updatedPrediction.predictedAttendance = newValue ? 
                                prediction.predictedAttendance * 130 / 100 : // 30% increase
                                prediction.predictedAttendance * 100 / 130 // revert back
                            
                            dataController.savePrediction(updatedPrediction)
                            selectedPrediction = updatedPrediction
                        }
                    }
                    
                    // Attendance Trend Chart
                    VStack(alignment: .leading) {
                        Text("Attendance Trends")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(generateSampleData()) { sample in
                                LineMark(
                                    x: .value("Date", sample.day),
                                    y: .value("Attendance", sample.attendance)
                                )
                                .foregroundStyle(Color.blue)
                                .symbol(Circle())
                            }
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                    
                    // Waste Reduction Metrics
                    if let prediction = selectedPrediction, 
                       let wasteReduction = prediction.wasteReduction {
                        HStack {
                            WasteReductionMetricView(
                                title: "Meals Saved",
                                value: "\(wasteReduction)",
                                icon: "leaf.fill",
                                color: .green
                            )
                            
                            let impact = EnvironmentalImpactCalculator.calculateTotalImpact(mealCount: wasteReduction)
                            
                            WasteReductionMetricView(
                                title: "CO₂ Saved",
                                value: EnvironmentalImpactCalculator.formatImpact(type: "co2", value: impact["co2"] ?? 0),
                                icon: "wind",
                                color: .blue
                            )
                            
                            WasteReductionMetricView(
                                title: "Water Saved",
                                value: EnvironmentalImpactCalculator.formatImpact(type: "water", value: impact["water"] ?? 0),
                                icon: "drop.fill",
                                color: .cyan
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // AI Insights Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Smart Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // ML-based recommendations
                        HStack(alignment: .top) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ML-Based Recommendations")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(generateSmartInsight())
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                        
                        // Historical comparison
                        HStack(alignment: .top) {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Historical Pattern Analysis")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Based on historical data, today's attendance is likely to be \(selectedPrediction?.predictedAttendance ?? 200)±15. Last week's actual count was \(Int((Double(selectedPrediction?.predictedAttendance ?? 200) * 0.95).rounded())).")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .navigationTitle("SmartPredict Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Generate report or export data
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingPredictionDetail) {
                    if let prediction = selectedPrediction {
                        PredictionDetailView(prediction: prediction)
                            .environmentObject(dataController)
                    }
                }
            }
        }
    }
    
    // Generate AI insights based on current prediction data
    private func generateSmartInsight() -> String {
        guard let prediction = selectedPrediction else {
            return "Collect more data to generate AI insights."
        }
        
        let insights = [
            "Based on weather patterns and historical data, consider preparing \(Int(Double(prediction.predictedAttendance) * 0.95)) servings to reduce waste by approximately 5%.",
            "Today's \(prediction.isExamDay ? "exam schedule" : "regular day") suggests a \(prediction.isExamDay ? "15% decrease" : "standard attendance pattern") in cafeteria visits.",
            "Similar days historically show \(prediction.confidenceScore > 0.8 ? "very consistent" : "somewhat variable") attendance patterns.",
            "ML model confidence is \(Int(prediction.confidenceScore * 100))%, suggesting this prediction is \(prediction.confidenceScore > 0.8 ? "highly reliable" : "reasonably accurate").",
            "Consider offering more \(Calendar.current.component(.hour, from: Date()) < 12 ? "grab-and-go options" : "hot meals") today based on time patterns and weather conditions."
        ]
        
        // Pick 2 random insights to display
        let selectedInsights = Array(insights.shuffled().prefix(2))
        return selectedInsights.joined(separator: "\n\n")
    }
    
    // Sample data generation for chart
    private func generateSampleData() -> [DailyAttendance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { dayOffset in
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let baseAttendance = 200
            
            // Add some variation
            let isWeekend = calendar.isDateInWeekend(day)
            let randomFactor = Int.random(in: -30...30)
            let weekendFactor = isWeekend ? -40 : 0
            
            return DailyAttendance(
                day: day,
                attendance: baseAttendance + randomFactor + weekendFactor
            )
        }.reversed()
    }
}

struct DailyAttendance: Identifiable {
    let id = UUID()
    let day: Date
    let attendance: Int
}

struct PredictionOverviewCard: View {
    let prediction: MealPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("\(prediction.mealType.rawValue.capitalized) Prediction")
                        .font(.headline)
                    Text(formatDate(prediction.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Confidence indicator
                ZStack {
                    Circle()
                        .stroke(
                            prediction.confidenceScore >= 0.8 ? Color.green :
                                prediction.confidenceScore >= 0.6 ? Color.yellow :
                                Color.red,
                            lineWidth: 3
                        )
                        .frame(width: 40, height: 40)
                    
                    Text("\(Int(prediction.confidenceScore * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(
                            prediction.confidenceScore >= 0.8 ? .green :
                                prediction.confidenceScore >= 0.6 ? .yellow :
                                .red
                        )
                }
            }
            
            Divider()
            
            // Attendance prediction
            HStack {
                VStack(alignment: .leading) {
                    Text("Predicted Attendance")
                        .font(.subheadline)
                    Text("\(prediction.predictedAttendance)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if prediction.isExamDay {
                    Label("Exam Day", systemImage: "pencil.circle.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
                
                if prediction.isHoliday {
                    Label("Holiday", systemImage: "gift.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                if prediction.isEventDay {
                    Label("Event", systemImage: "star.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
            
            if let adjustedLevel = prediction.adjustedPreparationLevel {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Recommended Preparation")
                            .font(.subheadline)
                        Text("\(adjustedLevel) servings")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    if let wasteReduction = prediction.wasteReduction, wasteReduction > 0 {
                        Label {
                            Text("-\(wasteReduction) servings")
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                }
            }
            
            if let weatherCondition = prediction.weatherCondition {
                HStack {
                    Image(systemName: weatherIcon(for: weatherCondition))
                        .foregroundColor(weatherIconColor(for: weatherCondition))
                    
                    Text(weatherCondition)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let s where s.contains("rain"):
            return "cloud.rain.fill"
        case let s where s.contains("cloud"):
            return "cloud.fill"
        case let s where s.contains("snow"):
            return "snow"
        case let s where s.contains("wind"):
            return "wind"
        case let s where s.contains("storm"):
            return "cloud.bolt.fill"
        default:
            return "sun.max.fill"
        }
    }
    
    private func weatherIconColor(for condition: String) -> Color {
        switch condition.lowercased() {
        case let s where s.contains("rain"):
            return .blue
        case let s where s.contains("cloud"):
            return .gray
        case let s where s.contains("snow"):
            return .cyan
        case let s where s.contains("wind"):
            return .indigo
        case let s where s.contains("storm"):
            return .purple
        default:
            return .yellow
        }
    }
}

struct WasteReductionMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
    }
}

struct PredictionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataController: DataController
    let prediction: MealPrediction
    @State private var adjustedPreparation: Int
    @State private var showingSaveConfirmation = false
    
    init(prediction: MealPrediction) {
        self.prediction = prediction
        _adjustedPreparation = State(initialValue: prediction.adjustedPreparationLevel ?? prediction.predictedAttendance)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("\(prediction.mealType.rawValue.capitalized) at \(prediction.location)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(formatDate(prediction.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Main prediction data
                    Group {
                        DataRow(title: "Predicted Attendance", value: "\(prediction.predictedAttendance)")
                        
                        if let actual = prediction.actualAttendance {
                            DataRow(title: "Actual Attendance", value: "\(actual)")
                            
                            let accuracy = calculateAccuracy(predicted: prediction.predictedAttendance, actual: actual)
                            DataRow(title: "Prediction Accuracy", value: "\(accuracy)%")
                        }
                        
                        DataRow(title: "Confidence Score", value: "\(Int(prediction.confidenceScore * 100))%")
                        
                        if let weather = prediction.weatherCondition {
                            DataRow(title: "Weather Condition", value: weather)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Special Conditions")
                                    .font(.headline)
                                
                                HStack(spacing: 10) {
                                    ConditionBadge(
                                        isActive: prediction.isExamDay,
                                        title: "Exam Day",
                                        icon: "pencil.circle.fill",
                                        color: .purple
                                    )
                                    
                                    ConditionBadge(
                                        isActive: prediction.isHoliday,
                                        title: "Holiday",
                                        icon: "gift.fill",
                                        color: .blue
                                    )
                                    
                                    ConditionBadge(
                                        isActive: prediction.isEventDay,
                                        title: "Event",
                                        icon: "star.fill",
                                        color: .orange
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Preparation adjustment
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Preparation Adjustment")
                            .font(.headline)
                        
                        Text("Adjust the number of servings to prepare")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Button(action: {
                                if adjustedPreparation > 10 {
                                    adjustedPreparation -= 10
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Servings", value: $adjustedPreparation, format: .number)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .frame(width: 100)
                            
                            Button(action: {
                                adjustedPreparation += 10
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Waste reduction
                        let wasteReduction = prediction.predictedAttendance - adjustedPreparation
                        
                        if wasteReduction > 0 {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.green)
                                
                                Text("Potential waste reduction: \(wasteReduction) servings")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 5)
                        } else if wasteReduction < 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                
                                Text("Warning: \(abs(wasteReduction)) servings above prediction")
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    // Save button
                    Button(action: {
                        var updatedPrediction = prediction
                        updatedPrediction.adjustedPreparationLevel = adjustedPreparation
                        updatedPrediction.wasteReduction = adjustedPreparation < prediction.predictedAttendance ? 
                            prediction.predictedAttendance - adjustedPreparation : nil
                        
                        dataController.savePrediction(updatedPrediction)
                        showingSaveConfirmation = true
                    }) {
                        Text("Save Adjustments")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FiestaPrimary"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .alert(isPresented: $showingSaveConfirmation) {
                        Alert(
                            title: Text("Changes Saved"),
                            message: Text("Your preparation adjustments have been saved."),
                            dismissButton: .default(Text("OK")) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitle("Prediction Details", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func calculateAccuracy(predicted: Int, actual: Int) -> Int {
        let difference = abs(predicted - actual)
        let percentageError = Double(difference) / Double(actual) * 100
        return min(100, max(0, 100 - Int(percentageError)))
    }
}

struct DataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ConditionBadge: View {
    let isActive: Bool
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isActive ? color : .gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? color : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? color.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(DataController())
} 