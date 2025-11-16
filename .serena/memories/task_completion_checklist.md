# Task Completion Checklist

## Before Committing

### 1. Code Quality (MANDATORY)
```bash
flutter analyze
```
**Target**: `No issues found!`

Common issues to fix:
- `avoid_print`: Use `debugPrint()` instead of `print()`
- `unused_field`: Remove unused variables
- `prefer_final_fields`: Mark immutable fields as `final`
- `argument_type_not_assignable`: Check API documentation for correct types

### 2. Code Review
- [ ] All widgets use `const` where possible
- [ ] Theme constants used (AppColors, AppSpacing, AppTextStyles, AppRadius)
- [ ] No deprecated Flutter APIs used (see Flutter API 주의사항 in CLAUDE.md)
- [ ] BuildContext not used after async gaps (store Navigator instance)
- [ ] `path` package imported as `import 'package:path/path.dart' as path;`

### 3. Testing
```bash
flutter test              # If tests exist
flutter run -d <device>   # Manual testing on device
```

### 4. Format (Optional)
```bash
dart format lib/          # Auto-format code (optional)
```

## Git Workflow
```bash
git status
git add .
git commit -m "descriptive message"
git push
```

## Platform-Specific Testing
- Test on both iOS and Android when possible
- Note platform differences (especially scanner mode behavior)
- Check Safe Area padding on devices with notches/gesture bars
