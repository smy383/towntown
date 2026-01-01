import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? characterName;
  final List<Map<String, dynamic>>? characterStrokes; // 캐릭터 그림 데이터
  final DateTime joinDate;
  final String loginProvider; // 'google', 'apple', 'kakao'

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.characterName,
    this.characterStrokes,
    required this.joinDate,
    required this.loginProvider,
  });

  /// 캐릭터가 생성되었는지 확인
  bool get hasCharacter => characterName != null && characterName!.isNotEmpty;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      characterName: data['characterName'],
      characterStrokes: data['characterStrokes'] != null
          ? List<Map<String, dynamic>>.from(data['characterStrokes'])
          : null,
      joinDate: data['joinDate'] != null
          ? (data['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      loginProvider: data['loginProvider'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'characterName': characterName,
      'characterStrokes': characterStrokes,
      'joinDate': Timestamp.fromDate(joinDate),
      'loginProvider': loginProvider,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? characterName,
    List<Map<String, dynamic>>? characterStrokes,
    DateTime? joinDate,
    String? loginProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      characterName: characterName ?? this.characterName,
      characterStrokes: characterStrokes ?? this.characterStrokes,
      joinDate: joinDate ?? this.joinDate,
      loginProvider: loginProvider ?? this.loginProvider,
    );
  }
}
