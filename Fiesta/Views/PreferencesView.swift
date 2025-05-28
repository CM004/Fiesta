import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var generalPreferences: GeneralPreferences
    @State private var showingSaveAlert = false
    @State private var cuisineToAdd: String = ""
    @State private var showingTimePicker = false
    @State private var reminderTime: Date = Date()
    
    // Common cuisine options
    let commonCuisines = [
        "Italian", "Mexican", "Chinese", "Indian", "Japanese", 
        "Thai", "Mediterranean", "American", "French", "Middle Eastern"
    ]
    
    init() {
        // Initialize with current user preferences or empty defaults
        _generalPreferences = State(initialValue: GeneralPreferences.empty)
    }
    
    var body: some View {
        List {
            Section(header: Text("Notifications")) {
                Toggle("Enable Automatic Notifications", isOn: $generalPreferences.automaticNotifications)
                    .tint(Color("FiestaPrimary"))
                
                Button(action: {
                    showingTimePicker = true
                }) {
                    HStack {
                        Text("Meal Reminder Time")
                        Spacer()
                        if let reminderTime = generalPreferences.mealReminderTime {
                            Text(timeFormatter.string(from: reminderTime))
                                .foregroundColor(.gray)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(header: Text("Food Preferences")) {
                VStack(alignment: .leading) {
                    Text("Spice Level")
                        .font(.subheadline)
                    
                    Picker("Spice Level", selection: $generalPreferences.spicePreference) {
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
                    
                    Picker("Portion Size", selection: $generalPreferences.portionSize) {
                        ForEach(GeneralPreferences.PortionSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 5)
                }
            }
            
            Section(header: Text("Preferred Cuisines")) {
                VStack(alignment: .leading) {
                    HStack {
                        TextField("Add a cuisine", text: $cuisineToAdd)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addCuisine) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color("FiestaPrimary"))
                        }
                    }
                    
                    Text("Common Cuisines")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonCuisines, id: \.self) { cuisine in
                                Button(action: {
                                    if !generalPreferences.preferredCuisines.contains(cuisine) {
                                        generalPreferences.preferredCuisines.append(cuisine)
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
                    
                    if !generalPreferences.preferredCuisines.isEmpty {
                        Text("Your Selections")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(generalPreferences.preferredCuisines, id: \.self) { cuisine in
                                HStack {
                                    Text(cuisine)
                                        .font(.caption)
                                    
                                    Button(action: {
                                        generalPreferences.preferredCuisines.removeAll { $0 == cuisine }
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
                }
                .padding(.vertical, 5)
            }
            
            Section(header: Text("Display Options")) {
                Toggle("Show Nutritional Information", isOn: $generalPreferences.showNutritionalInfo)
                    .tint(Color("FiestaPrimary"))
                
                Toggle("Show Environmental Impact", isOn: $generalPreferences.showEnvironmentalImpact)
                    .tint(Color("FiestaPrimary"))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Preferences")
        .toolbar {
            Button("Save") {
                savePreferences()
            }
        }
        .onAppear {
            // Load user preferences if available
            if let user = dataController.currentUser,
               let prefs = user.generalPreferences {
                generalPreferences = prefs
                if let reminderTime = prefs.mealReminderTime {
                    self.reminderTime = reminderTime
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: $reminderTime, isPresented: $showingTimePicker) {
                generalPreferences.mealReminderTime = reminderTime
            }
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("Preferences Saved"),
                message: Text("Your preferences have been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func addCuisine() {
        let cuisine = cuisineToAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cuisine.isEmpty && !generalPreferences.preferredCuisines.contains(cuisine) {
            generalPreferences.preferredCuisines.append(cuisine)
            cuisineToAdd = ""
        }
    }
    
    private func savePreferences() {
        guard var user = dataController.currentUser else { return }
        user.generalPreferences = generalPreferences
        dataController.updateUser(user)
        showingSaveAlert = true
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Select Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        
        for row in rows {
            height += row.maxY
            height += spacing
        }
        
        return CGSize(width: maxWidth, height: max(0, height - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            for index in row.range {
                let viewSize = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height)
                )
                x += viewSize.width + spacing
            }
            y += row.maxY + spacing
        }
    }
    
    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(range: 0..<0, maxY: 0)
        var x: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let viewSize = subview.sizeThatFits(.unspecified)
            
            if x + viewSize.width > maxWidth && currentRow.range.count > 0 {
                rows.append(currentRow)
                currentRow = Row(range: index..<index, maxY: viewSize.height)
                x = viewSize.width + spacing
            } else {
                currentRow.range = currentRow.range.lowerBound..<index + 1
                currentRow.maxY = max(currentRow.maxY, viewSize.height)
                x += viewSize.width + spacing
            }
        }
        
        if currentRow.range.count > 0 {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var range: Range<Int>
        var maxY: CGFloat
    }
}

#Preview {
    NavigationView {
        PreferencesView()
            .environmentObject(DataController())
    }
} 