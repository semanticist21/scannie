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
// 간격 상수 (double)
AppSpacing.xs  // 4px
AppSpacing.sm  // 8px
AppSpacing.md  // 16px (default)
AppSpacing.lg  // 24px
AppSpacing.xl  // 32px

// 간격 EdgeInsets (직접 사용)
AppSpacing.allMd          // EdgeInsets.all(16)
AppSpacing.horizontalLg   // EdgeInsets.symmetric(horizontal: 24)
AppSpacing.verticalSm     // EdgeInsets.symmetric(vertical: 8)

// Gap (Row/Column 사이 간격)
AppGap.vSm  // SizedBox(height: 8)
AppGap.hMd  // SizedBox(width: 16)

// Border Radius
AppRadius.sm   // 4px
AppRadius.md   // 8px (default)
AppRadius.lg   // 16px
AppRadius.xl   // 24px
AppRadius.round  // 999px (pills)
AppRadius.allMd  // BorderRadius.circular(8) - 직접 사용

// 다크모드 대응 색상 (ThemedColors)
final colors = ThemedColors.of(context);
colors.background      // 배경색
colors.surface         // 카드/컨테이너
colors.textPrimary     // 주 텍스트
colors.textSecondary   // 보조 텍스트
colors.border          // 테두리
colors.success / warning / error  // 상태 색상

// 그림자
AppShadows.card    // 카드용 약한 그림자
AppShadows.dialog  // 다이얼로그용 강한 그림자
AppShadows.subtle  // 미세한 그림자
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

AppToast.success(context, 'Success message');
AppToast.error(context, 'Error message');
AppToast.show(context, 'Message', isError: false);  // isError로 타입 결정

// 진행 상태 표시 (긴 작업용) - 반환된 인스턴스로 수동 dismiss
final notification = AppToast.info(context, 'Processing...');
await longOperation();
notification.dismiss();
```

### 다이얼로그
```dart
// 확인 다이얼로그 (콜백 버전)
ConfirmDialog.show(
  context: context,
  title: 'Delete?',
  message: 'Are you sure?',
  isDestructive: true,
  onConfirm: () async { ... },
);

// 확인 다이얼로그 (async 버전 - 결과 반환)
final confirmed = await ConfirmDialog.showAsync(
  context: context,
  title: 'Delete?',
  message: 'Are you sure?',
);
if (confirmed) { ... }

// 이름 변경
RenameDialog.show(context: context, currentName: name, onSave: (newName) async { ... });

// 텍스트 입력
TextInputDialog.show(context: context, title: 'Save', onSave: (value) async { ... });
```

### 모달 (WoltModalSheet 기반)
```dart
import '../utils/app_modal.dart';

// 센터 다이얼로그 (blur 배경)
AppModal.showDialog(
  context: context,
  pageListBuilder: (modalContext) => [
    WoltModalSheetPage(
      backgroundColor: ThemedColors.of(modalContext).surface,
      child: YourContent(),
    ),
  ],
);

// 바텀시트 (blur 배경)
AppModal.showBottomSheet(
  context: context,
  pageListBuilder: (modalContext) => [
    WoltModalSheetPage(
      child: Column(children: [
        AppModal.buildDragHandle(),  // 드래그 핸들
        YourContent(),
      ]),
    ),
  ],
);
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

## 스토어 업로드 스크립트

```bash
# iOS App Store Connect 업로드
python3 scripts/upload_app_store.py --all              # 전체 언어 업로드
python3 scripts/upload_app_store.py en-US              # 특정 언어만
python3 scripts/upload_app_store.py --skip-screenshots # 메타데이터만

# Google Play Store 업로드
python3 scripts/upload_play_store.py --all
python3 scripts/upload_play_store.py ko-KR
```

**필수 의존성**: `pip install pyjwt requests google-auth google-api-python-client`

## Git 컨벤션

- `feat:` 새 기능
- `fix:` 버그 수정
- `refactor:` 리팩토링
- `docs:` 문서 수정
