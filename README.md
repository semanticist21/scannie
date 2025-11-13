# Scannie - 문서 스캔 앱

카메라로 문서를 스캔하고 PDF로 변환하는 Flutter 앱

## 주요 기능

### 🎯 핵심 기능
- **스마트 스캔**: 카메라로 문서를 촬영하면 자동으로 테두리 감지
- **자동 보정**: Perspective transform으로 문서 왜곡 자동 교정
- **이미지 향상**: 대비, 밝기, 선명도 자동 조정
- **필터**: 원본, 향상, 흑백 등 다양한 필터
- **편집**: 자르기, 회전, 필터 적용
- **PDF 변환**: 스캔한 문서를 PDF로 변환 및 공유

### 📱 사용자 경험
- Material Design 3 기반 모던한 UI
- 라이트/다크 모드 자동 지원
- 직관적이고 심플한 사용법
- 드래그 앤 드롭으로 순서 조정

### 💎 프리미엄 기능
- 무제한 PDF 생성
- 이미지 업스케일링 (2배 확대)
- 광고 제거 (예정)
- 클라우드 동기화 (예정)

## 스크린샷

_Coming Soon_

## 기술 스택

- **Framework**: Flutter 3.5+
- **상태 관리**: Provider
- **로컬 저장**: SharedPreferences
- **이미지 처리**: image, edge_detection, image_cropper
- **PDF 생성**: pdf, printing
- **카메라**: camera
- **권한**: permission_handler

## 시작하기

### 사전 요구사항
- Flutter SDK 3.5.0 이상
- Android Studio / Xcode
- Android API 21+ / iOS 12+

### 설치

```bash
# 1. 레포지토리 클론
git clone https://github.com/semanticist21/scannie.git
cd scannie

# 2. 의존성 설치
flutter pub get

# 3. 실행
flutter run
```

### 플랫폼별 설정

#### Android
AndroidManifest.xml에 이미 권한이 설정되어 있습니다:
- 카메라 권한
- 저장소 권한

#### iOS
Info.plist에 이미 권한 설명이 추가되어 있습니다:
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSPhotoLibraryAddUsageDescription

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/
│   └── scanned_document.dart    # 문서 데이터 모델
├── providers/
│   └── document_provider.dart   # 상태 관리
├── screens/
│   ├── home_screen.dart         # 홈 화면
│   ├── camera_screen.dart       # 카메라 화면
│   ├── gallery_screen.dart      # 갤러리 (보관함)
│   ├── edit_screen.dart         # 편집 화면
│   ├── edge_detection_screen.dart  # 테두리 감지 화면
│   └── premium_screen.dart      # 프리미엄 구독
├── services/
│   ├── image_service.dart       # 이미지 처리
│   └── pdf_service.dart         # PDF 생성
└── widgets/
    └── a4_guide_overlay.dart    # A4 가이드 오버레이
```

## 사용 방법

1. **스캔하기**: 하단의 "스캔하기" 버튼을 눌러 카메라 화면으로 이동
2. **촬영**: A4 가이드에 문서를 맞추고 자동 또는 수동으로 촬영
3. **확인**: 테두리가 자동으로 감지되고 보정됨
4. **편집**: 필터 적용, 자르기, 회전 등 편집 기능 사용
5. **저장**: 보관함에 자동 저장
6. **PDF 생성**: 여러 문서를 선택하고 PDF로 변환

## 가격 정책

### 무료 버전
- 하루 3개 PDF 생성
- 기본 스캔 및 편집 기능

### 프리미엄 버전
- **월간 구독**: $1.00/월
- **평생 이용권**: $9.99 (일회성 결제)
- 무제한 PDF 생성
- 고급 기능 (업스케일링 등)

## 로드맵

- [x] 기본 스캔 기능
- [x] Edge detection
- [x] PDF 변환
- [x] 프리미엄 페이지
- [ ] In-App Purchase 연동
- [ ] 광고 통합
- [ ] 클라우드 동기화
- [ ] OCR 기능
- [ ] 배치 스캔

## 기여하기

기여는 언제나 환영합니다! Pull Request를 보내주세요.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 개인 사용을 위한 것입니다.

## 연락처

프로젝트 링크: [https://github.com/semanticist21/scannie](https://github.com/semanticist21/scannie)

## 감사의 말

- [Flutter](https://flutter.dev/)
- [edge_detection](https://pub.dev/packages/edge_detection)
- [image](https://pub.dev/packages/image)
- [pdf](https://pub.dev/packages/pdf)

---

**개발**: Claude (Anthropic AI)
**날짜**: 2025-11-13
