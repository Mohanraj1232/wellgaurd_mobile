# WellGuard AI

A Flutter-based women's safety mobile application that provides real-time journey tracking, emergency SOS alerts, AI-powered chat assistance, grievance reporting, and community news feed.

## Features

- **Emergency SOS** - One-tap emergency alert that sends your live location to registered emergency contacts via WhatsApp and SMS
- **Real-time Journey Tracking** - Set a destination and share your live route with trusted contacts using Google Maps integration
- **AI Chat Assistant** - Voice and text-based chat with an AI assistant for safety guidance (supports speech-to-text)
- **Grievance Reporting** - Report and track safety grievances with image/audio attachments
- **Community News Feed** - Stay updated with local safety news and community posts
- **Emergency Contacts Management** - Manage trusted contacts who receive alerts during emergencies

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Networking:** Dio
- **Maps:** Google Maps Flutter + Polyline Points
- **Location:** Geolocator
- **Voice Input:** Speech to Text
- **UI:** Glassmorphism, Lottie animations, Flutter Animate, Iconsax icons

## Prerequisites

- Flutter SDK `^3.10.7`
- Android Studio / Xcode
- Google Maps API key (for map features)
- Backend server running (see [Backend Setup](#backend-setup))

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/wellguard-mobile.git
   cd wellguard-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure the API base URL**

   Edit `lib/constants.dart` and set `apiBaseUrl` to point to your backend server:
   ```dart
   static const String apiBaseUrl = 'http://YOUR_SERVER_IP:PORT/backend';
   ```

4. **Add Google Maps API key**

   - **Android:** Add your key in `android/app/src/main/AndroidManifest.xml`
   - **iOS:** Add your key in `ios/Runner/AppDelegate.swift`

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart              # App entry point & route definitions
├── constants.dart         # API URLs & app configuration
├── models/               # Data models (JSON serializable)
├── providers/            # State management (JourneyProvider)
├── screens/              # UI screens
│   ├── home.dart         # Dashboard with quick actions
│   ├── emergency_sos.dart # SOS alert trigger
│   ├── map_page.dart     # Live journey tracking with Google Maps
│   ├── chat_page.dart    # AI chat with voice input
│   ├── news_feed.dart    # Community safety news
│   ├── greivance.dart    # Grievance filing
│   └── login.dart        # Authentication
├── services/             # API client & location services
├── theme/                # Colors, typography, spacing
└── widgets/              # Reusable UI components
```

## Backend Setup

The app requires a Node.js backend server. See [`backendreadme.md`](backendreadme.md) for full API documentation.

```bash
cd backend
npm install
npm run dev
```

Key API endpoints:
| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/login` | User login/registration |
| `POST /api/auth/onboarding` | Save emergency contacts |
| `GET /api/info/user/:id` | Fetch user info |
| `POST /api/map/fetch-route` | Get route between points |
| `POST /api/map/update-location` | Live location updates |
| `POST /api/map/sos` | Trigger emergency SOS |

## Screenshots

<!-- Add screenshots here -->

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter
- Google Maps Platform for mapping services
- Designed for women's safety and community well-being
