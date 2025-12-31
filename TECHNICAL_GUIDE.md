# 웹빵(Webbang) 기술 설명서

> Flutter 멀티플랫폼 앱 개발을 위한 종합 기술 가이드
>
> 이 문서는 웹빵 프로젝트에서 사용된 핵심 기술들을 다른 프로젝트에서 재사용할 수 있도록 정리한 기술 설명서입니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [프로젝트 구조](#2-프로젝트-구조)
3. [인증 시스템](#3-인증-시스템)
4. [결제 시스템](#4-결제-시스템)
5. [실시간 채팅](#5-실시간-채팅)
6. [푸시 알림 (FCM)](#6-푸시-알림-fcm)
7. [Firebase 백엔드](#7-firebase-백엔드)
8. [멀티플랫폼 설정](#8-멀티플랫폼-설정)
9. [보안 아키텍처](#9-보안-아키텍처)
10. [성능 최적화](#10-성능-최적화)

---

## 1. 프로젝트 개요

### 1.1 기술 스택

| 분류 | 기술 |
|------|------|
| **Frontend** | Flutter 3.9+, Dart |
| **State Management** | Provider |
| **Backend** | Firebase (Firestore, Auth, Storage, Functions) |
| **Push Notification** | Firebase Cloud Messaging (FCM) |
| **Payment** | Google Play Billing, App Store IAP, PortOne (Web) |
| **Authentication** | Google, Apple, Kakao, Email/Password |

### 1.2 지원 플랫폼

- **Android**: Min SDK 21, Target SDK 34
- **iOS**: iOS 12+
- **Web**: Firebase Hosting

### 1.3 주요 패키지 (pubspec.yaml)

```yaml
dependencies:
  # State Management
  provider: ^6.1.2

  # Firebase
  firebase_core: ^4.1.0
  firebase_auth: ^6.0.2
  cloud_firestore: ^6.0.1
  firebase_storage: ^13.0.1
  firebase_messaging: ^16.0.1
  cloud_functions: ^6.0.1
  firebase_app_check: ^0.4.0+1

  # Social Login
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^7.0.1
  kakao_flutter_sdk_user: ^1.9.5

  # Payment
  in_app_purchase: ^3.2.1

  # Storage
  shared_preferences: ^2.5.3
  sqflite: ^2.4.0

  # Media
  image_picker: ^1.1.2
  just_audio: ^0.9.40
  cached_network_image: ^3.4.1
  flutter_image_compress: ^2.1.0

  # Utilities
  uuid: ^4.5.1
  intl: ^0.20.2
  http: ^1.2.2
  connectivity_plus: ^6.1.0
  permission_handler: ^11.3.1
```

---

## 2. 프로젝트 구조

### 2.1 디렉토리 구조

```
lib/
├── main.dart                 # 앱 진입점
├── firebase_options.dart     # Firebase 설정 (자동 생성)
├── screens/                  # 화면 UI (61개)
│   ├── auth_screen.dart
│   ├── main_navigation_screen.dart
│   ├── chat_room_screen.dart
│   └── ...
├── services/                 # 비즈니스 로직 (49개)
│   ├── auth_service.dart
│   ├── in_app_purchase_service.dart
│   ├── chat_service.dart
│   ├── notification_service.dart
│   └── ...
├── models/                   # 데이터 모델 (20개)
│   ├── user_model.dart
│   ├── chat_model.dart
│   ├── point_model.dart
│   └── ...
├── widgets/                  # 재사용 위젯 (28개)
├── providers/                # 상태 관리
├── config/                   # 설정 파일
├── utils/                    # 유틸리티 함수
└── rules/                    # 비즈니스 규칙

functions/                    # Firebase Cloud Functions (Node.js)
├── src/
│   ├── index.ts              # 메인 진입점
│   ├── points.ts             # 포인트/영수증 검증
│   ├── admin.ts              # 관리자 권한
│   ├── kakao-auth.ts         # 카카오 인증
│   └── portone-webhook.ts    # 웹 결제 웹훅
└── package.json
```

### 2.2 아키텍처 패턴

```
┌─────────────────────────────────────────────────────┐
│                    Screens (UI)                      │
├─────────────────────────────────────────────────────┤
│                   Providers (State)                  │
├─────────────────────────────────────────────────────┤
│                  Services (Business Logic)           │
├─────────────────────────────────────────────────────┤
│                   Models (Data)                      │
├─────────────────────────────────────────────────────┤
│              Firebase (Backend + Storage)            │
└─────────────────────────────────────────────────────┘
```

---

## 3. 인증 시스템

웹빵은 4가지 로그인 방식을 지원합니다.

### 3.1 Google 로그인

#### 설정

**Android (android/app/build.gradle)**
```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

**iOS (ios/Runner/Info.plist)**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Google Sign In URL Scheme -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Web (web/index.html)**
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

#### 구현 코드

```dart
// lib/services/auth_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Google Sign In 객체 초기화
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // 웹이 아닌 경우에만 serverClientId 설정
        serverClientId: kIsWeb ? null : 'YOUR_SERVER_CLIENT_ID',
      );

      // 2. Google 계정 선택 화면 표시
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // 사용자 취소

      // 3. 인증 토큰 획득
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // 6. 사용자 프로필 생성/업데이트
      await _createOrUpdateUserProfile(userCredential.user!);

      return userCredential;
    } catch (e) {
      debugPrint('Google 로그인 에러: $e');
      rethrow;
    }
  }
}
```

### 3.2 Apple 로그인

#### 설정

**iOS (Xcode)**
1. Signing & Capabilities에서 "Sign in with Apple" 추가
2. Apple Developer Console에서 App ID 설정

**Web (Firebase Console)**
1. Authentication > Sign-in method > Apple 활성화
2. Services ID 설정

#### 구현 코드

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<UserCredential?> signInWithApple() async {
  try {
    if (kIsWeb) {
      // Web: OAuth 팝업 사용
      final provider = OAuthProvider("apple.com")
        ..addScope('email')
        ..addScope('name');
      return await _auth.signInWithPopup(provider);
    } else {
      // iOS/macOS: 네이티브 Apple Sign In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(oauthCredential);
    }
  } catch (e) {
    debugPrint('Apple 로그인 에러: $e');
    rethrow;
  }
}
```

### 3.3 카카오 로그인

카카오 로그인은 Firebase Custom Token을 사용합니다.

#### 설정

**pubspec.yaml**
```yaml
kakao_flutter_sdk_user: ^1.9.5
```

**Android (android/app/build.gradle)**
```gradle
manifestPlaceholders = [
    'KAKAO_NATIVE_APP_KEY': 'YOUR_KAKAO_NATIVE_APP_KEY'
]
```

**iOS (ios/Runner/Info.plist)**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakaoYOUR_NATIVE_APP_KEY</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
</array>
```

#### 클라이언트 구현

```dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<UserCredential?> signInWithKakao() async {
  try {
    OAuthToken token;

    if (kIsWeb) {
      // Web: 팝업 로그인
      token = await UserApi.instance.loginWithKakaoAccount();
    } else {
      // Mobile: 카카오톡 앱 우선, 없으면 웹 로그인
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    }

    // Firebase Function 호출하여 Custom Token 발급
    final callable = FirebaseFunctions.instance.httpsCallable('verifyKakaoToken');
    final result = await callable.call({
      'accessToken': token.accessToken,
    });

    // Custom Token으로 Firebase 로그인
    final customToken = result.data['customToken'];
    return await _auth.signInWithCustomToken(customToken);

  } catch (e) {
    debugPrint('카카오 로그인 에러: $e');
    rethrow;
  }
}
```

#### 서버 구현 (Firebase Functions)

```typescript
// functions/src/kakao-auth.ts

import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export const verifyKakaoToken = onCall(async (request) => {
  const accessToken = request.data.accessToken;

  // 1. 카카오 API로 사용자 정보 조회
  const userInfo = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { 'Authorization': `Bearer ${accessToken}` },
  });
  const kakaoUser = await userInfo.json();

  // 2. 기존 Firebase 사용자 확인
  let existingUser;
  try {
    existingUser = await admin.auth()
      .getUserByEmail(kakaoUser.kakao_account.email);
  } catch (e) {
    // 새 사용자 생성
    existingUser = await admin.auth().createUser({
      email: kakaoUser.kakao_account.email,
      displayName: kakaoUser.kakao_account.profile.nickname,
      photoURL: kakaoUser.kakao_account.profile.profile_image_url,
    });
  }

  // 3. Custom Token 발급
  const customToken = await admin.auth().createCustomToken(existingUser.uid);

  return {
    customToken,
    needsUsernameSetup: !existingUser.displayName,
  };
});
```

### 3.4 사용자 프로필 생성

```dart
Future<void> _createOrUpdateUserProfile(User firebaseUser) async {
  final userDoc = FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid);

  final doc = await userDoc.get();

  if (!doc.exists) {
    // 새 사용자 프로필 생성
    await userDoc.set({
      'id': firebaseUser.uid,
      'email': firebaseUser.email,
      'username': '', // 나중에 설정
      'displayName': firebaseUser.displayName ?? '',
      'photoURL': firebaseUser.photoURL ?? '',
      'joinDate': FieldValue.serverTimestamp(),
      'pPoints': 0,  // 충전 포인트
      'gPoints': 0,  // 수익 포인트
      'role': 'escaper',
      'creatorTier': 'amateur',
    });

    _needsUsernameSetup = true;
  } else {
    // FCM 토큰 업데이트
    await userDoc.update({
      'fcmToken': await FirebaseMessaging.instance.getToken(),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### 3.5 Firestore 보안 규칙 (인증)

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 인증 확인 함수
    function isAuthenticated() {
      return request.auth != null;
    }

    // 본인 확인 함수
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // 관리자 확인 함수
    function isAdmin() {
      return request.auth != null &&
             (request.auth.token.admin == true ||
              request.auth.token.superAdmin == true);
    }

    // 사용자 컬렉션
    match /users/{userId} {
      // 읽기: 모든 인증 사용자
      allow read: if isAuthenticated();

      // 생성: 본인만
      allow create: if isOwner(userId);

      // 수정: 본인만 (민감 필드 제외)
      allow update: if isOwner(userId) &&
        !request.resource.data.diff(resource.data).affectedKeys().hasAny([
          'pPoints', 'gPoints', 'creatorTier', 'role'
        ]);

      // 민감 필드 수정: 관리자만
      allow update: if isAdmin();
    }
  }
}
```

---

## 4. 결제 시스템

### 4.1 포인트 구조

```dart
// 포인트 타입
// P Points (Purchase): 사용자가 구매한 포인트 - 콘텐츠 이용에 사용
// G Points (Game revenue): 제작자가 받은 수익 - 출금만 가능
```

### 4.2 Android 인앱 결제 (Google Play Billing)

#### 상품 정의

```dart
// lib/services/in_app_purchase_service.dart

class InAppPurchaseService {
  static const List<String> _productIds = [
    'esc_points_1000',   // ₩1,000 → 1000P
    'esc_points_2000',   // ₩2,000 → 2000P
    'esc_points_3000',   // ₩3,000 → 3000P + 100 보너스
    'esc_points_5000',   // ₩5,000 → 5000P + 200 보너스
    'esc_points_10000',  // ₩10,000 → 10000P + 500 보너스
  ];

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
}
```

#### 초기화 및 상품 로드

```dart
Future<void> initialize() async {
  // 1. IAP 사용 가능 여부 확인
  final available = await _inAppPurchase.isAvailable();
  if (!available) {
    throw Exception('인앱 결제를 사용할 수 없습니다.');
  }

  // 2. 구매 스트림 리스너 등록
  _subscription = _inAppPurchase.purchaseStream.listen(
    _onPurchaseUpdate,
    onError: (error) => debugPrint('구매 스트림 에러: $error'),
  );

  // 3. 상품 정보 로드
  final response = await _inAppPurchase.queryProductDetails(_productIds.toSet());
  if (response.notFoundIDs.isNotEmpty) {
    debugPrint('찾을 수 없는 상품: ${response.notFoundIDs}');
  }
  _products = response.productDetails;

  // 4. 미완료 구매 복구
  await _inAppPurchase.restorePurchases();
}
```

#### 상품 구매

```dart
Future<void> buyProduct(String productId) async {
  final product = _products.firstWhere(
    (p) => p.id == productId,
    orElse: () => throw Exception('상품을 찾을 수 없습니다.'),
  );

  final purchaseParam = PurchaseParam(productDetails: product);

  // 소모성 상품으로 구매 (재구매 가능)
  await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
}
```

#### 구매 처리

```dart
void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
  for (final purchase in purchases) {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // 결제 대기 중 UI 표시
        _showLoadingIndicator();
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // 영수증 검증 및 포인트 추가
        _handleSuccessfulPurchase(purchase);
        break;

      case PurchaseStatus.error:
        debugPrint('구매 에러: ${purchase.error}');
        _hideLoadingIndicator();
        break;

      case PurchaseStatus.canceled:
        _hideLoadingIndicator();
        break;
    }
  }
}

Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
  try {
    // 1. 서버에서 영수증 검증
    final result = await _verifyAndAddPoints(purchase);

    if (result['success']) {
      // 2. 구매 완료 처리 (중복 방지)
      await _inAppPurchase.completePurchase(purchase);

      // 3. 성공 UI 표시
      _showSuccessDialog(result['addedPoints']);
    }
  } catch (e) {
    debugPrint('구매 처리 에러: $e');
  } finally {
    _hideLoadingIndicator();
  }
}
```

#### 서버 영수증 검증 (Firebase Functions)

```typescript
// functions/src/points.ts

import { onCall } from 'firebase-functions/v2/https';
import { google } from 'googleapis';

export const addPoints = onCall(async (request) => {
  const { userId, amount, platform, purchaseToken, productId, packageName } = request.data;

  // 1. Android 영수증 검증
  if (platform === 'android') {
    const isValid = await verifyGooglePlayPurchase(
      packageName,
      productId,
      purchaseToken
    );

    if (!isValid) {
      throw new Error('영수증 검증 실패');
    }
  }

  // 2. Firestore 트랜잭션으로 포인트 추가
  await admin.firestore().runTransaction(async (transaction) => {
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await transaction.get(userRef);

    if (!userDoc.exists) {
      throw new Error('사용자를 찾을 수 없습니다.');
    }

    const currentPoints = userDoc.data()?.pPoints || 0;

    // 포인트 추가
    transaction.update(userRef, {
      pPoints: currentPoints + amount,
    });

    // 거래 기록 생성
    const transactionRef = admin.firestore().collection('point_transactions').doc();
    transaction.set(transactionRef, {
      id: transactionRef.id,
      userId,
      type: 'purchase',
      amount,
      balanceBefore: currentPoints,
      balanceAfter: currentPoints + amount,
      status: 'completed',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { productId, platform },
    });
  });

  return { success: true, addedPoints: amount };
});

async function verifyGooglePlayPurchase(
  packageName: string,
  productId: string,
  purchaseToken: string
): Promise<boolean> {
  // Google API 인증
  const auth = new google.auth.GoogleAuth({
    credentials: require('./service-account.json'),
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const androidPublisher = google.androidpublisher({ version: 'v3', auth });

  try {
    const response = await androidPublisher.purchases.products.get({
      packageName,
      productId,
      token: purchaseToken,
    });

    // purchaseState: 0 = 구매 완료
    // consumptionState: 0 = 미사용 (첫 구매)
    return response.data.purchaseState === 0 &&
           response.data.consumptionState === 0;
  } catch (e) {
    console.error('영수증 검증 에러:', e);
    return false;
  }
}
```

### 4.3 웹 결제 (PortOne V2)

#### 설정

```html
<!-- web/index.html -->
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
```

#### 구현 코드

```dart
// lib/services/web_payment_service_web.dart

import 'dart:js' as js;

class WebPaymentService {
  static const String storeId = 'store-YOUR-STORE-ID';

  // 결제 채널 설정
  static const channels = [
    {
      'channelKey': 'channel-key-xxx',
      'name': '카카오페이',
      'pgProvider': 'kakaopay',
      'payMethod': 'EASY_PAY',
    },
  ];

  Future<Map<String, dynamic>> requestPayment({
    required String userId,
    required String productId,
    required int amount,
    required int totalPoints,
    required String channelKey,
    required String payMethod,
  }) async {
    final paymentId = Uuid().v4().replaceAll('-', '');

    final paymentData = js.JsObject.jsify({
      'storeId': storeId,
      'channelKey': channelKey,
      'paymentId': paymentId,
      'orderName': '빵 ${totalPoints}개',
      'totalAmount': amount,
      'currency': 'CURRENCY_KRW',
      'payMethod': payMethod,
      'redirectUrl': html.window.location.href,
      'customer': {
        'customerId': userId,
        'fullName': '사용자',
      },
      'customData': {
        'userId': userId,
        'productId': productId,
        'pointAmount': amount,
        'totalPoints': totalPoints,
      },
    });

    // PortOne SDK 호출
    final portOne = js.context['PortOne'];
    final promise = portOne.callMethod('requestPayment', [paymentData]);

    // Promise를 Future로 변환
    final result = await _promiseToFuture(promise);

    return {
      'success': result['code'] == null,
      'paymentId': paymentId,
    };
  }
}
```

#### 웹훅 처리 (서버)

```typescript
// functions/src/portone-webhook.ts

import { onRequest } from 'firebase-functions/v2/https';
import * as crypto from 'crypto';

export const portoneWebhook = onRequest(async (request, response) => {
  try {
    // 1. 웹훅 서명 검증
    const signature = request.headers['webhook-signature'] as string;
    if (!verifyWebhookSignature(signature, request.rawBody)) {
      return response.status(401).json({ error: 'Unauthorized' });
    }

    // 2. 결제 정보 추출
    const paymentData = request.body.data.payment;
    const customData = JSON.parse(paymentData.customData);

    // 3. PortOne API로 결제 상세 조회
    const accessToken = await getPortOneAccessToken();
    const paymentDetail = await fetch(
      `https://api.portone.io/v2/payments/${paymentData.id}`,
      { headers: { 'Authorization': `Bearer ${accessToken}` } }
    );
    const payment = await paymentDetail.json();

    // 4. 결제 상태 및 금액 확인
    if (payment.status !== 'PAID') {
      return response.status(400).json({ error: 'Invalid payment status' });
    }

    if (payment.amount.total !== customData.totalPrice) {
      return response.status(400).json({ error: 'Amount mismatch' });
    }

    // 5. 포인트 추가 (addPoints 함수 재사용)
    await addPointsToUser(customData.userId, customData.totalPoints);

    return response.status(200).json({ success: true });

  } catch (error) {
    console.error('Webhook error:', error);
    return response.status(500).json({ error: error.message });
  }
});

function verifyWebhookSignature(signature: string, body: Buffer): boolean {
  const webhookSecret = process.env.PORTONE_WEBHOOK_SECRET;
  const expectedSig = crypto
    .createHmac('sha256', webhookSecret)
    .update(body)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSig)
  );
}
```

### 4.4 환불 시스템

```dart
// lib/services/refund_service.dart

class RefundService {

  // 환불 가능 조건 확인
  Future<bool> canRequestRefund(PointTransaction transaction) async {
    // 1. 충전 거래인지 확인
    if (transaction.type != PointTransactionType.purchase) return false;

    // 2. 본인 거래인지 확인
    if (transaction.userId != _auth.currentUser?.uid) return false;

    // 3. 7일 이내인지 확인
    final daysSincePurchase = DateTime.now()
        .difference(transaction.timestamp)
        .inDays;
    if (daysSincePurchase > 7) return false;

    // 4. 포인트 사용 여부 확인
    final hasUsed = await _hasUsedPointsAfterPurchase(transaction);
    if (hasUsed) return false;

    // 5. 이미 환불 신청했는지 확인
    final hasRequest = await _hasRefundRequest(transaction.id);
    if (hasRequest) return false;

    return true;
  }

  // 환불 신청 생성
  Future<void> createRefundRequest(PointTransaction transaction) async {
    // 1. 환불 가능 여부 재확인
    if (!await canRequestRefund(transaction)) {
      throw Exception('환불 조건을 충족하지 않습니다.');
    }

    // 2. 포인트 즉시 차감
    await _pointService.spendPoints(
      transaction.userId,
      transaction.amount,
      description: '환불 신청',
      metadata: {'type': 'refund_request'},
    );

    // 3. 환불 신청 문서 생성
    await _firestore.collection('refund_requests').add({
      'userId': transaction.userId,
      'transactionId': transaction.id,
      'amount': transaction.amount,
      'refundPrice': _calculateRefundPrice(transaction),
      'paymentMethod': transaction.metadata['platform'],
      'status': 'pending',
      'requestTime': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## 5. 실시간 채팅

### 5.1 데이터 모델

```dart
// lib/models/chat_model.dart

enum ChatRoomType {
  recruitment,  // 모집 단체 채팅
  admin,        // 관리자 1:1 채팅
  direct,       // 사용자 간 DM
}

enum MessageType {
  text,     // 텍스트
  image,    // 이미지
  system,   // 시스템 메시지
  join,     // 입장
  leave,    // 퇴장
}

class ChatRoom {
  final String id;
  final ChatRoomType type;
  final String postTitle;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final bool isActive;

  // 모집 채팅용
  final String? recruitmentPostId;
  final DateTime? eventDate;
  final String? eventTime;
  final String? location;
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String? content;
  final String? imagePath;
  final DateTime timestamp;
}
```

### 5.2 채팅방 생성

```dart
// lib/services/chat_service.dart

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 모집 채팅방 생성
  Future<String> createRecruitmentChatRoom({
    required String postId,
    required String postTitle,
    required List<String> participantIds,
    DateTime? eventDate,
    String? eventTime,
    String? location,
  }) async {
    final chatRoomRef = _firestore.collection('chatRooms').doc();

    final chatRoom = ChatRoom(
      id: chatRoomRef.id,
      type: ChatRoomType.recruitment,
      recruitmentPostId: postId,
      postTitle: postTitle,
      participantIds: participantIds,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      isActive: true,
      eventDate: eventDate,
      eventTime: eventTime,
      location: location,
    );

    // 배치 쓰기로 효율성 확보
    final batch = _firestore.batch();

    // 채팅방 생성
    batch.set(chatRoomRef, chatRoom.toFirestore());

    // 각 참여자의 알림 설정 생성
    for (final participantId in participantIds) {
      final settingsRef = _firestore
          .collection('userChatSettings')
          .doc('${participantId}_${chatRoomRef.id}');

      batch.set(settingsRef, {
        'userId': participantId,
        'chatRoomId': chatRoomRef.id,
        'notificationsEnabled': true,
      });
    }

    await batch.commit();

    // 시스템 메시지 추가
    await sendMessage(
      chatRoomId: chatRoomRef.id,
      type: MessageType.system,
      content: '채팅방이 개설되었습니다.',
    );

    return chatRoomRef.id;
  }
}
```

### 5.3 메시지 전송

```dart
Future<void> sendMessage({
  required String chatRoomId,
  required MessageType type,
  String? content,
  String? imagePath,
}) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('로그인이 필요합니다.');

  final messageRef = _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .doc();

  final message = ChatMessage(
    id: messageRef.id,
    chatRoomId: chatRoomId,
    senderId: user.uid,
    senderName: user.displayName ?? '익명',
    type: type,
    content: content,
    imagePath: imagePath,
    timestamp: DateTime.now(),
  );

  final batch = _firestore.batch();

  // 메시지 저장
  batch.set(messageRef, message.toFirestore());

  // 채팅방 메타데이터 업데이트
  batch.update(
    _firestore.collection('chatRooms').doc(chatRoomId),
    {
      'lastMessage': content ?? '[이미지]',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSender': user.displayName,
    },
  );

  await batch.commit();

  // 푸시 알림 전송 (발신자 제외)
  await _notificationService.sendChatMessageNotification(
    chatRoomId: chatRoomId,
    senderId: user.uid,
    senderName: user.displayName ?? '익명',
    content: content ?? '[이미지]',
  );
}
```

### 5.4 실시간 구독 (Streams)

```dart
// 채팅방 목록 구독
Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
  return _firestore
      .collection('chatRooms')
      .where('participantIds', arrayContains: userId)
      .where('isActive', isEqualTo: true)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data()))
          .toList());
}

// 메시지 구독
Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
  return _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(100)  // 최신 100개만
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data()))
          .toList());
}
```

### 5.5 이미지 메시지

```dart
// lib/services/chat_image_service.dart

class ChatImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadChatImage({
    required String chatRoomId,
    required File imageFile,
  }) async {
    // 1. 이미지 압축
    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 80,
    );

    if (compressed == null) throw Exception('이미지 압축 실패');

    // 2. Storage에 업로드
    final fileName = '${Uuid().v4()}.jpg';
    final ref = _storage.ref('chat_images/$chatRoomId/$fileName');

    await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // 3. 다운로드 URL 반환
    return await ref.getDownloadURL();
  }
}
```

### 5.6 Firestore 구조

```
chatRooms/{chatRoomId}
├── id: string
├── type: 'recruitment' | 'admin' | 'direct'
├── postTitle: string
├── participantIds: [userId, ...]
├── createdAt: timestamp
├── lastMessageAt: timestamp
├── lastMessage: string
├── lastMessageSender: string
├── isActive: boolean
│
└── messages/{messageId}
    ├── id: string
    ├── senderId: string
    ├── senderName: string
    ├── type: 'text' | 'image' | 'system'
    ├── content: string
    ├── imagePath: string
    └── timestamp: timestamp

userChatSettings/{`${userId}_${chatRoomId}`}
├── userId: string
├── chatRoomId: string
└── notificationsEnabled: boolean
```

---

## 6. 푸시 알림 (FCM)

### 6.1 초기화

```dart
// lib/services/notification_service.dart

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  Future<void> initialize() async {
    // 1. 알림 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('알림 권한이 거부되었습니다.');
      return;
    }

    // 2. FCM 토큰 획득 (모바일만)
    if (!kIsWeb) {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // 토큰을 Firestore에 저장
      await _updateUserFcmToken(_fcmToken!);
    }

    // 3. 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _updateUserFcmToken(newToken);
    });

    // 4. 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. 백그라운드 메시지 핸들러 (main.dart에서도 설정 필요)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _updateUserFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### 6.2 포그라운드 메시지 처리

```dart
void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');

  // 특수 알림 처리
  final type = message.data['type'];

  switch (type) {
    case 'force_logout':
      // 다른 기기에서 로그인됨
      _handleForceLogout(message.data);
      break;

    case 'chat_message':
      // 현재 활성 채팅방 메시지인지 확인
      if (_currentActiveChatRoomId == message.data['chatRoomId']) {
        return; // 이미 화면에 표시 중이면 알림 스킵
      }
      _showLocalNotification(message);
      break;

    default:
      _showLocalNotification(message);
  }
}

void _handleForceLogout(Map<String, dynamic> data) {
  showDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('알림'),
      content: const Text('다른 기기에서 로그인되어 로그아웃됩니다.'),
      actions: [
        TextButton(
          onPressed: () async {
            await AuthService().signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          },
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
```

### 6.3 서버에서 알림 전송

```typescript
// functions/src/index.ts

import * as admin from 'firebase-admin';

// 채팅 메시지 생성 시 자동 알림
export const onChatMessageCreated = functions.firestore
  .document('chatRooms/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatRoomId } = context.params;

    // 채팅방 정보 조회
    const chatRoomDoc = await admin.firestore()
      .collection('chatRooms')
      .doc(chatRoomId)
      .get();

    if (!chatRoomDoc.exists) return;

    const chatRoom = chatRoomDoc.data()!;
    const participantIds = chatRoom.participantIds as string[];

    // 발신자 제외
    const recipients = participantIds.filter(id => id !== message.senderId);

    // 배치 쿼리로 사용자 정보 조회
    const users = await batchGetUsers(recipients);

    for (const user of users) {
      // 알림 설정 확인
      const settingsDoc = await admin.firestore()
        .collection('userChatSettings')
        .doc(`${user.id}_${chatRoomId}`)
        .get();

      // null이면 기본값 true (알림 활성화)
      const notificationsEnabled =
        settingsDoc.data()?.notificationsEnabled ?? true;

      if (!notificationsEnabled) continue;
      if (!user.fcmToken) continue;

      // 알림 전송
      try {
        await admin.messaging().send({
          token: user.fcmToken,
          notification: {
            title: `${message.senderName}님의 메시지`,
            body: message.content?.substring(0, 50) || '[이미지]',
          },
          data: {
            type: 'chat_message',
            chatRoomId,
            messageId: snap.id,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'chat_messages',
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: 'default',
              },
            },
          },
        });
      } catch (e) {
        console.error(`알림 전송 실패 (${user.id}):`, e);
      }
    }
  });

// 배치 쿼리 헬퍼 (성능 최적화)
async function batchGetUsers(userIds: string[]): Promise<any[]> {
  const users: any[] = [];

  // Firestore는 'in' 쿼리에 최대 10개 제한
  for (let i = 0; i < userIds.length; i += 10) {
    const batch = userIds.slice(i, i + 10);
    const snapshot = await admin.firestore()
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', batch)
      .get();

    users.push(...snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    })));
  }

  return users;
}
```

### 6.4 Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<application>
    <!-- FCM 기본 알림 아이콘 -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />

    <!-- FCM 기본 알림 색상 -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_color" />

    <!-- FCM 기본 채널 ID -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="default_channel" />
</application>
```

### 6.5 iOS 설정

1. Apple Developer Console에서 APNs 키 생성
2. Firebase Console > Project Settings > Cloud Messaging에서 APNs 키 업로드
3. Xcode에서 Push Notifications capability 추가

---

## 7. Firebase 백엔드

### 7.1 Firestore 데이터 모델

#### users 컬렉션
```javascript
{
  id: string,
  username: string,
  email: string,
  displayName: string,
  photoURL: string,

  // 계정
  joinDate: Timestamp,
  status: 'active' | 'inactive',

  // 역할
  role: 'creator' | 'escaper' | 'both',
  creatorTier: 'amateur' | 'professional' | ...,

  // 포인트
  pPoints: number,  // 충전 포인트
  gPoints: number,  // 수익 포인트

  // FCM
  fcmToken: string,
  fcmTokenUpdatedAt: Timestamp,
}
```

#### point_transactions 컬렉션
```javascript
{
  id: string,
  userId: string,
  type: 'purchase' | 'spend' | 'refund' | 'revenueShare',
  amount: number,
  balanceBefore: number,
  balanceAfter: number,
  status: 'pending' | 'completed' | 'failed',
  timestamp: Timestamp,
  description: string,
  metadata: { ... },
}
```

### 7.2 Storage 보안 규칙

```javascript
// storage.rules

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // 인증 확인
    function isAuthenticated() {
      return request.auth != null;
    }

    // 파일 크기 확인
    function isValidImageSize() {
      return request.resource.size < 5 * 1024 * 1024; // 5MB
    }

    function isValidAudioSize() {
      return request.resource.size < 10 * 1024 * 1024; // 10MB
    }

    // 프로필 이미지
    match /users/{userId}/profile/{fileName} {
      allow read: if true;
      allow write: if isAuthenticated() &&
                      request.auth.uid == userId &&
                      isValidImageSize();
    }

    // 채팅 이미지
    match /chat_images/{chatRoomId}/{fileName} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isValidImageSize();
    }

    // 콘텐츠 이미지
    match /rooms/{roomId}/{allPaths=**} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
  }
}
```

### 7.3 Cloud Functions 구조

```typescript
// functions/src/index.ts

import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Callable 함수들
export { addPoints, verifyGooglePlayPurchase } from './points';
export { verifyKakaoToken } from './kakao-auth';
export { grantAdminRole, revokeAdminRole } from './admin';
export { portoneWebhook } from './portone-webhook';

// Firestore 트리거
export const onChatMessageCreated = functions.firestore
  .document('chatRooms/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    // 채팅 알림 전송
  });

// 스케줄러
export const checkCreatorTiers = functions.scheduler
  .onSchedule({ schedule: '0 0 * * *', timeZone: 'Asia/Seoul' })
  .run(async () => {
    // 매일 자정 제작자 등급 자동 승급 확인
  });
```

---

## 8. 멀티플랫폼 설정

### 8.1 Android 설정

#### build.gradle (app)
```gradle
android {
    defaultConfig {
        applicationId "com.your.app.id"
        minSdkVersion 21
        targetSdkVersion 34

        // Kakao 네이티브 앱 키
        manifestPlaceholders = [
            'KAKAO_NATIVE_APP_KEY': 'your_kakao_native_app_key'
        ]
    }

    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword "password"
            keyAlias "alias"
            keyPassword "password"
        }
    }
}

dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
    implementation 'com.android.billingclient:billing:6.0.1'
}
```

### 8.2 iOS 설정

#### Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <!-- URL Schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <!-- Google Sign In -->
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
            </array>
        </dict>
        <!-- Kakao -->
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>kakaoYOUR_NATIVE_APP_KEY</string>
            </array>
        </dict>
    </array>

    <!-- Kakao Query Schemes -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>kakaokompassauth</string>
        <string>kakaolink</string>
    </array>
</dict>
</plist>
```

### 8.3 Web 설정

#### index.html
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Google Sign In -->
    <meta name="google-signin-client_id"
          content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">

    <!-- PortOne 결제 SDK -->
    <script src="https://cdn.portone.io/v2/browser-sdk.js"></script>

    <!-- Kakao SDK -->
    <script src="https://developers.kakao.com/sdk/js/kakao.js"></script>
    <script>
        Kakao.init('YOUR_JAVASCRIPT_KEY');
    </script>
</head>
<body>
    <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

### 8.4 플랫폼별 분기 처리

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// 플랫폼 확인
bool get isAndroid => !kIsWeb && Platform.isAndroid;
bool get isIOS => !kIsWeb && Platform.isIOS;
bool get isWeb => kIsWeb;
bool get isMobile => isAndroid || isIOS;

// 플랫폼별 기능 분기
void initializePlatformFeatures() {
  if (isWeb) {
    // 웹: FCM 비활성화, PortOne 결제 사용
    initWebPayment();
  } else if (isAndroid) {
    // Android: FCM 활성화, Google Play Billing
    initFCM();
    initGooglePlayBilling();
  } else if (isIOS) {
    // iOS: FCM 활성화, App Store IAP
    initFCM();
    initAppStoreIAP();
  }
}
```

---

## 9. 보안 아키텍처

### 9.1 인증 보안

```dart
// Custom Claims를 통한 권한 관리
// Firebase Admin SDK에서 설정

// 클라이언트에서 Claims 확인
Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final token = await user.getIdTokenResult();
  return token.claims?['admin'] == true;
}
```

### 9.2 결제 보안

```
┌──────────────────────────────────────────────────────────┐
│                    결제 보안 플로우                        │
├──────────────────────────────────────────────────────────┤
│  1. 클라이언트: 결제 요청                                  │
│         ↓                                                │
│  2. Google Play / App Store: 결제 처리                   │
│         ↓                                                │
│  3. 클라이언트: 영수증 수신                                │
│         ↓                                                │
│  4. 서버(Functions): 영수증 검증 ← Google/Apple API      │
│         ↓                                                │
│  5. 서버: 포인트 추가 (Firestore 트랜잭션)                 │
│         ↓                                                │
│  6. 클라이언트: 결과 수신                                  │
└──────────────────────────────────────────────────────────┘
```

### 9.3 Firestore 보안 규칙 패턴

```javascript
// 민감 필드 보호 패턴
match /users/{userId} {
  // 읽기: 인증된 사용자
  allow read: if request.auth != null;

  // 쓰기: 본인만, 민감 필드 제외
  allow update: if request.auth.uid == userId &&
    !request.resource.data.diff(resource.data).affectedKeys().hasAny([
      'pPoints',      // 포인트
      'gPoints',      // 수익
      'role',         // 역할
      'creatorTier',  // 등급
    ]);

  // 민감 필드: 관리자 또는 서버만
  allow update: if request.auth.token.admin == true;
}
```

---

## 10. 성능 최적화

### 10.1 앱 시작 최적화

```dart
// main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 필수 초기화만 await
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());

  // 비필수 초기화는 백그라운드에서
  _initializeInBackground();
}

void _initializeInBackground() {
  // FCM 초기화 (백그라운드)
  NotificationService().initialize();

  // App Check 초기화 (백그라운드)
  FirebaseAppCheck.instance.activate();
}
```

### 10.2 Firestore 배치 쿼리

```typescript
// 비효율적: N번 개별 쿼리
for (const userId of userIds) {
  const user = await firestore.collection('users').doc(userId).get();
}

// 효율적: 배치 쿼리 (10개씩)
async function batchGetUsers(userIds: string[]) {
  const users = [];

  for (let i = 0; i < userIds.length; i += 10) {
    const batch = userIds.slice(i, i + 10);
    const snapshot = await firestore
      .collection('users')
      .where(FieldPath.documentId(), 'in', batch)
      .get();

    users.push(...snapshot.docs.map(doc => doc.data()));
  }

  return users;
}
```

### 10.3 이미지 최적화

```dart
// 이미지 압축 후 업로드
Future<Uint8List?> compressImage(File file) async {
  return await FlutterImageCompress.compressWithFile(
    file.path,
    quality: 80,
    minWidth: 1024,
    minHeight: 1024,
  );
}

// 캐시된 네트워크 이미지 사용
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  cacheManager: DefaultCacheManager(),
)
```

### 10.4 스트림 페이지네이션

```dart
// 무한 스크롤 구현
Stream<List<Message>> getMessagesStream(String chatRoomId) {
  return _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)  // 처음 50개만
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList());
}

// 더 로드
Future<List<Message>> loadMoreMessages(
  String chatRoomId,
  DocumentSnapshot lastDoc,
) async {
  final snapshot = await _firestore
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .startAfterDocument(lastDoc)
      .limit(50)
      .get();

  return snapshot.docs
      .map((doc) => Message.fromFirestore(doc))
      .toList();
}
```

---

## 부록: 체크리스트

### 새 프로젝트 시작 시 체크리스트

#### Firebase 설정
- [ ] Firebase 프로젝트 생성
- [ ] Android 앱 등록 (SHA-1 포함)
- [ ] iOS 앱 등록
- [ ] Web 앱 등록
- [ ] google-services.json 다운로드 (Android)
- [ ] GoogleService-Info.plist 다운로드 (iOS)
- [ ] firebase_options.dart 생성 (`flutterfire configure`)

#### 인증 설정
- [ ] Firebase Auth 활성화
- [ ] Google Sign In 설정
- [ ] Apple Sign In 설정 (iOS)
- [ ] Kakao Developers 앱 생성
- [ ] 각 플랫폼별 URL Scheme 설정

#### 결제 설정 (Android)
- [ ] Google Play Console 앱 등록
- [ ] 인앱 상품 등록
- [ ] 서비스 계정 생성 및 권한 부여
- [ ] service-account.json Functions에 추가

#### 결제 설정 (iOS)
- [ ] App Store Connect 앱 등록
- [ ] 인앱 상품 등록
- [ ] Shared Secret 생성

#### 결제 설정 (Web)
- [ ] PortOne 계정 생성
- [ ] 채널 설정 (카카오페이 등)
- [ ] Webhook URL 등록

#### FCM 설정
- [ ] Android: google-services.json 확인
- [ ] iOS: APNs 키 업로드
- [ ] 알림 아이콘 생성 (Android)

#### 보안
- [ ] Firestore 보안 규칙 작성
- [ ] Storage 보안 규칙 작성
- [ ] App Check 활성화
- [ ] API 키 제한 설정

---

## 문서 정보

- **버전**: 1.0.0
- **최종 수정일**: 2024년
- **프로젝트**: 웹빵 (Webbang) - 텍스트 방탈출 게임 플랫폼
