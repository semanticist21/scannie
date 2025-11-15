# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 모바일 애플리케이션입니다. 네이티브 카메라로 문서를 스캔하고, CamScanner 스타일 필터를 적용하며, PDF로 내보낼 수 있습니다.

**핵심 기술**:
- Flutter 3.39.0-0.1.pre (beta), Dart 3.11.0, Material Design 3
- `cunning_document_scanner_plus` v1.0.3 (네이티브 iOS/Android 스캐너)
- `image` v4.5.4 (CamScanner 스타일 필터 + 원근 변환 copyRectify)

**현재 상태**:
- ✅ 문서 스캔 (cunning_document_scanner_plus)
- ✅ 5가지 필터 (그림자 제거 B&W 포함)
- ✅ 밝기/대비/회전 기능
- ✅ **EditScreen 4코너 재조정 + 원근 보정** (image.copyRectify)
- ❌ Save/PDF 기능 (미구현)

## Quick Reference

```bash
# 앱 실행
flutter devices                # 사용 가능한 기기 확인
flutter run -d <device-id>     # 실행 (Hot Reload: r, Hot Restart: R, 종료: q)

# 개발 도구
flutter analyze                # 린트 분석 (코드 수정 전/후 필수!)
flutter clean && flutter pub get  # 의존성 초기화

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

### 디렉토리 구조

```
lib/
├── screens/          # 4개 전체 화면
│   ├── gallery_screen.dart          # 홈, 문서 리스트/그리드, 스캔 버튼
│   ├── edit_screen.dart              # 필터, 밝기/대비, 회전, **모서리 조정 + 원근 보정**
│   ├── document_viewer_screen.dart   # 페이지 갤러리, 전체 화면 뷰어
│   └── export_screen.dart            # PDF 설정 (미구현)
├── widgets/common/   # 재사용 위젯
│   ├── scan_card.dart
│   ├── custom_app_bar.dart
│   └── custom_button.dart
├── theme/            # 디자인 시스템
│   ├── app_theme.dart        # M3 ThemeData 구성
│   ├── app_colors.dart       # 색상 팔레트
│   └── app_text_styles.dart  # 타이포그래피
├── models/
│   └── scan_document.dart    # ScanDocument(id, name, createdAt, imagePaths, isProcessed)
└── utils/
    └── image_filters.dart    # 이미지 필터 (B&W Adaptive Thresholding 포함)
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
  → Scan 버튼 → CunningDocumentScanner.getPictures(mode: ScannerMode.filters)
      → 스캔 완료 → '/edit' → EditScreen (arguments: List<String> imagePaths)
          → 필터/밝기/대비/회전 적용
          → Save → Navigator.pop(ScanDocument) [미구현]
  → 문서 탭 → '/viewer' → DocumentViewerScreen (arguments: ScanDocument) [미구현]
      → PDF 버튼 → '/export' → ExportScreen [미구현]
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

## 이미지 처리 (ImageFilters)

### 필터 종류

- `applyOriginal()`: 원본
- `applyGrayscale()`: 흑백
- **`applyBlackAndWhite()`**: CamScanner 스타일 고대비 이진화 (그림자 제거)
- `applyMagicColor()`: 자동 색상 향상
- `applyLighten()`: 밝게

### B&W 필터 - CamScanner 스타일 Adaptive Thresholding

`applyBlackAndWhite()`는 그림자가 있어도 깔끔한 문서 스캔을 위한 **5단계 처리**:

```
1. Grayscale 변환
   ↓
2. 조명 보정 (_removeIllumination)
   - Gaussian blur (radius=20)로 그림자/조명 불균일 추정
   - 원본 + (128 - 조명맵) = 균일한 조명
   ↓
3. Histogram 정규화
   - 0-255 전체 범위 활용 (normalize)
   ↓
4. Adaptive Thresholding (_applyAdaptiveThreshold)
   - 25×25 블록별 로컬 평균 계산
   - 픽셀값 > (로컬평균 - 10) ? 흰색 : 검은색
   - 그림자 있어도 텍스트 살아남음!
   ↓
5. 대비 강화 (1.2x)
   - 최종 선명도 향상
```

**전역 임계값 vs Adaptive Thresholding**:
- 전역 임계값: 이미지 전체에 동일한 기준값 (128) 적용 → 그림자 영역 검게 변함
- **Adaptive**: 지역별로 다른 임계값 적용 → 그림자 영향 최소화 ✨

### 이미지 처리 파이프라인

```dart
// EditScreen에서의 처리 순서
_originalImage = await ImageFilters.loadImage(imagePath);
img.Image processed = _originalImage!.clone();

// 1. 회전 (선택)
if (_rotationAngle != 0) processed = ImageFilters.rotate90(processed);

// 2. 필터
processed = ImageFilters.applyBlackAndWhite(processed); // 또는 다른 필터

// 3. 밝기/대비 (-100~100)
if (_brightness != 0 || _contrast != 0) {
  processed = ImageFilters.applyBrightnessAndContrast(processed, _brightness, _contrast);
}

// 4. UI 표시용 인코딩
_displayImageBytes = ImageFilters.encodeImage(processed);
setState(() { ... });
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

**3가지 스캐너 모드**:
- `ScannerMode.full`: 모든 기능
- `ScannerMode.filters`: 필터 옵션 활성화 ✨
- `ScannerMode.base`: 기본 스캔만

**제약사항**: 네이티브 UI는 커스터마이징 불가 (iOS/Android 기본 UI)

## 모서리 조정 + 원근 보정 (EditScreen)

### 개요

EditScreen에서 **4개 코너 포인트를 드래그**하여 문서 경계를 조정하고, **image 패키지의 copyRectify**로 원근 변환을 적용할 수 있습니다.

### 사용 방법

```
1. EditScreen 진입 (스캔 후)
2. 하단 "Crop" 버튼 클릭 → Crop 모드 활성화
3. 4개 빨간색 핸들 드래그 (TL/TR/BR/BL)
   - 드래그 중: 주황색으로 변경
   - 정규화 좌표 (0-1) 사용 → UI 크기 독립적
4. "Apply" 버튼 클릭 → 원근 보정 적용 ✨
5. 필터/밝기/대비 조정 → Save
```

### 구현 세부사항

**image 패키지의 copyRectify 사용**:
```dart
import 'package:image/image.dart' as img;

// 1. 정규화 좌표(0-1)를 실제 픽셀 좌표로 변환
final imageWidth = _originalImage!.width;
final imageHeight = _originalImage!.height;

final topLeft = img.Point(
  (_corners[0].dx * imageWidth).toInt(),
  (_corners[0].dy * imageHeight).toInt(),
);
final topRight = img.Point(
  (_corners[1].dx * imageWidth).toInt(),
  (_corners[1].dy * imageHeight).toInt(),
);
final bottomRight = img.Point(
  (_corners[2].dx * imageWidth).toInt(),
  (_corners[2].dy * imageHeight).toInt(),
);
final bottomLeft = img.Point(
  (_corners[3].dx * imageWidth).toInt(),
  (_corners[3].dy * imageHeight).toInt(),
);

// 2. copyRectify로 원근 변환 적용
final rectified = img.copyRectify(
  _originalImage!,
  topLeft: topLeft,
  topRight: topRight,
  bottomLeft: bottomLeft,
  bottomRight: bottomRight,
);

// 3. 원본 이미지 교체
_originalImage = rectified;

// 4. 현재 필터 재적용
await _applyCurrentFilter();
```

**장점**:
- ✅ 순수 Dart 구현 (네이티브 바인딩 없음)
- ✅ ARM64 아키텍처 호환성 문제 없음
- ✅ 경량 의존성 (이미 사용 중인 image 패키지)
- ✅ 간단한 API (한 줄로 원근 변환)

**주의사항**:
- `img.Point`는 정수 좌표만 허용 (double → toInt() 변환 필수)
- 정규화 좌표(0-1) 사용으로 다양한 화면 크기 지원
- CustomPainter로 4각형 + 라벨(TL/TR/BR/BL) 그리기

**UI 컴포넌트**:
- `_buildCropHandles()`: LayoutBuilder로 크기 감지 + GestureDetector로 드래그 처리
- `_CropQuadPainter`: CustomPainter로 4각형 오버레이 그리기
- `_buildHandle()`: 코너 핸들 (빨간색/주황색 원 + TL/TR/BR/BL 라벨)

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
