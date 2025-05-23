# Fiesta - Food Waste Reduction App

Fiesta is an iOS app designed to reduce food waste in cafeterias by enabling meal swapping and using machine learning to predict meal demand.

## Features

### For Students
- **Meal Swapping**: Offer meals you won't consume and claim meals offered by others
- **Environmental Impact Tracking**: See how your actions reduce CO2 emissions, water usage, and energy consumption
- **Gamified Experience**: Earn Conscious Quotient (CQ) points and compete on the leaderboard
- **User Profiles**: Track your environmental impact and display earned badges

### For Cafeteria Staff
- **SmartPredict Dashboard**: ML-powered predictions of meal attendance
- **Waste Reduction Metrics**: Track how much food, water, and CO2 you've saved
- **Attendance Trends**: Visualize historical attendance patterns
- **AI Insights**: Get ML-informed recommendations to optimize meal preparation

## Technical Architecture

### Data Models
- **User**: Stores user information, role (student, staff, admin), and CQ score
- **Meal**: Contains meal details, nutritional info, and status (available, offered, claimed)
- **MealSwap**: Tracks meal exchanges between users
- **MealPrediction**: Stores attendance forecasts and factors affecting them

### Components
- **DataController**: Manages data operations, authentication, and persistence
- **MealPredictionModel**: ML model for forecasting cafeteria attendance
- **SwapView**: Tinder-style interface for offering/claiming meals
- **AdminDashboardView**: Interface for cafeteria staff to view predictions and insights

### Data Storage
Currently uses local JSON storage with plans for future Supabase integration.

## Getting Started

1. Clone the repository
2. Open the project in Xcode
3. Build and run on an iOS simulator or device

## Future Enhancements
- Supabase backend integration
- CoreML model training with real historical data
- QR code verification for meal pickup
- Push notifications for meal offers and claims
- Weather API integration for more accurate predictions

## Screenshots

[Screenshots will be added here]

## License

MIT 