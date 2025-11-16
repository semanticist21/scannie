# Architecture Patterns and Guidelines

## Design System (Theme System)
**MANDATORY**: All components MUST use theme constants instead of hardcoded values.

### Import Pattern
```dart
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
```

### Constants Reference
- **Spacing**: `AppSpacing.xs(4)`, `sm(8)`, `md(16)`, `lg(24)`, `xl(32)`, `xxl(48)`
- **Border Radius**: `AppRadius.sm(4)`, `md(8)`, `lg(16)`, `xl(24)`, `round(999)`
- **Colors**: `AppColors.primary`, `accent`, `surface`, `background`
- **Typography**: `AppTextStyles.h1`, `h2`, `bodyLarge`, `button`

## Material Design 3
- Use M3 native components: `FilledButton`, `SegmentedButton`, `Card`
- Avoid custom Material 2 widgets
- Follow M3 color system and elevation guidelines

## Navigation Pattern
Uses named routes with `onGenerateRoute` in main.dart:

```dart
case '/edit':
  return MaterialPageRoute(
    builder: (context) => const EditScreen(),
    settings: settings,  // CRITICAL: Required for arguments
  );
```

**Pass arguments**: `Navigator.pushNamed('/route', arguments: data)`
**Receive arguments**: `ModalRoute.of(context)?.settings.arguments as Type`

## Async/Context Pattern
**CRITICAL**: Never use BuildContext directly after async operations.

```dart
// ✅ CORRECT
Future<void> someFunction() async {
  final navigator = Navigator.of(context);
  await someAsyncOperation();
  if (!mounted) return;  // Check if widget still mounted
  navigator.pop();
}

// ❌ WRONG
Future<void> someFunction() async {
  await someAsyncOperation();
  Navigator.pop(context);  // Widget might be disposed!
}
```

## Safe Area Handling
Account for notches and gesture bars:

```dart
final bottomPadding = MediaQuery.of(context).padding.bottom;
padding: EdgeInsets.only(bottom: AppSpacing.md + bottomPadding)
```

## File Organization
```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── screens/               # Full-screen pages
├── widgets/common/        # Reusable widgets
├── theme/                 # Design system constants
├── services/              # Business logic (empty currently)
└── utils/                 # Helper functions (empty currently)
```

## Error Handling Pattern
- Use `debugPrint()` for logging (not `print()`)
- Show user-friendly messages with `fluttertoast` package
- Handle null cases from scanner (user cancellation)

## Performance Optimization
- Use `const` constructors everywhere possible
- Avoid rebuilding entire widget trees (extract widgets)
- Use `mainAxisSize: MainAxisSize.min` for Column/Row to prevent overflow
