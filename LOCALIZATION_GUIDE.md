# Localization System Documentation

## Overview

The mamamind app now has a comprehensive localization system that separates all UI text into JSON files. This makes it easier to manage translations, add new languages, and maintain consistency across the app.

## Architecture

### JSON Files Structure

All translation files are located in the `languages/` directory:

- **common.json** - Common UI elements (buttons, labels, error messages)
- **auth.json** - Authentication screens (Login, Sign Up, Forgot Password)
- **home.json** - Home screen texts
- **profile.json** - Profile and GDPR screens
- **chat.json** - RAG Chat screen
- **questionnaires.json** - Questionnaire-related texts
- **achievements.json** - Achievements page
- **validators.json** - Form validation messages

Each JSON file follows this structure:

```json
{
  "en": {
    "key": "English text"
  },
  "si": {
    "key": "Sinhala text"
  }
}
```

### Core Services

1. **LocalizationService** (`lib/services/localization_service.dart`)
   - Singleton service that loads all translation files
   - Provides methods to access translations by module
   - Automatically initialized in `main.dart`

2. **Translate Helper** (`lib/utils/translate.dart`)
   - Provides convenient access to translations in widgets
   - Integrates with existing `LanguageProvider`
   - Offers context extensions for easy usage

## How to Use

### Method 1: Using Context Extension (Recommended)

```dart
import 'package:mamamind/utils/translate.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.t.common('loading'));
  }
}
```

### Method 2: Using Translate Helper

```dart
import 'package:mamamind/utils/translate.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Translate.of(context);

    return Column(
      children: [
        Text(t.auth('login')),
        Text(t.common('cancel')),
        Text(t.profile('settings')),
      ],
    );
  }
}
```

### Method 3: Direct Service Access (For non-UI code)

```dart
import 'package:mamamind/services/localization_service.dart';

String getErrorMessage(String lang) {
  return LocalizationService.instance.common('error', lang);
}
```

## Migration Examples

### Before (Old Code)

```dart
// Old hardcoded translations
final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";
final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
final passwordText = langProvider.currentLang == 'en' ? "Password" : "මුරපදය";
```

### After (New Localization System)

```dart
// Using context extension
Text(context.t.auth('login'))
Text(context.t.auth('email'))
Text(context.t.auth('password'))

// Or using Translate helper
final t = Translate.of(context);
Text(t.auth('login'))
Text(t.auth('email'))
Text(t.auth('password'))
```

### Form Validation Example

**Before:**

```dart
validator: (val) {
  if (val == null || val.isEmpty) {
    return isSinhala ? 'ඊමේල් අවශ්‍යයි' : 'Email is required';
  }
  return null;
}
```

**After:**

```dart
validator: (val) {
  if (val == null || val.isEmpty) {
    return context.t.validators('emailRequired');
  }
  return null;
}
```

### Complete Widget Migration Example

**Before:**

```dart
AppBar(
  title: Text(
    langProvider.currentLang == 'en' ? "Profile" : "ප්‍රොෆයිල්",
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.logout),
      tooltip: langProvider.currentLang == 'en' ? 'Logout' : 'පිටවීම',
      onPressed: () => _logout(),
    ),
  ],
)
```

**After:**

```dart
AppBar(
  title: Text(context.t.profile('profile')),
  actions: [
    IconButton(
      icon: Icon(Icons.logout),
      tooltip: context.t.common('logout'),
      onPressed: () => _logout(),
    ),
  ],
)
```

## Best Practices

1. **Use Descriptive Keys**: Use clear, descriptive keys instead of abbreviations
   - Good: `emailRequired`, `loginSuccess`
   - Bad: `err1`, `msg2`

2. **Group Related Texts**: Keep related texts in the same module
   - All authentication texts → `auth.json`
   - All form validations → `validators.json`

3. **Avoid Duplication**: If text appears in multiple places, put it in `common.json`

4. **Consistent Naming**: Use camelCase for keys
   - Good: `forgotPassword`, `confirmPassword`
   - Bad: `forgot_password`, `ConfirmPassword`

5. **Context Extension for Widgets**: Prefer `context.t` in widget builds for brevity

6. **Check Language in Logic**: Use `context.isSinhala` or `context.isEnglish` for conditional logic

## Adding New Translations

### Step 1: Add to JSON File

```json
// languages/home.json
{
  "en": {
    "newFeature": "New Feature"
  },
  "si": {
    "newFeature": "නව විශේෂාංගය"
  }
}
```

### Step 2: Use in Code

```dart
Text(context.t.home('newFeature'))
```

## Migration Checklist

To migrate existing code to the new localization system:

1. ✅ Install localization files (already done)
2. ✅ Initialize LocalizationService in main.dart (already done)
3. ✅ Import translate helper: `import 'package:mamamind/utils/translate.dart';`
4. ✅ Replace ternary operators with `context.t.module('key')`
5. ✅ Replace `isSinhala` checks with appropriate translations
6. ✅ Update validators to use `context.t.validators('key')`
7. ✅ Test all screens in both languages
8. ✅ Remove old hardcoded translations

## Available Translation Modules

- `context.t.common(key)` - Common UI elements
- `context.t.auth(key)` - Authentication
- `context.t.home(key)` - Home screen
- `context.t.profile(key)` - Profile & settings
- `context.t.chat(key)` - Chat interface
- `context.t.questionnaires(key)` - Questionnaires
- `context.t.achievements(key)` - Achievements
- `context.t.validators(key)` - Form validation

## Helper Properties

```dart
// Check current language
if (context.isSinhala) { ... }
if (context.isEnglish) { ... }

// Get current language code
String lang = context.currentLang; // 'en' or 'si'

// Access Translate helper
final t = Translate.of(context);
bool isSi = t.isSinhala;
bool isEn = t.isEnglish;
String langCode = t.lang;
```

## Troubleshooting

### Translation Not Found

If a key returns the key itself instead of translated text:

1. Check if the key exists in the JSON file
2. Verify the module is correct (e.g., `auth` vs `common`)
3. Ensure JSON syntax is valid

### Translations Not Loading

1. Verify `languages/` directory is in `pubspec.yaml` assets
2. Check `LocalizationService.instance.isLoaded` returns `true`
3. Look for initialization errors in console logs

### Hot Reload Issues

- JSON file changes require a full restart, not just hot reload
- After modifying JSON, stop the app and run again

## Performance Notes

- All translations are loaded once at app startup
- Translations are cached in memory
- No file I/O happens during runtime after initial load
- Minimal performance impact compared to hardcoded strings

## Future Enhancements

Potential improvements for the localization system:

1. **Lazy Loading**: Load translation modules on-demand
2. **Interpolation**: Support for dynamic values in translations
   - Example: "Hello {name}" with variable substitution
3. **Pluralization**: Handle singular/plural forms
4. **Additional Languages**: Easy to add Tamil, Hindi, etc.
5. **Translation Management**: Tools for managing translations
6. **Missing Translation Warnings**: Flag untranslated keys in debug mode

## Example: Migrating a Complete Screen

See the examples below for step-by-step migration guides for different screen types:

### Login Screen Migration

**File**: `lib/screens/auth/login_page.dart`

**Old Code (Lines to Replace)**:

```dart
final loginText = langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න";
final emailText = langProvider.currentLang == 'en' ? "Email" : "ඊමේල්";
final passwordText = langProvider.currentLang == 'en' ? "Password" : "මුරපදය";
```

**New Code**:

```dart
// Add import at top
import 'package:mamamind/utils/translate.dart';

// Replace in build method
Text(context.t.auth('login'))
decoration: InputDecoration(labelText: context.t.auth('email'))
decoration: InputDecoration(labelText: context.t.auth('password'))
```

This pattern can be applied to all screens throughout the app!
