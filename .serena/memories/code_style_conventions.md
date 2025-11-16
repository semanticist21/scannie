# Code Style and Conventions

## Linting
- Uses `package:flutter_lints/flutter.yaml` (standard Flutter lints)
- MUST pass `flutter analyze` with zero issues before committing

## Naming Conventions
- **Files**: snake_case (e.g., `edit_screen.dart`, `scan_document.dart`)
- **Classes**: PascalCase (e.g., `EditScreen`, `ScanDocument`)
- **Variables/Functions**: camelCase (e.g., `imagePaths`, `buildReorderableGrid`)
- **Private members**: prefix with `_` (e.g., `_imagePaths`, `_openCamera`)
- **Constants**: lowerCamelCase for local, SCREAMING_SNAKE_CASE for static const

## Import Organization
```dart
// 1. Dart core libraries
import 'dart:io';

// 2. Flutter libraries
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:path/path.dart' as path;  // REQUIRED: use 'as path' to avoid conflicts

// 4. Project imports
import '../theme/app_colors.dart';
import '../models/scan_document.dart';
```

## Widget Structure
- Prefer `const` constructors for performance
- Use `const` for static widgets whenever possible
- Extract complex widgets into separate methods (prefix with `_build`)

## State Management
- Currently using StatefulWidget with setState
- No external state management library (Riverpod, Provider, etc.)

## Code Organization Pattern
```dart
class MyScreen extends StatefulWidget {
  // 1. Constructor
  const MyScreen({super.key});
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // 2. State variables
  final List<String> _items = [];
  
  // 3. Lifecycle methods
  @override
  void initState() { super.initState(); }
  
  // 4. Build method
  @override
  Widget build(BuildContext context) { ... }
  
  // 5. Private helper methods
  void _handleAction() { ... }
  Widget _buildSection() { ... }
}
```

## Documentation
- No strict docstring requirements
- Inline comments for complex logic only
- Prefer self-documenting code names
