# Scannie 개발 진행 상황

## 프로젝트 개요
- **앱 이름**: Scannie
- **플랫폼**: Flutter (Android + iOS)
- **주요 기능**: 카메라로 문서 스캔 → 이미지 보정 → PDF 변환

## 완료된 작업 ✅

### 1. 프로젝트 구조 (2025-11-13 14:30)
```
lib/
├── main.dart
├── models/
│   └── scanned_document.dart
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── gallery_screen.dart
│   └── edit_screen.dart
├── services/
│   ├── image_service.dart
│   └── pdf_service.dart
└── widgets/
    └── a4_guide_overlay.dart
```

### 2. 핵심 기능 구현
- ✅ 카메라 프리뷰 + A4 가이드 오버레이
- ✅ 자동 촬영 기능 (시뮬레이션)
- ✅ 이미지 향상 (대비, 밝기, 선명도)
- ✅ 필터 기능 (원본, 향상, 흑백)
- ✅ 갤러리 화면 (드래그 앤 드롭 재정렬)
- ✅ 편집 화면 (필터, 자르기, 회전 예정)
- ✅ PDF 변환 및 공유 기능
- ✅ 무료 제한 (하루 3개 PDF)

### 3. 디자인
- ✅ Material Design 3
- ✅ 라이트/다크 모드 지원 (시스템 설정 따름)
- ✅ 심플하고 직관적인 UI

### 4. Permission 설정
- ✅ Android: AndroidManifest.xml (카메라, 저장소)
- ✅ iOS: Info.plist (카메라, 사진 라이브러리)

### 5. 패키지
- camera: ^0.11.0+2
- edge_detection: ^1.1.1
- image: ^4.1.7
- pdf: ^3.11.1
- printing: ^5.12.0
- path_provider: ^2.1.3
- permission_handler: ^11.3.1
- provider: ^6.1.2
- shared_preferences: ^2.2.3

### 6. 상태 관리 (2025-11-13 15:00)
- ✅ Provider 기반 상태 관리 구현
- ✅ DocumentProvider로 전역 문서 관리
- ✅ SharedPreferences로 문서 영구 저장
- ✅ PDF 생성 제한 완전 동작 (하루 3개, 날짜 기준 자동 리셋)
- ✅ 드래그 앤 드롭 재정렬 완벽 동작

### 7. 가격 정책
- **무료**: 하루 3개 PDF 생성
- **프리미엄**: 월 $1.00 또는 영구 구매 옵션
  - 무제한 PDF 생성
  - 업스케일링 기능
  - 광고 제거 (예정)

## 진행 중 작업 🚧

### 2025-11-13 15:20
- ✅ 첫 커밋 완료 (b0536d2)
- 🚀 실제 Edge Detection 구현 시작
- edge_detection 패키지 통합 중

## 예정 작업 📋

1. **실제 Edge Detection 구현** (현재는 시뮬레이션) - 우선순위: 높음
2. **업스케일링 기능** (Pro 기능) - 우선순위: 중간
3. **자르기/회전 기능** (편집 화면) - 우선순위: 중간
4. **통계 화면** (선택사항) - 우선순위: 낮음
5. **프리미엄 구독 페이지** (In-App Purchase 연동) - 우선순위: 높음
6. **광고 통합** (무료 버전) - 우선순위: 중간

## 알려진 이슈 ⚠️

1. Edge detection이 시뮬레이션으로 구현됨 (30% 확률로 정렬 판단)
   - 해결 방안: edge_detection 패키지 또는 Google ML Kit 사용
2. 업스케일링 기능 미구현 (Pro 기능 예정)
3. 자르기/회전 기능 UI만 있음 (실제 동작 미구현)

## 롤백 포인트 📌

### Commit 1: 기본 구조 및 UI (2025-11-13 15:15 예정)
- ✅ 프로젝트 구조 완성
- ✅ 모든 화면 구현
- ✅ Permission 설정
- ✅ Provider 상태 관리
- ✅ 문서 저장/로드 (SharedPreferences)
- ✅ PDF 생성 및 공유
- ✅ 하루 3개 PDF 제한

---

**다음 업데이트**: 코드 점검 완료 및 첫 커밋 후
