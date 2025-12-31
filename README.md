# NeonTown (네온타운)

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

### Firebase 연동
- Firebase 프로젝트: `neontown`
- 지원 플랫폼: iOS, Android, Web
- 패키지: firebase_core, firebase_auth, cloud_firestore

## 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **백엔드**: Firebase
  - Authentication (예정)
  - Cloud Firestore (예정)
  - Storage (예정)

## 다음 단계 (TODO)

- [ ] Authentication 설정 (로그인/회원가입)
- [ ] Firestore 데이터 모델 설계
- [ ] 캐릭터 데이터 저장
- [ ] 실시간 멀티플레이어 동기화
- [ ] 채팅 메시지 저장

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 웹으로 실행
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

## 프로젝트 구조

```
lib/
├── main.dart              # 메인 앱 코드
├── firebase_options.dart  # Firebase 설정
```
