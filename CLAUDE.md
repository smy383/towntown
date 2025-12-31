# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeonTown (네온타운) is a village-based SNS metaverse app built with Flutter. Users can create characters, explore villages, and interact in a 2D environment.

**Target Platforms:** Android, iOS, Web

## Design Style Guide

**Theme: Cyberpunk / Neon Sign**

전체적인 디자인은 **사이버펑크 스타일의 네온사인** 컨셉을 따릅니다.

### Color Palette
- **Primary**: Cyan (`Colors.cyanAccent`)
- **Secondary**: Blue (`Colors.blueAccent`)
- **Accent**: Magenta/Pink (`Colors.pinkAccent`)
- **Background**: Black (`Colors.black`)
- **Surface**: Dark Grey (`Colors.grey[900]`)

### Neon Glow Effect
텍스트나 UI 요소에 네온 글로우 효과 적용:
```dart
shadows: [
  Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 10),
  Shadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 20),
  Shadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 30),
  Shadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 40),
]
```

### Typography
- 제목: 대문자, letterSpacing 추가, 네온 글로우
- 본문: 밝은 회색 또는 흰색

### UI Elements
- 카드/버튼: 어두운 배경에 네온 테두리 또는 글로우
- 아이콘: 네온 컬러 사용
- 구분선: 네온 컬러로 글로우 효과

## Localization (다국어 지원)

**모든 텍스트는 반드시 3개 언어를 지원해야 합니다:**

| 언어 | 코드 | ARB 파일 |
|------|------|----------|
| 한국어 | `ko` | `lib/l10n/app_ko.arb` |
| 영어 | `en` | `lib/l10n/app_en.arb` |
| 일본어 | `ja` | `lib/l10n/app_ja.arb` |

### 새 텍스트 추가 방법
1. 3개의 ARB 파일에 모두 키-값 추가
2. `flutter gen-l10n` 실행
3. 코드에서 `L10n.of(context)!.키이름` 으로 사용

### 사용 예시
```dart
import '../l10n/app_localizations.dart';

final l10n = L10n.of(context)!;
Text(l10n.homeWelcome)  // "어디로 갈까요?" / "Where to go?" / "どこへ行く?"
```

## Common Commands

```bash
# Run on Chrome (web)
flutter run -d chrome --web-port=8080

# Run on Android emulator
flutter run -d android

# Run on iOS simulator
flutter run -d ios

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Build and deploy web
flutter build web && firebase deploy --only hosting

# Build APK
flutter build apk --debug
```

## Architecture

Currently a single-file app (`lib/main.dart`) with all code in one place. As the app grows, it should follow this structure:

```
lib/
├── main.dart              # App entry point
├── screens/               # Screen widgets
├── widgets/               # Reusable widgets
├── models/                # Data models
├── services/              # Business logic
└── utils/                 # Utility functions
```

## Key Components

### Character System
- **StickmanPainter**: CustomPainter that renders a stick figure character with joint-based animation
- **WalkCycle**: Calculates pose data (hip angles, knee bends, arm swings) for walk/run animations
- **Joint**: Helper class for calculating joint positions using rotation

### Animation System
- Front view when standing still, side view when moving
- Tap to walk (slow), long press to run (fast)
- Uses `AnimationController` for movement and walk cycle animations

### Screens
- **CreateCharacterScreen**: Character name input with animated preview
- **VillageLand**: Main game area with tap-to-move character control

## Technical Notes

- Uses `CustomPainter` for character rendering instead of sprites
- Joint angles use radians (pi/2 = down, 0 = right)
- Knee joints bend forward only (positive direction)
- Elbow joints bend forward only (negative direction in angle calculation)
- Character faces direction of movement via `Matrix4.scale` transform

## Current Implementation Status

### Completed
- [x] Firebase 프로젝트 설정 (neontown)
- [x] Google 로그인 (Android, iOS, Web)
- [x] Cloud Firestore 설정 (asia-northeast3)
- [x] 보안 규칙 (firestore.rules)
- [x] HomeScreen (메인 메뉴)
- [x] 다국어 지원 (ko, en, ja)
- [x] 언어 수동 선택 기능 (설정 메뉴)
- [x] LocaleProvider (SharedPreferences 저장)
- [x] 네온사인 스타일 타이틀 (NEON: 보라 / TOWN: 시안)
- [x] 마을 생성 기능
- [x] Firebase Hosting 배포 설정

### In Progress
- [ ] Apple 로그인 설정 (Apple Developer 설정 필요)
- [ ] Kakao 로그인 설정 (Kakao Developers 설정 필요)

### Pending
- [ ] 마을 탐험 기능
- [ ] 내 마을 기능
- [ ] 캐릭터 생성 화면 연결
- [ ] 프로필/내 정보 화면

## Firebase Configuration

- **Project ID**: neontown
- **Project Number**: 471086979502
- **Firestore Region**: asia-northeast3 (Seoul)
- **Web Client ID**: 471086979502-96qdivr6mhcsfja1kc5sdllk4mgl4tnc.apps.googleusercontent.com
- **Hosting URL**: https://neontown.web.app

### Enabled APIs
- Cloud Firestore
- Firebase Authentication
- Firebase Hosting
- People API (for Google Sign-In on Web)

## Future Integration

See `TECHNICAL_GUIDE.md` for reference implementation patterns for:
- Firebase backend (Auth, Firestore, Storage, Functions)
- Authentication (Google, Apple, Kakao)
- In-app purchases (Google Play, App Store, PortOne for web)
- Real-time chat with FCM push notifications
- Provider state management
