# IBDPal - iOS App

A comprehensive iOS application designed to help patients with Inflammatory Bowel Disease (IBD) and Crohn's disease manage their condition through nutrition tracking, symptom monitoring, and personalized insights.

## 🏥 Features

### Core Functionality
- **Daily Logging**: Track meals, symptoms, medications, and bowel health
- **Nutrition Analysis**: Research-based nutrition benchmarks for IBD/Crohn's patients
- **Flare Risk Assessment**: AI-powered flare prediction based on 3-month data trends
- **Symptom Tracking**: Comprehensive symptom monitoring with severity levels
- **Medication Management**: Track medication adherence and side effects

### Advanced Analytics
- **Nutrition Deficiencies**: Identify gaps in nutrition based on IBD research benchmarks
- **Trend Analysis**: Visualize nutrition and symptom trends over time
- **Personalized Recommendations**: Data-driven suggestions for diet and lifestyle
- **Flare Risk Indicators**: Early warning system for potential flare-ups

### Research-Based Benchmarks
- **IBD Nutrition Standards**: Based on FODMAP, IBD, and Crohn's research studies
- **Crohn's-Specific Guidelines**: Specialized nutrition targets for Crohn's patients
- **Symptom Correlation**: Advanced algorithms linking diet, symptoms, and flare risk

## 🛠 Technical Stack

### Frontend
- **SwiftUI**: Modern iOS UI framework
- **Charts**: Data visualization for trends and analytics
- **Core Data**: Local data persistence
- **Combine**: Reactive programming for data binding

### Backend Integration
- **RESTful API**: Node.js/Express server
- **PostgreSQL**: Relational database for user data
- **Real-time Analytics**: Live nutrition and flare risk calculations

### Development Tools
- **Xcode**: iOS development environment
- **Charles Proxy**: Network traffic monitoring
- **Git**: Version control
- **GitHub**: Code repository and collaboration

## 📱 Screens

### Main Navigation
1. **Home**: Nutrition deficiencies, flare risk, and quick insights
2. **Daily Log**: Comprehensive daily tracking interface
3. **Discover**: Trend analysis and research-based benchmarks
4. **More**: Settings, profile, and additional features

### Key Views
- **Nutrition Analysis**: Real-time nutrition scoring (0-100)
- **Flare Risk Dashboard**: Trend visualization and risk factors
- **Meal Logging**: Detailed nutrition tracking for all meals
- **Symptom Tracker**: Comprehensive symptom monitoring

## 🔧 Setup & Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Node.js 18+ (for backend)
- PostgreSQL (for database)

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/IBDPal.git
   cd IBDPal
   ```

2. **iOS App Setup**
   ```bash
   # Open in Xcode
   open IBDPal/IBDPal.xcodeproj
   
   # Build and run
   # Select your target device/simulator
   # Press Cmd+R to build and run
   ```

3. **Backend Setup** (see IBDPal-Server repository)
   ```bash
   cd ../IBDPal-Server
   npm install
   npm start
   ```

4. **Environment Configuration**
   - Configure API endpoints in `HomeView.swift`
   - Set up database connection in server
   - Configure CORS settings for local development

## 📊 API Endpoints

### Nutrition Analysis
- `GET /api/journal/nutrition/analysis/:userId`
- Returns nutrition score, deficiencies, and recommendations

### Flare Risk Assessment
- `GET /api/journal/flare-risk/:userId`
- Returns flare risk trend and contributing factors

### Journal Entries
- `GET /api/journal/entries/:userId`
- `POST /api/journal/entries`
- `PUT /api/journal/entries/:entryId`

## 🧪 Testing

### Unit Tests
```bash
# Run tests in Xcode
Cmd+U
```

### Network Testing
```bash
# Test API endpoints
curl -X GET "http://localhost:3005/api/health"
curl -X GET "http://localhost:3005/api/journal/nutrition/analysis/{userId}"
```

## 📈 Research Integration

### Nutrition Benchmarks
- **IBD Standards**: Based on FODMAP research and IBD guidelines
- **Crohn's Guidelines**: Specialized nutrition targets for Crohn's patients
- **Fiber Tolerance**: Lower fiber targets for IBD patients (20-25g vs 30g)
- **Protein Requirements**: Higher protein needs (1.2-1.5g/kg vs 0.8g/kg)

### Flare Risk Factors
- Pain severity and frequency
- Bowel movement patterns
- Blood presence and urgency
- Stress levels and sleep quality
- Medication adherence

## 🔒 Security

- **API Authentication**: JWT-based user authentication
- **Data Encryption**: Secure transmission and storage
- **Privacy Compliance**: HIPAA-compliant data handling
- **Environment Variables**: Secure configuration management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏥 Medical Disclaimer

IBDPal is designed to assist patients in managing their IBD condition but should not replace professional medical advice. Always consult with healthcare providers for medical decisions.

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation in the `/docs` folder

---

**Built with ❤️ for the IBD community** 