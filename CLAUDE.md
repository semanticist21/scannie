# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 문서 스캔 Flutter 모바일 애플리케이션입니다. 네이티브 카메라로 문서를 스캔하고, CamScanner 스타일 필터를 적용하며, PDF로 내보낼 수 있습니다.

**핵심 기술**: Flutter (SDK >=3.5.0), Dart, Material Design 3, shadcn_ui

**주요 패키지**:
- `cunning_document_scanner_plus` - 네이티브 iOS/Android 스캐너
- `shadcn_ui` - UI 컴포넌트 (ShadButton, ShadBadge, LucideIcons)
- `flutter_reorderable_grid_view` - 드래그앤드롭 순서 변경
- `pdf` + `printing` - PDF 생성/공유
- `easy_localization` - 75개 언어 지원
- `google_mobile_ads` + `in_app_purchase` - 수익화

**배포 정보**:
- Package Name / Bundle ID: `com.kobbokkom.scannie`
- In-App Product ID: `premium_remove_ads` (non-consumable)

## Quick Reference

```bash
# 개발
flutter devices                    # 사용 가능한 기기 확인
flutter analyze                    # 린트 분석 (코드 수정 후 필수!)
flutter clean && flutter pub get   # 의존성 초기화

# 테스트
flutter test                                    # 모든 테스트
flutter test test/language_settings_test.dart   # 언어 설정 테스트

# 빌드
flutter build apk --release    # Android APK
flutter build appbundle        # Android App Bundle (Play Store)
flutter build ios --release    # iOS 빌드
```

⚠️ **Claude는 `flutter run` 절대 실행 금지** - 사용자가 직접 실행합니다!

## 핵심 규칙

### 필수 사항
- ✅ shadcn_ui 컴포넌트 우선 (ShadButton, ShadBadge, LucideIcons)
- ✅ 테마 시스템 사용 (`AppSpacing`, `AppColors`, `AppTextStyles`)
- ✅ `flutter analyze` 통과 필수 - 에러/경고 0개 확인
- ✅ 토스트는 `AppToast` 유틸리티만 사용
- ✅ 다이얼로그는 공통 위젯 사용 (`ConfirmDialog`, `RenameDialog`, `TextInputDialog`)

### 금지 사항
```dart
// ❌ Color.withOpacity() → ✅ withValues(alpha:)
Colors.white.withOpacity(0.5)  // WRONG
Colors.white.withValues(alpha: 0.5)  // CORRECT

// ❌ Async gap 후 context 직접 사용 → ✅ Navigator 인스턴스 저장
await someAsyncOperation();
Navigator.pop(context);  // WRONG - context가 유효하지 않을 수 있음

final navigator = Navigator.of(context);
await someAsyncOperation();
if (mounted) navigator.pop();  // CORRECT

// ❌ path 패키지 직접 import → ✅ as path 사용
import 'package:path/path.dart';  // WRONG
import 'package:path/path.dart' as path;  // CORRECT

// ❌ print() → ✅ debugPrint() (릴리스 빌드에서 자동 제거)
```

## 아키텍처

### 상태 관리
StatefulWidget + setState (외부 라이브러리 미사용)

### 디렉토리 구조
```
lib/
├── screens/           # 3개 화면: gallery, edit, document_viewer
├── widgets/
│   ├── common/        # 공통 위젯 (다이얼로그, 시트, 뷰어)
│   ├── gallery/       # GalleryScreen 전용
│   ├── edit/          # EditScreen 전용
│   └── viewer/        # DocumentViewerScreen 전용
├── services/          # 비즈니스 로직 (싱글톤 서비스들)
├── theme/             # 디자인 시스템 (colors, spacing, typography)
├── utils/             # 유틸리티 (toast, modal)
└── models/            # 데이터 모델
```

### 네비게이션 플로우
```
GalleryScreen (홈)
  → Scan → EditScreen (이미지 관리)
      → Save → DocumentViewerScreen
  → 문서 탭 → DocumentViewerScreen
  → 문서 메뉴 → Share/Download PDF
```

### 싱글톤 서비스
- `AdService.instance` - AdMob 광고 관리
- `PurchaseService.instance` - 인앱 결제 관리
- `ThemeService` - 테마 상태 관리

## 테마 시스템

```dart
// 간격
AppSpacing.xs(4) / sm(8) / md(16) / lg(24) / xl(32) / xxl(48)

// Border Radius
AppRadius.sm(4) / md(8) / lg(16) / xl(24) / round(999)

// 다크모드 대응 색상
final colors = ThemedColors.of(context);
Text('Title', style: AppTextStyles.h3.copyWith(color: colors.textPrimary))
```

**하드코딩 금지**: 숫자 값 직접 사용 금지 → 디자인 토큰 사용

## 다국어 지원

### 앱 내 번역 (easy_localization)
- 파일 위치: `assets/translations/{언어코드}.json`
- 75개 언어 지원
- 사용: `'common.save'.tr()`

### 스토어 메타데이터 번역
- Android: `store/metadata/android/{언어코드}.xml` (71개 언어)
- iOS: `store/metadata/ios/{언어코드}.xml` (39개 언어)
- 형식: XML (`<listing>`, `<title>`, `<short-description>`, `<full-description>`)

### 스토어 프로모션 이미지
- **Android**: `store/screenshots/promotions/android/lang/{언어코드}/promo_1~4.svg`
- **iOS**: `store/screenshots/promotions/ios/lang/{언어코드}/promo_1~4.svg`
- iOS 39개 언어, Android 71개 언어 지원
- 재생성 스크립트: `regenerate_all.sh`
- PNG 변환: `rsvg-convert promo_1.svg -o promo_1.png`

**번역 작업 시 주의**:
- 아르메니아어(hy-AM), 크메르어(km-KH) 등 특수 문자는 `translate-shell` CLI 사용
- 말투: 카카오/토스 스타일 (친근한 ~요 체)

```bash
# translate-shell 설치 및 사용
brew install translate-shell
trans -b :hy "Document Scanner"  # 아르메니아어 번역
```

## 주요 패턴

### 토스트 알림
```dart
import '../utils/app_toast.dart';

AppToast.show(context, 'Message');
AppToast.success(context, 'Success');
AppToast.error(context, 'Error');
```

### 다이얼로그
```dart
// 확인 다이얼로그
ConfirmDialog.show(context: context, title: 'Delete?', onConfirm: () async { ... });

// 이름 변경
RenameDialog.show(context: context, currentName: name, onSave: (newName) async { ... });

// 텍스트 입력
TextInputDialog.show(context: context, title: 'Save', onSave: (value) async { ... });
```

### Race Condition 방지
```dart
// 다이얼로그에서 async 작업 후 pop() 순서
onSave: (value) async {
  await saveData(value);  // 1. 먼저 저장
  Navigator.pop(context);  // 2. 그 다음 pop
},
```

### RouteAware (화면 복귀 시 리로드)
GalleryScreen은 `RouteAware`로 다른 화면에서 돌아올 때 문서 목록 자동 리로드

## 문제 해결

### 빌드 실패
```bash
flutter clean && flutter pub get
```

### iOS Pod 에러
```bash
rm -rf ios/.symlinks ios/Pods ios/Podfile.lock
flutter clean && flutter pub get
```

### arguments가 null일 때
`main.dart`의 `onGenerateRoute`에서 `settings: settings` 누락 확인

## Git 컨벤션

- `feat:` 새 기능
- `fix:` 버그 수정
- `refactor:` 리팩토링
- `docs:` 문서 수정
