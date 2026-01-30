# WellGuard AI - Copilot Instructions

## Project Overview
WellGuard AI is a Flutter mobile safety application that enables users to manage emergency contacts and trigger SOS alerts. The app implements an authentication flow with contact management and emergency notification system.

**Package Name:** `wellguard_ai` | **SDK:** Flutter 3.10.7+

---

## Architecture & Data Flow

### App Structure
```
lib/
├── main.dart              # App entry point with auth check & route setup
├── theme/
│   └── colors.dart        # Centralized color constants (AppColors class)
├── models/
│   └── contact_model.dart # Contact data model with serialization
└── screens/
    ├── login.dart         # Auth screen (no backend validation yet)
    ├── onboarding.dart    # Emergency contact setup
    ├── home.dart          # Main app hub with drawer menu
    ├── sos.dart           # Standard SOS alert screen
    └── emergency_sos.dart # Emergency SOS alert screen
```

### Navigation Flow
1. **App Launch** → Check `SharedPreferences.isloggedin` 
   - `true` → HomeScreen
   - `false` → LoginScreen
2. **Login** → OnboardingScreen (userId=1 hardcoded)
3. **Onboarding** → Save contacts + login state → HomeScreen
4. **HomeScreen** → Drawer menu routes to SOS/Emergency SOS
5. **Back Button Disabled** on HomeScreen via `WillPopScope`

### Persistent Data (SharedPreferences)
Structure for contact storage:
```dart
prefs.setBool('isloggedin', true);
prefs.setInt('userid', 1);
prefs.setInt('contacts_count', 2);
prefs.setString('contact1name', 'Alice');
prefs.setString('contact1number', '+1234567890');
prefs.setString('contact2name', 'Bob');
prefs.setString('contact2number', '+9876543210');
```
**Clearing:** Logout calls `prefs.clear()` to remove all data.

---

## Critical Conventions & Patterns

### 1. **Screen Structure Pattern**
All screens follow this template:
- `StatefulWidget` for screens with state (auth checks, contact loading)
- `InitState()` for async loading (contacts, preferences)
- `WillPopScope` for back-button control (HomeScreen prevents navigation)
- Use `mounted` check before setState after async calls

Example: [lib/screens/home.dart](lib/screens/home.dart#L1-L50) (contact loading pattern)

### 2. **Color Theme Usage**
**MUST use `AppColors` class** from [lib/theme/colors.dart](lib/theme/colors.dart):
```dart
backgroundColor: AppColors.primary,        // Deep Trust Blue
accentColor: AppColors.secondary,          // Wellness Green
dangerColor: AppColors.accentDanger,       // Red alerts
```
Never use hardcoded colors or `Colors.blue`. Each color has semantic meaning.

### 3. **Email Validation Pattern**
Real-time validation with field highlighting:
```dart
bool _isValidEmail(String email) {
  final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return regex.hasMatch(email);
}
// Red border on invalid: enabledBorder with accentDanger
```

### 4. **Contact Dialog Pattern**
Reusable dialog for add/edit contacts:
- `TextEditingController` for inputs
- Named parameter `Contact? contact` to distinguish add vs edit
- Clear controllers after dialog close
- Call `_saveContacts()` before Navigator.pop

### 5. **Async Pattern**
All SharedPreferences calls:
```dart
Future<void> _loadContacts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    setState(() { /* update UI */ });
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

## Key Developer Workflows

### Build & Run
```powershell
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter pub add <package>    # Add new dependency (corrected spelling!)
```

### Important Notes on Dependencies
- ✅ `shared_preferences: ^2.5.4` for auth state persistence
- ✅ `package_name: wellguard_ai` (note: not wellgaurd_mobile)
- No network/backend implemented yet—auth is placeholder only

### Testing Pattern
Login screen has placeholder `_validateUser()` function that must be connected to backend later.

---

## Integration Points & Future Work

### 1. **Backend Authentication**
Currently stubbed in [lib/screens/login.dart](lib/screens/login.dart). Replace `_validateUser()` with API call.

### 2. **SOS Notifications**
[lib/screens/sos.dart](lib/screens/sos.dart) and [lib/screens/emergency_sos.dart](lib/screens/emergency_sos.dart) are UI placeholders. Integrate:
- Push notifications to contacts
- Location services
- Background task execution

### 3. **Contact Storage Migration**
Current flat SharedPreferences structure will not scale beyond ~10 contacts. Plan: Migrate to local SQLite DB or Firestore when implementing sync.

---

## Common Tasks

### Add a New Screen
1. Create `lib/screens/screen_name.dart` with `StatefulWidget`
2. Use `WillPopScope` if back-button control needed
3. Add route in `main.dart` routes map
4. Import theme colors from `AppColors`

### Add New Persistent Data
1. Use SharedPreferences keys with underscore prefix (e.g., `user_prefs`, `emergency_data`)
2. Always wrap with try/catch
3. Check `mounted` before setState
4. Add clear logic to logout function

### Modify Contact Flow
Contact operations centralized in [lib/screens/home.dart](lib/screens/home.dart) (add/edit/delete methods). Onboarding screen mirrors this pattern for initial setup.

---

## Debugging Tips

- **Empty contacts after login?** Check SharedPreferences keys match exactly (`contact1name` not `contact_1_name`)
- **Stuck on splash?** `_isCheckingLogin` may not be set to false; check Firebase/preference loading
- **Back button navigating unexpectedly?** Ensure `WillPopScope(onWillPop: () async => false)` is applied
- **Colors look wrong?** Verify imports: `import 'package:wellguard_ai/theme/colors.dart'` (not a typo)

---

## Questions for Feedback
- Should we migrate to a state management solution (Provider/GetX) before adding more features?
- Contact storage: SQLite DB or Firestore integration when ready?
- Need location/notification service setup guidance?
