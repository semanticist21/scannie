# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 모바일 애플리케이션입니다. 네이티브 카메라로 문서를 스캔하고, CamScanner 스타일 필터를 적용하며, PDF로 내보낼 수 있습니다.

**핵심 기술**:
- Flutter 3.39.0-0.1.pre (beta), Dart 3.11.0, Material Design 3
- `cunning_document_scanner_plus` v1.0.3 (네이티브 iOS/Android 스캐너 + 필터/크롭)
- `shadcn_ui` (UI 컴포넌트 - ShadButton, ShadBadge, LucideIcons)
- `flutter_reorderable_grid_view` v5.4.0 (드래그 앤 드롭 순서 변경 + 가상화)
- `pdf` + `printing` (PDF 생성/공유 - Isolate 지원)
- `flutter_pdfview` v1.3.2 (PDF 미리보기)
- `flutter_image_compress` (PDF 품질별 이미지 압축)
- `image_cropper` v8.0.2 (이미지 크롭/회전 - uCrop + TOCropViewController)
- `image_picker` (앨범에서 이미지 가져오기)
- `elegant_notification` (토스트 알림)
- `share_plus` (파일 공유)
- `google_fonts` (커스텀 폰트)
- `easy_localization` v3.0.7 (다국어 지원)
- `google_mobile_ads` v6.0.0 (AdMob 전면 광고)

**현재 상태**:
- ✅ 문서 스캔 (네이티브 필터/크롭/회전 포함)
- ✅ **EditScreen 이미지 관리** (드래그앤드롭 순서 변경, 삭제, 추가)
- ✅ 세션 유지 (스캔 후 이미지 추가 가능)
- ✅ PDF 내보내기 (공유 + 다운로드)
- ✅ **PDF 옵션** (품질, 페이지 크기, 방향, 이미지 맞춤, 여백 - 문서별 저장)
- ✅ **PDF 다운로드** (MediaStore API - 권한 불필요)
- ✅ DocumentViewerScreen (페이지 갤러리, 전체 화면 뷰어)
- ✅ **FullScreenImageViewer 필터** (Original, B&W, Contrast, Brighten, Document, Sepia, Invert, Warm, Cool)
- ✅ **이미지 크롭/회전** (image_cropper - 네이티브 UI)
- ✅ **광고 수익화** (AdMob 전면 광고 - 새 스캔 저장 시 표시)
- ✅ **광고 제거 기능** ($2 일회성 구매)

## Quick Reference

```bash
# 앱 실행
flutter devices                # 사용 가능한 기기 확인
# ⚠️ IMPORTANT: Claude는 절대 flutter run을 자동 실행하지 마세요!
# 사용자가 직접 실행합니다!
# Hot Reload: r (빠름, 상태 유지)
# Hot Restart: R (전체 재시작)
# 종료: q

# 개발 도구
flutter analyze                # 린트 분석 (코드 수정 전/후 필수!)
flutter clean && flutter pub get  # 의존성 초기화

# 테스트 (현재 테스트 파일 없음)
# flutter test                          # 모든 테스트 실행
# flutter test test/path/to/test.dart   # 단일 테스트 파일 실행

# 빌드
flutter build apk --release           # Android 릴리스 APK
flutter build ios --release           # iOS 릴리스 빌드
flutter build appbundle               # Android App Bundle (Play Store)

# 빌드 경고 무시 (beta 채널)
flutter run -d <device-id> --android-skip-build-dependency-validation
```

**핵심 규칙**:
- ✅ shadcn_ui 컴포넌트 우선 (ShadButton, ShadBadge, LucideIcons)
- ✅ 테마 시스템 필수 (`AppSpacing`, `AppColors`, `AppTextStyles`)
- ✅ **`flutter analyze` 통과 필수** - 모든 코드 수정 후 실행하여 에러/경고 0개 확인!
- ⚠️ **Claude는 `flutter run` 절대 실행 금지** - 사용자가 직접 실행합니다!
- ❌ `Color.withOpacity()` 사용 금지 → `withValues(alpha:)` 사용
- ❌ Async gap 후 BuildContext 직접 사용 금지 → Navigator 인스턴스 저장
- ❌ path 패키지는 `import 'package:path/path.dart' as path;` 형식으로만
- ❌ `print()` 사용 금지 → `debugPrint()` 사용 (프로덕션 빌드에서 자동 제거)

## 토스트 알림 (AppToast)

**필수**: 모든 토스트는 `AppToast` 유틸리티를 사용합니다.

### 사용 패턴

```dart
import '../utils/app_toast.dart';

// 간편 사용 (권장)
AppToast.show(context, 'Document saved');
AppToast.show(context, 'Failed to save PDF', isError: true);

// 명시적 메서드
AppToast.success(context, 'Document saved');
AppToast.error(context, 'Failed to save PDF');
AppToast.info(context, 'Processing...');
```

### 토스트 표시 규칙

**에러만 표시하는 경우** (성공은 UI 변화로 충분):
- 이미지 추가 (Add Scan, Add Photo) - 그리드 업데이트가 시각적 피드백
- 이미지 삭제 - 즉시 그리드에서 제거됨
- 필터 저장 후 뒤로가기 - 이미지 변경이 시각적 피드백

**성공/에러 모두 표시하는 경우**:
- 문서 저장/이름 변경 - 사용자 확인 필요
- PDF 공유/다운로드 - 완료 알림 필요
- 문서 삭제 - 중요한 작업 확인

### 금지 사항

```dart
// ❌ WRONG - 다른 토스트 라이브러리 사용 금지
ShadToaster.of(context).show(ShadToast(...));
ScaffoldMessenger.of(context).showSnackBar(...);

// ❌ WRONG - ElegantNotification 직접 사용 금지
ElegantNotification.success(...).show(context);

// ✅ CORRECT - AppToast 유틸리티 사용
AppToast.show(context, 'Message');
AppToast.success(context, 'Success');
AppToast.error(context, 'Error');
```

## 다이얼로그 (공통 위젯 사용)

**필수**: 공통 다이얼로그 위젯을 우선 사용합니다.

### 공통 다이얼로그 위젯

| 위젯 | 용도 | 위치 |
|------|------|------|
| `ConfirmDialog` | 확인/삭제/폐기 다이얼로그 | `widgets/common/confirm_dialog.dart` |
| `RenameDialog` | 문서 이름 변경 | `widgets/common/rename_dialog.dart` |
| `TextInputDialog` | 텍스트 입력 (새 문서 생성 등) | `widgets/common/text_input_dialog.dart` |

### 사용 패턴

```dart
// 확인 다이얼로그
import '../widgets/common/confirm_dialog.dart';

ConfirmDialog.show(
  context: context,
  title: 'Delete Scan',
  message: 'Delete "${document.name}"?',
  confirmText: 'Delete',
  isDestructive: true,
  onConfirm: () async {
    await deleteDocument();
  },
);

// Async 버전 (결과 반환)
final confirmed = await ConfirmDialog.showAsync(
  context: context,
  title: 'Discard Changes?',
  message: 'Your changes will not be saved.',
  confirmText: 'Discard',
  isDestructive: true,
);
if (confirmed) { /* ... */ }

// 이름 변경 다이얼로그
import '../widgets/common/rename_dialog.dart';

RenameDialog.show(
  context: context,
  currentName: document.name,
  onSave: (newName) async {
    await renameDocument(newName);
  },
);

// 텍스트 입력 다이얼로그
import '../widgets/common/text_input_dialog.dart';

TextInputDialog.show(
  context: context,
  title: 'Save Scan',
  description: 'Enter a name for this scan',
  initialValue: 'Scan 2024-01-01',
  onSave: (name) async {
    await saveDocument(name);
  },
);
```

### 파일명 유효성 검사 (자동 적용)

`RenameDialog`와 `TextInputDialog`에는 파일명 유효성 검사가 내장되어 있습니다:

- **최대 길이**: 100자
- **금지 문자**: `/ \ : * ? " < > |`
- **빈 이름 불가**
- **실시간 글자 수 표시**: `현재글자수 / 100`

### 버튼 스타일 가이드

- **일반 확인**: `ShadButton` (Primary)
- **취소**: `ShadButton.outline`
- **삭제/위험 액션**: `ShadButton.destructive`

### 금지 사항

```dart
// ❌ WRONG - 기본 AlertDialog 사용 금지
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);

// ❌ WRONG - 중복 다이얼로그 구현
DialogBackground(...).show(context); // 공통 위젯이 있는 경우

// ✅ CORRECT - 공통 위젯 사용
ConfirmDialog.show(...);
RenameDialog.show(...);
TextInputDialog.show(...);
```

## Flutter API 주의사항

### 🚫 절대 사용 금지 (Deprecated in Flutter 3.27+)

#### 1. Color.withOpacity()
```dart
// ❌ WRONG
Colors.white.withOpacity(0.5)

// ✅ CORRECT
Colors.white.withValues(alpha: 0.5)
```

#### 2. Async Gap에서 BuildContext 직접 사용
```dart
// ❌ WRONG - Widget이 dispose될 수 있음
Future<void> someFunction() async {
  await someAsyncOperation();
  Navigator.pop(context); // 위험!
}

// ✅ CORRECT - Navigator 인스턴스 저장
Future<void> someFunction() async {
  final navigator = Navigator.of(context);
  await someAsyncOperation();
  if (!mounted) return;
  navigator.pop();
}
```

#### 3. showDialog context 변수명 충돌
```dart
// ❌ WRONG
showDialog(
  context: context,
  builder: (context) => AlertDialog(...) // 같은 이름
);

// ✅ CORRECT
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(...) // 다른 이름
);
```

#### 4. path 패키지 import 충돌
```dart
// ❌ WRONG - dart:io와 충돌
import 'package:path/path.dart';

// ✅ CORRECT
import 'package:path/path.dart' as path;
```

#### 5. print() 사용 (프로덕션 코드에서)
```dart
// ❌ WRONG - 프로덕션 빌드에서도 출력됨
print('Debug message');

// ✅ CORRECT - 디버그 빌드에서만 출력
debugPrint('Debug message');
```

**이유**: `print()`는 프로덕션 빌드에서도 실행되어 성능 저하 및 로그 노출 위험. `debugPrint()`는 디버그 모드에서만 동작하고 릴리스 빌드에서 자동 제거됨.

## 코드 품질 관리

### flutter analyze 필수 실행

**모든 코드 수정 후 반드시 실행**:
```bash
flutter analyze
```

**목표**: `No issues found!` 달성

**일반적인 이슈**:
- `avoid_print`: print() 대신 debugPrint() 사용
- `unused_field`: 사용하지 않는 필드 제거
- `prefer_final_fields`: 변경되지 않는 필드는 final 선언
- `argument_type_not_assignable`: 잘못된 타입 전달 (API 문서 확인)

**예시**:
```bash
# ✅ Good
flutter analyze
# Analyzing scannie...
# No issues found! (ran in 1.6s)

# ❌ Bad
flutter analyze
# 35 issues found. (ran in 1.8s)
# error • The argument type 'VecPoint2f' can't be assigned...
```

## 아키텍처

### 상태 관리

**현재 패턴**: StatefulWidget + setState (외부 상태 관리 라이브러리 사용 안 함)

### Import 순서 규칙

```dart
// 1. Dart 코어 라이브러리
import 'dart:io';

// 2. Flutter 라이브러리
import 'package:flutter/material.dart';

// 3. 서드파티 패키지
import 'package:path/path.dart' as path;  // path는 반드시 'as path' 사용!

// 4. 프로젝트 임포트
import '../theme/app_colors.dart';
import '../models/scan_document.dart';
```

### 디렉토리 구조

```
lib/
├── screens/          # 3개 화면
│   ├── gallery_screen.dart          # 홈, 문서 리스트/그리드, PDF 공유/다운로드
│   ├── edit_screen.dart              # 이미지 관리 (드래그앤드롭 순서, 삭제, 추가)
│   └── document_viewer_screen.dart   # 페이지 갤러리, 전체 화면 뷰어
├── widgets/common/   # 재사용 위젯
│   ├── scan_card.dart              # 문서 카드 (GalleryScreen 그리드)
│   ├── document_grid_card.dart     # 문서 그리드 카드 (대체 레이아웃)
│   ├── page_card.dart              # 개별 페이지 카드 (DocumentViewer)
│   ├── image_tile.dart             # EditScreen 이미지 타일
│   ├── custom_app_bar.dart         # 커스텀 AppBar
│   ├── custom_fab.dart             # 커스텀 FAB 컴포넌트
│   ├── custom_icon_button.dart     # 커스텀 아이콘 버튼
│   ├── context_menu_sheet.dart     # 공통 컨텍스트 메뉴 (bottom sheet)
│   ├── pdf_options_sheet.dart      # PDF 옵션 설정 시트
│   ├── quality_selector_sheet.dart # PDF 품질 선택 시트
│   ├── settings_sheet.dart         # 앱 설정 시트
│   ├── edit_bottom_actions.dart    # EditScreen 하단 액션 버튼
│   ├── document_info_header.dart   # 문서 정보 헤더
│   ├── empty_state.dart            # 빈 상태 표시 위젯
│   ├── full_screen_image_viewer.dart # 이미지 뷰어 + 필터 + 저장
│   ├── confirm_dialog.dart         # 공통 확인 다이얼로그
│   ├── rename_dialog.dart          # 이름 변경 다이얼로그
│   ├── text_input_dialog.dart      # 텍스트 입력 다이얼로그
│   └── premium_dialog.dart         # 프리미엄 기능 다이얼로그
├── services/         # 비즈니스 로직
│   ├── document_storage.dart         # 문서 영구 저장/로드
│   ├── pdf_generator.dart            # PDF 생성 (Isolate 지원)
│   ├── pdf_settings_service.dart     # PDF 기본 설정 관리
│   └── ad_service.dart               # AdMob 광고 관리 (싱글톤)
├── theme/            # 디자인 시스템
│   ├── app_theme.dart        # M3 ThemeData 구성
│   ├── app_colors.dart       # 색상 팔레트
│   └── app_text_styles.dart  # 타이포그래피
├── utils/            # 유틸리티
│   └── app_toast.dart        # 토스트 알림 유틸리티
└── models/
    ├── scan_document.dart    # ScanDocument + PDF 옵션 enums
    ├── context_menu_item.dart # 컨텍스트 메뉴 아이템 모델
    └── image_filter_type.dart # 이미지 필터 타입 enum
```

### 위젯 책임 분리

| 위젯 | 용도 | 사용 화면 |
|------|------|-----------|
| `scan_card.dart` | 문서 카드 (리스트/그리드 뷰) | GalleryScreen |
| `document_grid_card.dart` | 대체 그리드 카드 레이아웃 | GalleryScreen |
| `page_card.dart` | 단일 페이지 썸네일 카드 | DocumentViewerScreen |
| `image_tile.dart` | 드래그 가능한 이미지 타일 | EditScreen |
| `pdf_options_sheet.dart` | PDF 옵션 설정 바텀 시트 | GalleryScreen, DocumentViewer |
| `settings_sheet.dart` | 앱 설정 (기본 PDF 옵션) | GalleryScreen |
| `edit_bottom_actions.dart` | 저장/추가 버튼 그룹 | EditScreen |
| `empty_state.dart` | 빈 문서 목록 상태 표시 | GalleryScreen |
| `confirm_dialog.dart` | 확인/삭제/폐기 다이얼로그 | 전체 화면 |
| `rename_dialog.dart` | 문서 이름 변경 | GalleryScreen, DocumentViewer |
| `text_input_dialog.dart` | 텍스트 입력 (새 문서 등) | GalleryScreen, EditScreen |
| `premium_dialog.dart` | 프리미엄 기능 안내 | 전체 화면 |

### 테마 시스템 (필수)

모든 위젯은 테마 상수를 사용해야 합니다:

```dart
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

// 간격: AppSpacing.xs(4) / sm(8) / md(16) / lg(24) / xl(32) / xxl(48)
// Border Radius: AppRadius.sm(4) / md(8) / lg(16) / xl(24) / round(999)
// 색상: AppColors.primary / accent / surface / background
// 타이포그래피: AppTextStyles.h1 / h2 / bodyLarge / button
```

### 네비게이션 플로우

```
GalleryScreen (홈)
  → Scan 버튼 → CunningDocumentScanner.getPictures(mode: ScannerMode.full)
      → Android: Enhance/Clean/Filter 버튼 제공 (네이티브 UI)
      → iOS: 기본 자동 처리 (mode 파라미터 무시됨)
      → '/edit' → EditScreen (arguments: List<String> imagePaths)
          ├─ 이미지 카드 탭 → 전체 화면 뷰어 (0.5x~4.0x 줌)
          ├─ 드래그앤드롭으로 순서 변경 (PDF 페이지 순서)
          ├─ 삭제 (X 버튼, 최소 1개 유지)
          ├─ "Add More" → 스캐너 재호출 → 세션에 추가
          └─ Save → pushReplacementNamed('/viewer') → DocumentViewerScreen
              (GalleryScreen은 RouteAware.didPopNext()로 문서 리로드)

  → 문서 카드 탭 → '/viewer' → DocumentViewerScreen
      ├─ 그리드/리스트 뷰 전환
      ├─ 페이지 탭 → FullScreenImageViewer (InteractiveViewer 줌)
      └─ PDF 버튼 → "PDF export is available from the gallery" 안내

  → 문서 카드 메뉴:
      ├─ Share → _exportToPdf() → 시스템 공유 시트 (A4 PDF)
      └─ Download → _savePdfLocally() → MediaStore API (Downloads/Scannie/)
```

### 라우트 패턴 및 주의사항

#### 🚨 핵심 주의사항: Race Condition 방지

**다이얼로그/시트에서 async 작업 후 pop() 할 때 반드시 이 순서를 따르세요:**

```dart
// ✅ CORRECT - onSave를 pop BEFORE에 호출
onSave: (value) async {
  await saveData(value);  // 1. 먼저 저장
  Navigator.pop(context);  // 2. 그 다음 pop
},

// ❌ WRONG - pop 후 저장하면 didPopNext와 race condition 발생
onSave: (value) {
  Navigator.pop(context);  // pop이 먼저 되면
  saveData(value);         // GalleryScreen.didPopNext()와 경쟁
},
```

**이유**: `pop()`이 먼저 실행되면 GalleryScreen의 `didPopNext()`가 즉시 호출되어 아직 저장되지 않은 데이터를 로드할 수 있음.

#### 네비게이션 메서드 선택 가이드

| 상황 | 메서드 | 예시 |
|------|--------|------|
| 화면 이동 (뒤로가기 가능) | `pushNamed` | Gallery → Viewer |
| 화면 교체 (스택에서 제거) | `pushNamedAndRemoveUntil` | Edit → Viewer (Edit 제거) |
| 이전 화면으로 복귀 | `pop` | Viewer → Gallery |
| 결과 반환하며 복귀 | `pop(result)` | Edit → Gallery with document |

```dart
// EditScreen에서 저장 후 DocumentViewerScreen으로 이동
// EditScreen은 스택에서 제거되어 Viewer에서 뒤로가면 Gallery로 감
navigator.pushNamedAndRemoveUntil(
  '/viewer',
  ModalRoute.withName('/'),  // '/'까지만 남김 (GalleryScreen)
  arguments: newDocument,
);
```

#### RouteAware 패턴 (화면 복귀 시 데이터 리로드)

GalleryScreen은 `RouteAware`를 사용하여 다른 화면에서 돌아올 때 문서 목록을 자동으로 리로드합니다:

```dart
// main.dart
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// GalleryScreen
import '../main.dart' show routeObserver;

class _GalleryScreenState extends State<GalleryScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 화면에서 돌아올 때 호출
    _loadDocuments();
  }
}
```

#### PopScope로 뒤로가기 제어 (확인 다이얼로그)

EditScreen은 사용자가 실수로 나가는 것을 방지합니다:

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,  // 시스템 뒤로가기 차단
    onPopInvokedWithResult: (bool didPop, dynamic result) async {
      if (didPop) return;  // 이미 pop 되었으면 무시

      // 확인 다이얼로그 표시
      final shouldPop = await _confirmDiscard();
      if (shouldPop && mounted) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(...),
  );
}
```

#### 라우트 설정 필수 패턴

```dart
// main.dart의 onGenerateRoute
case '/edit':
  return MaterialPageRoute(
    builder: (context) => const EditScreen(),
    settings: settings, // ⚠️ arguments 전달을 위해 필수!
  );

case '/viewer':
  final document = settings.arguments as ScanDocument?;
  if (document == null) {
    return MaterialPageRoute(
      builder: (context) => const GalleryScreen(),
    );
  }
  return MaterialPageRoute(
    builder: (context) => DocumentViewerScreen(document: document),
  );
```

**`settings` 없이는 `ModalRoute.of(context)?.settings.arguments`가 null 반환!**

#### 일반적인 라우트 실수들

```dart
// ❌ WRONG - context 캡처 후 async gap에서 사용
onPressed: () async {
  await saveData();
  Navigator.pop(context);  // context가 유효하지 않을 수 있음
}

// ✅ CORRECT - Navigator 인스턴스 먼저 저장
onPressed: () async {
  final navigator = Navigator.of(context);
  await saveData();
  if (mounted) navigator.pop();
}

// ❌ WRONG - pushReplacementNamed 사용 (RouteAware 동작 안 함)
navigator.pushReplacementNamed('/viewer', arguments: doc);

// ✅ CORRECT - pushNamedAndRemoveUntil 사용
navigator.pushNamedAndRemoveUntil(
  '/viewer',
  ModalRoute.withName('/'),
  arguments: doc,
);
```

**`pushReplacementNamed` vs `pushNamedAndRemoveUntil`**:
- `pushReplacementNamed`: 현재 라우트만 교체, `didPopNext()` 호출 안 됨
- `pushNamedAndRemoveUntil`: 여러 라우트 제거 가능, 남은 라우트의 `didPopNext()` 정상 동작

## EditScreen 기능

### 개요

EditScreen은 스캔된 이미지를 관리하는 화면입니다. **필터/크롭/회전은 네이티브 스캐너에서 처리**하므로 EditScreen에서는 이미지 순서 관리만 담당합니다.

### 주요 기능

1. **전체 화면 이미지 뷰어** (`InteractiveViewer`)
   - 이미지 카드 탭 → 전체 화면으로 확대
   - 핀치 줌: 0.5x ~ 4.0x (더블 탭 지원)
   - 팬/드래그로 확대된 이미지 이동
   - AppBar에 페이지 번호 표시 (Page 2 / 5)

2. **드래그 앤 드롭 순서 변경** (`flutter_reorderable_grid_view`)
   - 2열 그리드 레이아웃 (A4 비율 210:297)
   - 드래그하여 이미지 순서 변경 (PDF 페이지 순서)
   - 각 카드에 페이지 번호 표시
   - **가상화 지원**: 화면에 보이는 이미지만 렌더링 (메모리 효율적)

3. **이미지 삭제**
   - 각 카드 우측 상단에 X 버튼
   - 마지막 이미지는 삭제 불가 (최소 1개 유지)
   - 성공 시 토스트 없음 (조용한 삭제)

4. **이미지 추가 (세션 유지)**
   - "Add More" 버튼으로 스캐너 재호출
   - 새로 스캔한 이미지를 현재 리스트에 추가
   - 스캔 세션 중단 없이 이미지 추가 가능

5. **저장**
   - Save 버튼으로 `ScanDocument` 생성
   - `DocumentStorage.saveDocuments()`로 영구 저장
   - `pushReplacementNamed('/viewer')`로 DocumentViewerScreen으로 직접 이동
   - GalleryScreen은 `didPopNext()`로 자동 리로드

### 제거된 기능 (네이티브 스캐너로 이동)

다음 기능들은 `cunning_document_scanner_plus`의 네이티브 UI에서 처리하므로 EditScreen에서 제거되었습니다:

- ❌ **필터** (B&W, Enhanced, Grayscale, Lighten) → `ScannerMode.full`에서 처리
- ❌ **밝기/대비 조정** → Android: Enhance 버튼 / iOS: 자동
- ❌ **회전** → 네이티브 회전 기능 사용
- ❌ **Crop/모서리 조정** → 네이티브 자동 edge 감지 + 원근 보정
- ❌ **얼룩 제거** → Android: Clean 버튼 (브러시로 수동) / iOS: 없음

### 코드 예시

```dart
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

// State에 추가
final _scrollController = ScrollController();
final _gridViewKey = GlobalKey();

@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}

Widget _buildReorderableGrid() {
  final generatedChildren = _imagePaths.asMap().entries.map((entry) {
    final index = entry.key;
    final imagePath = entry.value;
    return ImageTile(
      key: ValueKey(imagePath),
      index: index,
      imagePath: imagePath,
      onTap: () => _viewImage(imagePath, index),
      onDelete: () => _deleteImage(index),
    );
  }).toList();

  return ReorderableBuilder(
    scrollController: _scrollController,
    onReorder: (ReorderedListFunction reorderedListFunction) {
      setState(() {
        _imagePaths = reorderedListFunction(_imagePaths) as List<String>;
      });
    },
    children: generatedChildren,
    builder: (children) {
      return GridView(
        key: _gridViewKey,
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 210 / 297, // A4 ratio
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: children,
      );
    },
  );
}
```

## FullScreenImageViewer 필터 기능

### 개요

FullScreenImageViewer는 이미지를 전체 화면으로 보고, Flutter 내장 `ColorFiltered`를 사용한 필터를 적용하여 저장할 수 있는 위젯입니다.

### 사용 가능한 필터

| 필터 | 설명 | Color Matrix |
|------|------|--------------|
| Original | 원본 이미지 | null |
| B&W (Grayscale) | 흑백 변환 | Luminosity matrix |
| High Contrast | 대비 강화 | 1.5x + -40 offset |
| Brighten | 밝기 증가 | +30 offset |
| Document | 문서 스캔용 | 1.8x + -60 offset |

### 구현 패턴

```dart
// ColorFilter.matrix를 사용한 필터 적용
ColorFilter? _getColorFilter() {
  switch (_currentFilter) {
    case ImageFilterType.grayscale:
      return const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    // ... 다른 필터들
  }
}

// ColorFiltered 위젯으로 적용
ColorFiltered(
  colorFilter: colorFilter,
  child: Image.file(imageFile),
)
```

### 필터된 이미지 저장

```dart
// dart:ui를 사용한 이미지 렌더링
final recorder = ui.PictureRecorder();
final canvas = Canvas(recorder);
final paint = Paint()..colorFilter = _getColorFilter();
canvas.drawImage(image, Offset.zero, paint);
final filteredImage = await picture.toImage(width, height);

// PNG로 변환 후 갤러리에 저장
final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
await ImageGallerySaverPlus.saveFile(tempFile.path);
```

### 필터 저장 시 토스트

필터 적용 후 저장 시 `AppToast` 유틸리티를 사용합니다 (ElegantNotification 직접 사용 금지):

```dart
AppToast.success(context, 'Image saved to gallery');
```

### 이미지 크롭/회전 (image_cropper)

FullScreenImageViewer에서 `image_cropper` 패키지를 사용하여 네이티브 크롭/회전 UI를 제공합니다.

**주요 특징**:
- 임시 파일 방식: 크롭 결과는 Save 버튼 누를 때까지 임시 파일로 저장
- Android: uCrop 라이브러리 사용 (FlutterFragmentActivity 필수)
- iOS: TOCropViewController 사용

**구현 패턴**:

```dart
import 'package:image_cropper/image_cropper.dart';

Future<void> _cropAndRotateImage() async {
  final sourcePath = _tempRotatedImagePath ?? widget.imagePaths[_currentPage];

  final croppedFile = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Rotate',
        toolbarColor: AppColors.darkBackground,
        toolbarWidgetColor: Colors.white,
        statusBarLight: false,
        backgroundColor: AppColors.darkBackground,
        dimmedLayerColor: Colors.black.withValues(alpha: 0.7),
        activeControlsWidgetColor: AppColors.primary,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
        hideBottomControls: false,
        showCropGrid: true,
        cropFrameStrokeWidth: 2,
        aspectRatioPresets: [CropAspectRatioPreset.original],
      ),
      IOSUiSettings(
        title: 'Rotate',
        doneButtonTitle: 'Save',
        cancelButtonTitle: 'Cancel',
        aspectRatioLockEnabled: false,
        resetAspectRatioEnabled: false,
        rotateButtonsHidden: false,
        rotateClockwiseButtonHidden: false,
        aspectRatioPickerButtonHidden: true,
        hidesNavigationBar: false,
        showCancelConfirmationDialog: false,
        aspectRatioLockDimensionSwapEnabled: false,
      ),
    ],
  );

  if (croppedFile != null) {
    _tempRotatedImagePath = croppedFile.path;
    imageCache.clear();
    imageCache.clearLiveImages();
    setState(() {});
  }
}
```

**Android 설정 필수사항**:

1. `MainActivity.kt`를 `FlutterFragmentActivity`로 변경:
```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

2. `AndroidManifest.xml`에 UCropActivity 추가:
```xml
<!-- UCrop Activity for image_cropper -->
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

**주의사항**:
- `aspectRatioPresets`는 최소 1개 필요 (빈 배열 시 crash)
- `statusBarColor`는 deprecated → `statusBarLight` 사용
- iOS는 시스템 색상 사용 (색상 커스터마이징 불가)

## 문서 스캔 (cunning_document_scanner_plus)

### 주요 기능

- **네이티브 스캐너**: iOS VNDocumentCameraViewController + Android Intents
- **네이티브 필터**: `ScannerMode.filters`로 스캔 중 필터 적용 가능
- **자동 Edge 감지**: 문서 테두리 실시간 인식
- **원근 보정**: 비스듬한 각도 자동 평탄화
- **갤러리 import**: 기존 사진에서도 문서 추출
- **다중 페이지**: 여러 페이지 연속 스캔

### 사용 방법

```dart
import 'package:cunning_document_scanner_plus/cunning_document_scanner_plus.dart';

// 스캔 실행 (GalleryScreen._openCamera)
final scannedImages = await CunningDocumentScanner.getPictures(
  mode: ScannerMode.filters, // full, filters, base 중 선택
) ?? [];

if (scannedImages.isEmpty) return; // 사용자 취소

// EditScreen으로 이동
final navigator = Navigator.of(context);
final result = await navigator.pushNamed('/edit', arguments: scannedImages);
```

**3가지 스캐너 모드** (현재: `ScannerMode.full`):

| Mode | Android (Google ML Kit) | iOS (VNDocumentCamera) |
|------|-------------------------|------------------------|
| `ScannerMode.full` | ✅ 모든 기능 (Enhance + Clean + Filters) | ⚠️ 기본 기능만 (mode 파라미터 무시됨) |
| `ScannerMode.filters` | ✅ 필터 + 기본 기능 | ⚠️ 기본 기능만 |
| `ScannerMode.base` | ✅ 기본 스캔만 (필터 UI 없음) | ⚠️ 기본 기능만 |

**Android `ScannerMode.full` 기능** (Google ML Kit):
- ✨ **Enhance**: 원탭 자동 이미지 개선 (white balance, 그림자 제거, 대비 향상, 샤프닝)
- 🖌️ **Clean**: 브러시로 얼룩 수동 제거 (커피 얼룩, 손가락 자국, 주름 AI 제거)
- 🎨 **Filters**: Grayscale, Auto-enhance 등 수동 선택
- 📋 모든 기능은 스캔 후 Preview 화면에서 **사용자가 직접 버튼 눌러서** 사용
- ⚠️ **자동 적용되지 않음** - Edge 감지/Crop/원근 보정만 자동

**iOS 제약사항** (Apple VNDocumentCameraViewController):
- ❌ `mode` 파라미터 완전히 무시됨
- ❌ 수동 필터 선택 불가 (Apple이 자동으로 최적화)
- ❌ Enhance, Clean 기능 없음
- ✅ 자동 Edge 감지, Crop, 원근 보정만 제공

**공통 제약사항**:
- 네이티브 UI는 커스터마이징 불가 (iOS/Android 기본 UI)
- 기본 필터 값 전달 불가 (사용자가 직접 선택)
- 세션 재개 불가 (한 번 호출 → 완료 → 결과 반환으로 끝)
- `noOfPages`, `isGalleryImportAllowed` 파라미터는 Android에서만 동작

## PDF 내보내기

### 개요

앱은 두 가지 내보내기 방식과 문서별 PDF 옵션을 제공합니다:

1. **Share** (공유): `Printing.sharePdf()` - 시스템 공유 시트
2. **Download** (다운로드): MediaStore API - Downloads/Scannie/ 폴더

### PDF 옵션 시스템

`ScanDocument`에 5가지 PDF 옵션이 저장됩니다 (문서별 영구 저장):

| 옵션 | enum | 값 | 기본값 |
|------|------|-----|--------|
| 품질 | `PdfQuality` | low, medium, high, original | medium |
| 페이지 크기 | `PdfPageSize` | a4, letter, legal | a4 |
| 방향 | `PdfOrientation` | portrait, landscape | portrait |
| 이미지 맞춤 | `PdfImageFit` | contain, cover, fill | contain |
| 여백 | `PdfMargin` | none, small, medium, large, xl | medium |

```dart
// 문서별 PDF 옵션
final document = ScanDocument(
  // ...
  pdfQuality: PdfQuality.medium,
  pdfPageSize: PdfPageSize.a4,
  pdfOrientation: PdfOrientation.portrait,
  pdfImageFit: PdfImageFit.contain,
  pdfMargin: PdfMargin.medium,
);
```

### PDF 품질 설정

| 품질 | JPEG Quality | Max Dimension | 압축률 |
|------|-------------|---------------|--------|
| Low | 60 | 1024px | ~20% |
| Medium | 75 | 1536px | ~50% |
| High | 85 | 2048px | ~95% |
| Original | 100 | 원본 | 100% |

### PDF Generator 서비스

`PdfGenerator`는 Isolate를 사용하여 백그라운드에서 PDF를 생성합니다:

```dart
import 'services/pdf_generator.dart';

// PDF 생성 (Isolate에서 실행)
final pdfFile = await PdfGenerator.generatePdf(
  imagePaths: document.imagePaths,
  documentName: document.name,
  quality: document.pdfQuality,
  pageSize: document.pdfPageSize,
  orientation: document.pdfOrientation,
  imageFit: document.pdfImageFit,
  margin: document.pdfMargin,
);
```

**Isolate 사용 이유**: PDF 생성은 CPU 집약적 작업이므로 메인 스레드 블로킹 방지

**이미지 압축**: `flutter_image_compress` 패키지로 품질별 JPEG 압축

### PDF 기본 설정 서비스

`PdfSettingsService`는 앱 전역 기본 PDF 설정을 관리합니다:

```dart
import 'services/pdf_settings_service.dart';

// 싱글톤 인스턴스 가져오기
final settings = await PdfSettingsService.getInstance();

// 기본값 읽기
final defaultQuality = settings.defaultQuality;
final defaultPageSize = settings.defaultPageSize;

// 기본값 설정
await settings.setDefaultQuality(PdfQuality.high);
await settings.setDefaultPageSize(PdfPageSize.letter);
```

### PDF 옵션 시트 사용

```dart
import '../widgets/common/pdf_options_sheet.dart';

PdfOptionsSheet.show(
  context: context,
  quality: document.pdfQuality,
  pageSize: document.pdfPageSize,
  orientation: document.pdfOrientation,
  imageFit: document.pdfImageFit,
  margin: document.pdfMargin,
  onSave: (quality, pageSize, orientation, imageFit, margin) async {
    // 문서 업데이트 및 저장
    final updated = document.copyWith(
      pdfQuality: quality,
      pdfPageSize: pageSize,
      pdfOrientation: orientation,
      pdfImageFit: imageFit,
      pdfMargin: margin,
    );
    await DocumentStorage.updateDocument(updated);
  },
);
```

### Android MediaStore API 사용

**Why MediaStore?**
- ✅ **권한 불필요**: `MANAGE_EXTERNAL_STORAGE` 같은 특수 권한 없이 Downloads 폴더 접근
- ✅ **Android 10+ 호환**: Scoped Storage 정책 준수
- ✅ **Google Play 승인 불필요**: 위험한 권한 요구하지 않음

**사용 패키지**: `media_store_plus: ^0.1.3`

### 구현 패턴

```dart
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_manager/open_file_manager.dart';

Future<void> _savePdfLocally() async {
  try {
    // 1. PDF 생성
    final pdf = pw.Document();
    // ... 페이지 추가 ...
    final pdfBytes = await pdf.save();

    // 2. 임시 파일로 저장
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'filename.pdf'));
    await tempFile.writeAsBytes(pdfBytes);

    // 3. MediaStore 초기화
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Scannie';

    // 4. Downloads 폴더에 복사 (권한 불필요!)
    final mediaStore = MediaStore();
    final saveInfo = await mediaStore.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: FilePath.root, // Downloads 폴더 루트
    );

    debugPrint('PDF saved to MediaStore: ${saveInfo?.uri}');

    // 5. 파일 매니저 열기
    await openFileManager();
  } catch (e) {
    debugPrint('Error saving PDF: $e');
  }
}
```

### 주요 포인트

1. **임시 파일 필수**: MediaStore는 기존 파일을 복사하는 방식으로 동작
2. **초기화 필수**: `MediaStore.ensureInitialized()` 먼저 호출
3. **앱 폴더 설정**: `MediaStore.appFolder` 설정으로 Downloads/Scannie 경로 생성
4. **Hot Restart 필수**: 네이티브 플러그인 등록을 위해 hot reload가 아닌 full restart 필요

### 플러그인 Gradle 호환성 이슈

일부 Flutter 플러그인은 구버전 Gradle 설정을 사용하여 빌드 에러 발생:

```
Namespace not specified. Specify a namespace in the module's build file
```

**해결 방법**:
```dart
// 플러그인 AndroidManifest.xml에서 package 속성 제거
// 예: /Users/semanticist/.pub-cache/hosted/pub.dev/media_store_plus-0.1.3/android/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- package="..." 제거 -->
</manifest>

// 플러그인 build.gradle에 namespace 추가
android {
    namespace 'com.snnafi.media_store_plus'  // 추가
    compileSdk 33
    // ...
}
```

**영향받는 플러그인**:
- `media_store_plus` v0.1.3
- `open_file_manager` v0.0.2

⚠️ **주의**: `.pub-cache` 수정은 `flutter clean` 후 재설정 필요!

### 권한 관련

**필요 없는 권한**:
- ❌ `MANAGE_EXTERNAL_STORAGE` - MediaStore API는 불필요
- ❌ 런타임 권한 요청 - 사용자 다이얼로그 없음

**AndroidManifest.xml 설정**:
```xml
<!-- Android 13+ 미디어 접근 (MediaStore API와 무관) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Android 10-12 스토리지 (maxSdkVersion 주의) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

## 문제 해결

### 이미지가 EditScreen에 표시되지 않을 때

**증상**: EditScreen이 빈 화면 또는 placeholder만 표시

**원인**: main.dart 라우트에서 `settings` 누락

**해결**:
```dart
case '/edit':
  return MaterialPageRoute(
    builder: (context) => const EditScreen(),
    settings: settings, // 이 줄 필수!
  );
```

**디버그 로그**:
```
📸 Scanned 2 images: /path/to/image.png
🔍 EditScreen - Received arguments: [/path/...] (type: List<String>)
🖼️ _loadCurrentImage: Loading image 1/2
✓ Image loaded: 1920x1080
```

null arguments가 보이면 `settings: settings` 누락 확인!

### 빌드 실패 시

```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

### iOS Pod 관련 빌드 에러

**증상**: `No podspec found for 'xxx' in '.'` 또는 `Build input file cannot be found`

**원인**: pubspec.yaml에서 패키지를 제거했지만 ios/Podfile에 참조가 남아있음

**해결**:
1. `ios/Podfile` 확인 - 제거된 패키지 참조가 있는지 검사
2. `post_install` 섹션에서도 해당 패키지 관련 설정 제거
3. 캐시 정리 후 재빌드:
```bash
rm -rf ios/.symlinks ios/Pods ios/Podfile.lock
flutter clean && flutter pub get
flutter run -d <device-id>
```

**⚠️ 재발 방지**: pubspec.yaml에서 패키지 제거 시 반드시 ios/Podfile도 함께 확인!

### RenderFlex Overflow

Column/Row에 `mainAxisSize: MainAxisSize.min` 추가:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [...]
)
```

### const 최적화

성능 향상을 위해 모든 위젯에 `const` 사용:

```dart
// ✅ Good
const Text('Title', style: AppTextStyles.h2)

// ❌ Bad
Text('Title', style: AppTextStyles.h2)
```

### Safe Area 패딩 처리

iOS/Android의 홈 인디케이터 영역(notch, gesture bar)에 대응하려면 `MediaQuery.padding.bottom` 사용:

```dart
Widget _buildBottomActions() {
  final bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    padding: EdgeInsets.only(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: AppSpacing.md,
      bottom: AppSpacing.md + bottomPadding, // Safe area 대응
    ),
    child: // ... 버튼들
  );
}
```

- iOS: 홈 인디케이터 영역만큼 자동 패딩
- Android: 제스처 네비게이션 영역만큼 자동 패딩
- 일반 기기: bottomPadding = 0

## Git 워크플로우

```bash
# 변경사항 확인
git status
git diff

# 커밋
git add .
git commit -m "feat: 기능 설명"

# 푸시
git push
```

**커밋 메시지 컨벤션**:
- `feat:` 새 기능
- `fix:` 버그 수정
- `refactor:` 리팩토링
- `docs:` 문서 수정
- `style:` 코드 포맷팅

## AdMob 광고 통합

### 개요

앱은 AdMob 전면 광고를 사용하여 수익화합니다. 사용자는 $2 일회성 구매로 광고를 제거할 수 있습니다.

### 광고 표시 조건

전면 광고는 다음 경우에만 표시됩니다:
1. **새 스캔 저장 시**: 이름 입력 다이얼로그에서 Save 버튼 누른 후 광고 표시
2. **빈 문서에 이미지 추가 후 저장 시**: 저장 버튼 누른 후 광고 표시

**중요**: 광고는 반드시 사용자가 저장 확정한 후에 표시해야 함 (이름 입력 전 X)

**광고가 표시되지 않는 경우**:
- 광고 제거 구매한 프리미엄 사용자
- 기존 문서 편집 (이미지가 있던 문서 수정)
- PDF 내보내기/공유

### AdService 싱글톤

```dart
import 'services/ad_service.dart';

// 앱 시작 시 초기화 (main.dart)
await AdService.instance.initialize();

// 광고 표시 (프리미엄 상태 자동 확인)
await AdService.instance.showInterstitialAd();
```

### 광고 단위 ID

| 플랫폼 | 앱 ID | 광고 단위 ID |
|--------|-------|-------------|
| Android | `ca-app-pub-6737616702687889~6959584615` | `ca-app-pub-6737616702687889/4385392169` |
| iOS | `ca-app-pub-6737616702687889~9190996284` | `ca-app-pub-6737616702687889/3204882872` |

**테스트 광고**: 디버그 빌드에서는 자동으로 테스트 광고 ID 사용

### 플랫폼 설정

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-6737616702687889~6959584615"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-6737616702687889~9190996284</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

### 프리미엄 상태

`SharedPreferences`의 `isPremium` 키로 광고 제거 상태 관리:

```dart
final prefs = await SharedPreferences.getInstance();
final isPremium = prefs.getBool('isPremium') ?? false;
```

## 앱 아이콘 생성

```bash
# SVG → PNG 변환 (rsvg-convert 필요: brew install librsvg)
rsvg-convert -w 1024 -h 1024 assets/app_icon.svg -o assets/app_icon.png

# Flutter 앱 아이콘 적용
dart run flutter_launcher_icons
```

**Android Adaptive Icon Safe Zone**: 콘텐츠는 중앙 66dp (전체의 61%) 내에 배치. 현재 55%로 설정하여 여유 공간 확보.
