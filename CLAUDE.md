# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 모바일 애플리케이션입니다. 네이티브 카메라로 문서를 스캔하고, CamScanner 스타일 필터를 적용하며, PDF로 내보낼 수 있습니다.

**핵심 기술**:
- Flutter 3.39.0-0.1.pre (beta), Dart 3.11.0, Material Design 3
- `cunning_document_scanner_plus` v1.0.3 (네이티브 iOS/Android 스캐너 + 필터/크롭)
- `reorderable_grid_view` v2.2.8 (드래그 앤 드롭 순서 변경)
- `pdf` + `printing` (PDF 생성/공유)

**현재 상태**:
- ✅ 문서 스캔 (네이티브 필터/크롭/회전 포함)
- ✅ **EditScreen 이미지 관리** (드래그앤드롭 순서 변경, 삭제, 추가)
- ✅ 세션 유지 (스캔 후 이미지 추가 가능)
- ✅ PDF 내보내기 (공유 기능 포함)

## Quick Reference

```bash
# 앱 실행
flutter devices                # 사용 가능한 기기 확인
flutter run -d <device-id>     # 실행
# Hot Reload: r (빠름, 상태 유지)
# Hot Restart: R (전체 재시작)
# 종료: q

# 개발 도구
flutter analyze                # 린트 분석 (코드 수정 전/후 필수!)
flutter clean && flutter pub get  # 의존성 초기화

# 테스트
flutter test                          # 모든 테스트 실행
flutter test test/path/to/test.dart   # 단일 테스트 파일 실행

# 빌드
flutter build apk --release           # Android 릴리스 APK
flutter build ios --release           # iOS 릴리스 빌드
flutter build appbundle               # Android App Bundle (Play Store)

# 빌드 경고 무시 (beta 채널)
flutter run -d <device-id> --android-skip-build-dependency-validation
```

**핵심 규칙**:
- ✅ Material 3 네이티브 컴포넌트 우선 (FilledButton, SegmentedButton, Card)
- ✅ 테마 시스템 필수 (`AppSpacing`, `AppColors`, `AppTextStyles`)
- ✅ **`flutter analyze` 통과 필수** - 모든 코드 수정 후 실행하여 에러/경고 0개 확인!
- ❌ `Color.withOpacity()` 사용 금지 → `withValues(alpha:)` 사용
- ❌ Async gap 후 BuildContext 직접 사용 금지 → Navigator 인스턴스 저장
- ❌ path 패키지는 `import 'package:path/path.dart' as path;` 형식으로만
- ❌ `print()` 사용 금지 → `debugPrint()` 사용 (프로덕션 빌드에서 자동 제거)

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
│   ├── gallery_screen.dart          # 홈, 문서 리스트/그리드, 스캔 버튼
│   ├── edit_screen.dart              # **이미지 관리** (드래그앤드롭 순서, 삭제, 추가)
│   ├── document_viewer_screen.dart   # 페이지 갤러리, 전체 화면 뷰어 (미구현)
│   └── export_screen.dart            # PDF 설정 (미구현)
├── widgets/common/   # 재사용 위젯
│   ├── scan_card.dart
│   ├── custom_app_bar.dart
│   └── custom_button.dart
├── theme/            # 디자인 시스템
│   ├── app_theme.dart        # M3 ThemeData 구성
│   ├── app_colors.dart       # 색상 팔레트
│   └── app_text_styles.dart  # 타이포그래피
└── models/
    └── scan_document.dart    # ScanDocument(id, name, createdAt, imagePaths, isProcessed)
```

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
      (네이티브 UI에서 필터/크롭/회전 모두 처리)
      → Android: Enhance/Clean/Filter 버튼 제공
      → iOS: 기본 자동 처리 (mode 파라미터 무시됨)
      → 스캔 완료 → '/edit' → EditScreen (arguments: List<String> imagePaths)
          ├─ 이미지 카드 탭 → 전체 화면 뷰어 (InteractiveViewer, 0.5x~4.0x 줌)
          ├─ 드래그 앤 드롭으로 이미지 순서 변경 (PDF 페이지 순서)
          ├─ 이미지 삭제 (X 버튼, 토스트 없음)
          ├─ "Add More" 버튼 → 스캐너 재호출 → 현재 세션에 추가
          └─ Save → Navigator.pop(ScanDocument)
  → 문서 탭 → '/viewer' → DocumentViewerScreen (미구현)
      → PDF 버튼 → '/export' → ExportScreen (미구현)
```

**라우트 설정 필수 패턴**:
```dart
// main.dart의 onGenerateRoute
case '/edit':
  return MaterialPageRoute(
    builder: (context) => const EditScreen(),
    settings: settings, // arguments 전달을 위해 필수!
  );
```

`settings` 없이는 `ModalRoute.of(context)?.settings.arguments`가 null 반환!

## EditScreen 기능

### 개요

EditScreen은 스캔된 이미지를 관리하는 화면입니다. **필터/크롭/회전은 네이티브 스캐너에서 처리**하므로 EditScreen에서는 이미지 순서 관리만 담당합니다.

### 주요 기능

1. **전체 화면 이미지 뷰어** (`InteractiveViewer`)
   - 이미지 카드 탭 → 전체 화면으로 확대
   - 핀치 줌: 0.5x ~ 4.0x (더블 탭 지원)
   - 팬/드래그로 확대된 이미지 이동
   - AppBar에 페이지 번호 표시 (Page 2 / 5)

2. **드래그 앤 드롭 순서 변경** (`reorderable_grid_view`)
   - 2열 그리드 레이아웃 (A4 비율 210:297)
   - 드래그하여 이미지 순서 변경 (PDF 페이지 순서)
   - 각 카드에 페이지 번호 표시

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
   - `Navigator.pop(newDocument)`로 GalleryScreen에 반환

### 제거된 기능 (네이티브 스캐너로 이동)

다음 기능들은 `cunning_document_scanner_plus`의 네이티브 UI에서 처리하므로 EditScreen에서 제거되었습니다:

- ❌ **필터** (B&W, Enhanced, Grayscale, Lighten) → `ScannerMode.full`에서 처리
- ❌ **밝기/대비 조정** → Android: Enhance 버튼 / iOS: 자동
- ❌ **회전** → 네이티브 회전 기능 사용
- ❌ **Crop/모서리 조정** → 네이티브 자동 edge 감지 + 원근 보정
- ❌ **얼룩 제거** → Android: Clean 버튼 (브러시로 수동) / iOS: 없음

### 코드 예시

```dart
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

Widget _buildReorderableGrid() {
  return ReorderableGridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
    childAspectRatio: 210 / 297, // A4 ratio
    padding: const EdgeInsets.all(AppSpacing.md),
    onReorder: (oldIndex, newIndex) {
      setState(() {
        final item = _imagePaths.removeAt(oldIndex);
        _imagePaths.insert(newIndex, item);
      });
    },
    children: _imagePaths.map((path) {
      return Card(
        key: ValueKey(path),
        child: Stack(
          children: [
            Image.file(File(path)),
            // 페이지 번호, 삭제 버튼 등
          ],
        ),
      );
    }).toList(),
  );
}
```

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
