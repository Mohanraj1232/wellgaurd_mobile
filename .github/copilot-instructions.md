# WellGuard AI - Copilot Instructions

## Project Overview
WellGuard AI is a Flutter mobile safety application that enables users to securely manage emergency contacts and trigger SOS alerts. The app implements a complete authentication flow with backend integration, persistent contact management, and emergency notification system.

**Package Name:** `wellguard_ai` | **SDK:** Flutter 3.10.7+ | **Backend:** Node.js API on port 5000

---

## Architecture & Data Flow

### App Structure
```
lib/
├── main.dart                    # App entry point with auth check & route setup
├── constants.dart               # API configuration (baseUrl, port, endpoints)
├── theme/
│   └── colors.dart              # Centralized color constants (AppColors class)
├── models/
│   ├── user_data.dart           # User model with name, email, emergency contacts
│   ├── login_request.dart       # Login request (name, email, password)
│   ├── onboarding_request.dart  # Contact submission model
│   └── api_response.dart        # Generic API response wrapper
├── services/
│   ├── dio_client.dart          # Dio singleton with interceptors
│   └── api_client.dart          # API endpoints (login, onboarding, getUserInfo)
└── screens/
    ├── login.dart               # Auth screen with name field
    ├── onboarding.dart          # Emergency contact setup during signup
    ├── home.dart                # Main hub with user info & sidebar menu
    ├── emergency_contacts.dart  # Dedicated page for viewing all contacts
    ├── sos.dart                 # Standard SOS alert screen
    └── emergency_sos.dart       # Emergency SOS alert screen
```

### Navigation Flow
1. **App Launch** → Check `SharedPreferences.userid` 
   - `true` → HomeScreen
   - `false` → LoginScreen
2. **Login** → Backend validates, returns `isExistingUser` flag
   - New user → OnboardingScreen (add emergency contacts)
   - Existing user → HomeScreen
3. **Onboarding** → Save contacts to backend + SharedPreferences → HomeScreen
4. **HomeScreen** → Sidebar menu: SOS, Emergency SOS, Emergency Contacts (page), Logout
5. **Emergency Contacts Page** → Full-screen view of all contacts with details

### Backend API Integration
**Dio client setup:** [lib/services/dio_client.dart](lib/services/dio_client.dart) with automatic interceptors and timeout handling.

**Configuration:** [lib/constants.dart](lib/constants.dart)
- Base URL: `http://10.0.2.2:5000` (Android emulator) or configurable for physical devices
- Connection timeout: 10 seconds
- Response timeout: 10 seconds

**API Endpoints (in [lib/services/api_client.dart](lib/services/api_client.dart)):**
```dart
POST /api/auth/login           // LoginRequest(name, email, password) → userId, isExistingUser
POST /api/auth/onboarding      // OnboardingRequest(contacts) → success
GET  /api/info/user/{userId}   // → UserData(name, email, emergencyContacts)
```

### Data Models
- **UserData:** userId, name, email, emergencyContact list (from backend)
- **EmergencyContact:** name, smsNumber (phoneNumber), whatsappNumber
- **LoginRequest:** name, email, password (sent to backend)
- **OnboardingRequest:** userId, emergencyContacts array

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

### To Implement
- SOS notification delivery to emergency contacts (SMS/WhatsApp API)
- Location capture and sharing during SOS
- Push notifications for incoming emergency alerts
- Background task execution
- Contact editing/management UI

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
