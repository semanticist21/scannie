# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Scannie는 Flutter 멀티 플랫폼 애플리케이션입니다. 현재 초기 개발 단계로, 기본 Flutter 프로젝트 구조를 가지고 있습니다.

## 개발 환경

- Flutter SDK: main 채널 사용
- Dart SDK: >=3.5.0-236.0.dev <4.0.0
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

# 빌드 의존성 검증 건너뛰기 (Android 문제 발생 시)
flutter run -d emulator-5554 --android-skip-build-dependency-validation

# 클린 후 실행
flutter clean && flutter run
```

### 빌드 및 린트

```bash
# 프로젝트 클린 (빌드 아티팩트 제거)
flutter clean

# 린트 분석 실행
flutter analyze

# 패키지 의존성 가져오기
flutter pub get

# 패키지 업그레이드
flutter pub upgrade
```

### 테스트

```bash
# 테스트 실행 (현재 test 디렉토리 없음)
flutter test

# 특정 테스트 파일 실행
flutter test test/widget_test.dart
```

### 기기 및 플랫폼

```bash
# 사용 가능한 기기 목록 확인
flutter devices

# 연결된 기기 확인
flutter doctor -v
```

## 프로젝트 구조

```
scannie/
├── lib/                    # Dart 소스 코드
│   └── main.dart          # 앱 진입점
├── android/               # Android 네이티브 코드
├── ios/                   # iOS 네이티브 코드
├── macos/                 # macOS 네이티브 코드
├── linux/                 # Linux 네이티브 코드
├── windows/               # Windows 네이티브 코드
├── web/                   # Web 플랫폼 코드
├── pubspec.yaml          # 프로젝트 의존성 및 메타데이터
└── analysis_options.yaml  # 린트 규칙 설정
```

## 지원 플랫폼

이 프로젝트는 Flutter 멀티 플랫폼 지원이 활성화되어 있습니다:
- Android
- iOS
- macOS
- Linux
- Windows
- Web

## 아키텍처 및 코드 스타일

### 현재 상태
- 프로젝트는 초기 단계로 기본 Flutter 앱 템플릿 구조를 사용합니다
- `lib/main.dart`는 간단한 "Hello World" MaterialApp을 포함합니다
- Material Design을 사용하도록 설정되어 있습니다 (`uses-material-design: true`)

### 린트 규칙
- `flutter_lints` 패키지의 표준 규칙을 따릅니다
- `analysis_options.yaml`에서 린트 규칙 확인 가능

## 일반적인 문제 해결

### Android 빌드 문제
빌드 의존성 검증 오류가 발생하면:
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
