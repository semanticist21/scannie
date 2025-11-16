# Suggested Commands

## Development Workflow

### Device Management
```bash
flutter devices                    # List available devices
flutter run -d <device-id>         # Run on specific device
flutter run -d <device-id> --android-skip-build-dependency-validation  # Skip beta channel warnings
```

### Hot Reload/Restart
While app is running:
- `r` - Hot reload (faster, preserves state)
- `R` - Hot restart (full restart)
- `q` - Quit

### Code Quality (MANDATORY)
```bash
flutter analyze                    # MUST run after every code change
                                  # Target: "No issues found!"
```

### Dependency Management
```bash
flutter pub get                    # Install dependencies
flutter clean && flutter pub get   # Clean rebuild dependencies
```

### Build Commands
```bash
flutter build ios --debug --no-codesign   # iOS debug build
flutter build apk --debug                 # Android debug APK
```

### Testing
```bash
flutter test                       # Run all tests
flutter test test/path/to/test.dart  # Run single test file
```

## macOS-Specific Utilities
```bash
ls -la                            # List files with details
find . -name "*.dart" -type f     # Find Dart files
grep -r "pattern" lib/            # Search in lib directory
```
