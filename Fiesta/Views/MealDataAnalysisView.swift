import SwiftUI
import Charts

struct MealDataAnalysisView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var selectedTimeframe = "Weekly"
    let timeframes = ["Daily", "Weekly", "Monthly", "All Time"]
    @State private var selectedCategory = "Meals Saved"
    let categories = ["Meals Saved", "Meals Offered", "Meals Claimed", "Food Waste Reduction"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Filters section
                    HStack {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(timeframes, id: \.self) { timeframe in
                                Text(timeframe).tag(timeframe)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Summary statistics
                    HStack(spacing: 15) {
                        StatisticCard(
                            title: "Total Meals Saved",
                            value: "347",
                            change: "+12%",
                            trend: .up
                        )
                        
                        StatisticCard(
                            title: "Active Users",
                            value: "128",
                            change: "+5%",
                            trend: .up
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        StatisticCard(
                            title: "Avg. Claim Time",
                            value: "14 min",
                            change: "-8%",
                            trend: .down,
                            isPositiveTrend: true
                        )
                        
                        StatisticCard(
                            title: "Food Waste",
                            value: "68 kg",
                            change: "-23%",
                            trend: .down,
                            isPositiveTrend: true
                        )
                    }
                    .padding(.horizontal)
                    
                    // Main chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(selectedCategory) - \(selectedTimeframe)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ChartView(data: generateChartData())
                            .frame(height: 250)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 3)
                            .padding(.horizontal)
                    }
                    
                    // Popular locations
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Popular Meal Locations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            LocationStatRow(
                                location: "Main Cafeteria",
                                count: 187,
                                percentage: 54
                            )
                            
                            LocationStatRow(
                                location: "East Wing Cafe",
                                count: 93,
                                percentage: 27
                            )
                            
                            LocationStatRow(
                                location: "Snack Corner",
                                count: 67,
                                percentage: 19
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                        .padding(.horizontal)
                    }
                    
                    // Top meal types
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Meal Types")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            PieChartView(
                                data: [
                                    ("Lunch", 0.45, Color.green),
                                    ("Dinner", 0.30, Color.blue),
                                    ("Breakfast", 0.15, Color.orange),
                                    ("Snack", 0.10, Color.purple)
                                ]
                            )
                            .frame(width: 150, height: 150)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                LegendItem(color: .green, label: "Lunch", value: "45%")
                                LegendItem(color: .blue, label: "Dinner", value: "30%")
                                LegendItem(color: .orange, label: "Breakfast", value: "15%")
                                LegendItem(color: .purple, label: "Snack", value: "10%")
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                        .padding(.horizontal)
                    }
                    
                    // Environmental impact
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Environmental Impact")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            ImpactMetricView(
                                title: "CO₂ Emissions Saved",
                                value: "1.8 tons",
                                icon: "leaf.fill",
                                color: .green
                            )
                            
                            ImpactMetricView(
                                title: "Water Saved",
                                value: "34,500 L",
                                icon: "drop.fill",
                                color: .blue
                            )
                            
                            ImpactMetricView(
                                title: "Energy Saved",
                                value: "754 kWh",
                                icon: "bolt.fill",
                                color: .orange
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Meal Data Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Generate report
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    // Sample data generator for charts
    private func generateChartData() -> [(String, Double)] {
        var data: [(String, Double)] = []
        
        switch selectedTimeframe {
        case "Daily":
            data = [
                ("Mon", 12), ("Tue", 18), ("Wed", 15),
                ("Thu", 22), ("Fri", 28), ("Sat", 16),
                ("Sun", 10)
            ]
        case "Weekly":
            data = [
                ("Week 1", 65), ("Week 2", 72), ("Week 3", 85),
                ("Week 4", 92)
            ]
        case "Monthly":
            data = [
                ("Jan", 185), ("Feb", 212), ("Mar", 256),
                ("Apr", 278), ("May", 298), ("Jun", 312)
            ]
        default:
            data = [
                ("Q1", 654), ("Q2", 832), ("Q3", 914),
                ("Q4", 1072)
            ]
        }
        
        return data
    }
}

// Reusable components for the view
struct StatisticCard: View {
    let title: String
    let value: String
    let change: String
    let trend: TrendDirection
    var isPositiveTrend: Bool = true
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(trendColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "arrow.forward"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return isPositiveTrend ? .green : .red
        case .down: return isPositiveTrend ? .green : .red
        case .neutral: return .gray
        }
    }
}

struct ChartView: View {
    let data: [(String, Double)]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.0) { item in
                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Value", item.1)
                )
                .foregroundStyle(Color("FiestaPrimary").gradient)
            }
        }
    }
}

struct LocationStatRow: View {
    let location: String
    let count: Int
    let percentage: Int
    
    var body: some View {
        HStack {
            Text(location)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("(\(percentage)%)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct PieChartView: View {
    let data: [(String, Double, Color)]
    
    var body: some View {
        Canvas { context, size in
            // Calculate the center and radius
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            // Starting angle is 0 (right side)
            var startAngle = Angle.zero
            
            // Draw each segment
            for (_, value, color) in data {
                // Calculate the segment's angle
                let segmentAngle = Angle(degrees: 360 * value)
                
                // Create a path for the segment
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: startAngle + segmentAngle, clockwise: false)
                path.closeSubpath()
                
                // Fill the path with the segment's color
                context.fill(path, with: .color(color))
                
                // Update the starting angle for the next segment
                startAngle += segmentAngle
            }
            
            // Add a hole in the middle for a donut chart effect
            let innerRadius = radius * 0.6
            let centerCircle = Path(ellipseIn: CGRect(
                x: center.x - innerRadius,
                y: center.y - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            ))
            context.fill(centerCircle, with: .color(Color(.systemBackground)))
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct ImpactMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MealDataAnalysisView()
        .environmentObject(DataController())
} 