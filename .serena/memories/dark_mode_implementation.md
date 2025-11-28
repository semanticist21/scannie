# Dark Mode Implementation (2025-11-28)

## 완료된 작업

### 1. ThemeService 생성
- `lib/services/theme_service.dart` - 테마 상태 관리 싱글톤
- SharedPreferences로 테마 설정 영구 저장
- `AppThemeMode` enum: system, light, dark
- `ValueNotifier<ThemeMode>` 사용하여 실시간 테마 변경

### 2. ThemedColors 헬퍼 클래스
- `lib/theme/app_theme.dart`에 추가
- 현재 테마에 맞는 색상 자동 반환
- 사용법: `final colors = ThemedColors.of(context);`
- 속성: `surface`, `background`, `textPrimary`, `textSecondary`, `textHint`, `border`, `error`

### 3. 다크모드 색상 정의
- `lib/theme/app_colors.dart`에 dark 색상 추가
- 다크모드 배경: `#171717` (neutral-900)
- 다크모드 surface: `#262626` (neutral-800)
- 다크모드 border: `#404040` (neutral-700)

### 4. 수정된 위젯 파일들 (ThemedColors 적용)

**공통 위젯:**
- `confirm_dialog.dart` - 제목 색상
- `rename_dialog.dart` - 제목 색상
- `text_input_dialog.dart` - 제목 색상
- `tag_dialog.dart` - 제목, "태그 색상" 레이블
- `pdf_options_sheet.dart` - 헤더, 옵션 레이블
- `context_menu_sheet.dart` - 제목

**갤러리 위젯:**
- `settings_sheet.dart` - 전체 (헤더, 섹션 제목, 옵션들)
- `document_grid_card.dart` - 문서 제목
- `premium_dialog.dart` - 배경, 제목, 설명, outline 버튼 배경

**뷰어 위젯:**
- `document_info_header.dart` - 문서 이름

### 5. 번역 변경
- `ko.json`: "appearance": "테마" (이전: "외관")

### 6. 테마 전환 UX
- SettingsSheet에서 테마 변경 시 자동으로 drawer 닫힘
- `_setThemeMode` 함수에 `Navigator.of(context).pop()` 추가

## 패턴: Text 색상 적용

```dart
// ❌ 다크모드에서 텍스트 안 보임
Text('Title', style: AppTextStyles.h3)

// ✅ 다크모드에서 제대로 보임
final colors = ThemedColors.of(context);
Text('Title', style: AppTextStyles.h3.copyWith(color: colors.textPrimary))
```

## 패턴: ShadButton.outline 배경색

다크모드에서 outline 버튼 테두리가 안 보이는 문제:
```dart
// ✅ 배경색 명시
ShadButton.outline(
  backgroundColor: colors.surface,
  child: Text('Cancel'),
)
```

## 커밋 이력
- `21d7476` - feat: add dark mode support with theme toggle
- (현재) - fix: premium dialog dark mode & settings sheet close on theme change
