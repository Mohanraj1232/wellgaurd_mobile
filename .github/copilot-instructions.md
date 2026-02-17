# WellGuard AI - Copilot Instructions

## Project Overview
WellGuard AI is a Flutter mobile safety application that enables users to securely manage emergency contacts, track journeys with real-time location monitoring, and trigger SOS alerts. The app implements a complete authentication flow with backend integration, persistent contact management, safety-scored routing, and emergency notification system.

**Package Name:** `wellguard_ai` | **SDK:** Flutter 3.10.7+ | **Backend:** Node.js API on port 5000

---

## Architecture & Data Flow

### App Structure
```
lib/
├── main.dart                    # App entry point with Provider setup & routes
├── constants.dart               # API configuration (baseUrl, port, endpoints)
├── theme/
│   └── colors.dart              # Centralized color constants (AppColors class)
├── models/
│   ├── user_data.dart           # User model with name, email, emergency contacts
│   ├── login_request.dart       # Login request (name, email, password)
│   ├── onboarding_request.dart  # Contact submission model
│   ├── route_data.dart          # Route, road info, location update models
│   └── api_response.dart        # Generic API response wrapper
├── providers/
│   └── journey_provider.dart    # Journey state management (ChangeNotifier)
├── services/
│   ├── dio_client.dart          # Dio singleton with interceptors
│   ├── api_client.dart          # API endpoints (auth, map, SOS)
│   └── location_service.dart    # Location permissions & GPS tracking
└── screens/
    ├── login.dart               # Auth screen with name field
    ├── onboarding.dart          # Emergency contact setup during signup
    ├── home.dart                # Main hub with Start Journey button
    ├── location_entry_page.dart # Destination & time limit input
    ├── map_page.dart            # Google Maps with real-time tracking
    ├── emergency_contacts.dart  # Dedicated page for viewing all contacts
    ├── sos.dart                 # Standard SOS alert screen (calls API on open)
    └── emergency_sos.dart       # Emergency SOS alert screen (calls API on open)
```

### Navigation Flow
1. **App Launch** → Check `SharedPreferences.userid` 
   - `true` → HomeScreen
   - `false` → LoginScreen
2. **Login** → Backend validates, returns `isExistingUser` flag
   - New user → OnboardingScreen (add emergency contacts)
   - Existing user → HomeScreen
3. **Onboarding** → Save contacts to backend + SharedPreferences → HomeScreen
4. **HomeScreen** → Start New Journey button, Quick Actions, Sidebar menu
5. **LocationEntryPage** → Enter destination + time limit → API fetches route
6. **MapPage** → Real-time GPS tracking every 1 second, SOS button
7. **Journey Complete** → User arrives or time exceeded triggers auto-SOS

### Backend API Integration
**Dio client setup:** [lib/services/dio_client.dart](lib/services/dio_client.dart) with automatic interceptors and timeout handling.

**Configuration:** [lib/constants.dart](lib/constants.dart)
- Base URL: `http://10.0.2.2:5000` (Android emulator) or configurable for physical devices
- Connection timeout: 10 seconds
- Response timeout: 10 seconds

**API Endpoints (in [lib/services/api_client.dart](lib/services/api_client.dart)):**
```dart
// Auth endpoints
POST /api/auth/login           // LoginRequest(name, email, password) → userId, isExistingUser
POST /api/auth/onboarding      // OnboardingRequest(contacts) → success
GET  /api/info/user/{userId}   // → UserData(name, email, emergencyContacts)

// Map/Journey endpoints
POST /api/map/fetch-route      // Create route with safety score
PUT  /api/map/update-location  // Update current location during journey
POST /api/map/sos              // Trigger SOS alert with location (see below)
POST /api/map/cancel-route     // Cancel active journey
```

**SOS Endpoint Request Body:**
```json
{
  "userId": 123,
  "routeId": "route-id-here",
  "message": "I feel unsafe, please help!",
  "currentLocation": {
    "latitude": 13.0827,
    "longitude": 80.2707,
    "timestamp": "2026-01-30T10:15:00.000Z"
  }
}
```

### Data Models
- **UserData:** userId, name, email, emergencyContact list (from backend)
- **EmergencyContact:** name, smsNumber (phoneNumber), whatsappNumber
- **LoginRequest:** name, email, password (sent to backend)
- **OnboardingRequest:** userId, emergencyContacts array
- **RouteData:** routeId, safetyScore, polyline, distance, duration, riskLevel, roadsUsed
- **LocationUpdateResponse:** status, distanceToDestination, minutesRemaining, sosTriggered

### Journey Tracking Flow
1. **LocationEntryPage** → User enters destination + time limit
2. **API Call** → `POST /api/map/fetch-route` with current location
3. **MapPage** → Display route on Google Maps with safety score
4. **Location Timer** → Every 1 second, call `PUT /api/map/update-location` with stored coordinates
5. **Completion** → Status becomes "completed" when user arrives
6. **Auto-SOS** → If time exceeded, backend triggers SOS automatically

### Hardcoded Start Location (Development)
**Location:** 12.914293, 80.168757 (configured in [lib/screens/location_entry_page.dart](lib/screens/location_entry_page.dart))
```dart
static const double _hardcodedLatitude = 12.914293;
static const double _hardcodedLongitude = 80.168757;
```
To use real GPS, call `_fetchCurrentLocation()` instead of `_setHardcodedLocation()` in `_initialize()`.

**Important:** The MapPage uses the stored `_currentLatLng` for location updates (not real-time GPS), preventing emulator default coordinates from overriding the hardcoded location during development.

### Map Page Features
- **Auto-follow toggle**: Map auto-follows user location by default. When user interacts with the map (pan/zoom), auto-follow disables. Press "My Location" button to re-enable.
- **Distance display**: Backend returns distance in meters; `JourneyProvider.formattedDistance` auto-converts to km when ≥ 1000m.
- **Location updates**: Uses stored coordinates from JourneyProvider, not real-time GPS (for development with hardcoded location).

---

## Critical Conventions & Patterns

### 1. **Screen Structure Pattern**
All screens follow this template:
- `StatefulWidget` for screens with state (loading, user data)
- `initState()` for async operations (API calls, SharedPreferences loading)
- `WillPopScope` for back-button control (HomeScreen prevents back navigation)
- Always use `mounted` check before `setState()` after async calls

**Key pattern:**
```dart
Future<void> _fetchData() async {
  try {
    final response = await apiClient.getUserInfo(userId);
    if (response.success && response.data != null) {
      if (mounted) setState(() { /* update UI */ });
    }
  } on DioException catch (e) {
    // Handle connection, timeout, and response errors
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### 2. **Color Theme Usage**
**MUST use `AppColors` class** from [lib/theme/colors.dart](lib/theme/colors.dart):
```dart
AppColors.primary,          // Primary action color
AppColors.secondary,        // Secondary/success color
AppColors.accentDanger,     // Emergency/alert color
AppColors.accentWarning,    // Warning color
AppColors.bgMain,           // Main background
AppColors.bgCard,           // Card background
AppColors.textMain,         // Primary text
AppColors.textSecondary,    // Secondary text
```
Never hardcode colors—each has semantic meaning for accessibility and theming.

### 3. **Authentication Pattern**
Login flow in [lib/screens/login.dart](lib/screens/login.dart):
1. Validate name, email (regex), password on client
2. Send `LoginRequest(name, email, password)` to backend
3. Backend returns `{ success, userId, isExistingUser }`
4. If new user: `pushReplacementNamed('/onboarding', arguments: userId)`
5. If existing: save `userid` to SharedPreferences, navigate to home

**Error handling:** Distinguish connection errors ("backend not running"), timeout errors, and auth failures with specific messages.

### 4. **API Response Pattern**
All responses use generic `ApiResponse<T>` wrapper:
```dart
// Success response: ApiResponse(success: true, data: T, message: null)
// Error response: ApiResponse(success: false, data: null, message: "error text")
if (response.success && response.data != null) {
  // Process response.data
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(response.message ?? 'Error'))
  );
}
```

### 5. **Home Screen User Display**
[lib/screens/home.dart](lib/screens/home.dart) loads user info via `_fetchUserData()`:
```dart
final userData = response.data!;
setState(() {
  _userName = userData.name;           // Display prominently
  _userEmail = userData.email;         // Secondary info
  _emergencyContacts = userData.emergencyContact; // For sidebar
});
```

### 6. **Sidebar Menu Pattern**
Drawer in home.dart contains:
- SOS and Emergency SOS action tiles
- Emergency Contacts navigation tile (routes to `EmergencyContactsScreen`)
- Logout tile with confirmation dialog

Emergency contacts passed as constructor argument: `EmergencyContactsScreen(contacts: _emergencyContacts ?? [])`

### 7. **SOS Screen Pattern**
Both [lib/screens/sos.dart](lib/screens/sos.dart) and [lib/screens/emergency_sos.dart](lib/screens/emergency_sos.dart) are `StatefulWidget` screens that:
1. **Auto-trigger SOS on open**: Call `triggerSOS()` API in `initState()`
2. **Get current location**: Use GPS via Geolocator, fallback to JourneyProvider
3. **Show loading state**: Display spinner while sending SOS
4. **Handle errors**: Show error message with retry button
5. **Show success**: Display confirmation with notifications sent count

**SOS messages:**
- Standard SOS: `"I feel unsafe, please help!"`
- Emergency SOS: `"EMERGENCY! I am in danger and need immediate help!"`

**API call pattern:**
```dart
final response = await apiClient.triggerSOS(
  userId: userId,
  routeId: routeId,  // Empty string if no active journey
  latitude: latitude,
  longitude: longitude,
  message: 'I feel unsafe, please help!',
);
```

---

## Key Developer Workflows

### Setup & Run
```powershell
# Initial setup
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator

# Backend must be running on configured port (default 5000)
# Update lib/constants.dart if using different IP or port
```

### Important Configuration
- **API Base URL:** [lib/constants.dart](lib/constants.dart)
  - Android emulator: `http://10.0.2.2:5000`
  - Physical device: Use your machine's local IP (e.g., `http://192.168.1.100:5000`)
- **Package name:** `wellguard_ai` (note: different from folder `wellgaurd_mobile`)
- **Key dependencies:** 
  - `dio: ^5.x` (HTTP client with interceptors)
  - `shared_preferences: ^2.5.4` (local auth state)
  - `json_annotation` + `build_runner` (serialization)
  - `geolocator: ^13.x` (GPS location tracking)
  - `google_maps_flutter: ^2.x` (Map display)
  - `flutter_polyline_points: ^2.x` (Route polyline decoding)
  - `provider: ^6.x` (State management)
  - `permission_handler: ^11.x` (Location permissions)
  - `intl: ^0.20.x` (Date/time formatting)

### Google Maps Setup
**Android:** Add API key in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

**iOS:** Add API key in [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift):
```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### Code Generation
JSON models use `json_annotation`. After modifying models, run:
```powershell
dart run build_runner build
```

### Testing Notes
- Login/onboarding requires backend running
- Test with connection errors by disabling backend or changing API URL
- SharedPreferences persists across app restarts; use logout to clear

---

## Common Tasks

### Add a New Screen
1. Create `lib/screens/screen_name.dart` as `StatefulWidget`
2. Add route in `main.dart`: `'/screen_name': (context) => const ScreenName(),`
3. Import `AppColors` for all styling
4. Use proper error handling for any API calls

### Fetch User Data
```dart
Future<void> _fetchUserData(int userId) async {
  try {
    final response = await DioClient.getApiClient().getUserInfo(userId);
    if (response.success && response.data != null) {
      if (mounted) setState(() { /* update state */ });
    }
  } on DioException catch (e) {
    // Handle errors with user-friendly messages
  }
}
```

### Add API Endpoint
1. Define in [lib/services/api_client.dart](lib/services/api_client.dart)
2. Add corresponding model in [lib/models/](lib/models/)
3. Update `lib/constants.dart` if new endpoint URL needed
4. Handle response with `ApiResponse<T>` pattern

### Modify Emergency Contacts
- Backend data fetched in `_fetchUserData()` from `UserData.emergencyContact`
- Display in sidebar as menu item (routes to dedicated page)
- Full details shown in [lib/screens/emergency_contacts.dart](lib/screens/emergency_contacts.dart)

---

## Integration Points & Future Work

### Current Integrations
✅ Backend authentication (name, email, password)
✅ User profile retrieval with name field
✅ Emergency contacts from backend
✅ Local state persistence with SharedPreferences
✅ Error handling for network issues
✅ Journey tracking with real-time location updates
✅ Google Maps integration with route polyline display
✅ Safety score calculation and display
✅ Manual SOS trigger with confirmation dialog
✅ Auto-SOS when time limit exceeded
✅ Journey cancellation

### To Implement
- SOS notification delivery to emergency contacts (SMS/WhatsApp API)
- Push notifications for incoming emergency alerts
- Background location tracking (WorkManager/Background Fetch)
- Contact editing/management UI
- Journey history

---

## Debugging Tips

| Issue | Solution |
|-------|----------|
| "Cannot connect to server" | Check backend is running on port 5000; verify `apiBaseUrl` in `constants.dart` matches your IP |
| Login fails with correct credentials | Backend may be returning `success: false`; check backend logs |
| User name not showing in home | Ensure backend returns `name` field in UserData response |
| Emergency contacts empty | Verify onboarding saved contacts to backend; check backend persistence |
| Back button behavior wrong | Check `WillPopScope(onWillPop: () async => false)` is applied to HomeScreen |
| Colors inconsistent | Verify imports use `AppColors` from `theme/colors.dart` (typo in package name!) |
| MissingPluginException | Run `flutter clean` then `flutter run` to rebuild native plugins |
| Google Maps not showing | Verify API key is set in AndroidManifest.xml and AppDelegate.swift |
| Location permission denied | Check permissions in AndroidManifest.xml and Info.plist; test on real device |
| Route polyline not displaying | Verify backend returns valid encoded polyline string |
| Map jumping to wrong location | MapPage uses stored coordinates for PUT calls; ensure hardcoded location is set correctly in LocationEntryPage |
| Distance showing in meters | JourneyProvider.formattedDistance auto-converts; verify you're using this getter, not raw distance value |
