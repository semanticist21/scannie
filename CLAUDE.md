# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 애플리케이션입니다. 카메라로 문서를 스캔하고, 필터를 적용하며, PDF로 내보낼 수 있는 UI를 제공합니다.

## 개발 환경

- Flutter SDK: 3.39.0-0.1.pre (beta 채널)
- Dart SDK: 3.11.0
- Android: Gradle 8.5, AGP 8.3.0, Kotlin 1.9.22, Java 17
- 린트: flutter_lints ^4.0.0

## 필수 명령어

### 앱 실행

```bash
# 기본 실행 (연결된 기기/에뮬레이터에서)
flutter run

# 특정 기기에서 실행
flutter run -d <device-id>

# Android 에뮬레이터에서 실행
flutter run -d emulator-5554

# macOS에서 실행
flutter run -d macos

# Hot Reload: r 키 (코드 수정 후)
# Hot Restart: R 키 (새 화면 추가 시)
```

### 빌드 및 분석

```bash
# 프로젝트 클린 (빌드 아티팩트 제거)
flutter clean

# 린트 분석 실행
flutter analyze

# 패키지 의존성 가져오기
flutter pub get

# 클린 후 실행 (빌드 문제 발생 시)
flutter clean && flutter pub get && flutter run
```

### 기기 관리

```bash
# 사용 가능한 기기 목록 확인
flutter devices

# Flutter 환경 진단
flutter doctor -v
```

## 아키텍처

### 디렉토리 구조
- **lib/screens/**: 모든 전체 화면 (5개)
  - `gallery_screen.dart`: 홈 화면, 문서 리스트
  - `camera_screen.dart`: 스캔 UI
  - `edit_screen.dart`: 필터 및 조정
  - `document_viewer_screen.dart`: 페이지 갤러리 + 전체 화면 뷰어
  - `export_screen.dart`: PDF 설정 및 내보내기
- **lib/widgets/common/**: 재사용 가능한 공통 위젯
- **lib/theme/**: 중앙화된 디자인 시스템 (색상, 타이포그래피, 테마)
- **lib/models/**: 데이터 모델 (`ScanDocument`)

### 테마 시스템
모든 UI 컴포넌트는 중앙화된 테마를 사용합니다:
- `AppColors`: Material Design 색상 팔레트
- `AppTextStyles`: 타이포그래피 계층 (h1-h3, body, caption)
- `AppTheme`: Material 3 테마 설정
- `AppSpacing`: 일관된 간격 상수 (xs: 4 → xxl: 48)
- `AppRadius`: 표준화된 border radius

새 위젯 추가 시 이 테마 상수들을 import하여 일관성을 유지하세요.

### 네비게이션 플로우
앱은 명명된 라우트를 사용하며 `main.dart`의 `onGenerateRoute`에서 관리됩니다:

**주요 플로우:**
```
GalleryScreen (홈)
  → '/camera' → CameraScreen
      → 촬영 → '/edit' → EditScreen
          → 저장 → 새 ScanDocument 반환 → GalleryScreen (업데이트됨)
  → 문서 클릭 → '/viewer' → DocumentViewerScreen (페이지 갤러리)
      → 페이지 클릭 → FullScreenImageViewer (전체 화면 + 줌)
      → PDF 버튼 → '/export' → ExportScreen
```

**데이터 전달:**
- 라우트 간 데이터는 `Navigator.pushNamed(context, route, arguments: data)` 사용
- 새 문서는 `Navigator.pop(context, newDocument)`로 반환
- 모델: `ScanDocument` (id, name, createdAt, imagePaths, isProcessed)

### 화면별 주요 기능
1. **GalleryScreen**: 문서 리스트/그리드 뷰, 검색, 삭제/공유
2. **CameraScreen**: 스캔 오버레이, Auto/Manual 모드, 플래시 토글
3. **EditScreen**: 5가지 필터, 밝기/대비 조절, Auto Crop, 회전
4. **DocumentViewerScreen**: 페이지 갤러리, 그리드/리스트 뷰, 다중 선택, 편집/회전/삭제
5. **ExportScreen**: 페이지 크기 선택 (A4/Letter/Legal), 품질 설정, PDF 내보내기

### 구현 상태 및 제약사항
- **UI 전용 프로토타입**: 모든 화면이 시각적으로 완성되었으나 실제 기능은 미구현
- **Mock 데이터**: 카메라 촬영, 이미지 처리, PDF 생성은 시뮬레이션됨
- **이미지 플레이스홀더**: 실제 이미지 대신 아이콘 표시
- **완전한 네비게이션**: 모든 화면 간 이동과 데이터 전달은 작동함

새 기능 추가 시:
- 기존 테마 시스템 및 위젯 스타일을 따르세요
- 라우트는 `main.dart`의 `onGenerateRoute`에 추가
- 일관성을 위해 `CustomAppBar` 같은 공통 위젯 재사용

## 일반적인 문제 해결

### Android Gradle/Kotlin 오류
Flutter beta 채널 사용 시 Gradle/Kotlin 호환성 문제가 발생할 수 있습니다.

**증상:**
```
Unresolved reference: filePermissions
Compilation error in FlutterPlugin.kt
```

**해결 방법:**
프로젝트가 이미 최신 버전으로 설정되어 있습니다:
- Gradle 8.5
- Android Gradle Plugin 8.3.0
- Kotlin 1.9.22
- Java 17

문제 발생 시:
```bash
flutter clean
flutter pub get
flutter run
```

### Android 빌드 경고
Flutter beta가 더 높은 버전을 권장하는 경고가 나올 수 있습니다:
- Gradle 8.7+, AGP 8.6+, Kotlin 2.1.0+ 권장
- 현재 버전으로도 앱은 정상 작동하며, 이는 미래 호환성에 대한 경고입니다

빌드 의존성 검증 오류 발생 시:
```bash
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

### 빌드 캐시 문제
빌드 오류가 지속되면 클린 후 재시도:
```bash
flutter clean
flutter pub get
flutter run
```

### 기기 인식 문제
기기가 인식되지 않으면:
```bash
flutter doctor -v  # 환경 문제 확인
flutter devices    # 사용 가능한 기기 확인
```

## 향후 개발 계획

현재는 UI만 구현된 상태입니다. 실제 기능 구현 시 필요한 패키지:

- **카메라**: `camera` - 실시간 카메라 접근
- **이미지 처리**: `image` - 필터 및 크롭 적용
- **PDF 생성**: `pdf` - PDF 문서 생성
- **파일 저장**: `path_provider` - 파일 시스템 접근
- **권한**: `permission_handler` - 카메라/저장소 권한
