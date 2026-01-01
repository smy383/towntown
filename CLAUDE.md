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

```
lib/
├── main.dart                    # App entry point (Firebase 초기화, 라우팅, VillageLand)
├── firebase_options.dart        # Firebase 설정
├── l10n/                        # 다국어 지원 (ko, en, ja)
├── models/
│   ├── user_model.dart
│   ├── village_model.dart       # 마을 + MembershipRequest + MembershipInvitation 모델
│   └── chat_model.dart          # 채팅 모델 (ChatMessage, ChatRoom)
├── providers/
│   ├── auth_provider.dart       # 인증 상태 관리
│   └── locale_provider.dart     # 언어 설정 관리
├── screens/
│   ├── auth_screen.dart         # 로그인 화면
│   ├── main_navigation_screen.dart  # 메인 네비게이션 (4탭)
│   ├── feed_screen.dart         # 피드 탭
│   ├── search_screen.dart       # 검색 탭 (마을+사용자 통합 검색)
│   ├── town_screen.dart         # 마을 탭 (전체 마을 리스트, 초대 관리)
│   ├── my_village_screen.dart   # 내 마을 상세 화면
│   ├── create_village_screen.dart   # 마을 생성 화면
│   ├── settings_screen.dart     # 설정 화면
│   ├── chat_screen.dart         # 채팅 화면 (목록 + 채팅방)
│   ├── membership_management_screen.dart  # 주민 신청/초대 관리 (이장용)
│   └── invitations_screen.dart  # 받은 초대 관리 화면
├── services/
│   ├── auth_service.dart        # 인증 서비스
│   ├── village_service.dart     # 마을 CRUD + 주민 신청/초대 서비스
│   ├── player_service.dart      # 멀티플레이어 상태 관리
│   ├── chat_service.dart        # 채팅 서비스 (1:1, 그룹)
│   └── search_service.dart      # 통합 검색 서비스
└── widgets/
    ├── globe_widget.dart        # 지구본 위젯
    └── membership_button.dart   # 주민 관리 버튼 위젯
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
- **MainNavigationScreen**: 하단 4탭 네비게이션 (피드, 검색, 마을, 설정)
- **TownScreen**: 전체 마을 리스트 (간단한 카드 형태), 초대 배지 표시
- **MyVillageScreen**: 내 마을 상세 정보 및 관리
- **CreateVillageScreen**: 마을 생성 (이름 입력, 자동 위치 배정)
- **CreateCharacterScreen**: 캐릭터 이름 입력 화면 (로그인 후 캐릭터 없으면 자동 이동)
- **CharacterDesignScreen**: 캐릭터 그리기 화면 (Firestore에 저장)
- **VillageLand**: 마을 내부 탐험 화면 (캐릭터 이동 가능)
- **MembershipManagementScreen**: 주민 신청/초대 관리 (이장 전용)
- **InvitationsScreen**: 받은 초대 목록 및 수락/거절

## Technical Notes

- Uses `CustomPainter` for character rendering instead of sprites
- Joint angles use radians (pi/2 = down, 0 = right)
- Knee joints bend forward only (positive direction)
- Elbow joints bend forward only (negative direction in angle calculation)
- Character faces direction of movement via `Matrix4.scale` transform

## Current Implementation Status

**현재 버전: 1.0.6**

### Completed
- [x] Firebase 프로젝트 설정 (neontown)
- [x] Google 로그인 (Android, iOS, Web)
- [x] Cloud Firestore 설정 (asia-northeast3)
- [x] 보안 규칙 (firestore.rules) - players, membershipRequests, membershipInvitations 포함
- [x] Firestore 인덱스 설정 (firestore.indexes.json)
- [x] 메인 네비게이션 (4탭: 피드, 검색, 마을, 설정)
- [x] 다국어 지원 (ko, en, ja)
- [x] 언어 수동 선택 기능 (설정 메뉴)
- [x] LocaleProvider (SharedPreferences 저장)
- [x] 네온사인 스타일 타이틀 (NEON: 보라 / TOWN: 시안)
- [x] 마을 생성 기능 (자동 위치 배정)
- [x] 마을 탭 - 전체 마을 리스트 (간단한 카드 UI)
- [x] 내 마을 화면 (MyVillageScreen) 분리
- [x] Firebase Hosting 배포 설정
- [x] 캐릭터 생성 화면 연결 (로그인 후 캐릭터 없으면 자동 이동)
- [x] 캐릭터 데이터 Firestore 저장 (이름 + 그림 데이터)
- [x] 마을 입장/퇴장 기능 (캐릭터 확인 후 VillageLand 진입)
- [x] 마을 수용 인원 시스템 (최대 10명, 공개/비공개)
- [x] 멀티플레이어 기능 (실시간 위치 동기화, 말풍선)
- [x] 채팅방 기능 구현 (1:1, 그룹 채팅)
- [x] 통합 검색 기능 (마을+사용자 동시 검색, 채팅 연동)
- [x] 주민 신청 기능 (MembershipRequest: pending/approved/rejected)
- [x] 주민 초대 기능 (MembershipInvitation: 이장이 사용자 초대)
- [x] 주민 관리 화면 (MembershipManagementScreen)
- [x] 초대 관리 화면 (InvitationsScreen)

### In Progress
- [ ] Apple 로그인 설정 (Apple Developer 설정 필요)
- [ ] Kakao 로그인 설정 (Kakao Developers 설정 필요)

### Pending
- [ ] 피드 기능 (게시글 작성/조회)
- [ ] 프로필/내 정보 화면

## Tech Stack

- **Flutter**: 3.35.2 (Dart 3.9.0)
- **Android SDK**: 36.0.0 (Android 16 지원)
- **16KB 페이지**: 지원됨 (Flutter 3.22+)
- **Firebase**: core 4.3.0, auth 6.1.3, firestore 6.1.1

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
