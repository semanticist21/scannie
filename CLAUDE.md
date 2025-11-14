# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 애플리케이션입니다. 카메라로 문서를 스캔하고, 필터를 적용하며, PDF로 내보낼 수 있는 UI를 제공합니다.

**중요**: 이것은 **모바일 앱**입니다. 테스트 시 Android 에뮬레이터를 사용하세요.

**현재 상태**: UI 프로토타입 단계 - 모든 화면이 시각적으로 완성되었으나 실제 카메라, 이미지 처리, PDF 기능은 시뮬레이션입니다.

## 개발 환경

- Flutter SDK: 3.39.0-0.1.pre (beta 채널)
- Dart SDK: 3.11.0
- Android: Gradle 8.5, AGP 8.3.0, Kotlin 1.9.22, Java 17
- 린트: flutter_lints ^4.0.0
- **Material Design 3**: `useMaterial3: true` 활성화됨

## ⚠️ Flutter API 주의사항 (자주 하는 실수)

**이 프로젝트는 Flutter 3.39 (beta)를 사용합니다. 최신 API를 사용하세요!**

### 🚫 절대 사용 금지 (Deprecated)

#### 1. `Color.withOpacity()` ❌
```dart
// ❌ WRONG - Deprecated!
Colors.white.withOpacity(0.5)
Colors.black.withOpacity(0.3)

// ✅ CORRECT - Use withValues()
Colors.white.withValues(alpha: 0.5)
Colors.black.withValues(alpha: 0.3)
```

**이유**: `withOpacity()`는 precision loss 문제로 deprecated됨. Flutter 3.27+ 에서는 `withValues()` 사용 필수.

#### 2. Async Gap에서 BuildContext 직접 사용 ❌
```dart
// ❌ WRONG - Context across async gap
Future<void> someFunction() async {
  await someAsyncOperation();
  if (!mounted) return;
  Navigator.pop(context); // 위험! async gap 후 context 사용
}

// ✅ CORRECT - Store Navigator before async
Future<void> someFunction() async {
  final navigator = Navigator.of(context);
  await someAsyncOperation();
  if (!mounted) return;
  navigator.pop(); // 안전! navigator 인스턴스 사용
}
```

**이유**: `async` 작업 후 위젯이 dispose될 수 있으므로 `BuildContext` 사용이 위험함. 미리 `Navigator` 인스턴스를 저장하거나 `mounted` 체크 후 사용.

#### 3. showDialog에서 context 변수명 충돌 ❌
```dart
// ❌ WRONG - context shadowing
showDialog(
  context: context,
  builder: (context) => AlertDialog( // 같은 이름 사용
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context); // 어느 context?
        },
      ),
    ],
  ),
);

// ✅ CORRECT - Use different name
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog( // 다른 이름
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(dialogContext); // 명확!
        },
      ),
    ],
  ),
);
```

#### 4. path 패키지 import 충돌 ❌
```dart
// ❌ WRONG - Conflicts with dart:io
import 'package:path/path.dart';

void test() {
  join('a', 'b'); // 어느 join? dart:io vs package:path
}

// ✅ CORRECT - Use alias
import 'package:path/path.dart' as path;

void test() {
  path.join('a', 'b'); // 명확!
}
```

### ✅ 권장 패턴

#### BuildContext 안전하게 사용하기
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> safeAsyncOperation() async {
    // 1. Navigator를 먼저 저장
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 2. async 작업 실행
    await someAsyncWork();

    // 3. mounted 체크
    if (!mounted) return;

    // 4. 저장한 인스턴스 사용
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('Done')));
  }
}
```

#### const 최적화
```dart
// ✅ 가능한 모든 곳에 const 사용
const Text('Title', style: AppTextStyles.h2)
const Icon(Icons.search, size: 24)
const SizedBox(height: AppSpacing.md)
const EdgeInsets.all(AppSpacing.lg)
```

## 필수 명령어

### 앱 실행 (모바일)

```bash
# 사용 가능한 기기 확인
flutter devices

# Android 에뮬레이터에서 실행 (기기 ID는 flutter devices로 확인)
flutter run -d <device-id>
# 예: flutter run -d emulator-5554

# Hot Reload: r 키 (상태 유지하며 UI 변경사항 반영)
# Hot Restart: R 키 (앱 재시작, 상태 초기화)
# 종료: q 키

# 빌드 경고 무시하고 실행 (beta 채널 사용 시)
flutter run -d <device-id> --android-skip-build-dependency-validation
```

### 빌드 및 분석

```bash
# 린트 분석
flutter analyze

# 프로젝트 클린
flutter clean

# 의존성 업데이트
flutter pub get

# 클린 후 실행 (빌드 문제 시)
flutter clean && flutter pub get && flutter run -d emulator-5554
```

## 아키텍처

### Material Design 3 (Material You)

앱은 Flutter 네이티브 Material 3를 사용합니다:
- **FilledButton**: 주요 액션 버튼 (예: GalleryScreen의 Scan 버튼, ExportScreen의 Export 버튼)
- **SegmentedButton**: 필터 선택 UI (EditScreen)
- **Card**: M3 elevation과 shape 자동 적용
- **ColorScheme.fromSeed**: Primary 색상에서 자동 생성된 조화로운 색상 팔레트

**중요 원칙**: 외부 UI 라이브러리를 추가하지 마세요. Material 3 네이티브 컴포넌트를 우선 사용하세요.

**M3 컴포넌트 선호도**:
1. FilledButton > ElevatedButton (주요 액션)
2. OutlinedButton (보조 액션)
3. TextButton (낮은 우선순위 액션)
4. SegmentedButton > ToggleButtons (다중 선택)
5. Card with M3 elevation (콘텐츠 그룹화)

### 디렉토리 구조

- **lib/screens/**: 5개의 전체 화면
  - `gallery_screen.dart`: 홈, 문서 리스트/그리드
  - `camera_screen.dart`: 스캔 UI (Auto/Manual 모드)
  - `edit_screen.dart`: 5가지 필터, 밝기/대비, 회전, Auto Crop
  - `document_viewer_screen.dart`: 페이지 갤러리, 전체 화면 뷰어
  - `export_screen.dart`: PDF 설정 (페이지 크기, 품질)
- **lib/widgets/common/**: 재사용 위젯 (`ScanCard`, `CustomAppBar`, `CustomButton`)
- **lib/theme/**: 중앙화된 디자인 시스템
  - `app_theme.dart`: ThemeData 구성, M3 설정
  - `app_colors.dart`: 색상 팔레트 상수
  - `app_text_styles.dart`: 타이포그래피 스타일
- **lib/models/**: 데이터 모델
  - `scan_document.dart`: ScanDocument 모델 (id, name, createdAt, imagePaths, isProcessed)
- **lib/utils/**: 유틸리티 함수
  - `image_filters.dart`: 이미지 필터 및 처리 함수 (`image` 패키지 사용)

### 테마 시스템

**중요**: 모든 새 위젯은 반드시 테마 상수를 사용해야 합니다:

```dart
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

// 간격
AppSpacing.xs   // 4
AppSpacing.sm   // 8
AppSpacing.md   // 16
AppSpacing.lg   // 24
AppSpacing.xl   // 32
AppSpacing.xxl  // 48

// Border Radius
AppRadius.sm    // 4
AppRadius.md    // 8
AppRadius.lg    // 16
AppRadius.xl    // 24
AppRadius.round // 999

// 색상
AppColors.primary
AppColors.accent
AppColors.surface
AppColors.background
// ... (app_colors.dart 참조)

// 타이포그래피
AppTextStyles.h1
AppTextStyles.h2
AppTextStyles.h3
AppTextStyles.bodyLarge
AppTextStyles.bodyMedium
AppTextStyles.bodySmall
AppTextStyles.caption
AppTextStyles.label
AppTextStyles.button
```

### 네비게이션 플로우

앱은 `main.dart`의 `onGenerateRoute`에서 명명된 라우트를 관리합니다:

```
GalleryScreen (홈)
  → '/camera' → CameraScreen
      → 촬영 → '/edit' → EditScreen
          → Save → Navigator.pop(context, newDocument)
  → 문서 탭 → '/viewer' → DocumentViewerScreen (arguments: ScanDocument)
      → PDF 버튼 → '/export' → ExportScreen (arguments: ScanDocument)
```

**라우트 추가 방법**:
1. `main.dart`의 `onGenerateRoute`에 새 case 추가
2. `arguments`로 데이터 전달: `Navigator.pushNamed(context, '/route', arguments: data)`
3. 데이터 반환: `Navigator.pop(context, returnValue)`

**데이터 모델**: `ScanDocument(id, name, createdAt, imagePaths, isProcessed)`

### 구현 상태

**완료된 기능**:
- ✅ 모든 화면 UI (5개 화면)
- ✅ 네비게이션 플로우 (명명된 라우트)
- ✅ 테마 시스템 (M3, 색상, 타이포그래피, 간격)
- ✅ 재사용 가능한 공통 위젯
- ✅ 이미지 필터 유틸리티 (`image` 패키지 통합)
- ✅ **실제 문서 스캔 기능** (`flutter_doc_scanner` - ML Kit 기반)
  - 자동 문서 edge 감지
  - A4 용지 정렬 시 자동 캡처
  - 원근 보정 (perspective correction)
  - iOS (VisionKit) 및 Android (ML Kit) 네이티브 지원

**미구현 기능** (향후 개발 필요):
- ❌ 파일 시스템 저장 (`path_provider` 필요)
- ❌ PDF 생성 (`pdf` 패키지 필요)
- ❌ EditScreen의 실제 이미지 편집 통합

**새 기능 추가 시 지켜야 할 원칙**:
- 테마 시스템 준수 (`AppSpacing`, `AppColors`, `AppTextStyles` 사용)
- Material 3 네이티브 위젯 우선 사용
- 공통 위젯 재사용 (`CustomAppBar`, `ScanCard`, `CustomButton`)
- `const` 키워드 적극 사용 (성능 최적화)

## 일반적인 문제 해결

### Android 빌드 경고

Flutter beta는 더 높은 버전을 권장하지만, 현재 버전(Gradle 8.5, AGP 8.3.0, Kotlin 1.9.22)으로도 정상 작동합니다.

경고 무시:
```bash
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

### 빌드 실패 시

```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### RenderFlex Overflow 오류

Column/Row에 `mainAxisSize: MainAxisSize.min`, `mainAxisAlignment: MainAxisAlignment.center` 추가:

```dart
// 예: ScanCard의 Column
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  mainAxisSize: MainAxisSize.min,
  children: [...]
)
```

### Const 최적화

성능 향상을 위해 가능한 모든 위젯에 `const` 사용:

```dart
// ✅ Good
const Text('Title', style: AppTextStyles.h2)
const Icon(Icons.search, size: 24)

// ❌ Bad
Text('Title', style: AppTextStyles.h2)
Icon(Icons.search, size: 24)
```

## 이미지 처리 (ImageFilters)

`lib/utils/image_filters.dart`는 `image` 패키지를 사용하여 문서 스캔 필터를 제공합니다.

**주요 필터**:
- `applyOriginal()`: 원본 (변경 없음)
- `applyGrayscale()`: 흑백
- `applyBlackAndWhite()`: 고대비 이진화 (문서 스캔에 최적)
- `applyMagicColor()`: 자동 색상 향상
- `applyLighten()`: 밝게

**조정 기능**:
- `applyBrightness(image, value)`: 밝기 (-100 ~ 100)
- `applyContrast(image, value)`: 대비 (-100 ~ 100)
- `rotate90/180/270(image)`: 회전
- `autoCrop(image)`: 자동 자르기 (TODO: edge detection 구현 필요)

**이미지 로딩/저장**:
- `loadImage(path)`: 파일에서 이미지 로드
- `saveImage(image, path)`: JPEG로 저장 (품질 95%)
- `encodeImage(image)`: UI 표시용 Uint8List 인코딩

## 문서 스캔 기능 (edge_detection)

앱은 `edge_detection` 패키지를 사용하여 실시간 Edge Detection 기반 문서 스캔을 제공합니다.

**주요 기능**:
- **실시간 카메라 UI**: 커스텀 카메라 인터페이스 제공
- **네모 가이드 프레임**: 화면에 사각형 가이드가 표시되어 문서 위치를 안내
- **자동 Edge 감지**: 문서의 테두리를 실시간으로 자동 인식
- **자동 캡처**: 문서가 가이드 프레임에 맞춰지면 자동으로 촬영
- **수동 편집**: 캡처 후 모서리 조정, 자르기, 흑백 필터 적용 가능
- **갤러리 선택**: 카메라뿐만 아니라 갤러리에서도 이미지 선택 가능

**사용 방법**:
```dart
// 실시간 카메라로 Edge Detection 시작
bool success = await EdgeDetection.detectEdge(
  imagePath,
  canUseGallery: true,
  androidScanTitle: '문서 스캔',
  androidCropTitle: '자르기',
);
```

**플랫폼별 구현**:
- **Android**: OpenCV 기반 Edge Detection
- **iOS**: WeScan 라이브러리 (Vision 프레임워크)

**요구사항**:
- Android: minSdkVersion 21 이상
- iOS: iOS 13.0 이상
- 카메라 및 사진 라이브러리 권한 필수

## 향후 개발 계획

실제 기능 구현 시 필요한 패키지:

- `path_provider`: 파일 시스템 경로 접근
- `pdf`: PDF 문서 생성

**개발 우선순위 제안**:
1. ~~카메라 기능~~ ✅ 완료 (`flutter_doc_scanner` 통합)
2. EditScreen에 실제 스캔 이미지 표시
3. 파일 저장 (`path_provider` 통합)
4. PDF 내보내기 (`pdf` 패키지 통합)
5. 다국어 지원 (현재 한국어만)
