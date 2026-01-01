import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 마을 내 플레이어 상태
class PlayerState {
  final String uid;
  final String characterName;
  final List<Map<String, dynamic>> characterStrokes;
  final double x;
  final double y;
  final bool facingRight;
  final bool isMoving;
  final bool isRunning;
  final String? chatMessage;
  final DateTime? chatTime;
  final DateTime lastSeen;

  PlayerState({
    required this.uid,
    required this.characterName,
    required this.characterStrokes,
    required this.x,
    required this.y,
    this.facingRight = true,
    this.isMoving = false,
    this.isRunning = false,
    this.chatMessage,
    this.chatTime,
    required this.lastSeen,
  });

  factory PlayerState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerState(
      uid: doc.id,
      characterName: data['characterName'] ?? '',
      characterStrokes: List<Map<String, dynamic>>.from(data['characterStrokes'] ?? []),
      x: (data['x'] as num?)?.toDouble() ?? 1000,
      y: (data['y'] as num?)?.toDouble() ?? 1000,
      facingRight: data['facingRight'] ?? true,
      isMoving: data['isMoving'] ?? false,
      isRunning: data['isRunning'] ?? false,
      chatMessage: data['chatMessage'],
      chatTime: data['chatTime'] != null
          ? (data['chatTime'] as Timestamp).toDate()
          : null,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'characterName': characterName,
      'characterStrokes': characterStrokes,
      'x': x,
      'y': y,
      'facingRight': facingRight,
      'isMoving': isMoving,
      'isRunning': isRunning,
      'chatMessage': chatMessage,
      'chatTime': chatTime != null ? Timestamp.fromDate(chatTime!) : null,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  PlayerState copyWith({
    String? uid,
    String? characterName,
    List<Map<String, dynamic>>? characterStrokes,
    double? x,
    double? y,
    bool? facingRight,
    bool? isMoving,
    bool? isRunning,
    String? chatMessage,
    DateTime? chatTime,
    DateTime? lastSeen,
  }) {
    return PlayerState(
      uid: uid ?? this.uid,
      characterName: characterName ?? this.characterName,
      characterStrokes: characterStrokes ?? this.characterStrokes,
      x: x ?? this.x,
      y: y ?? this.y,
      facingRight: facingRight ?? this.facingRight,
      isMoving: isMoving ?? this.isMoving,
      isRunning: isRunning ?? this.isRunning,
      chatMessage: chatMessage ?? this.chatMessage,
      chatTime: chatTime ?? this.chatTime,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// 플레이어 상태 관리 서비스
class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 플레이어 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _playersRef(String villageId) {
    return _firestore.collection('villages').doc(villageId).collection('players');
  }

  /// 마을 입장 - 플레이어 상태 생성
  Future<void> enterVillage({
    required String villageId,
    required String uid,
    required String characterName,
    required List<Map<String, dynamic>> characterStrokes,
    double initialX = 1000,
    double initialY = 1000,
  }) async {
    await _playersRef(villageId).doc(uid).set({
      'characterName': characterName,
      'characterStrokes': characterStrokes,
      'x': initialX,
      'y': initialY,
      'facingRight': true,
      'isMoving': false,
      'isRunning': false,
      'chatMessage': null,
      'chatTime': null,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// 플레이어 위치 업데이트
  Future<void> updatePosition({
    required String villageId,
    required String uid,
    required double x,
    required double y,
    required bool facingRight,
    required bool isMoving,
    required bool isRunning,
  }) async {
    await _playersRef(villageId).doc(uid).set({
      'x': x,
      'y': y,
      'facingRight': facingRight,
      'isMoving': isMoving,
      'isRunning': isRunning,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 채팅 메시지 전송
  Future<void> sendChat({
    required String villageId,
    required String uid,
    required String message,
  }) async {
    await _playersRef(villageId).doc(uid).set({
      'chatMessage': message,
      'chatTime': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 채팅 메시지 삭제 (말풍선 사라짐)
  Future<void> clearChat({
    required String villageId,
    required String uid,
  }) async {
    await _playersRef(villageId).doc(uid).set({
      'chatMessage': null,
      'chatTime': null,
    }, SetOptions(merge: true));
  }

  /// 마을 퇴장 - 플레이어 상태 삭제
  Future<void> leaveVillage({
    required String villageId,
    required String uid,
  }) async {
    await _playersRef(villageId).doc(uid).delete();
  }

  /// 마을 내 모든 플레이어 실시간 스트림
  Stream<List<PlayerState>> playersStream(String villageId) {
    return _playersRef(villageId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlayerState.fromFirestore(doc))
            .toList());
  }

  /// 오래된 플레이어 정리 (30초 이상 업데이트 없으면 삭제)
  Future<void> cleanupStalePlayers({
    required String villageId,
  }) async {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
    final query = await _playersRef(villageId)
        .where('lastSeen', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  /// Heartbeat - 주기적으로 lastSeen 업데이트
  Future<void> heartbeat({
    required String villageId,
    required String uid,
  }) async {
    await _playersRef(villageId).doc(uid).set({
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
