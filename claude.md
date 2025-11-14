# Scannie 개발 진행 상황

## 프로젝트 개요
- **앱 이름**: Scannie
- **플랫폼**: Flutter (Android + iOS)
- **주요 기능**: 카메라로 문서 스캔 → 이미지 보정 → PDF 변환

## 완료된 작업 ✅

### 1. 프로젝트 구조
```
lib/
├── main.dart
├── models/
│   └── scanned_document.dart
├── providers/
│   └── document_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── gallery_screen.dart
│   ├── edit_screen.dart
│   ├── edge_detection_screen.dart
│   └── premium_screen.dart
├── services/
│   ├── image_service.dart
│   └── pdf_service.dart
└── widgets/
    └── a4_guide_overlay.dart
```

### 2. 핵심 기능 구현 (완료)
- ✅ 카메라 프리뷰 + A4 가이드 오버레이
- ✅ 자동 촬영 기능 (문서 정렬 감지 시뮬레이션)
- ✅ **실제 Edge Detection** (edge_detection 패키지 통합)
- ✅ **Perspective Transform** (문서 테두리 자동 보정)
- ✅ 이미지 향상 (대비, 밝기, 선명도)
- ✅ 필터 기능 (원본, 향상, 흑백)
- ✅ **자르기 기능** (image_cropper 패키지)
- ✅ **회전 기능** (90도 회전)
- ✅ **업스케일링 기능** (2배 확대 + 선명도 향상, Pro 기능)
- ✅ 갤러리 화면 (드래그 앤 드롭 재정렬)
- ✅ 편집 화면 (완전 동작)
- ✅ PDF 변환 및 공유 기능
- ✅ 무료 제한 (하루 3개 PDF)

### 3. 디자인
- ✅ Material Design 3
- ✅ 라이트/다크 모드 지원 (시스템 설정 따름)
- ✅ 심플하고 직관적인 UI
- ✅ 과한 애니메이션 없음

### 4. 상태 관리 & 저장
- ✅ Provider 기반 상태 관리
- ✅ DocumentProvider로 전역 문서 관리
- ✅ SharedPreferences로 문서 영구 저장
- ✅ PDF 생성 제한 완전 동작 (하루 3개, 날짜 기준 자동 리셋)

### 5. Permission 설정
- ✅ Android: AndroidManifest.xml (카메라, 저장소)
- ✅ iOS: Info.plist (카메라, 사진 라이브러리)

### 6. 프리미엄 기능
- ✅ 프리미엄 구독 페이지 UI
- ✅ 월간 구독 ($1.00/월) 및 평생 구매 ($9.99) 옵션
- ✅ 프리미엄 기능 목록 표시
- ⏳ In-App Purchase 연동 (추후 구현 예정)

### 7. 패키지
- camera: ^0.11.0+2 (카메라)
- edge_detection: ^1.1.1 (문서 테두리 감지)
- image: ^4.1.7 (이미지 처리)
- image_cropper: ^5.0.1 (이미지 자르기)
- pdf: ^3.11.1 (PDF 생성)
- printing: ^5.12.0 (PDF 공유)
- path_provider: ^2.1.3 (파일 저장)
- permission_handler: ^11.3.1 (권한)
- provider: ^6.1.2 (상태 관리)
- shared_preferences: ^2.2.3 (로컬 저장)

## 커밋 히스토리 📌

### Commit 1: b0536d2 (2025-11-13 15:15)
초기 Scannie 앱 구현
- 기본 프로젝트 구조 및 UI 구현 완료
- 모든 화면 생성 완료
- Permission 설정 완료

### Commit 2: 19aa1bd (2025-11-13 15:30)
Edge Detection 구현
- EdgeDetectionScreen 추가
- edge_detection 패키지 통합
- 카메라 촬영 후 자동 문서 테두리 감지

### Commit 3: 23469f7 (2025-11-13 15:45)
자르기/회전 기능 구현
- image_cropper 패키지 추가
- EditScreen에 자르기 기능 통합
- ImageService에 90도 회전 기능 추가

### Commit 4: bbe4950 (2025-11-13 16:00)
프리미엄 구독 페이지 구현
- PremiumScreen 추가 (월간 $1, 평생 $9.99)
- 프리미엄 기능 목록 표시
- Gallery/EditScreen에서 프리미엄 페이지 연동

### Commit 5: 22694d9 (2025-11-13 16:10)
이미지 업스케일링 기능 구현
- ImageService에 upscaleImage 메서드 추가
- 2배 크기 확대 + 선명도 향상
- Pro 기능으로 표시

## 가격 정책

### 무료 버전
- 하루 3개 PDF 생성
- 기본 스캔 기능
- 기본 필터 (원본, 향상, 흑백)
- 자르기/회전

### 프리미엄 버전
- **월간 구독**: $1.00/월
- **평생 이용권**: $9.99 (70% 할인)
- 무제한 PDF 생성
- 이미지 업스케일링
- 광고 제거 (예정)
- 클라우드 저장 (예정)
- 우선 지원

## 예정 작업 📋

### 높은 우선순위
1. **In-App Purchase 연동**
   - in_app_purchase 패키지 통합
   - Google Play Billing 및 Apple In-App Purchase 설정
   - 프리미엄 상태 체크 로직
   - 구독 복원 기능

2. **실제 자동 촬영 개선**
   - 현재 30% 확률 시뮬레이션을 실제 ML 기반으로 변경
   - Google ML Kit 또는 OpenCV 통합

### 중간 우선순위
3. **광고 통합**
   - google_mobile_ads 패키지
   - 무료 버전에 배너/전면 광고
   - 프리미엄 사용자는 광고 제거

4. **클라우드 동기화**
   - Firebase Storage 또는 AWS S3
   - 스캔한 문서 클라우드 백업
   - 여러 기기 간 동기화

5. **OCR 기능**
   - 스캔한 문서에서 텍스트 추출
   - google_ml_kit 사용
   - 검색 가능한 PDF 생성

### 낮은 우선순위
6. **통계 화면**
   - 스캔한 문서 수
   - 생성한 PDF 수
   - 저장한 용량 등

7. **추가 필터**
   - 세피아, 음화, 블루스케일 등

8. **배치 스캔**
   - 여러 페이지를 연속으로 스캔
   - 한 번에 PDF로 변환

## 알려진 제한사항 ⚠️

1. **자동 촬영이 시뮬레이션**
   - 현재: 30% 확률로 "정렬됨" 판단
   - 개선: ML Kit 또는 OpenCV로 실제 문서 감지 필요

2. **프리미엄 상태 체크 미구현**
   - 현재: 항상 프리미엄 다이얼로그 표시
   - 개선: In-App Purchase 연동 후 실제 구독 상태 체크

3. **업스케일링 품질**
   - 현재: 2배 확대 + 기본 선명화
   - 개선: AI 기반 Super Resolution (ESRGAN 등)

4. **오프라인 동작만 지원**
   - 클라우드 동기화 미구현
   - 모든 데이터가 로컬에만 저장

## 앱 스토어 출시 체크리스트 📱

### Android (Google Play)
- [ ] 앱 아이콘 제작
- [ ] 스크린샷 준비 (최소 2개)
- [ ] 앱 설명 작성 (한국어, 영어)
- [ ] 개인정보 처리방침 작성
- [ ] Google Play Console 계정 생성 ($25)
- [ ] Release APK/AAB 빌드
- [ ] In-App Purchase 상품 등록
- [ ] 베타 테스트 진행

### iOS (App Store)
- [ ] Apple Developer 계정 ($99/년)
- [ ] 앱 아이콘 제작
- [ ] 스크린샷 준비 (여러 기기 크기)
- [ ] 앱 설명 작성
- [ ] App Store Connect 설정
- [ ] Release 빌드 및 업로드
- [ ] In-App Purchase 상품 등록
- [ ] TestFlight 베타 테스트
- [ ] 앱 심사 제출

## 기술적 노트

### 이미지 처리 파이프라인
1. 카메라 촬영 → XFile
2. Edge Detection → 테두리 감지 및 Perspective Transform
3. 이미지 향상 → 대비/밝기/선명도 조정
4. 필터 적용 (선택사항)
5. 로컬 저장 (DocumentProvider)
6. PDF 변환 시 모든 이미지 병합

### 상태 관리
- Provider 패턴 사용
- DocumentProvider가 전역 상태 관리
- SharedPreferences로 영구 저장
- 앱 재시작 시 자동 로드

### PDF 생성
- pdf 패키지 사용
- A4 크기로 자동 조정
- 이미지를 페이지별로 추가
- printing 패키지로 공유 기능

---

**개발 완료**: 2025-11-13 16:15
**개발자**: Claude (Anthropic AI)
**다음 단계**: In-App Purchase 연동 및 스토어 출시 준비
