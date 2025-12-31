# TownTown (타운타운)

마을 기반 SNS 메타버스 앱

## 프로젝트 개요

네온 스타일의 캐릭터를 만들고, 마을에서 다른 사람들과 소통하는 메타버스 앱입니다.

## 현재 구현된 기능

### 캐릭터 시스템
- 캐릭터 이름 입력
- 졸라맨 실루엣 위에 그림 그리기
- 네온 글로우 효과 (빛나는 선)
- 신체 부위별 그리기 (머리, 몸통, 팔, 다리)
- 캐릭터 수정 기능 (외모 변경, 이름 변경 - 월 1회 제한)

### 마을 시스템
- RPG 스타일 카메라 (캐릭터 중심, 월드 스크롤)
- 월드 크기: 2000x2000
- 터치로 걷기, 길게 누르면 달리기
- 달리기 시 손가락 따라가기

### 채팅/말풍선
- 하단 채팅 입력창
- 캐릭터 위 말풍선 표시
- 50자 글자 제한 (실시간 카운터)
- 5초 후 자동 사라짐
- 말풍선 고정 기능 (탭하면 핀 고정)

### 소셜 로그인 (구현 완료 - 테스트 필요)
- **Google 로그인**: google_sign_in 패키지
- **Apple 로그인**: sign_in_with_apple 패키지 (iOS/macOS/Web)
- **Kakao 로그인**: kakao_flutter_sdk_user + Firebase Cloud Functions
- Provider 상태 관리
- Firestore 사용자 프로필 저장

### Firebase 연동
- Firebase 프로젝트: `neontown`
- 지원 플랫폼: iOS, Android, Web
- 사용 패키지:
  - firebase_core, firebase_auth, cloud_firestore, cloud_functions
  - provider (상태 관리)
  - google_sign_in, sign_in_with_apple, kakao_flutter_sdk_user

## 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **백엔드**: Firebase
  - Authentication (Google, Apple 활성화 필요)
  - Cloud Firestore (사용자 프로필)
  - Cloud Functions (카카오 인증)

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── firebase_options.dart        # Firebase 설정
├── models/
│   └── user_model.dart          # 사용자 모델
├── services/
│   └── auth_service.dart        # 인증 서비스
├── providers/
│   └── auth_provider.dart       # 인증 상태 관리
└── screens/
    ├── auth_screen.dart         # 로그인 화면
    ├── create_character_screen.dart
    ├── character_design_screen.dart
    └── village_land.dart

functions/
├── src/
│   ├── index.ts                 # Functions 진입점
│   └── kakao-auth.ts            # 카카오 토큰 검증
├── package.json
└── tsconfig.json
```

## 설정 필요 사항 (TODO)

### 1. Firebase Blaze Plan 업그레이드
Cloud Functions 사용을 위해 필요합니다.

### 2. API 키 설정
다음 파일에서 플레이스홀더를 실제 키로 교체:

| 파일 | 교체할 값 |
|------|----------|
| `lib/main.dart` | `YOUR_KAKAO_NATIVE_APP_KEY`, `YOUR_KAKAO_JAVASCRIPT_KEY` |
| `android/app/build.gradle.kts` | `YOUR_KAKAO_NATIVE_APP_KEY` |
| `ios/Runner/Info.plist` | `YOUR_KAKAO_NATIVE_APP_KEY` |
| `web/index.html` | Google Client ID (471086979502-XXXX) |

### 3. Firebase Console 설정
- Authentication → Google 로그인 활성화
- Authentication → Apple 로그인 활성화

### 4. Xcode 설정
- Runner → Signing & Capabilities → + Sign in with Apple

### 5. Cloud Functions 배포
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 웹으로 실행
flutter run -d chrome --web-port=8080

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

## 다음 단계 (TODO)

- [ ] API 키 설정 및 테스트
- [ ] Firebase Console에서 Google/Apple 로그인 활성화
- [ ] Cloud Functions 배포
- [ ] 캐릭터 데이터 Firestore 저장
- [ ] 실시간 멀티플레이어 동기화
- [ ] 채팅 메시지 저장
