# Localization Quick Reference

## Setup (Already Done)

✅ JSON files created in `languages/` directory
✅ LocalizationService implemented
✅ Translate helper created
✅ main.dart initialization complete

## Import This

```dart
import 'package:mamamind/utils/translate.dart';
```

## Basic Usage

### Display Text

```dart
// Old way ❌
langProvider.currentLang == 'en' ? "Login" : "ඇතුළු වන්න"

// New way ✅
context.t.auth('login')
```

### Check Language

```dart
// Old way ❌
final isSinhala = langProvider.currentLang == 'si';

// New way ✅
if (context.isSinhala) { ... }
if (context.isEnglish) { ... }
```

## All Modules

| Module         | Usage                             | Example                                 |
| -------------- | --------------------------------- | --------------------------------------- |
| common         | `context.t.common('key')`         | `context.t.common('loading')`           |
| auth           | `context.t.auth('key')`           | `context.t.auth('login')`               |
| home           | `context.t.home('key')`           | `context.t.home('welcome')`             |
| profile        | `context.t.profile('key')`        | `context.t.profile('settings')`         |
| chat           | `context.t.chat('key')`           | `context.t.chat('thinking')`            |
| questionnaires | `context.t.questionnaires('key')` | `context.t.questionnaires('score')`     |
| achievements   | `context.t.achievements('key')`   | `context.t.achievements('locked')`      |
| validators     | `context.t.validators('key')`     | `context.t.validators('emailRequired')` |

## Common Patterns

### AppBar Title

```dart
AppBar(title: Text(context.t.profile('profile')))
```

### Button Text

```dart
ElevatedButton(
  child: Text(context.t.common('cancel')),
  onPressed: () => ...,
)
```

### TextField Label

```dart
TextField(
  decoration: InputDecoration(
    labelText: context.t.auth('email'),
  ),
)
```

### Validation

```dart
validator: (val) {
  if (val == null || val.isEmpty) {
    return context.t.validators('emailRequired');
  }
  return null;
}
```

### Conditional Display

```dart
// Instead of checking isSinhala, just use the translation
Text(context.t.questionnaires('availableNow'))
```

### Dialog

```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(context.t.common('confirm')),
    content: Text(context.t.profile('deleteAccountWarning')),
    actions: [
      TextButton(
        child: Text(context.t.common('cancel')),
        onPressed: () => Navigator.pop(ctx),
      ),
      TextButton(
        child: Text(context.t.common('delete')),
        onPressed: () => _delete(),
      ),
    ],
  ),
)
```

## Top 20 Most Used Keys

### Common Module

- `cancel`, `confirm`, `ok`, `yes`, `no`
- `save`, `delete`, `edit`, `done`
- `next`, `previous`, `start`
- `loading`, `error`, `success`
- `logout`, `settings`

### Auth Module

- `login`, `signUp`, `email`, `password`
- `confirmPassword`, `fullName`
- `forgotPassword`, `rememberMe`
- `dontHaveAccount`, `alreadyHaveAccount`

### Validators Module

- `emailRequired`, `emailInvalid`
- `passwordRequired`, `passwordTooShort`
- `passwordsDoNotMatch`
- `nameRequired`

## Migration Steps

1. Add import: `import 'package:mamamind/utils/translate.dart';`
2. Find ternary: `langProvider.currentLang == 'en' ? "Text" : "පාඨය"`
3. Replace with: `context.t.module('key')`
4. Test both languages
5. Done! ✅

## Need More Detail?

See **LOCALIZATION_GUIDE.md** for comprehensive documentation.
